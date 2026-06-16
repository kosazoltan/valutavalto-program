---
title: Scaleway Standby Failover Runbook
created: 2026-05-13
last_tested: NEVER (initial — needs live drill)
maturity: DEPRECATED (streaming-HA kivezetve 2026-06-16)
trigger: Hetzner primary down (excvaluta.com 5xx > 3 min OR backend unreachable)
estimated_downtime: 2-5 min
---

# Scaleway Failover Runbook

> ## ⚠️ DEPRECATED (2026-06-16) — a streaming-HA KIVEZETVE (Local-First)
>
> A Hetzner↔Scaleway szinkron replikáció nyugdíjazva. **Prod-állapot:** Scaleway standby postgres
> leállítva, `standby_slot_0` slot eltávolítva, `synchronous_standby_names=''`, `sync-replication-guard`
> + `primary-watchdog` leállítva, a `deploy-standby` job és a failover-drill inaktív (`if:false`).
>
> **Új védvonal (Local-First):** lokális primary + Neon-backup (~5 perc RPO) + napi B2 `pg_dump` +
> kliens-outbox (idempotens resync) + on-host `freeze-watchdog`. **Helyreállítás új gépre:** a Neon-backup
> a Local-First igazság-forrás melletti teljes, friss másolat (lásd `project_neon_backup_local_first_rebuild_2026_06_16`).
>
> Az alábbi failover-eljárás **történeti referencia** — csak a streaming-HA visszaállítása után érvényes.

> **2-régiós HA** (történeti): Hetzner Helsinki (primary, 95.216.191.162) ↔ Scaleway Paris (warm standby, 163.172.152.234)

## 0. Mikor használd?

**Trigger feltételek (BÁRMELYIK):**
- `excvaluta.com` 5xx HTTP > 3 perc folyamatosan
- Hetzner VPS SSH timeout > 5 perc
- PostgreSQL primary nem fogad kapcsolatot Scaleway-ről > 2 perc
- Hosting provider (Hetzner) bejelentett outage > 10 perc

**NE használd** automatikusan ha:
- Csak rövid network blip (< 1 perc) — Cloudflare cache még kiszolgálja statikusan
- Csak deploy alatt vagyunk (CI rebuild ~3 perc, NEM hiba)
- A Scaleway replication lag > 5 perc (adatvesztés kockázat — előbb fontold meg)

## 1. Quick decision tree

```
Hetzner primary HEALTH?
│
├── HTTP 200 → NINCS failover, csak vizsgálat
│
├── HTTP 5xx / timeout > 3 perc
│   │
│   ├── Scaleway elérhető? (curl https://scaleway.excvaluta.com/api/v1/auth/bootstrap-status)
│   │   ├── HTTP 200 → FOLYTASD a 2. lépéssel (failover)
│   │   └── HTTP fail → IT-mérnök segítség (mindkettő down)
│   │
│   └── Replication lag check (Scaleway-en):
│       sudo -u postgres psql -c "SELECT NOW() - pg_last_xact_replay_timestamp();"
│       ├── < 60s → OK, kis adatvesztés (max 1 perc)
│       ├── 60s - 5 perc → CONFIRM kell (közepes kockázat)
│       └── > 5 perc → MEGGONDOLD, hívd a fő üzemeltetőt
```

## 2. Failover végrehajtás (Scaleway promote)

### 2.1 SSH-zás a standby-ra

```bash
ssh -i ~/.ssh/hetzner_ed25519 root@163.172.152.234
```

### 2.2 Failover script futtatás

```bash
cd /opt/valutavalto/deploy/hetzner/ha
bash failover-to-standby.sh
```

