# Terv: Scaleway streaming-HA visszaállítása (user-direktíva 2026-07-02)

Orchestrator: Fable 5 · Végrehajtás: közvetlen SSH-műveletek a prod gépeken (NEM kód-változás,
hanem infrastruktúra-helyreállítás a meglévő, repo-ban verziózott szkriptekkel) + utána drill.
Felhatalmazás: "nekem 60-70 iroda működtetése sokkal fontosabb, mint a Scaleway kis költsége" —
a 06-16-i kivezetés FÉLREÉRTÉS volt, vissza kell állítani.

## Kiindulási állapot (2026-07-02, élő mérésből)
- Hetzner primary (95.216.191.162): ÉL, backend 2.28.25, V337 lefutott.
- Scaleway (163.172.152.234): gép ÉL (ping 63ms, nginx 301), standby postgres LEÁLLÍTVA,
  slot törölve, synchronous_standby_names='', guard+watchdog leállítva.
- Repo-eszközök megvannak: deploy/hetzner/ha/ (install-standby.sh, pg-repl-tunnel.service,
  sync-replication-guard, primary-watchdog, failover-to-standby.sh, SYNC-REPLICATION-SETUP.md,
  REPLICATION-TUNNEL-SETUP.md, drill-workflow).

## Végrehajtási mód (F1 felmérés UTÁNI pontosítás, 2026-07-02 18:20)

- Hetzner elérés: lokálról SSH OK (root@95.216.191.162, default kulcs).
- Scaleway elérés: lokálról és Hetznerről SINCS kulcs — KIZÁRÓLAG a GitHub Actions
  SCALEWAY_SSH_PRIVATE_KEY secret éri el (a drill-workflow mintája).
- WireGuard: ÉL (handshake 14s, 37ms RTT, wg-quick@wg0 active mindkét oldalon feltételezve).
- Hetzner PG 16.13: wal_level=replica OK, max_wal_senders=10 OK, slot NINCS,
  synchronous_standby_names ÜRES, guard+watchdog inactive.

EZÉRT: a helyreállítás egy ÚJ, egyszeri workflow-val megy:
`.github/workflows/scaleway-ha-restore.yml` (workflow_dispatch, inputs: dry_run).
A workflow a VPS_SSH_PRIVATE_KEY-jel a Hetznerre, a SCALEWAY_SSH_PRIVATE_KEY-jel a
Scaleway-re SSH-zik, és az F2+F3 lépéseket hajtja végre az alábbi sorrendben:

1. (Hetzner) pre-flight: wg show handshake < 60s; PG él; NEON lánc érintetlen marad.
2. (Hetzner) replicator user jelszó beolvasás (a meglévő /var/lib/postgresql/.pgpass-ból
   vagy /opt/valutavalto/ha.env-ből — amelyik létezik; ha egyik sincs: hibával áll le,
   NEM generál újat, mert a pg_hba scram hash-hez a régi kell).
3. (Hetzner) slot: SELECT pg_create_physical_replication_slot('standby_slot_0')
   ha nem létezik (idempotens).
4. (Scaleway) PG16 státusz; postgres stop; data-dir wipe; pg_basebackup
   -h 10.8.0.1 -U replicator -X stream -R -S standby_slot_0; standby.signal check; start.
5. (Hetzner) várakozás: pg_stat_replication-ben scaleway_standby state=streaming (max 10 perc,
   a basebackup ~pár GB a WG-n).
6. (Hetzner) sync bekapcsolás CSAK ezután: ALTER SYSTEM SET synchronous_standby_names='scaleway_standby';
   synchronous_commit=on; wal_sender_timeout='10s'; SELECT pg_reload_conf();
   verify sync_state='sync'.
7. (Hetzner) systemctl enable --now sync-replication-guard.service primary-watchdog.timer.
8. (Scaleway) backend .env standby-mód ellenőrzés (READ_ONLY=true, FLYWAY disabled) — csak jelentés.
9. Összefoglaló jelentés a workflow-logba (lag, sync_state, guard-státusz).
dry_run=true: csak 1-2 + slot-létezés check + jelentés, SEMMI változtatás.

### F2 — Standby újraépítés (SYNC-REPLICATION-SETUP.md, 2026-06-05 — WIREGUARD-alapú!)
- A replikáció NEM SSH-tunnelen, hanem WireGuardon megy: Hetzner 10.8.0.1 ↔ Scaleway 10.8.0.2
  (wg-quick@wg0, UDP 51820, PersistentKeepalive). ELSŐ lépés: wg állapot ellenőrzés mindkét
  oldalon (`wg show`), handshake él-e; ha nem, wg-quick@wg0 restart.
- Hetzner: standby_slot_0 slot újra-létrehozás (SELECT pg_create_physical_replication_slot),
  listen_addresses tartalmazza a 10.8.0.1-et, pg_hba replicator 10.8.0.2/32 sor megvan-e.
- Scaleway: install-standby.sh mintájára friss pg_basebackup a WG-címen át
  (PRIMARY_IP=10.8.0.1, SLOT_NAME=standby_slot_0, replicator jelszó a Hetzner .pgpass/env-ből) —
  a script data-wipe + basebackup + standby.signal + start láncot csinál.
- Replikáció-ellenőrzés: pg_stat_replication a primary-n (state=streaming), lag < 10s.

### F3 — Szinkronitás + őrszemek
- synchronous_standby_names visszaállítás a SYNC-REPLICATION-SETUP.md szerint (sync_state=sync).
  FIGYELEM: előbb a standby legyen stabil streaming, csak utána sync — különben a primary
  írásai beragadnak!
- sync-replication-guard.service + primary-watchdog.timer enable+start (Hetzner),
  freeze-watchdog marad ahogy van.
- Scaleway backend .env: standby-mód (HIBERNATE read-only, FLYWAY disabled) — a
  failover-to-standby.sh futtatáskor írja át élesre.

### F4 — Verifikáció + drill
- pg_stat_replication: sync_state=sync, lag ≈ 0.
- Drill workflow reaktiválás: a scaleway-failover-drill.yml DEPRECATED fejléc + if:false eltávolítás
  (EZ már kód-változás → külön mini-PR-ben, a szokásos pipeline-nal).
- Drill 1 futtatás dry_run=true (pre-flight), majd éles Drill 1 (promote+failback, DNS érintetlen).
- Runbook frissítés: DEPRECATED jelölés le, last_tested dátum.

### F5 — Dokumentáció
- vault/sessions/handoff a visszaállításról; a 06-16-i doksi kiegészítése ("visszaállítva 07-02,
  user-döntés").

## Kockázatok / óvintézkedések
- SEMMI destruktív a Hetzner primary-n: csak slot-létrehozás + conf-reload (nem restart, ha nem kell).
- sync bekapcsolás CSAK stabil streaming után (különben prod-írások blokkolódnak!).
- Basebackup alatt a primary terhelése nő — nyitvatartási időn kívül vagy alacsony forgalomnál futtatni,
  DE a user-direktíva a mielőbbi védelem, és a 06-05-i drill is nappal futott.
- Ha a Scaleway-n a PG major verzió eltér a Hetznerétől → előbb verzió-egyeztetés (F1 dönt).

## Amit NEM csinálunk
- DNS-swap, éles forgalom-átirányítás (az csak valódi katasztrófánál).
- Neon-backup lánc bármilyen módosítása (az marad, ahogy van — kettős védelem).
