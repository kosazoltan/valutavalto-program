#!/usr/bin/env bash
# ============================================================================
# HA setup - PRIMARY node (a jelenlegi Hetzner VPS)
# ============================================================================
# Engedelyezi a PostgreSQL streaming replikaciot a standby VPS szamara.
#
# Kell:
#   STANDBY_IP=<standby VPS IP>
#   REPLICATION_PASSWORD=<eros random - openssl rand -hex 24>
#
# Hasznalat:
#   STANDBY_IP=100.x.x.x REPLICATION_PASSWORD="$(openssl rand -hex 24)" \
#       bash install-primary.sh
# ============================================================================
set -euo pipefail
: "${STANDBY_IP:?kell STANDBY_IP}"
: "${REPLICATION_PASSWORD:?kell REPLICATION_PASSWORD}"

log() { echo "[primary-ha] $*"; }

PG_CONF=/etc/postgresql/16/main/postgresql.conf
PG_HBA=/etc/postgresql/16/main/pg_hba.conf

log "=== 1. Replication user letrehozasa ==="
sudo -u postgres psql <<SQL
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='replicator') THEN
        CREATE ROLE replicator LOGIN REPLICATION PASSWORD '$REPLICATION_PASSWORD';
    ELSE
        ALTER ROLE replicator WITH LOGIN REPLICATION PASSWORD '$REPLICATION_PASSWORD';
    END IF;
END\$\$;
SQL

log "=== 2. postgresql.conf - WAL + replication ==="
declare -A settings=(
    ["wal_level"]="replica"
    ["max_wal_senders"]="10"
    ["max_replication_slots"]="10"
    ["hot_standby"]="on"
    ["wal_keep_size"]="1024"
)
for key in "${!settings[@]}"; do
    if grep -qE "^${key}\s*=" "$PG_CONF"; then
        sed -i -E "s|^${key}\s*=.*|${key} = ${settings[$key]}|" "$PG_CONF"
    else
        echo "${key} = ${settings[$key]}" >> "$PG_CONF"
    fi
done

log "=== 3. pg_hba.conf - replication access ==="
if ! grep -q "replicator.*$STANDBY_IP" "$PG_HBA"; then
    echo "host replication replicator $STANDBY_IP/32 scram-sha-256" >> "$PG_HBA"
fi

log "=== 4. Replication slot ==="
sudo -u postgres psql -d valuta -c "SELECT * FROM pg_create_physical_replication_slot('standby_slot') WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name='standby_slot');" || true

log "=== 5. PG restart ==="
systemctl restart postgresql@16-main
sleep 3
systemctl is-active postgresql@16-main

log "=== 6. Replication status ==="
sudo -u postgres psql -c "SELECT slot_name, active FROM pg_replication_slots;"

log "=== KESZ. Folytasd a STANDBY VPS-en az install-standby.sh-t. ==="
