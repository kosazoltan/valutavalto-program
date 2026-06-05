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
## OFF-HOST watchdog (Scaleway) — MEGOLDVA 2026-06-05

Az on-host Alertmanager nem tud riasztani, ha a TELJES Hetzner host meghal (akkor o is
vele hal). Ezert a Scaleway standby-n fut egy fuggetlen watchdog:
`deploy/hetzner/ha/primary-watchdog.{sh,service,timer}` (systemd timer, 1 perc).

- Figyeli az `excvaluta.com/api/v1/auth/bootstrap-status`-t publikusan ES kozvetlen origin IP-n.
- 3 egymas utani bukas utan e-mailt kuld mind a 4 kollegahoz, majd recovery-mailt feljovetelkor.
- **FONTOS: a Scaleway BLOKKOLJA a kimeno SMTP-t (25/465/587)** → a watchdog **Resend HTTP API**-n
  (443) kuld. From: `watchdog@ebciroda.com` (verifikalt Resend-domain). Kulcs a szerveren:
  `/etc/primary-watchdog/resend_api_key` (root:600, NEM repoban). Elve tesztelve, megerkezett.
- **Auto-failover BE** (`AUTO_FAILOVER=yes`, user-dontes 2026-06-05). A watchdog tartos
  kiesesnel MAGA promote-olja a standby-t (`failover-to-standby.sh FAILOVER_AUTO=1`) ES
  atkapcsolja a Cloudflare DNS-t (`cloudflare-dns-failover.sh CF_AUTO=1`, CF-creds:
  `/etc/primary-watchdog/cf_env` root:600). SPLIT-BRAIN VEDELEM:
  (1) promote CSAK ha a publikus (Cloudflare) ES a kozvetlen origin is down -> Scaleway-lokalis
  blip nem indit failovert; (2) magasabb kuszob (`PROMOTE_THRESHOLD=6` ~6 perc) mint a riasztas
  (`FAIL_THRESHOLD=3`); (3) promote elotti friss ujra-ellenorzes (3 burst); (4) max-lag abort
  (`FAILOVER_MAX_LAG=300` -> tul nagy adatvesztesnel inkabb riaszt); (5) one-shot (`promoted`).
  TESZTELVE: dry-run (`WATCHDOG_DRY_RUN=1 ... --simulate-down`) a teljes dontesi lancot
  vegigvitte valodi promote nelkul; CF-creds `status`-szal verifikalva.
  ⚠️ **A valodi promote+DNS END-TO-END meg NEM volt elesben futtatva** (az production-leallast
  jelentene) — ajanlott egy kontrollalt drill alacsony forgalmu idoben:
  `gh workflow run scaleway-failover-drill.yml -f drill_level=1 -f dry_run=false`.

Megjegyzes: a Hetzner-oldali Alertmanager Gmail SMTP-vel kuld (ott a 587 nyitva); a Scaleway
watchdog Resend-del (ott az SMTP tiltva). Mindketto ugyanahhoz a 4 cimzetthez er el.
