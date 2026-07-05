# Handoff — 2026-07-05 PROD-VERSION-STALE (DNS-misroute) diagnózis + fix

## Mi volt a baj
A publikus `excvaluta.com`/`/api/v1/version` hetekig `2.28.8`-at adott (buildTime
07-04 15:11), miközben minden deploy sikeresen `2.28.27`-et telepített. A backlog
eredeti hipotézise (systemctl restart nem cserélte a JVM-et) **HAMIS** volt.

## Valós gyökérok (VERIFY-DON'T-TRUST győzött)
- Hetzner primary VÉGIG egészséges: `curl localhost:8080/api/v1/version` → 2.28.27,
  JVM PID uptime = a #1315 restart pillanata, `current.jar`→2.28.27.jar, ExecStart helyes.
- A `2.28.8`-at a **Cloudflare edge** szolgálta: az `excvaluta.com`+`www` A-rekord egy
  korábbi **auto-failover** óta a **Scaleway standby IP-jén (163.172.152.234) ragadt**,
  ahol egy régi 2.28.8 backend futott. `primary.excvaluta.com` végig a friss 2.28.27-et adta.
- A `primary-watchdog` recovery-kor NEM csinál DNS-failbacket (csak emailt) → beragadt.
- A deploy health-check a PUBLIKUS edge-et pingelte → stale origin 200 → hamis-zöld deploy.

## Adatbiztonság (kritikus — bizonyítva, NINCS split-brain)
Minden pénz/mozgás-tábla `count(*)` bájtra azonos Hetzner↔Scaleway (transaction=134,
cash_balance=1232, audit_log=236, employee=196…), legfrissebb audit UUID egyezik,
és **0 írás a Scaleway-promote (07-04 15:10) óta** → nincs csak-Scaleway-n létező adat.

## Amit csináltunk
### A — azonnali prod-helyreállítás (élő)
- **#1316** `prod-dns-failback.yml`: CF apex+www A-rekord → Hetzner (95.216.191.162),
  proxied megőrizve, dry_run-first. Prod publikus most 2.28.27. ✅
- **#1317** `scaleway-standdown.yml`: Scaleway `primary-watchdog.timer` + `valuta-backend`
  stop+disable (rogue 2.28.8 origin megszűnt, nincs re-failover). PG ÉRINTETLEN. ✅

### B — tartós kód-megelőzés (#1318 MERGED, pipeline: Fable→GPT-5.5→GLM, holdout 5/5)
- `deploy-hetzner.yml`: health-check origin-pin `--resolve VPS_SERVER_IP` + origin
  `/version`==build-verzió BLOKKOLÓ assert; edge-drift NEM-blokkoló warning.
- `cloudflare-dns-failover.sh`: apex ÉS www kezelés, per-rekord CF-hiba izolálva.
- `primary-watchdog.sh`: recovery-ág 24h-ismétlő FAILBACK-SZÜKSÉGES riasztás a pontos
  paranccsal; `promoted=1` csak DNS==ORIGIN_IP esetén nullázódik.

## Hátralévő / követő teendő (user-döntést igényel)
- **Scaleway warm-standby ÚJRAÉPÍTÉSE**: a Scaleway PG jelenleg PROMOTÁLT
  (pg_is_in_recovery=f), NEM streaming standby. A teljes HA visszaállításához
  `scaleway-ha-restore.yml` (pg_basebackup a Hetznerről, NEM rewind) kell — külön,
  gondos művelet. Amíg ez nincs meg, NINCS élő failover-védelem (a watchdog OFF).
  → user-döntés: mikor építsük újra a HA-t.
- A `deploy-hetzner.yml` `deploy-standby` job (if:false) — a HA-rebuild után újraaktiválandó.

## Kulcs-tanulságok
- CF proxied rekord mögött a `dig` a CF edge IP-ket adja; origin-igazsághoz
  `curl --resolve <host>:443:<origin-ip>` VAGY `curl localhost:8080` a boxon.
- `primary.excvaluta.com` origin-hostname mindig a Hetznert adta — hasznos diff-pont.
- Redaction-csapda (pitfall 27): patch-eléskor `$CF_API_TOKEN`→`***` becsúszhat;
  hex/char-split próba a döntő, a terminál-nézet maszkol.
- Egyszeri ops-workflow-k csak a main-ről dispatchelhetők (workflow_dispatch) → PR+admin-merge.
