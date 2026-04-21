#!/usr/bin/env bash
set -euo pipefail
: "${CF_API_TOKEN:?kell CF_API_TOKEN}"
: "${CF_ZONE_ID:?kell CF_ZONE_ID}"
: "${STANDBY_IP:?kell STANDBY_IP}"
log() { echo "[cf-failover] $*"; }
API="https://api.cloudflare.com/client/v4"
log "=== A record lookup ==="
RECORD_ID=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" "$API/zones/$CF_ZONE_ID/dns_records?type=A&name=excvaluta.com" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["result"][0]["id"])')
log "Record ID: $RECORD_ID"
log "=== TTL -> 60s ==="
curl -s -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json" -X PATCH "$API/zones/$CF_ZONE_ID/dns_records/$RECORD_ID" -d '{"ttl":60,"proxied":false}' | python3 -c 'import sys,json; d=json.load(sys.stdin); print("New TTL:", d["result"]["ttl"])'
log ""
log "=== MANUAL FAILOVER COMMAND (copy-paste-elheto ha a primary leall) ==="
cat <<EOC
curl -X PATCH "$API/zones/$CF_ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer <CF_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"content":"$STANDBY_IP"}'
EOC
