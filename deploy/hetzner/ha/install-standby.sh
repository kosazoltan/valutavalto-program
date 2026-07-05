#!/usr/bin/env bash
# ============================================================================
# HA setup - STANDBY node (barmely Ubuntu 24.04 + Postgres 16 VPS-en)
# ============================================================================
# Kell:
#   PRIMARY_IP=<primary VPS IP>
#   REPLICATION_PASSWORD=<ugyanaz mint a primary-n>
#   SLOT_NAME=standby_slot_0  (Contabo) vagy standby_slot_1 (Scaleway), stb.
#     - a primary install-primary.sh kiirja a megfelelo slot-neveket
#     - ha kihagyod, alapertelmezetten 'standby_slot' (legacy, 1-standby setup)
# ============================================================================
set -euo pipefail
: "${PRIMARY_IP:?kell PRIMARY_IP}"
: "${REPLICATION_PASSWORD:?kell REPLICATION_PASSWORD}"
SLOT_NAME="${SLOT_NAME:-standby_slot}"

log() { echo "[standby-ha] $*"; }

log "=== PostgreSQL 16 telepites ==="
DEBIAN_FRONTEND=noninteractive apt-get update -qq
if ! dpkg -l | grep -q postgresql-16; then
    DEBIAN_FRONTEND=noninteractive apt-get install -yq postgresql-16
fi

log "=== PG stop + data wipe ==="
systemctl stop postgresql@16-main
DATA_DIR=/var/lib/postgresql/16/main

# --- A1: PRE-FLIGHT GUARD — sosem wipe-olunk primary data dir-t ---
if sudo -u postgres pg_isready -q 2>/dev/null; then
    # PG még fut — pg_is_in_recovery() dönt
    recovery="$(sudo -u postgres psql -tAc 'SELECT pg_is_in_recovery()' 2>/dev/null | tr -d '[:space:]')"
    if [ "$recovery" = "f" ]; then
        log "ABORT: pg_is_in_recovery()=f — ez a node PRIMARY! A data wipe LEALLITVA."
        log "Ha tenyleg standby-t epitesz, bizonyoskodj rola, hogy ez a node standby-e."
        exit 1
    fi
    log "pre-flight OK: pg_is_in_recovery()=$recovery (standby)"
elif [ -f "$DATA_DIR/standby.signal" ]; then
    log "pre-flight OK: PG leallitva, standby.signal jelen — korábbi standby"
else
    log "FIGYELEM: PG nem fut es nincs standby.signal — ez PRIMARY lehet!"
    log "Ha ez egy UJ standby-setup (ures/friss PG install), jovahagyas:"
    log "  STANDBY_SETUP_CONFIRM=1 PRIMARY_IP=... REPLICATION_PASSWORD=... bash install-standby.sh"
    [ "${STANDBY_SETUP_CONFIRM:-0}" = "1" ] || { log "ABORT: STANDBY_SETUP_CONFIRM=1 hianyzik"; exit 1; }
    log "STANDBY_SETUP_CONFIRM=1 — folytatod (friss install, kockazatvallalas)"
fi

find "$DATA_DIR" -mindepth 1 -delete 2>/dev/null || true

log "=== pg_basebackup - klonozas primary-rol (slot: $SLOT_NAME) ==="
PGPASSWORD="$REPLICATION_PASSWORD" sudo -u postgres pg_basebackup \
    -h "$PRIMARY_IP" -U replicator -D "$DATA_DIR" \
    -X stream -P -R -S "$SLOT_NAME"

log "=== standby.signal ellenorzes ==="
[ -f "$DATA_DIR/standby.signal" ] && log "standby.signal OK" || { log "HIBA: standby.signal hianyzik"; exit 1; }

log "=== PG start (recovery mode) ==="
systemctl start postgresql@16-main
sleep 5
systemctl is-active postgresql@16-main

log "=== Verifikacio ==="
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
sudo -u postgres psql -c "SELECT NOW() - pg_last_xact_replay_timestamp() AS replication_lag;"

log "=== KESZ ==="
log "  Slot: $SLOT_NAME, Primary: $PRIMARY_IP"
log "  Ez a node most READ-ONLY, a primary-tol streaming-el szinkronizal."
log "  Failover: bash failover-to-standby.sh"
