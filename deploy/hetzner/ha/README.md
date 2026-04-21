# High-Availability (HA) - Warm-standby VPS setup

A 60 pénztárhoz szükséges üzletfolytonossági rendszer. Ha a primary Hetzner VPS leáll, a pénztárak 2-5 percen belül átállnak a standby VPS-re, és a munka folytatódik.

## FONTOS: MULTI-PROVIDER standby (nem csak Hetzner!)

A standby-t **másik szolgáltatónál** erdemes elhelyezni, hogy a cég-szintu Hetzner incidensek (BGP/DNS/billing/account-suspension) NE vigyenek el mindent egyszerre. Tapasztalati esetek: 2023 szept. Hetzner globális outage, 2021 márc. OVH Strasbourg tűz.

### Ajánlott standby providerek (60 pénztárhoz)

| Provider | Ár/hó | Spec | Régió | Regisztráció |
|----------|-------|------|-------|--------------|
| **Contabo VPS S** | **4.50 €** | 4 vCPU, 8 GB RAM, 50 GB NVMe | Nürnberg (DE) | https://contabo.com/en/vps/ |
| **Scaleway DEV1-M** | ~6 € | 3 vCPU, 4 GB RAM, 40 GB SSD | Párizs (FR) | https://www.scaleway.com/en/pricing/ |
| **OVH VPS Essential** | ~6 € | 2 vCPU, 4 GB RAM, 80 GB NVMe | Gravelines (FR) | https://www.ovhcloud.com/en/vps/ |
| **DigitalOcean 2GB** | ~11 € | 2 vCPU, 2 GB, 60 GB SSD | Frankfurt (DE) | https://www.digitalocean.com |
| **Linode Shared 4GB** | ~22 € | 2 vCPU, 4 GB, 80 GB SSD | Frankfurt (DE) | https://www.linode.com |

**Ajánlásaim:**

- **Legolcsóbb** (€9.50 össz): **Hetzner + Contabo** - két német cég, két adatközpont, max ár-érték
- **Geo-redundáns** (€11 össz): **Hetzner + Scaleway** - két ország (DE+FR), két cég
- **Teljes HA** (€14.50 össz): **Hetzner + Contabo + Scaleway** - 3-régiós, failover primary→Contabo→Scaleway

### Telepítés más providernél

Az `install-standby.sh` és `install-primary.sh` **provider-agnosztikus** — csak Ubuntu 24.04 + PostgreSQL 16 + SSH kell a standby VPS-re. Semmi Hetzner-specifikus feltételezés. Minden lépés a README-ben ugyanúgy működik:

1. **Contabo**: rendeld a VPS S-t Ubuntu 24.04-gyel, SSH kulcs feltöltés
2. Kapsz egy IPv4 + root password-öt (Contabo default)
3. SSH: `ssh root@<contabo_ip>` (password, első belépésnél változtasd jelszóra / SSH kulcsra)
4. Ugyanúgy: `install-standby.sh` stb.

**Contabo-specifikus megjegyzés**: a Contabo VPS-en először SSH kulcsot kell feltölteni az első belépés után (account → "My Services" → server → "SSH Keys"). Alapból password-auth van, ezt kapcsold át kulcsra + `PermitRootLogin prohibit-password`-re a `sshd_config`-ban.

**Scaleway-specifikus megjegyzés**: a Scaleway console-ban az SSH kulcsot előre feltölted az account-ra (Settings → SSH Keys), és a VPS-t létrehozva már benne van. Default root felhasználó, nem kell password.

### Kiváltottál kockázatok

| Kockázat | Egy-provider (Hetzner×2) | Multi-provider (Hetzner + Contabo) |
|----------|--------------------------|-------------------------------------|
| Hardver hiba | ✅ védett (másik VPS) | ✅ védett |
| Adatközpont kiesés | ✅ védett (HEL1≠HEL2) | ✅ védett (HEL≠Nürnberg) |
| Hálózati szintű provider outage | ❌ mindkettő eléheteteltlen | ✅ a másik elérhető |
| Account suspension / billing hiba | ❌ mindkettő zárolva | ✅ másik független |
| Cég-szintu incidens (BGP/DNS hack) | ❌ mindkettő down | ✅ másik megy |
| EU-szintu katasztrófa | ❌ mindkettő EU-ban | ⚠️ részleges — EU-n belül |


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

## Telepítés - 4 lépés

### 1. Új Hetzner VPS rendelése

- https://console.hetzner.cloud -> Új projekt "valuta-ha-standby"
- CX22 (2 vCPU, 4 GB RAM, 40 GB SSD) ~4.51 EUR/ho
- Régió: Helsinki 2 (földrajzilag redundáns HEL1-hez)
- OS: Ubuntu 24.04 LTS
- SSH kulcs: `~/.ssh/hetzner_ed25519.pub` (ugyanaz mint primary)

### 2. Primary VPS-en - replikáció engedélyezése

```bash
ssh root@95.216.191.162
cd /opt/valutavalto && git pull
STANDBY_IP=<uj_standby_ip> \
REPLICATION_PASSWORD="$(openssl rand -hex 24)" \
    bash deploy/hetzner/ha/install-primary.sh

# Mentsd el a REPLICATION_PASSWORD-ot jelszókezelőbe!
```

### 3. Standby VPS-en - bootstrap

```bash
ssh root@<uj_standby_ip>
git clone https://github.com/kosazoltan/valutavalto-program.git /opt/valutavalto
cd /opt/valutavalto

# Alap hardening
sudo bash deploy/hetzner/bootstrap-vps.sh
# -> Step 1 (SSH hardening): Y
# -> Tobbi: N (nincs szuksegunk Caddy/Redis/Monitoring-ra a standby-n)

# Replikáció setup
PRIMARY_IP=95.216.191.162 \
REPLICATION_PASSWORD=<ugyanaz mint primary-n> \
    bash deploy/hetzner/ha/install-standby.sh
```

### 4. Cloudflare DNS

1. https://dash.cloudflare.com -> Domain `excvaluta.com` (ingyenes plan)
2. API token: https://dash.cloudflare.com/profile/api-tokens
   - "Create Token" -> "Edit zone DNS" template
   - Zone: excvaluta.com
3. Zone ID: az `excvaluta.com` oldalon, jobb alsó sarok
4. Primary VPS-en:

```bash
CF_API_TOKEN=<token> \
CF_ZONE_ID=<zone_id> \
STANDBY_IP=<standby_ip> \
    bash /opt/valutavalto/deploy/hetzner/ha/cloudflare-dns-failover.sh
```

Ez leszállítja a TTL-t 60s-re és kiírja a failover parancsot.

## Failover menete (manuális)

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