A script automatikusan:
1. **Pre-flight check** — DB tényleg standby-e? Lag elfogadható?
2. **`pg_ctl promote`** — DB primary-vé válik (~3 sec)
3. **Replication slot cleanup** — törli a `standby_slot_0`-t
4. **`.env` átírás** — `SPRING_FLYWAY_ENABLED=true`, `HIBERNATE_CONNECTION_DEFAULT_READ_ONLY=false`, `REDIS_ENABLED=true`
5. **Redis service start** — ha nem fut
6. **Backend restart** — új env-vel
7. **Health check** — max 120 sec várakozás HTTP 200-ra
8. **Smoke test** — DB írhatóság ellenőrzés
9. **Kiírja** a Cloudflare DNS swap parancsot

### 2.3 DNS átkapcsolás (Cloudflare)

**FONTOS — a `excvaluta.com` A record proxied=True** (Cloudflare proxy aktív):
- TTL manuális állítása nem hatékony (CF mindig "Auto" / 300s-t használ)
- A failover során CSAK az origin IP-t változtatjuk; a CF cache propagáció ~30-60 mp
- A DDoS védelem, SSL termination, caching mind megmarad failover után is
- A `scaleway.excvaluta.com` (proxied=False, TTL=60s) közvetlen elérést biztosít

**Credentials (verifikálva 2026-05-13):**

| Érték | Tárolás |
|---|---|
| `CF_API_TOKEN` (DNS:Edit jogosult cfut_ token) | `D:\repo\valutavalto-program\.env` |
| `CF_ZONE_ID` (excvaluta.com) | `de1ba622a4a79728302443f801da0af9` |
| `CF_DNS_RECORD_ID_EXCVALUTA` (A record, proxied=True) | `81945bd09d978b316d68409e6cfdb5d4` |
| `CF_DNS_RECORD_ID_SCALEWAY` (proxied=False, TTL=60s) | `37fb1d31eec4cb221c83046e176cf6a5` |

A failover script kiírja, de saját géped is csinálhatod:

```bash
# Tokent és record ID-ket a .env-ből töltsük be:
set -a; source D:/repo/valutavalto-program/.env; set +a
export STANDBY_IP="163.172.152.234"

# Lekérdezés: aktuális A record
curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=A&name=excvaluta.com" \
  | python -c "import sys,json; d=json.load(sys.stdin); r=d['result'][0]; print(r['id'], r['content'], r['ttl'])"

# Swap: excvaluta.com A → Scaleway IP
RECORD_ID="<id_from_above>"
curl -s -X PATCH \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"163.172.152.234","ttl":60,"proxied":true}'
```

**Várható DNS propagáció:** ~1-2 perc (TTL 60s ha előzőleg már 60-ra állítottuk; egyébként akár 5-10 perc).

### 2.4 Verifikáció

```bash
# Globális DNS ellenőrzés
dig +short excvaluta.com @1.1.1.1
dig +short excvaluta.com @8.8.8.8

# Health
curl -s -o /dev/null -w "%{http_code}\n" https://excvaluta.com/api/v1/auth/bootstrap-status

# Írás teszt (admin felhasználóval, normál tranzakció)
curl -s -X POST https://excvaluta.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"branchCode":"EBC","workerCode":"ADMIN","password":"..."}'
```

## 3. Failback (Hetzner visszaállítás)

> **FONTOS:** A korábbi Hetzner primary-t **NE indítsd el** simán — split-brain veszély (mindkettő primary-ként látja magát).

### 3.1 Hetzner backend leállítás

```bash
ssh root@95.216.191.162  # ha elérhető
systemctl stop valuta-backend
systemctl stop postgresql
```

### 3.2 Hetzner re-clone a Scaleway-ról — IRÁNY: a FRISS-adatú node-ról! (2026-06-05 fix)

> **KRITIKUS IRÁNY:** valós failover után a **Scaleway** tartja a legfrissebb adatot (ő vette át a
> write-okat). A Hetzner visszatéréskor ELAVULT → a Hetznernek a **Scaleway-ról** kell újraklónoznia
> (NEM fordítva!), különben elveszik a failover-ablak összes tranzakciója.
>
> **`pg_rewind` NEM használható** (wal_log_hints=off + nincs checksum). A re-clone **`pg_basebackup`**,
> a **WireGuardon** át (a publikus 5432 cloud-firewall-blokkolt). A Scaleway WG-IP-je: `10.8.0.2`.

