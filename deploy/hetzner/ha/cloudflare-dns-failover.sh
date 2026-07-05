#!/usr/bin/env bash
# ============================================================================
# Cloudflare DNS Failover Helper (BOVITETT v2.5.49+)
# ============================================================================
# Atkapcsolja az excvaluta.com A record-ot Hetzner -> Scaleway (vagy vissza).
#
# Hasznalat:
#
#   1. Atkapcsolas Scaleway-re:
#      CF_API_TOKEN=xxx CF_ZONE_ID=yyy STANDBY_IP=163.172.152.234 \
#        bash cloudflare-dns-failover.sh apply
#
#   2. TTL preparation (csak TTL-t 60-ra allitja, atkapcsolas nelkul):
#      CF_API_TOKEN=xxx CF_ZONE_ID=yyy bash cloudflare-dns-failover.sh prepare
#
#   3. Allapot lekerdezes:
#      CF_API_TOKEN=xxx CF_ZONE_ID=yyy bash cloudflare-dns-failover.sh status
#
#   4. Visszakapcsolas Hetzner-re:
#      CF_API_TOKEN=xxx CF_ZONE_ID=yyy PRIMARY_IP=95.216.191.162 \
#        bash cloudflare-dns-failover.sh apply
#
# Env vars:
#   CF_API_TOKEN  - Cloudflare API token (Zone:DNS:Edit jog kell)
#   CF_ZONE_ID    - excvaluta.com zone ID
#   STANDBY_IP / PRIMARY_IP - cel IP cim
#   DOMAIN        - default: excvaluta.com
# ============================================================================
set -euo pipefail

DOMAIN="${DOMAIN:-excvaluta.com}"
ACTION="${1:-status}"
API="https://api.cloudflare.com/client/v4"
RECORD_NAMES=("$DOMAIN" "www.$DOMAIN")

: "${CF_API_TOKEN:?CF_API_TOKEN kotelezo (Cloudflare API token, Zone DNS Edit)}"
: "${CF_ZONE_ID:?CF_ZONE_ID kotelezo (excvaluta.com zone ID)}"

log() { echo "[cf-failover $(date +%T)] $*"; }
err() { echo "[cf-failover ERROR] $*" >&2; }

# Lekerdezzuk a megadott nevu A record-ot.
fetch_record() {  # $1 = record name (pl. excvaluta.com vagy www.excvaluta.com)
    curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
        "$API/zones/$CF_ZONE_ID/dns_records?type=A&name=$1"
}

extract_field() {
    python3 -c "import sys,json
d=json.load(sys.stdin)
if not d.get('success'):
    print('CF_API_ERROR:', d, file=sys.stderr)
    sys.exit(1)
r=d['result'][0] if d['result'] else None
if not r: sys.exit(2)
print(r.get('$1',''))"
}

case "$ACTION" in

    status)
        log "=== Aktualis A record-ok: ${RECORD_NAMES[*]} ==="
        for NAME in "${RECORD_NAMES[@]}"; do
            result=$(fetch_record "$NAME")
            REC_ID=$(echo "$result" | extract_field id) || { log "FIGYELEM: nincs A rekord: $NAME — kihagyva"; continue; }
            log "--- $NAME ---"
            echo "$result" | python3 -c "import sys,json
d=json.load(sys.stdin)
if not d.get('success'):
    print('API hiba:', d.get('errors')); sys.exit(1)
