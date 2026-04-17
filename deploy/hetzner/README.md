# Hetzner VPS Deploy

## Szerver adatok
- IP: 95.216.191.162
- OS: Ubuntu 24 (kernel 6.8.0)
- SSH kulcs: `~/.ssh/hetzner_ed25519`

## Systemd units

| Unit | Leírás | Menetrend |
|---|---|---|
| `pgdata-luks.service` | LUKS nyitás/mount | boot |
| `postgresql@16-main.service` | PostgreSQL 16 | pgdata-luks után |
| `valuta-backend.service` | Spring Boot backend | postgresql után |
| `valuta-backup.timer` | pg_dump → Nextcloud | naponta 03:00 |
| `valuta-health.timer` | uptime monitor | 5 percenként |

## Deploy

```bash
# Backend frissítés
git pull
mvn package -DskipTests
ln -sf target/valuta-backend-X.Y.Z.jar target/valuta-backend-current.jar
systemctl restart valuta-backend.service
```

## Backup aktiválás

```bash
nano /opt/valutavalto/.backup.env  # Nextcloud adatok
systemctl start valuta-backup.service  # teszt futtatás
journalctl -u valuta-backup -f
```

## Health monitor

```bash
journalctl -u valuta-health -f
# Log: /var/log/valutavalto/health.log
```

## Logok

```bash
journalctl -u valuta-backend -n 100 --no-pager
journalctl -u pgdata-luks --no-pager
cat /var/log/valutavalto/backup.log
cat /var/log/valutavalto/health.log
```
