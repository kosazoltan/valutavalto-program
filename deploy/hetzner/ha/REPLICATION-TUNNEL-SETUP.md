# Postgres replikáció SSH-tunnelen — setup + indok (2026-06-05)

## Miért tunnel?

A 2026-06-05 éles failover-teszt feltárta: a **publikus PostgreSQL-port (5432) a Hetzner és a
Scaleway között Hetzner-Cloud-Firewall-blokkolt** (network-szintű, a VM ufw/iptables FELETT — egy
explicit `iptables -I INPUT 1 ... ACCEPT` sem segített). Az addigi replikáció CSAK egy hetekkel
korábban felépült, established kapcsolaton élt; **új kapcsolat nem épülhetett** → a standby SOHA nem
tudott volna auto-helyreállni egy replikáció-megszakadásból (kritikus latens HA-bug).

A 22-es (SSH) port nyitva. Ezért a replikáció egy **perzisztens SSH-tunnelen** megy:
`Scaleway 127.0.0.1:5433 -> Hetzner 127.0.0.1:5432`. A tunnel a Hetzner localhost:5432-re terminál,
ahol a postgres **már figyel** és a `pg_hba.conf` **már engedi** a `127.0.0.1` replikációt — így NEM
kell Hetzner postgres-restart, sem `listen_addresses`/`pg_hba` változás. (Alternatíva lett volna a
Tailscale, de a repo `TAILSCALE_AUTHKEY`-e lejárt; Hetzner-cloud-token nincs.)

## Setup (Scaleway standby-n, egyszeri)

```bash
# 1) dedikalt, korlatozott tunnel-kulcs
mkdir -p /etc/pg-repl-tunnel
ssh-keygen -t ed25519 -N "" -C "pg-repl-tunnel-scaleway" -f /etc/pg-repl-tunnel/id_ed25519
chmod 600 /etc/pg-repl-tunnel/id_ed25519

# 2) a PUBKEY authorizalasa a Hetzneren — CSAK 127.0.0.1:5432 forwardra korlatozva:
#    /root/.ssh/authorized_keys-ba:
#    no-pty,no-X11-forwarding,no-agent-forwarding,permitopen="127.0.0.1:5432",command="/bin/false" ssh-ed25519 AAAA...

# 3) systemd tunnel-service (a repobeli pg-repl-tunnel.service):
cp pg-repl-tunnel.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now pg-repl-tunnel.service
```

## A standby primary_conninfo a tunnelre mutat

`pg_basebackup -R` automatikusan beirja a `-d` connection-stringbol:
`host=127.0.0.1 port=5433 user=replicator ...` + `primary_slot_name = 'standby_slot_0'` (kezzel hozzaadva).

## Standby (újra)felépítés — pg_basebackup a tunnelen (NEM pg_rewind!)

A `pg_rewind` ITT NEM hasznalhato: a cluster `wal_log_hints=off` ES nincs data-checksum. Ezert a
(failback/recovery) mindig **friss `pg_basebackup`** a tunnelen at (a DB ~35MB, masodpercek):

```bash
RPWD=$(grep -oE "password=[^ ']+" /var/lib/postgresql/16/main/postgresql.auto.conf | head -1 | cut -d= -f2-)
systemctl stop valuta-backend postgresql@16-main
rm -rf /var/lib/postgresql/16/main
sudo -u postgres /usr/lib/postgresql/16/bin/pg_basebackup -D /var/lib/postgresql/16/main \
  -d "host=127.0.0.1 port=5433 user=replicator password=$RPWD dbname=postgres" -R -X stream -c fast
echo "primary_slot_name = 'standby_slot_0'" >> /var/lib/postgresql/16/main/postgresql.auto.conf
chown -R postgres:postgres /var/lib/postgresql/16/main; chmod 700 /var/lib/postgresql/16/main
systemctl start postgresql@16-main valuta-backend
```

## Primary oldali védelem

`ALTER SYSTEM SET max_slot_wal_keep_size = '2GB';` (Hetzneren) — ha a standby sokáig le, a slot miatt
ne teljen meg a primary lemeze.

## Validálva (2026-06-05)

Éles watchdog-vezérelt auto-failover teszt: Hetzner-backend leállítás → watchdog észlel → off-host
email → promote → backend writable (DDL_AUTO=none fix) → Cloudflare DNS → Scaleway szolgálta ki az
excvaluta.com-ot (HTTP 200). Failback: DNS→Hetzner + pg_basebackup re-clone a tunnelen. Replikáció a
slot-on, lag < 10s, élő write-teszt propagált.