r=d['result'][0]
print(f\"  ID:      {r['id']}\")
print(f\"  Content: {r['content']}\")
print(f\"  TTL:     {r['ttl']}s\")
print(f\"  Proxied: {r['proxied']}\")
print(f\"  Modified: {r['modified_on']}\")"
        done
        ;;

    prepare)
        log "=== TTL leszallitas 60s-ra (felkeszules failover-re) ==="
        for NAME in "${RECORD_NAMES[@]}"; do
            result=$(fetch_record "$NAME")
            REC_ID=$(echo "$result" | extract_field id) || { log "FIGYELEM: nincs A rekord: $NAME — kihagyva"; continue; }
            CURRENT_IP=$(echo "$result" | extract_field content)
            CURRENT_TTL=$(echo "$result" | extract_field ttl)
            log "$NAME: Record ID: $REC_ID, jelenlegi IP: $CURRENT_IP, TTL: $CURRENT_TTL"

            if [[ "$CURRENT_TTL" == "60" ]]; then
                log "$NAME: TTL mar 60s, nincs valtozas"
            else
                curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" \
                    -X PATCH "$API/zones/$CF_ZONE_ID/dns_records/$REC_ID" \
                    -d '{"ttl":60}' | python3 -c "import sys,json; d=json.load(sys.stdin); print('Uj TTL:', d['result']['ttl'] if d.get('success') else 'HIBA')"
            fi
        done
        ;;

    apply)
        TARGET_IP="${STANDBY_IP:-${PRIMARY_IP:-}}"
        : "${TARGET_IP:?STANDBY_IP vagy PRIMARY_IP kotelezo}"

        log "=== A record-ok atkapcsolasa -> $TARGET_IP (${RECORD_NAMES[*]}) ==="

        # Megerositest kerunk (interaktiv). CF_AUTO=1 -> kihagyas (auto-failover, watchdog).
        if [[ "${CF_AUTO:-0}" != "1" ]]; then
            read -t 10 -p "Folytatod a DNS atkapcsolast? (y/N, 10s timeout = N): " confirm || confirm=""
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                log "Megszakitva - nincs DNS atkapcsolas"
                exit 0
            fi
        else
            log "CF_AUTO=1 -> interaktiv megerosites kihagyva (auto-failover)"
        fi

        for NAME in "${RECORD_NAMES[@]}"; do
            result=$(fetch_record "$NAME")
            REC_ID=$(echo "$result" | extract_field id) || { log "FIGYELEM: nincs A rekord: $NAME — kihagyva"; continue; }
            OLD_IP=$(echo "$result" | extract_field content)
            log "$NAME: Record ID: $REC_ID, regi IP: $OLD_IP -> uj IP: $TARGET_IP"

            if [[ "$OLD_IP" == "$TARGET_IP" ]]; then
                log "$NAME: A record mar a celon van, nincs valtozas"
                continue
            fi

            # Cloudflare PATCH partial-update: a proxied flag automatikusan megorzodik.
            # Egy rekord CF-hibaja NE allitsa meg a masik rekord feldolgozasat (set -e alatt):
            # a PATCH-hibat naplozzuk es continue-val a kovetkezo rekordra lepunk (fail-loud, nem nema).
            if ! curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" \
                -X PATCH "$API/zones/$CF_ZONE_ID/dns_records/$REC_ID" \
                -d "{\"content\":\"$TARGET_IP\",\"ttl\":60}" \
                | python3 -c "import sys,json
d=json.load(sys.stdin)
if not d.get('success'):
    print('HIBA:', d.get('errors')); sys.exit(1)
r=d['result']
print(f'  Uj IP:    {r[\"content\"]}')
print(f'  TTL:      {r[\"ttl\"]}s')
print(f'  Modified: {r[\"modified_on\"]}')"; then
                err "$NAME: A PATCH NEM sikerult (CF API hiba) — a tobbi rekord feldolgozasa folytatodik"
                continue
            fi
        done

        log "DNS atkapcsolas KESZ - propagacio ~$(( ${TTL:-60} + 60 ))s alatt"
        log ""
        log "Verifikacio:"
        log "  dig +short $DOMAIN @1.1.1.1"
        log "  dig +short $DOMAIN @8.8.8.8"
        log "  dig +short www.$DOMAIN @1.1.1.1"
        log "  dig +short www.$DOMAIN @8.8.8.8"
        log "  curl -s -o /dev/null -w '%{http_code}\\n' https://$DOMAIN/api/v1/auth/bootstrap-status"
        ;;

    *)
        err "Ismeretlen akcio: $ACTION"
        echo "Hasznalat: $0 {status|prepare|apply}"
        exit 1
        ;;
esac
