#!/usr/bin/env bash
# ============================================================================
# Off-host primary watchdog — a SCALEWAY standby-n fut, a HETZNER primary
# publikus elerhetoseget figyeli. Tartos kieses eseten e-mailt kuld a 4
# whitelist-kolleganak. Ez fedi le azt, amit az on-host Alertmanager NEM tud:
# ha a TELJES Hetzner host meghal, az Alertmanager is vele -> az off-host
# watchdog (mas geprol) akkor is riaszt.
#
# 2026-06-05: a ~10 oras nema kieses tanulsaga. Lasd: scaleway-failover-runbook.md
#
# Auto-promote SZANDEKOSAN nincs alapertelmezetten: egy financialis ERP-nel a
# split-brain (mindket node primary -> adatdivergencia) veszelyesebb, mint egy
# riasztas-vezerelt KEZI failover. A standby mar 2.27.90, igy a runbook szerinti
# egyparancsos failover ELOSZOR tenylegesen mukodne. AUTO_FAILOVER=yes csak akkor,
# ha az uzemelteto vallalja a split-brain kockazatot.
# ============================================================================
set -uo pipefail

HEALTH_PATH="/api/v1/auth/bootstrap-status"
HEALTH_URL="https://excvaluta.com${HEALTH_PATH}"
ORIGIN_IP="95.216.191.162"
FAIL_THRESHOLD=3                                   # ennyi egymas utani bukas utan riaszt (~3 perc @1perc timer)
STATE_FILE="/var/lib/primary-watchdog/state"
# FONTOS: a Scaleway BLOKKOLJA a kimeno SMTP-t (25/465/587) -> a watchdog Resend
# HTTP API-n (443) kuld. A from verifikalt Resend-domain (ebciroda.com).
RESEND_API="https://api.resend.com/emails"
RESEND_KEY_FILE="/etc/primary-watchdog/resend_api_key"
MAIL_FROM="excvaluta watchdog <watchdog@ebciroda.com>"
AUTO_FAILOVER="no"                                 # "yes" = promote+DNS auto (split-brain kockazat!) — alapbol KI
RCPTS=( "kosa.zoltan.ebc@gmail.com" "borsi.tamas.ebc@gmail.com" "kasza.helga.ebc@gmail.com" "bali.henriett.ebc@gmail.com" )

mkdir -p "$(dirname "$STATE_FILE")"

send_email() {
  local subject="$1" body="$2"
  if [ ! -f "$RESEND_KEY_FILE" ]; then echo "watchdog: hianyzik a Resend kulcs ($RESEND_KEY_FILE)" >&2; return 1; fi
  local key payload code; key="$(cat "$RESEND_KEY_FILE")"
  # JSON osszeallitas python3-mal (biztonsagos escape; a body tartalmazhat ujsort/ekezetet)
  local to_json; to_json="$(printf '"%s",' "${RCPTS[@]}")"; to_json="[${to_json%,}]"
  payload="$(python3 -c 'import json,sys; print(json.dumps({"from":sys.argv[1],"to":json.loads(sys.argv[2]),"subject":sys.argv[3],"text":sys.argv[4]}))' \
            "$MAIL_FROM" "$to_json" "$subject" "$body")" || { echo "watchdog: JSON-build hiba" >&2; return 1; }
  code="$(curl -s -o /tmp/wd_resend.out -w '%{http_code}' --max-time 15 -X POST "$RESEND_API" \
         -H "Authorization: Bearer ${key}" -H 'Content-Type: application/json' -d "$payload")"
  if [ "$code" = "200" ] || [ "$code" = "201" ]; then rm -f /tmp/wd_resend.out; return 0; fi
  echo "watchdog: Resend HTTP ${code}: $(cat /tmp/wd_resend.out 2>/dev/null)" >&2; rm -f /tmp/wd_resend.out; return 1
}

# --- teszt mod: azonnali teszt-email ---
if [ "${1:-}" = "--test" ]; then
  send_email "[excvaluta watchdog] TESZT (off-host)" \
    "Ez a Scaleway off-host watchdog teszt-uzenete. Ha megkaptad, a kulso (Hetzner-fuggetlen) figyeles MUKODIK. Ido: $(date -u)" \
    && echo "teszt email elkuldve a 4 cimzettnek" || { echo "teszt email HIBA"; exit 1; }
  exit 0
fi

# --- allapot betoltes ---
fails=0; alerted=0
if [ -f "$STATE_FILE" ]; then
  fails="$(sed -n '1p' "$STATE_FILE" 2>/dev/null | grep -oE '^[0-9]+' || echo 0)"
  grep -q '^alerted=1$' "$STATE_FILE" 2>/dev/null && alerted=1
fi

# --- health: publikus (Cloudflare) ES kozvetlen origin (hogy a CF-cache ne fedje el) ---
pub="$(curl -s -o /dev/null -w '%{http_code}' --max-time 12 "$HEALTH_URL" || echo 000)"
orig="$(curl -s -o /dev/null -w '%{http_code}' --max-time 12 --resolve "excvaluta.com:443:${ORIGIN_IP}" "$HEALTH_URL" || echo 000)"

if [ "$pub" = "200" ] || [ "$orig" = "200" ]; then
  # ----- UP -----
  if [ "$alerted" = "1" ]; then
    send_email "[excvaluta RECOVERED] a primary ujra elerheto" \
      "A Hetzner primary (excvaluta.com) ismet HTTP 200 (publikus=${pub}, origin=${orig}). Ido: $(date -u)"
  fi
  printf '0\n' > "$STATE_FILE"
else
  # ----- DOWN -----
  fails=$(( fails + 1 ))
  if [ "$fails" -ge "$FAIL_THRESHOLD" ] && [ "$alerted" = "0" ]; then
    send_email "[excvaluta DOWN] a primary NEM elerheto" \
      "A Hetzner primary (excvaluta.com) ${fails} egymast koveto ellenorzesnel NEM elerheto (publikus=${pub}, origin=${orig}). Ido: $(date -u).

Teendo: ha tartos, kezi failover a standby-ra (mar 2.27.90) — lasd deploy/hetzner/ha/ + scaleway-failover-runbook.md."
    printf '%s\nalerted=1\n' "$fails" > "$STATE_FILE"
    if [ "$AUTO_FAILOVER" = "yes" ]; then
      echo "watchdog: AUTO_FAILOVER=yes -> failover-to-standby.sh inditasa" >&2
      /opt/valutavalto/deploy/hetzner/ha/failover-to-standby.sh >>/var/log/primary-watchdog-failover.log 2>&1 || true
    fi
  else
    printf '%s\n' "$fails" > "$STATE_FILE"
  fi
fi
