# High-Availability (HA) - Warm-standby VPS setup

> ## ⚠️ DEPRECATED (2026-06-16) — a streaming-HA KIVEZETVE (Local-First konszolidáció)
>
> A Hetzner↔Scaleway szinkron streaming-replikációt nyugdíjaztuk. Konkrét prod-állapot:
> - Scaleway standby postgres **leállítva** (`valuta-standby-fr`).
> - A Hetzner replikációs slot (`standby_slot_0`) **eltávolítva**, `synchronous_standby_names=''`
>   (a primary nem vár senkire), a `sync-replication-guard` és `primary-watchdog` **leállítva/disabled**.
> - A `deploy-standby` job (`deploy-hetzner.yml`, `if:false`) és a `scaleway-failover-drill.yml`
>   (minden job `if:false` — a `workflow_dispatch` trigger megmarad, de a job-ok skip-elnek) **inaktív**.
>
> **Új védvonal (Local-First):** lokális Hetzner primary (a backend ezt szolgálja) + **Neon-backup**
> (5 percenként, ~5 perc RPO, más felhő) + **napi B2 `pg_dump`** + **kliens-outbox** (pénztári adat a
> gépeken, idempotens resync) + on-host **`freeze-watchdog`** (auto-restart). Új gép ~5 perc alatt
> felállítható a Neon-backupból; a kliens-outbox felresync-eli a backup óta keletkezett tételeket.
>
> **Visszafordítás** (ha újra kell a streaming-HA): `install-standby.sh` + a slot újralétrehozása +
> `synchronous_standby_names='scaleway_standby'` + a guard/watchdog újraindítása + a `deploy-standby` /
> `drill` `if:false` levétele. A lenti dokumentáció **történeti referencia**.

A 60 pénztárhoz szükséges üzletfolytonossági rendszer. Ha a primary Hetzner VPS leáll, a pénztárak 2-5 percen belül átállnak a standby VPS-re, és a munka folytatódik.

## FONTOS: MULTI-PROVIDER standby (nem csak Hetzner!)

A standby-t **másik szolgáltatónál** érdemes elhelyezni, hogy a cég-szintű Hetzner incidensek (BGP/DNS/billing/account-suspension/hacker-támadás) NE vigyenek el mindent egyszerre. Tapasztalati esetek: 2023 szept. Hetzner globális outage (BGP), 2021 márc. OVH Strasbourg tűz.

### Ajánlott standby providerek (60 pénztárhoz)

| Provider | Ár/hó | Spec | Régió | Regisztráció |
|----------|-------|------|-------|--------------|
| **Contabo VPS S** | **4.50 EUR** | 4 vCPU, 8 GB RAM, 50 GB NVMe | Nürnberg (DE) | https://contabo.com/en/vps/ |
| **Scaleway DEV1-M** | ~6 EUR | 3 vCPU, 4 GB, 40 GB SSD | Párizs (FR) | https://www.scaleway.com/en/pricing/ |
| **OVH VPS Essential** | ~6 EUR | 2 vCPU, 4 GB, 80 GB NVMe | Gravelines (FR) | https://www.ovhcloud.com/en/vps/ |
| **DigitalOcean 2GB** | ~11 EUR | 2 vCPU, 2 GB, 60 GB SSD | Frankfurt (DE) | https://www.digitalocean.com |
| **Linode Shared 4GB** | ~22 EUR | 2 vCPU, 4 GB, 80 GB SSD | Frankfurt (DE) | https://www.linode.com |

**Ajánlásaim:**

- **Legolcsóbb multi-provider** (~9.50 EUR össz): **Hetzner + Contabo** - két német cég, két adatközpont (Helsinki + Nürnberg), max ár-érték
- **Geo-redundáns** (~11 EUR össz): **Hetzner + Scaleway** - két ország (DE + FR), két cég
- **Teljes HA** (~14.50 EUR össz): **Hetzner + Contabo + Scaleway** - 3-régiós, failover prioritás: primary -> Contabo -> Scaleway

### A scriptek provider-agnosztikusak

