#!/usr/bin/env bash
# ============================================================================
# Failover playbook - manualis promote a standby-on
# ============================================================================
# Ha a primary VPS leallt:
#   1. Ellenorizd, hogy a primary tenyleg halott
#   2. Futtasd ezt a STANDBY-on
#   3. Cloudflare DNS: allitsd at az A rekordot a standby IP-re
# ============================================================================
set -euo pipefail

log() { echo "[failover] $*"; }

log "=== Pre-flight check ==="
if ! sudo -u postgres psql -c "SELECT pg_is_in_recovery();" | grep -q ' t'; then
    log "HIBA: ez a node NEM standby"
    exit 1
fi

log "=== 1. pg_ctl promote ==="
sudo -u postgres pg_ctlcluster 16 main promote
sleep 3

log "=== 2. Verifikacio ==="
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"

log "=== 3. Replication slot torlese ==="
sudo -u postgres psql -c "DROP REPLICATION SLOT IF EXISTS standby_slot;" || true

log "=== KESZ. Kovetkezo lepesek: ==="
log "  1. Cloudflare DNS: excvaluta.com A rekord -> $(hostname -I | awk '{print $1}')"
log "  2. Az eddigi primary-t ne inditsd el (split-brain)"
log "  3. Backend restart: systemctl restart valuta-backend"
