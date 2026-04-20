#!/usr/bin/env bash
# ============================================================================
# Tailscale SSH bastion setup (vezerlokonyv par.30.1)
# ============================================================================
# Futtatas elott: kerj Tailscale authkey-t a https://login.tailscale.com/admin/settings/keys
# olda	lon (reusable, ephemeral=false, tags=tag:prod-vps).
#
# Peldas hasznalat:
#   TAILSCALE_AUTHKEY=tskey-abc123 bash install-tailscale.sh
#
# Elony: SSH a publikus Internet felol BLOKKOLHATO (UFW deny 22), de
# a 100.x.x.x tailscale IP-n elerheto marad. MITM-vedett end-to-end titkositas.
# ============================================================================

set -euo pipefail

if [[ -z "${TAILSCALE_AUTHKEY:-}" ]]; then
    echo "HIBA: TAILSCALE_AUTHKEY kornyezeti valtozo nincs beallitva."
    echo "Generalj key-t: https://login.tailscale.com/admin/settings/keys"
    echo "Futtasd ujra: TAILSCALE_AUTHKEY=tskey-xxx bash $0"
    exit 1
fi

log() { echo "[tailscale-install] $*"; }

log "=== Tailscale telepitese ==="
curl -fsSL https://tailscale.com/install.sh | sh

log "=== Node felhasznalas + SSH server ==="
# --ssh: Tailscale kozvetlenul kezeli az SSH auth-ot (ACL alapjan)
# --advertise-tags: ACL cimke, amit a https://login.tailscale.com/admin/acls-ben hasznal
# --accept-dns=false: a VPS DNS-e legyen autoritativ (nem a tailscale magic DNS)
tailscale up \
    --authkey="$TAILSCALE_AUTHKEY" \
    --ssh \
    --advertise-tags=tag:prod-vps \
    --accept-dns=false \
    --hostname="$(hostname)"

log "=== Verifikacio ==="
tailscale status | head -5
TS_IP=$(tailscale ip -4)
log "Tailscale IP: $TS_IP"

log "=== UFW modositas: publikus SSH portot torolni (opcionalis!) ==="
log "JAVASLAT: miutan ellenoriztek a tailscale SSH-t, futtasd:"
log "  ufw delete allow 22/tcp"
log "  ufw allow in on tailscale0 to any port 22"
log ""
log "A tailscale_config.example.json-ben osszetett ACL mintak vannak."

log "=== ACL minta (masold a tailscale admin konzolra) ==="
cat <<'ACLEOF'
{
  "acls": [
    { "action": "accept", "src": ["tag:admin"], "dst": ["tag:prod-vps:22"] },
    { "action": "accept", "src": ["tag:monitoring"], "dst": ["tag:prod-vps:9090"] }
  ],
  "tagOwners": {
    "tag:admin":       ["group:admins"],
    "tag:prod-vps":    ["group:admins"],
    "tag:monitoring":  ["group:admins"]
  },
  "groups": {
    "group:admins": ["kosa.zoltan.ebc@gmail.com"]
  },
  "ssh": [
    { "action": "accept", "src": ["tag:admin"], "dst": ["tag:prod-vps"], "users": ["root"] }
  ]
}
ACLEOF
log ""
log "=== KESZ ==="
