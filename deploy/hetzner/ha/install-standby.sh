#!/usr/bin/env bash
# ============================================================================
# HA setup - STANDBY node (uj VPS)
# ============================================================================
# Futtat az UJ VPS-en, miutan a primary install-primary.sh lefutott.
#
# Kell:
#   PRIMARY_IP=<primary VPS IP>
#   REPLICATION_PASSWORD=<ugyanaz mint a primary-n>
# ============================================================================
set -euo pipefail
: "${PRIMARY_IP:?kell PRIMARY_IP}"
: "${REPLICATION_PASSWORD:?kell REPLICATION_PASSWORD}"

log() { echo "[standby-ha] $*"; }

log "=== 1. PostgreSQL 16 telepites ==="
DEBIAN_FRONTEND=noninteractive apt-get update -qq
if ! dpkg -l | grep -q postgresql-16; then
    DEBIAN_FRONTEND=noninteractive apt-get install -yq postgresql-16
fi

log "=== 2. PG stop + data wipe ==="
systemctl stop postgresql@16-main
DATA_DIR=/var/lib/postgresql/16/main
find "$DATA_DIR" -mindepth 1 -delete 2>/dev/null || true

log "=== 3. pg_basebackup - klonozas primary-rol ==="
PGPASSWORD="$REPLICATION_PASSWORD" sudo -u postgres pg_basebackup \
    -h "$PRIMARY_IP" -U replicator -D "$DATA_DIR" \
    -X stream -P -R -S standby_slot

log "=== 4. standby.signal ==="
[ -f "$DATA_DIR/standby.signal" ] && log "standby.signal OK" || { log "HIBA: standby.signal hianyzik"; exit 1; }

log "=== 5. PG start (recovery mode) ==="
systemctl start postgresql@16-main
sleep 5
systemctl is-active postgresql@16-main

log "=== 6. Verifikacio ==="
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"

log "=== 7. Replication lag ==="
sudo -u postgres psql -c "SELECT NOW() - pg_last_xact_replay_timestamp() AS replication_lag;"

log "=== KESZ - a standby PG read-only modban fut. ==="