Az `install-standby.sh` + `install-primary.sh` NEM Hetzner-specifikus. Bármely Ubuntu 24.04 + PostgreSQL 16 + SSH VPS-en működnek. Provider-specifikus megjegyzések:

- **Contabo**: első belépés után SSH kulcs feltöltése (console -> My Services -> server -> SSH Keys); `PermitRootLogin prohibit-password`-re vált
- **Scaleway**: console-ba előre feltöltöd a SSH kulcsot (Settings -> SSH Keys), a VPS-hez már attached
- **OVH**: SoYouStart / OVH manager-ben setupolod a SSH kulcsot
- **DigitalOcean / Linode**: a fiók oldalról SSH kulcs feltöltés, aztán a VPS-hez auto-attached

### Kiváltott kockázatok

| Kockázat | Egy-provider (Hetzner×2) | Multi-provider (Hetzner + Contabo/Scaleway) |
|----------|--------------------------|----------------------------------------------|
| Hardver hiba | Védett | Védett |
| Adatközpont kiesés | Védett (HEL1 != HEL2) | Védett (két cég, két DC) |
| Provider hálózati outage | NEM védett (mindkettő Hetzner) | Védett (másik független) |
| Account suspension / billing | NEM védett (egy account) | Védett (külön fiók) |
| Cég-szintű incidens | NEM védett | Védett |
| EU-szintű katasztrófa | Nem védett | Részlegesen (EU-n belül) |


## Architektúra

```
+------------------+    WAL streaming    +------------------+
|  PRIMARY  HEL1   |  ---------------->  |  STANDBY  HEL2   |
|  excvaluta.com   |                     |  (read-only)     |
|  95.216.191.162  |                     |  <új IP>         |
+--------+---------+                     +---------+--------+
         |                                         |
         v                                         v
     Cloudflare DNS (TTL 60s, manual or health-check failover)
                         |
                         v
              Pénztárak (Electron, primary URL + fallback)
```

**Költség: ~5 EUR/hó** (Hetzner CX22 HEL2 régióban)

## Telepítés - 3-régiós (Hetzner + Contabo + Scaleway)

### 1. lépés — VPS-ek rendelése

**Standby #1 (warm) - Contabo Nürnberg:**
- https://contabo.com/en/vps/ -> VPS S (4 vCPU, 8 GB, 50 GB NVMe) ~4.50 EUR/hó
- OS: Ubuntu 24.04 LTS
- Kezdeti root jelszó a visszaigazoló e-mailben; első SSH után kulcsot feltölteni

**Standby #2 (cold) - Scaleway Paris:**
- https://www.scaleway.com -> Instance -> DEV1-M (3 vCPU, 4 GB, 40 GB SSD) ~6 EUR/hó
- Régió: fr-par-1 (Paris)
- OS: Ubuntu 24.04 LTS
- SSH kulcs előre feltöltendő az account-ba

Jegyezd fel mindkét VPS publikus IPv4 címét.

### 2. lépés — Primary (Hetzner) konfigurálása

```bash
ssh root@95.216.191.162
cd /opt/valutavalto && git pull

# STANDBY_IPS sorrend számít: 0. a warm (Contabo), 1. a cold (Scaleway).
STANDBY_IPS="<CONTABO_IP>,<SCALEWAY_IP>" REPLICATION_PASSWORD="$(openssl rand -hex 24)"     bash deploy/hetzner/ha/install-primary.sh

# Mentsd el a REPLICATION_PASSWORD-öt jelszókezelőbe! A primary kiírja.
```

Ez létrehoz 2 replication slot-ot: `standby_slot_0` (Contabo), `standby_slot_1` (Scaleway).

### 3. lépés — Contabo (warm standby) bootstrap

```bash
ssh root@<CONTABO_IP>
apt update && apt install -y fail2ban git
git clone https://github.com/kosazoltan/valutavalto-program.git /opt/valutavalto
cd /opt/valutavalto

PRIMARY_IP=95.216.191.162 REPLICATION_PASSWORD="<ugyanaz>" SLOT_NAME=standby_slot_0     bash deploy/hetzner/ha/install-standby.sh
```

### 4. lépés — Scaleway (cold standby) bootstrap

