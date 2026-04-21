#!/usr/bin/env bash
# ============================================================================
# Failover playbook - manualis promote
# ============================================================================
# 3-regios setup: Primary -> Contabo (warm) -> Scaleway (cold)
# Failover sorrend: ha primary leall, az ELSO elerheto standby-t promote-oljuk
#
# Hasznalat ezen a standby-n:
#   bash failover-to-standby.sh
# ============================================================================
set -euo pipefail

log() { echo "[failover] $*"; }

log "=== Pre-flight: ez tenyleg standby? ==="
if ! sudo -u postgres psql -c "SELECT pg_is_in_recovery();" | grep -q ' t'; then
    log "HIBA: ez a node NEM standby (mar primary, vagy recovery kikapcsolva)"
    exit 1
fi

log "=== Replication lag aktualizalt ==="
sudo -u postgres psql -c "SELECT NOW() - pg_last_xact_replay_timestamp() AS replication_lag;"
log "Ha ez > 60 masodperc, FONTOLJ meg egyszer a promotot (esetleges adatvesztes)"
read -t 5 -p "Folytatod? (y/N): " confirm || confirm=""
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log "Megszakitva - nincs promote"
    exit 0
fi

log "=== 1. pg_ctl promote ==="
sudo -u postgres pg_ctlcluster 16 main promote
sleep 3

log "=== 2. Verifikacio ==="
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"

log "=== 3. Replication slot cleanup (ez most primary lett) ==="
sudo -u postgres psql -c "SELECT slot_name FROM pg_replication_slots;" | while read -r slot; do
    if [[ "$slot" == standby_slot* ]]; then
        sudo -u postgres psql -c "SELECT pg_drop_replication_slot('$slot');" || true
    fi
done

log "=== KESZ - ez a node most PRIMARY ==="
log ""
log "KOVETKEZO LEPESEK:"
log "  1. Cloudflare DNS: excvaluta.com A record -> $(hostname -I | awk '{print $1}')"
log "     curl -X PATCH 'https://api.cloudflare.com/client/v4/zones/<ZONE>/dns_records/<REC>' \\"
log "       -H 'Authorization: Bearer <TOKEN>' -H 'Content-Type: application/json' \\"
log "       -d '{\"content\":\"$(hostname -I | awk '{print $1}')\"}'"
log ""
log "  2. A masik standby (ha Scaleway meg el) -> rewind + uj replica:"
log "     pg_rewind + install-standby.sh (PRIMARY_IP=$(hostname -I | awk '{print $1}'))"
log ""
log "  3. Az eredeti primary-t NE inditsd el (split-brain)"
log "     amig pg_rewind + uj standby-setup nem tortent meg"
