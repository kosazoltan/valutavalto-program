# Szinkron replikáció — max-biztonság (RPO=0) setup (2026-06-05)

A user-döntés: **a legnagyobb adatbiztonság** (nulla adatvesztés failovernél). Az egyetlen *hard*
garancia a szinkron replikáció. Az availability-csapdát (ha a standby leáll, a primary commitjai
blokkolnának) WireGuard + auto-degradáció oldja fel. 5 réteg:

## 1. WireGuard csatorna (stabil, kernel-szintű)

A replikáció eddig SSH-tunnelen ment (userspace, flap-elhet → szinkron commit megakadna). Most
**WireGuard**: Hetzner `10.8.0.1` ↔ Scaleway `10.8.0.2`, UDP 51820. A cloud-firewall a WG UDP-t
NEM blokkolja (handshake OK, 37ms RTT). `wg-quick@wg0` systemd, `PersistentKeepalive=25`.
Kulcsok: `/etc/wireguard/{privatekey,publickey,wg0.conf}` (priv kulcs root:600, NEM repóban).
ufw: `allow 51820/udp` mindkét gépen + Hetzner `allow from 10.8.0.0/24 to any port 5432`.

## 2. Szinkron replikáció

Hetzner postgres `listen_addresses` += `10.8.0.1`; `pg_hba`: `host replication/all replicator
10.8.0.2/32 scram-sha-256`. A standby `primary_conninfo`: `host=10.8.0.1 port=5432
application_name=scaleway_standby`, `primary_slot_name=standby_slot_0`.

Hetzneren (ALTER SYSTEM, perzisztált):
```
synchronous_commit = on
synchronous_standby_names = scaleway_standby
wal_sender_timeout = 10s          # holt standby gyors detektálása (különben perc-blokk)
```
Eredmény: `sync_state=sync` → minden commit a Scaleway-en is megvan a commit visszatérése ELŐTT
→ **RPO=0**. RTT 37ms → kis commit-latency.

## 3. Auto-degradáció guard (`sync-replication-guard.service`)

Hetzneren fut. Ha a szinkron standby >~20s nem elérhető (`pg_stat_replication`-ben nincs a
`scaleway_standby` — a `wal_sender_timeout=10s` miatt gyorsan kiesik), **async-ra degradál**
(`synchronous_standby_names=''`) → a Hetzner **írható marad**. Visszatéréskor **automatikusan
vissza sync-re**. Mindkettőről Gmail-SMTP e-mail (Hetzner, 587 nyitva) + journal (`-t sync-guard`).
TESZTELVE: Scaleway-postgres-stop → ~25s → degradált, írás nem blokkolt; visszaindítás → sync.

## 4. Kliens re-assert (local-first védőháló) — lásd backend + penztar-client

A 60 pénztár local-first; a synced rekordokat megőrzik (`synced=1`). Failover/reconnect után
újra-asszertálják a legutóbbi tranzakciókat (idempotency-key) → a degradált-ablakban esetleg
elveszett sorok is visszapótlódnak. (A szinkron replikáció ezt amúgy is lefedi nem-degradált
állapotban; ez a kettős-hiba elleni redundancia.)

## 5. Failback irány valós failover után

Valós Hetzner-halál + Scaleway-promote után a Scaleway tartja a friss adatot → a Hetzner
visszatéréskor a **Scaleway-ről** klónozódik újra (NEM fordítva). Lásd scaleway-failover-runbook.md.

## Verifikáció (2026-06-05)
sync_state=sync, élő write 0.196s, standby azonnal megkapta; degradáció+helyreállás tesztelve;
ALTER SYSTEM értékek perzisztáltak (restart-túlélő).