```bash
# Elofeltetel: a Scaleway (uj primary) figyeljen a WG-IP-n + engedje a Hetznert (10.8.0.1):
#   ssh root@163.172.152.234
#   sudo -u postgres psql -c "ALTER SYSTEM SET listen_addresses='localhost,163.172.152.234,10.8.0.2';"
#   echo 'host replication replicator 10.8.0.1/32 scram-sha-256' >> /etc/postgresql/16/main/pg_hba.conf
#   echo 'host all         replicator 10.8.0.1/32 scram-sha-256' >> /etc/postgresql/16/main/pg_hba.conf
#   systemctl restart postgresql@16-main   # ha a listen valtozott

# Hetzner-en (a friss adat a Scaleway-rol, WireGuardon):
RPWD=$(grep -oE "password=[^ ']+" /var/lib/postgresql/16/main/postgresql.auto.conf | head -1 | cut -d= -f2-)
systemctl stop valuta-backend postgresql@16-main
rm -rf /var/lib/postgresql/16/main
sudo -u postgres /usr/lib/postgresql/16/bin/pg_basebackup -D /var/lib/postgresql/16/main \
  -d "host=10.8.0.2 port=5432 user=replicator password=$RPWD application_name=hetzner_standby dbname=postgres" \
  -R -X stream -c fast
echo "primary_slot_name = 'standby_slot_0'" >> /var/lib/postgresql/16/main/postgresql.auto.conf
chown -R postgres:postgres /var/lib/postgresql/16/main; chmod 700 /var/lib/postgresql/16/main
systemctl start postgresql@16-main    # most a Hetzner a Scaleway STANDBY-ja, felzarkozik

# Ezutan TERVEZETT switchover: Hetzner-t promote + Scaleway-t re-clone Hetznerrol (2.1/2.2 forditva),
# vagy hagyd a Scaleway-t primary-nak amig kenyelmes a visszavaltas. A szinkron-config (sync_state)
# az uj primary-n allitando be (synchronous_standby_names a masik node app_name-jere).
```

### 3.3 DNS visszaállítás Cloudflare-en

Ugyanaz a curl mint 2.3-ban, csak `content="95.216.191.162"`.

### 3.4 Scaleway visszaállítás standby-vé

```bash
ssh root@163.172.152.234
# Lassú út: install-standby.sh újrafuttatás
# Gyors út: csak a backend env visszaállítás warm modra
cp /opt/valutavalto/backend/.env.bak.before-failover /opt/valutavalto/backend/.env
systemctl restart valuta-backend
```

## 4. Drill végrehajtás — két opció

### Opció A — Readiness Check (manuális drill)

Egy Anthropic scheduled routine vasárnaponként public health-checket csinál + checklist-et küld a usernek SSH-parancsokkal. A user manuálisan SSH-zik és lefuttatja.

Routine ID: `trig_01WpU5Vts7DnXE2d4XSnnW5Q` (egyszeri, 2026-05-17 04:00 CEST).

### Opció B — Teljesen automata GitHub Actions workflow ✅ **PRODUCTION-READY**

**Workflow:** `.github/workflows/scaleway-failover-drill.yml`
**Trigger:** `workflow_dispatch` (manuális indítás GitHub UI-ról vagy CLI-ből)

**Drill szintek (input):**
- **Level 1:** pg_ctl promote + pg_rewind failback (DNS érintetlen) — **biztos, ajánlott első**
- **Level 2:** Level 1 + Cloudflare DNS swap 5 percre + rollback (közepes kockázat)
- **Level 3:** Level 2 + adatvesztés mérés (legkomplexebb)

**Dry-run mód:** `dry_run=true` → csak pre-flight HTTP + replikáció check, NEM csinál promote-ot.

**Indítás:**

