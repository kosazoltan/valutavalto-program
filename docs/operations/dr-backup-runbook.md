# Disaster Recovery & Backup runbook — Valutaváltó ERP

> **Hatókör:** Hetzner production környezet (`excvaluta.com`).
> **Célközönség:** rendszergazdák, üzemeltetésért felelős fejlesztők, DPO.
> **Utolsó frissítés:** 2026-05-06.
> **NEM végfelhasználói dokumentum** (a kollégák számára a telepítő automatikusan kezel mindent — lásd `CLAUDE.md` "nem-informatikus végfelhasználók alapelv").

---

## 1. Production architektúra (tényszerű állapot)

| Réteg | Komponens | Hely | Forrás |
|---|---|---|---|
| Edge / TLS | Caddy reverse proxy | Hetzner VPS, port 443 | `application-production.properties` `server.forward-headers-strategy=native` |
| App | Spring Boot 4.0.6 + Tomcat 11 | Hetzner VPS, port 8080 (loopback) | `application.properties` `server.port=8080` |
| Management | Actuator (health/metrics/prometheus) | Hetzner VPS, port 9090 (loopback only) | `application-production.properties:120` `management.server.address=127.0.0.1` |
| DB | PostgreSQL | Hetzner (külön host vagy ugyanaz, env: `DATABASE_URL`) | `application-production.properties:34` |
| DNS | `excvaluta.com`, `www.excvaluta.com` | Cloudflare | `config/production-urls.json` |
| Optional fallback | `primary.excvaluta.com`, `scaleway.excvaluta.com` | `config/production-urls.json:19-20` | csak névtér; aktív HA failover script **GAP** — lásd 8. szakasz |
| Optional sync | Neon DB sync | `app.neon-sync.enabled=false` (default) | `application.properties:194` — alapból kikapcsolva |

**Egy backend node + egy PostgreSQL node** — verifikálva a `DATABASE_URL` egyetlen JDBC stringből deriválódik, nincs replikációs konfig a repoban.

---

## 2. Backup eljárás

### 2.1 Jelenlegi állapot — repo bizonyíték + telepítési ellenőrzés

A repo tartalmaz commit-olt backup telepítőt és systemd timer-t:

- `deploy/hetzner/scripts/setup-backup.sh`
- `deploy/hetzner/scripts/backup-pg.sh`
- `deploy/hetzner/systemd/valuta-backup.service`
- `deploy/hetzner/systemd/valuta-backup.timer`
- `deploy/hetzner/backup/install-b2-backup.sh` Backblaze B2 off-site feltöltéshez

| Tétel | Állapot | Megjegyzés |
|---|---|---|
| Application-szintű backup ütemező | **COMMITTED / VERIFY DEPLOY** | `valuta-backup.timer` |
| `pg_dump` napi mentés | **COMMITTED / VERIFY DEPLOY** | `backup-pg.sh`, atomikus dump + lokális retention |
| Off-site replikáció | **COMMITTED / VERIFY DEPLOY** | Nextcloud WebDAV és B2 script is van; élő credential + timer státusz SSH-val ellenőrizendő |
| Neon DB sync (`app.neon-sync.enabled`) | konfigurált, de **kikapcsolt** | `application.properties:194` default `false` |
| Backup integritás-ellenőrzés (test restore) | **VERIFY** | havi DR drillben kötelező |

**P0 javasolt akció:** SSH-val verifikálni, hogy `systemctl list-timers valuta-backup.timer` aktív, és a legutóbbi backup sikeresen feltöltődött off-site tárhelyre.

### 2.2 Javasolt backup eljárás (iparági standard)

#### Daily logical dump

```bash
# /etc/cron.d/valuta-pg-backup (Hetzner VPS, root)
# Daily 02:30 UTC pg_dump, gzip, retention rotate
30 2 * * *  postgres  /usr/local/bin/valuta-pg-backup.sh >> /var/log/valuta-backup.log 2>&1
```

