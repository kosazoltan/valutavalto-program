# Hetzner Systemd Units

These files are the canonical versions of the systemd units running on the Hetzner VPS (`95.216.191.162`).

## Files

| File | Target path on server | Notes |
|---|---|---|
| `pgdata-luks.service` | `/etc/systemd/system/pgdata-luks.service` | Idempotent LUKS open/mount. Fixed 2026-04-17 (was failing with exit 5 on second run). |
| `valuta-backend.service` | `/etc/systemd/system/valuta-backend.service` | Spring Boot backend. ExecStart uses hardcoded SNAPSHOT path — TODO: switch to symlink. |
| `postgresql@16-main.service.d/luks-dependency.conf` | `/etc/systemd/system/postgresql@16-main.service.d/luks-dependency.conf` | Drop-in: makes postgres depend on pgdata-luks. |

## Deploy (manual)

```bash
KEY=~/.ssh/hetzner_ed25519
SERVER=root@95.216.191.162

# Copy units
scp -i $KEY deploy/hetzner/systemd/pgdata-luks.service $SERVER:/etc/systemd/system/
scp -i $KEY deploy/hetzner/systemd/valuta-backend.service $SERVER:/etc/systemd/system/
ssh -i $KEY $SERVER 'mkdir -p /etc/systemd/system/postgresql@16-main.service.d'
scp -i $KEY deploy/hetzner/systemd/postgresql@16-main.service.d/luks-dependency.conf \
    $SERVER:/etc/systemd/system/postgresql@16-main.service.d/

# Reload and verify
ssh -i $KEY $SERVER 'systemctl daemon-reload && systemctl status pgdata-luks postgresql@16-main valuta-backend'
```

## Known issues

- `valuta-backend.service` ExecStart hardcodes `valuta-backend-1.0.0-SNAPSHOT.jar`.
  After each Maven build: `cp target/valuta-backend-<VERSION>.jar target/valuta-backend-1.0.0-SNAPSHOT.jar`
  Permanent fix: use symlink `valuta-backend-current.jar` and update unit.

## History

| Date | Change |
|---|---|
| 2026-04-17 | pgdata-luks.service patched to idempotent ExecStart (was causing PostgreSQL 6-day outage) |
| 2026-04-17 | valuta-backend.service documented from running server |