```bash
# Dry-run (mindig biztonságos):
gh workflow run scaleway-failover-drill.yml -f drill_level=1 -f dry_run=true

# Drill 1 ÉLESBEN (pg_ctl promote + failback):
gh workflow run scaleway-failover-drill.yml -f drill_level=1 -f dry_run=false

# Drill 2 (élesi DNS swap):
gh workflow run scaleway-failover-drill.yml -f drill_level=2 -f dry_run=false
```

Vagy: GitHub UI → Actions → Scaleway Failover Drill → Run workflow.

**Verifikálva 2026-05-13:** dry-run mód PASS (pre-flight + dry-run summary jobs).

### Drill végrehajtási checklist

- [x] **Workflow setup** — `.github/workflows/scaleway-failover-drill.yml` mergelve main-re
- [x] **GitHub Secrets** — SCALEWAY_SERVER_IP, SCALEWAY_SSH_PRIVATE_KEY, CF_API_TOKEN, CF_ZONE_ID, CF_DNS_RECORD_ID_EXCVALUTA mind setupolva
- [x] **Dry-run mód** verifikálva PASS
- [ ] **Drill 1 ÉLESBEN** — promote + pg_rewind failback (DNS érintetlen) — alacsony forgalmú időszakban
- [ ] **Drill 2 ÉLESBEN** — Drill 1 + CF DNS swap 5 percre
- [ ] **Drill 3 ÉLESBEN** — Drill 2 + adatvesztés mérés
- [ ] **Replikáció catchup verify** failback után (lag normalizálódik 60s alá)

## 5. Monitoring (jövőbeli, AJÁNLOTT)

- **UptimeRobot** vagy **Cloudflare Health Check** — 5 percenként `https://excvaluta.com/api/v1/auth/bootstrap-status`, ha 3× egymás után HTTP != 200 → email/SMS riasztás
- **Cloudflare Load Balancer** — automatikus DNS failover (origin pool: Hetzner primary, Scaleway origin pool fallback) — ~14 USD/hó
- **Replication lag riasztás** — Scaleway-en cron 1 percenként: ha `pg_last_xact_replay_timestamp()` > 5 min → email

## 6. Ismert kockázatok

| Kockázat | Mitigation |
|---|---|
| **Split-brain** (mindkettő primary) | NE indítsd a régi primary-t pg_rewind nélkül |
| **Adatvesztés** (replikációs lag) | TTL/replication monitoring, automatikus DNS swap előtt lag check |
| **Cloudflare API token expiry** | Token rotáció 6 havonta, 1Password-ben tartva |
| **Failover script bug** | Drill-ek (4.) |
| **SSL cert lejárat** Scaleway-en | Let's Encrypt auto-renew (certbot timer) |
| **Disk full** Scaleway-en | DEV1-M 40 GB SSD, monitoring szükséges |

## 7. Kapcsolatok

- **Üzemeltetés:** Kósa Zoltán (kosa.zoltan.ebc@gmail.com)
- **Cloudflare** account: excvaluta.com zone
- **Scaleway** account: SCW0B18D88VQE9JDCHJ9
- **Hetzner** projekt: ebc-prod

## 8. Aktuális komponens-állapot (warm standby, 2026-05-13)

| Komponens | Állapot |
|---|---|
| Backend | ✅ v2.5.49, fut, HTTP 200 (read-only DB mellett is OK ha SELECT-only) |
| PostgreSQL | ✅ streaming replikáció Hetzner-ről, recovery mode |
| Nginx | ✅ aktív, SSL Let's Encrypt (scaleway.excvaluta.com) |
| Redis | ⚠️ telepítve, jelszó beállítva, **DE service inaktív** (warm mode) |
| `.env` | ⚠️ `REDIS_ENABLED=false`, `HIBERNATE_READ_ONLY=true` (failover script flippeli) |
| failover-to-standby.sh | ✅ v2.5.49+ bővítve (env update + Redis start + health check) |
| Cloudflare DNS auto-swap | ❌ MANUÁLIS (curl parancs) |
| Health-check riasztás | ❌ nincs |
| End-to-end drill | ❌ még nincs tesztelve |