`/usr/local/bin/valuta-pg-backup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/var/backups/valuta"
TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
DUMP_FILE="${BACKUP_DIR}/valuta-${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

# Custom format dump (pg_restore --clean -hez), gzip-pel
pg_dump \
  --host=localhost \
  --username=valuta_user \
  --dbname=valuta \
  --format=custom \
  --no-owner --no-privileges \
  --file="${BACKUP_DIR}/valuta-${TIMESTAMP}.dump"

# Egyidejűleg sima SQL dump (vész esetén szöveges helyreállításhoz)
pg_dump \
  --host=localhost \
  --username=valuta_user \
  --dbname=valuta \
  --no-owner --no-privileges \
  | gzip -9 > "$DUMP_FILE"

# SHA-256 integritás-ellenőrzés
sha256sum "${BACKUP_DIR}/valuta-${TIMESTAMP}.dump" "$DUMP_FILE" \
  > "${BACKUP_DIR}/valuta-${TIMESTAMP}.sha256"

# Off-site upload — Hetzner Storage Box (rsync over SSH)
rsync -av --remove-source-files \
  "${BACKUP_DIR}/valuta-${TIMESTAMP}".* \
  storagebox.your-storagebox.de:/home/valuta-backup/

# Retention rotate (lokális GFS): 7 napi + 4 heti + 12 havi
find "$BACKUP_DIR" -name 'valuta-*.dump' -mtime +7 -delete
```

#### Retention policy (javasolt — iparági standard, GFS)

| Szint | Retention | Tárhely | Cél |
|---|---|---|---|
| Daily | 7 nap | Hetzner local disk | gyors RPO |
| Weekly | 4 hét | Hetzner Storage Box (off-site) | hosszabb távú visszaállítás |
| Monthly | 12 hónap | Hetzner Storage Box | NGM/GDPR audit |
| Yearly | 8 év | Storage Box + Glacier-szerű kompatibilis tier | `application.properties:123` `retention.financial-transactions.years=8` üzleti retention-nel összhangban |

**8 év** azért, mert a `retention.financial-transactions.years=8` (`application.properties:123`) a tranzakciókra üzleti retention. Az archív backup nem helyettesíti az élő DB retention logikáját, de fedezet katasztrófa esetén.

---

## 3. Restore eljárás

### 3.1 Teljes DB restore (catastrophic loss)

> **ELŐFELTÉTEL:** új vagy tisztított PostgreSQL instance, DBA jogosultság, a backup fájl elérhető.
> A `repair-on-migrate=true` PRODUCTION profilban aktív (`application-production.properties:71`) — restore után ez automatikusan kezeli a migration checksum-mismatch eseteket az első indításkor.

```bash
# 1. Backend leállítása (hogy ne írjon a DB-be restore közben)
sudo systemctl stop valuta-backend

# 2. Üres adatbázis létrehozása
sudo -u postgres psql -c "DROP DATABASE IF EXISTS valuta;"
sudo -u postgres psql -c "CREATE DATABASE valuta OWNER valuta_user;"

# 3. Restore custom format dumpból
pg_restore \
  --clean --if-exists \
  --no-owner --no-privileges \
  --host=localhost \
  --username=valuta_user \
  --dbname=valuta \
  --jobs=4 \
  /var/backups/valuta/valuta-YYYYMMDD-HHMMSS.dump

# Vagy gzipped SQL-ből:
gunzip -c /var/backups/valuta/valuta-YYYYMMDD-HHMMSS.sql.gz \
  | psql --host=localhost --username=valuta_user --dbname=valuta

# 4. Verify row counts (audit log + transactions a 2 legkritikusabb)
sudo -u postgres psql -d valuta -c \
  "SELECT 'audit_log' tbl, COUNT(*) FROM audit_log
   UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
   UNION ALL SELECT 'aml_report', COUNT(*) FROM aml_report;"

# 5. Backend indítása
sudo systemctl start valuta-backend

# 6. Smoke test — lásd 4. szakasz
```

### 3.2 Point-in-time recovery (PITR)

**GAP**: WAL archiválás nincs konfigurálva a repoban. Iparági standard megoldás: PostgreSQL `archive_mode=on` + `archive_command` a Storage Box-ra. Bevezetése külön sprint feladat.

---

## 4. Smoke test minden restore után

Restore vagy DR-event után **MINDEN tételt zöldnek kell látni** a backend újraindítása előtt és után.

