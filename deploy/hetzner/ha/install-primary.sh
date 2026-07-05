#!/usr/bin/env bash
# ============================================================================
# HA setup - PRIMARY node (a jelenlegi Hetzner VPS)
# ============================================================================
# Engedelyezi a PostgreSQL streaming replikaciot a standby VPS-ek szamara.
#
# Kell:
#   STANDBY_IPS=<ip1,ip2,...>  (vesszovel elvalasztott lista - pl. Contabo,Scaleway)
#   REPLICATION_PASSWORD=<eros random - openssl rand -hex 24>
#
# 3-regios setup pelda:
#   STANDBY_IPS=91.107.xxx.xxx,51.158.xxx.xxx \
#   REPLICATION_PASSWORD="$(openssl rand -hex 24)" \
#     bash install-primary.sh
#
# Egy-standby setup pelda:
#   STANDBY_IPS=91.107.xxx.xxx \
#   REPLICATION_PASSWORD="$(openssl rand -hex 24)" \
#     bash install-primary.sh
# ============================================================================
set -euo pipefail
# Kompatibilitas: ha csak STANDBY_IP van megadva (regi hivas), atirjuk STANDBY_IPS-re
if [[ -z "${STANDBY_IPS:-}" ]] && [[ -n "${STANDBY_IP:-}" ]]; then
    STANDBY_IPS="$STANDBY_IP"
fi
: "${STANDBY_IPS:?kell STANDBY_IPS (vesszovel elvalasztott IP-lista)}"
: "${REPLICATION_PASSWORD:?kell REPLICATION_PASSWORD}"

log() { echo "[primary-ha] $*"; }

PG_CONF=/etc/postgresql/16/main/postgresql.conf
PG_HBA=/etc/postgresql/16/main/pg_hba.conf

# IP-lista bontasa
IFS=',' read -ra IP_ARRAY <<< "$STANDBY_IPS"
log "=== Standby IP-k: ${IP_ARRAY[*]} ==="

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
    ["wal_keep_size"]="256"
)
for key in "${!settings[@]}"; do
    if grep -qE "^${key}\s*=" "$PG_CONF"; then
        sed -i -E "s|^${key}\s*=.*|${key} = ${settings[$key]}|" "$PG_CONF"
    else
        echo "${key} = ${settings[$key]}" >> "$PG_CONF"
    fi
done

log "=== 3. pg_hba.conf - replication access minden standby IP-hez ==="
i=0
for ip in "${IP_ARRAY[@]}"; do
    ip_trim=$(echo "$ip" | xargs)  # trim whitespace
    slot_name="standby_slot_$i"
    if ! grep -q "replicator.*${ip_trim}/32" "$PG_HBA"; then
        echo "host replication replicator ${ip_trim}/32 scram-sha-256" >> "$PG_HBA"
    fi
    log "  [$i] IP: $ip_trim, slot: $slot_name"
    i=$((i+1))
done

log "=== 4. Replication slot-ok letrehozasa ==="
i=0
for ip in "${IP_ARRAY[@]}"; do
    slot_name="standby_slot_$i"
    sudo -u postgres psql -d valuta -c "SELECT pg_create_physical_replication_slot('$slot_name') WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name='$slot_name');" 2>&1 | tail -1 || true
    i=$((i+1))
done

log "=== 5. PG restart ==="
systemctl restart postgresql@16-main
sleep 3
systemctl is-active postgresql@16-main

log "=== 6. Replication slots + status ==="
sudo -u postgres psql -c "SELECT slot_name, active, restart_lsn FROM pg_replication_slots;"
echo ""
sudo -u postgres psql -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;" || true

log "=== KESZ ==="
log ""
log "KOVETKEZO LEPESEK a STANDBY VPS-eken:"
log "  1. SSH mindegyikre (Contabo, Scaleway)"
log "  2. apt install postgresql-16 (ha nincs)"
log "  3. Futtasd: PRIMARY_IP=$(hostname -I | awk '{print $1}') \\"
log "                REPLICATION_PASSWORD=<REDACTED> \\"
log "                SLOT_NAME=standby_slot_<N>  \\"
log "                bash install-standby.sh"
log ""
log "  N = 0 a Contabo-nak, 1 a Scaleway-nak, stb. (a STANDBY_IPS sorrendjenek megfelel)"