```bash
ssh root@<SCALEWAY_IP>
apt update && apt install -y fail2ban git
git clone https://github.com/kosazoltan/valutavalto-program.git /opt/valutavalto
cd /opt/valutavalto

PRIMARY_IP=95.216.191.162 REPLICATION_PASSWORD="<ugyanaz>" SLOT_NAME=standby_slot_1     bash deploy/hetzner/ha/install-standby.sh
```

### 5. lépés — Cloudflare DNS setup

```bash
ssh root@95.216.191.162
CF_API_TOKEN=<token> CF_ZONE_ID=<zone_id> STANDBY_IP=<CONTABO_IP>     bash /opt/valutavalto/deploy/hetzner/ha/cloudflare-dns-failover.sh
# TTL -> 60s, DNS manual failover parancs a kimenetben.
```

### 6. lépés — Pénztár Electron client config

3 URL a SQLite config táblában:

```sql
UPDATE config SET value='https://excvaluta.com/api/v1' WHERE key='server_url';
INSERT INTO config VALUES('server_url_fallback_primary', 'https://contabo.excvaluta.com/api/v1');
INSERT INTO config VALUES('server_url_fallback_secondary', 'https://scaleway.excvaluta.com/api/v1');
```

A `sync-engine.ts` automatikusan lépked a 3 URL között:
1. Primary HTTP hiba → 30s múlva Contabo
2. Contabo is hiba → Scaleway
3. Mind 3 hiba → primary újrapróbál
4. Primary visszajött → 30 s múlva visszaáll

## Failover menete## Failover menete (manuális)

Ha a primary VPS leáll:

```bash
# 1. A standby VPS-en - promote:
ssh root@<standby_ip>
bash /opt/valutavalto/deploy/hetzner/ha/failover-to-standby.sh

# 2. Cloudflare DNS atallitas (a kiirt parancs):
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/<zone_id>/dns_records/<record_id>" \
  -H "Authorization: Bearer <cf_token>" \
  -H "Content-Type: application/json" \
  -d '{"content":"<standby_ip>"}'

# 3. 60s-en belul a penztarak automatikusan csatlakoznak az uj primary-ra.
```

## Visszatérés az eredeti primary-ra

Miután az eredeti primary újraindul:

```bash
ssh root@<old_primary>
systemctl stop postgresql@16-main

# Rewind az uj primary-hez:
sudo -u postgres pg_rewind \
    --target-pgdata=/var/lib/postgresql/16/main \
    --source-server="host=<new_primary> user=replicator password=<REPLICATION_PASSWORD>"

# Aztan install-standby.sh-val csatlakozik replikakent:
PRIMARY_IP=<new_primary> \
REPLICATION_PASSWORD=<...> \
    bash /opt/valutavalto/deploy/hetzner/ha/install-standby.sh

# Amikor ready: DNS vissza-atallitas.
```

## Monitoring

A Grafana dashboardra kerülnek majd:
- Primary <-> standby replication lag (Prometheus: `pg_replication_lag_seconds`)
- Mindkét backend health
- A Főértéktár képernyőjén piros jelzés, ha a lag > 30s

## Ingyenes health-check alternatíva

Cloudflare Load Balancing Monitors = 20 USD/ho (Pro plan). Ingyenes helyette:

- UptimeRobot (https://uptimerobot.com) - ingyenes 50 monitor + webhook
- BetterUptime (https://betterstack.com/better-uptime) - ingyenes 10 monitor
- Beallitod: monitor a `https://excvaluta.com/api/v1/auth/bootstrap-status`-ra
- Ha DOWN -> webhook -> a CF API failover parancs

## Kockázatok és mitigáció

| Kockázat | Mitigáció |
|----------|-----------|
| Split-brain (két primary) | Failover script kötelezően először promote, utána DNS. Old-primary csak REWIND után indítható. |
| Replication lag nő | Prometheus alert > 30s. Főértéktár látja. |
| Cloudflare API outage | Manuális DNS-váltás a registrar oldalán (registrar = ahol a domain) |
| Rosszul időzített DNS cache | TTL = 60s, de ISP resolverek ignorálják. Ezért a client-oldali fallback fontos. |