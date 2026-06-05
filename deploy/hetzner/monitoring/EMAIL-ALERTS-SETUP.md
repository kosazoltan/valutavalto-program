# E-mail riasztás beüzemelés — szerver-leállás (2026-06-05)

Miért: a 2026-06-05 ~10 órás kiesés alatt a Prometheus LÁTTA a `BackendDown`-t, de az
Alertmanager `null-receiver`-re küldött (bootstrapkor a Telegram kihagyva) → **senki nem
kapott értesítést**. Mostantól mind a 4 whitelist-kolléga e-mailt kap szerver-leállásról.

## Mi változott (repóban verziózva)

- `alertmanager/alertmanager.yml` — Gmail SMTP (`noraautomatizalas@gmail.com`), egyetlen
  `email-all` receiver, 4 címzett: kosa.zoltan / borsi.tamas / kasza.helga / bali.henriett
  (`.ebc@gmail.com`). `send_resolved: true` (recovery-mailt is küld).
- `docker-compose.monitoring.yml` — az alertmanager service mountolja a gitignore-olt
  `secrets/smtp_app_password`-ot `/run/secrets/`-be (`smtp_auth_password_file` olvassa).

## Szerver-oldali, EGYSZERI lépések (NEM repóban — titok/runtime)

1. **App-jelszó** (Gmail App Password, `noraautomatizalas@gmail.com`) a szerverre:
   `secrets/smtp_app_password` (16 byte, NO trailing newline). **Tulajdonos a konténer UID-je
   (65534:65534), mód 400** — különben az alertmanager (`nobody`) nem olvassa.
   Forrás: a kozos automation-fiok app-jelszava (openclaw `.env` `GMAIL_SMTP_APP_PASSWORD`).
2. **ufw sorrend-fix (KRITIKUS volt):** a `DENY 9090 Anywhere` szabaly MEGELOZTE az
   `ALLOW 9090 from 172.18.0.0/16`-ot → a Prometheus sosem tudta scrape-elni a backend
   actuatort (`up=0`, orok hamis `BackendDown`). Javitva: az ALLOW a DENY ELE kerult
   (`ufw delete <n>` + `ufw insert 6 allow from 172.18.0.0/16 to any port 9090 proto tcp`).
3. Recreate: `cd .../monitoring && POSTGRES_EXPORTER_PASSWORD=.. GRAFANA_ADMIN_PASSWORD=.. \
   docker compose -p valuta-monitoring up -d alertmanager`.

## Teszt (2026-06-05)

`POST /api/v2/alerts` teszt-riasztas → mind a 4 cimzett megkapta a
`[excvaluta FIRING] TESZT_EmailRiasztas` levelet. `BackendDown` az ufw-fix utan `up=1` →
feloldodott.

## NYITOTT follow-up-ok (NEM blokkolja a szerver-leallas riasztast)

- **PostgresDown elnemitva 7 napra** (`amtool silence`): a postgres-exporter
  `host.docker.internal:5432`-re "connection refused" (a Postgres csak localhost-on figyel,
  az exporter sosem ert el hozza). Valodi javitas: postgres `listen_addresses` + pg_hba a
  docker-bridge-re, VAGY az exporter pgbouncer (6432) fele iranyitasa. A backend-leallas
  amugy is lefedi a DB-kiesest (a backend nem szolgal ki DB nelkul).
- **caddy job up=0** (admin API 2019, ugyanaz az ufw-minta) — nincs hozza alert-rule, nem
  spamel; ha kell caddy-metrika, ugyanugy ALLOW a DENY ele.
- **OFF-HOST monitoring hianyzik:** a stack a Hetzner primaryn fut → ha a TELJES host meghal,
  az Alertmanager is vele → nincs e-mail. Teljes host-halal lefedesehez kulso/Scaleway-oldali
  health-probe kell (a failover-korben rendezzuk).
