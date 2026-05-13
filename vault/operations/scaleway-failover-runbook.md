---
title: Scaleway Standby Failover Runbook
created: 2026-05-13
last_tested: NEVER (initial — needs live drill)
maturity: documented-untested
trigger: Hetzner primary down (excvaluta.com 5xx > 3 min OR backend unreachable)
estimated_downtime: 2-5 min
---

# Scaleway Failover Runbook

> **2-régiós HA**: Hetzner Helsinki (primary, 95.216.191.162) ↔ Scaleway Paris (warm standby, 163.172.152.234)

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

### 3.2 PG rewind a Scaleway-ról (új primary)

```bash
# Hetzner-en
sudo -u postgres pg_rewind \
  --target-pgdata=/var/lib/postgresql/16/main \
  --source-server="host=163.172.152.234 port=5432 user=replicator password=<replicator_pwd>"

# standby.signal létrehozás
sudo -u postgres touch /var/lib/postgresql/16/main/standby.signal

# primary_conninfo beállítása
echo "primary_conninfo = 'host=163.172.152.234 port=5432 user=replicator password=<pwd>'" \
  | sudo -u postgres tee -a /var/lib/postgresql/16/main/postgresql.auto.conf

# PG start (most már standby)
systemctl start postgresql
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

## 4. Tesztelési checklist (még NEM tesztelt!)

> Élesben tesztelés előtt: **alacsony forgalmú időszakban** (hétvége hajnal 4-6 között), maintenance ablak kiírva.

- [ ] **Drill 1:** failover-to-standby.sh execution (PG promote + backend restart, DNS swap KIHAGYVA)
- [ ] **Drill 2:** End-to-end DNS swap rövid időre (Scaleway-en a forgalom, 5 perc majd vissza)
- [ ] **Drill 3:** Failback eljárás (pg_rewind + Hetzner standby)
- [ ] **Drill 4:** Adatvesztés mérés (Hetzner-en utolsó pillanatban tranzakció, Scaleway-en ellenőrzés)
- [ ] **Drill 5:** Replikáció helyreállás failback után (lag normalizálódik 60s alá)

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
