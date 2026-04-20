#!/usr/bin/env bash
# Caddy 2 install + Caddyfile telepites + systemd enable
set -euo pipefail

log() { echo "[caddy-install] $*"; }

log "=== Caddy repo + csomag telepites ==="
DEBIAN_FRONTEND=noninteractive apt-get install -yq debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -yq caddy

log "=== Caddyfile telepites ==="
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cp "$SCRIPT_DIR/Caddyfile" /etc/caddy/Caddyfile

log "=== Log dir ==="
mkdir -p /var/log/caddy
chown caddy:caddy /var/log/caddy

log "=== Caddy syntax ellenorzes ==="
caddy validate --config /etc/caddy/Caddyfile

log "=== systemctl reload ==="
systemctl enable --now caddy
systemctl reload caddy || systemctl restart caddy
systemctl status caddy --no-pager | head -5

log "=== Smoke test ==="
curl -sSf -I https://excvaluta.com/ | head -5 || true

log "=== KESZ ==="
log "Caddy metrikak: curl http://localhost:2019/metrics"
log "Caddy admin:    curl http://localhost:2019/config/"
