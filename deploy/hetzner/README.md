# Hetzner VPS Deploy

## Szerver adatok

- IP: 95.216.191.162
- OS: Ubuntu 24 (kernel 6.8.0)
- SSH kulcs: `~/.ssh/hetzner_ed25519`

## Systemd units

| Unit | Leiras | Menetrend |
|---|---|---|
| `pgdata-luks.service` | LUKS nyitas/mount | boot |
| `postgresql@16-main.service` | PostgreSQL 16 | pgdata-luks utan |
| `valuta-backend.service` | Spring Boot backend | postgresql utan |
| `valuta-backup.timer` | pg_dump Nextcloud feltoltes | naponta 03:00 |
| `valuta-health.timer` | uptime monitor | 5 percenkent |

## Deploy

```bash
# Backend frissites
git pull
mvn package -DskipTests
ln -sf target/valuta-backend-X.Y.Z.jar target/valuta-backend-current.jar
systemctl restart valuta-backend.service
```

## Backup aktivalas

```bash
# 1. Backup infrastruktura telepitese (csak elso alkalommal)
cd /path/to/repo/deploy/hetzner/scripts
bash setup-backup.sh

# 2. Nextcloud adatok kitoltese
nano /opt/valutavalto/.backup.env

# 3. Teszt futtatasa
systemctl start valuta-backup.service
journalctl -u valuta-backup -f
```

## Health monitor aktivalas

```bash
# 1. Telepites (csak elso alkalommal)
cd /path/to/repo/deploy/hetzner/scripts
bash setup-healthcheck.sh

# 2. Opcionalis: email alert beallitasa
nano /opt/valutavalto/.health.env   # ALERT_EMAIL=admin@example.com

# 3. Log kovetest
journalctl -u valuta-health -f
cat /var/log/valutavalto/health.log
```

### Health monitor mukodese

- 5 percenkent ellenorzi: `https://excvaluta.com/api/v1/auth/bootstrap-status`
- 3 egymast koveto hiba utan: auto-restart (valuta-backend.service) + email alert
- Fail szamlalo reset: amint 200-as valasz erkezik

## Logok

```bash
journalctl -u valuta-backend -n 100 --no-pager
journalctl -u pgdata-luks --no-pager
journalctl -u valuta-backup --no-pager
journalctl -u valuta-health --no-pager
cat /var/log/valutavalto/backup.log
cat /var/log/valutavalto/health.log
```

## Backup retention

- Helyi: 30 nap (konfiguralahto: `BACKUP_RETENTION_DAYS` a .backup.env-ben)
- Nextcloud: 30 nap (automatikus PROPFIND/DELETE, HTTP statusz ellenorzott)
- Atomikus iras: tmp fajl + mv, felkesz backup nem maradhat

## Config fajlok (NEM repo-ban, szerveren)

| Fajl | Tartalom |
|---|---|
| `/opt/valutavalto/.backup.env` | Nextcloud URL/user/pass, retention, alert email |
| `/opt/valutavalto/.health.env` | Alert email a health monitorhoz (fuggetlentul) |


## Gyors bootstrap - egyetlen parancs

A VPS elso telepitesekor (vagy uj gepre) futtasd:

```bash
# 1. Klonold a repo-t a VPS-re (ha meg nincs):
sudo mkdir -p /opt/valutavalto && sudo chown $USER /opt/valutavalto
cd /opt/valutavalto && git clone https://github.com/kosazoltan/valutavalto-program.git .

# 2. Root-kent futtasd a bootstrap-ot:
sudo bash /opt/valutavalto/deploy/hetzner/bootstrap-vps.sh
```

A script vegigmegy a 7 opcionalis lepesen, minden lepesnel Y/N kerdest tesz fel,
a secret-eket biztonsagosan (echo nelkul) bekeri. Automatikusan generalja a helyben
generalhato ertekeket (JWT secret, encryption salt/key, DB jelszo).

**Kezzel bekerendo secret-ek (opcionalis — csak ha az adott lepest valasztod):**

| Lepes | Secret | Forras |
|-------|--------|--------|
| 5. Tailscale | `TAILSCALE_AUTHKEY` | https://login.tailscale.com/admin/settings/keys |
| 6. B2 backup | `B2_KEY_ID` + `B2_APP_KEY` | https://secure.backblaze.com/app_keys.htm |
| 7. Monitoring | `GRAFANA_ADMIN_PASSWORD` | sajat valasztas (min 8 char) |
| 7. Monitoring | `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` | @BotFather, opcionalis |

**Non-interactive mod** (env var-okkal elore):

```bash
export TAILSCALE_AUTHKEY=tskey-auth-xxxx
export B2_KEY_ID=005xxxx B2_APP_KEY=K005xxxxx
export GRAFANA_ADMIN_PASSWORD="$(openssl rand -base64 24)"
export TELEGRAM_BOT_TOKEN=123:ABC TELEGRAM_CHAT_ID=-1001234567890
sudo -E bash /opt/valutavalto/deploy/hetzner/bootstrap-vps.sh
```

A bootstrap idempotens — ujra es ujra futtathato. Mar telepitett komponenseknel
ellenorzi a `systemctl is-active` / `docker ps` statust, es skip-el.

Log: `/var/log/valuta-bootstrap.log`