```bash
# 4.1 Bootstrap-status (HTTP 200 elvárt)
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  https://excvaluta.com/api/v1/auth/bootstrap-status

# 4.2 Public branches list (CompanyCode=EBC, non-empty array elvárt)
curl -s "https://excvaluta.com/api/v1/public/branches?companyCode=EBC" \
  | jq 'length'

# 4.3 Actuator health (loopback only — SSH-val a host-on)
curl -s http://127.0.0.1:9090/actuator/health | jq '.status'   # "UP" elvárt

# 4.4 Audit log hash-lánc folytonossága (lásd AuditLogService.applyHashChain)
sudo -u postgres psql -d valuta -c \
  "SELECT COUNT(*) total,
          COUNT(*) FILTER (WHERE entry_hash IS NULL) AS missing_hash,
          COUNT(*) FILTER (WHERE previous_hash IS NULL AND id <> (SELECT MIN(id) FROM audit_log)) AS broken_chain
   FROM audit_log;"

# 4.5 Flyway state check
sudo -u postgres psql -d valuta -c \
  "SELECT version, description, success FROM flyway_schema_history
   ORDER BY installed_rank DESC LIMIT 5;"

# 4.6 Admin login (Setup Wizard utáni admin user-rel)
# — manuálisan a https://excvaluta.com/admin/login URL-en
```

Ha **bármelyik** lépés FAIL → ne indítsd el a klienseket; eszkalálj DPO/fejlesztő felé.

---

## 5. RPO / RTO célok

| Mutató | Cél | Indoklás |
|---|---|---|
| RPO (Recovery Point Objective) | **max 24 óra** napi backup mellett | daily 02:30 UTC dump + GFS retention. **GAP**: PITR-rel <15 perc lenne elérhető. |
| RTO (Recovery Time Objective) | **~1 óra** restore + **30 perc** verifikáció | Hetzner VPS (single node, <50 GB DB), `pg_restore --jobs=4`. |
| Maximum tűréshatár (MTPD) | 4 óra | Üzletmenet-folytonossági becslés (a klienseknek SQLite + 30s retry-os offline puffere van — lásd 7. szakasz). |

---

## 6. Failover scenario — Hetzner VPS leáll

**Jelen állapot:** **GAP** — nincs aktív hot-standby. A `config/production-urls.json:19-20` definiált `primary.excvaluta.com` és `scaleway.excvaluta.com` névtér csak előkészület, nincs commit-olt failover automatika.

### 6.1 Manuális failover lépések (jelenleg)

1. **Diagnosztika:** Hetzner Cloud konzol → instance state.
   - Ha "Running" de unreachable → SSH-val belépni, `journalctl -u valuta-backend` log.
   - Ha "Off" → restart Hetzner konzolból.
2. **Cloudflare DNS check:** `excvaluta.com` A-record IP egyezés.
3. **TLS proxy (Caddy) restart:** `sudo systemctl restart caddy` SSH-val.
4. **Backend restart:** `sudo systemctl restart valuta-backend`.
5. **DB elérhetőség:** `pg_isready -h localhost -p 5432`.
6. **Smoke test** (4. szakasz).

### 6.2 Tartós kiesés esetén (Hetzner DC down >2 óra)

- **Új Hetzner instance** spawn (Ubuntu 24.04, Hetzner cloud-init script — **GAP**: nincs commit-olt Terraform/Ansible).
- **DB restore** legutóbbi off-site backupból (3.1).
- **Cloudflare DNS A-record** átállítás új IP-re.
- **Hetzner deploy CI** rerun: a `.github/workflows/deploy-hetzner.yml` workflow-t manuálisan triggerelni a main HEAD-ről.
- **Smoke test + monitoring re-baseline**.

---

## 7. Telepített kliens viselkedés Hetzner kiesésnél

A pénztáros Electron kliens (`penztar-client/`) **offline-képes**:

- **SQLite** lokális tárolás (forrás: `penztar-client/electron/sync-engine.ts`).
- **Sync engine 30 másodperces retry** ciklus a backend felé.
- **ESET TLS proxy retry pattern**: api:fetch IPC handler 3x retry-jal (lásd `~/.claude/projects/.../memory/feedback_eset_retry_pattern.md`, commit `c2a217a8`).
- **Tranzakció rögzítés** offline módban folytatható; sync visszaáll, amint a backend újra elérhető.
- **Bizonylatszám** a kliens-oldalon NEM generálódik draft formátumban (NGM 23/2014 megfelelőség: szerver oldali `ReceiptSequenceService` PESSIMISTIC LOCK-kal, formátum `V<branchCode>NNNNNN` — lásd `backend/.../ReceiptSequenceService.java:91`). Outage esetén a kliens **vár a sync-re**, nem ad kifelé bizonylatot draft sorszámmal.

> **Üzemeltetői implikáció:** rövid (<1 óra) kiesés alatt a pénztárak normál módon dolgoznak. Tartós kiesés (>4 óra) esetén szervezeti döntés kell a manuális (papír alapú) bizonylatozás aktiválásáról.

---

## 8. Monthly DR drill checklist

Havi rendszerességgel, a fejlesztő (vagy DPO) végezze el:

- [ ] **Backup integritás** — legutóbbi `valuta-*.dump` fájl SHA-256 ellenőrzése a `.sha256` mellett.
- [ ] **Test restore staging-be** — új Hetzner instance / lokális Docker postgres, `pg_restore` sikeres, row count >0 a kritikus táblákra (`transactions`, `audit_log`, `aml_report`, `customer`).
- [ ] **Smoke test staging restore-on** (4. szakasz teljes lista).
- [ ] **RTO mérés** — start time → smoke test green time, dokumentálni a vault-ba (`D:\valutavalto-vault\sessions\YYYY-MM-DD-dr-drill.md`).
- [ ] **Off-site backup ellenőrzés** — Storage Box-on lévő legrégebbi és legújabb dump letölthetősége.
- [ ] **Audit log hash-lánc verifikáció** restore után (lásd 4.4).
- [ ] **Flyway migration history** — a staging restore és prod state összevetése (`flyway_schema_history` tábla).
- [ ] **PostgreSQL verzió kompatibilitás** — `pg_dump` és target instance `SELECT version();` egyezés vagy supported upgrade path.

---

## 9. Incident response — kollégáknak küldendő sablon

> **A nem-informatikus végfelhasználó alapelv szerint a kollégákat NEM technikai részletekkel terheljük.** A telepítő automatikusan retry-ol; offline módban dolgozhatnak.

**Sablon — rövid kiesés (< 1 óra):**

```
Tisztelt Kollégák,

Az excvaluta.com szerver oldali karbantartás miatt rövid ideig nem elérhető.
A Pénztár program offline módban tovább működik — folytassátok a munkát normálisan.
A tranzakciók automatikusan szinkronizálódnak, amint a kapcsolat helyreáll.

Ha bármilyen hiba képernyőre kiírást láttok, NE csináljatok semmit, csak várjatok 1-2 percet.
A program magától újrapróbálkozik.

Becsült helyreállás: <időpont>
```

**Sablon — tartós kiesés (> 2 óra):**

```
Tisztelt Kollégák,

A központi szerver hosszabb karbantartás alatt áll.
Kérjük, a következő órákra váltsatok manuális (papír alapú) bizonylatozásra
a vészhelyzeti tömbök használatával.

NE indítsatok új tranzakciót a Pénztár programban, amíg külön értesítést nem kaptok.
Az addigi offline rögzített tranzakciók biztonságban vannak, automatikusan
felszinkronizálódnak.

Becsült helyreállás: <időpont>
Soron kívüli kérdés: kosa.zoltan.ebc@gmail.com
```

---

## 10. Hivatkozások és gap-list

**Hivatkozott források:**

- `backend/src/main/resources/application-production.properties` — production config.
- `backend/src/main/resources/application.properties:123` — `retention.financial-transactions.years=8`.
- `backend/src/main/java/hu/puzzleir/valuta/service/AuditLogService.java:135` — hash-lánc tamper-evidence (SHA-256 chained).
- `backend/src/main/java/hu/puzzleir/valuta/service/ReceiptSequenceService.java` — PESSIMISTIC LOCK + per-branch sorszám.
- `config/production-urls.json` — production URL SSOT.
- `D:\valutavalto-vault\feedback\own-server-data-access.md` — saját szerver hozzáférési alapelv.
- Auto-issue eszkaláció: `backend/src/main/java/hu/puzzleir/valuta/service/GitHubIssueAutoCreator.java`.

**Gap-list (P0 / P1 javítandó):**

| Gap | Prioritás | Javasolt fix |
|---|---|---|
| Backup timer production deploy verifikáció | P0 | `systemctl list-timers valuta-backup.timer` + legfrissebb off-site dump letöltési teszt |
| Off-site credentialek productionben | P0 | Nextcloud/B2 env kitöltés + próba-feltöltés |
| WAL archiválás (PITR) | P1 | PostgreSQL `archive_mode=on` + `archive_command` |
| Failover automatika | P1 | Terraform + cloud-init template, Cloudflare API DNS-failover script |
| Monthly DR drill log | P1 | `D:\valutavalto-vault\sessions\YYYY-MM-DR.md` minden hónap 1-jén |
| Backup encryption-at-rest | P2 | `gpg --symmetric` a `.dump`-ra Storage Box upload előtt |

**Lezárás:** a repo oldali backup automatika már rendelkezésre áll. Product-ready kapu továbbra is az élő hoston végzett timer/off-site/restore verifikáció.
