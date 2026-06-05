#!/usr/bin/env bash
# ============================================================================
# Off-host primary watchdog — a SCALEWAY standby-n fut, a HETZNER primary
# publikus elerhetoseget figyeli. Tartos kieses eseten e-mailt kuld a 4
# whitelist-kolleganak, es (ha engedelyezve) AUTOMATIKUS failovert vegez.
#
# Ez fedi le azt, amit az on-host Alertmanager NEM tud: ha a TELJES Hetzner host
# meghal, az Alertmanager is vele -> az off-host watchdog (mas geprol) akkor is riaszt.
#
# 2026-06-05: a ~10 oras nema kieses tanulsaga. Lasd: scaleway-failover-runbook.md
#
# SPLIT-BRAIN VEDELEM (auto-failover modban):
#   1. Auto-promote CSAK ha a publikus (Cloudflare) ES a kozvetlen origin is down
#      -> egy Scaleway-lokalis halozati blip (amikor a vilag meg eleri a Hetznert
#      Cloudflare-on at) NEM indit failovert.
#   2. Magasabb kuszob a promote-hoz (PROMOTE_THRESHOLD) mint a riasztashoz
#      (FAIL_THRESHOLD) -> ember elobb reagalhat, tranziens blip nem promote-ol.
#   3. Promote elott friss ujra-ellenorzes (burst).
#   4. A failover-to-standby.sh FAILOVER_AUTO=1 modban abortal, ha a replikacios
#      lag tul nagy (tul sok adatvesztes) -> inkabb ember dontson.
#   5. One-shot (promoted flag), es a promote utan a DB mar nem standby -> a
#      failover-script pre-flight masodszor nem promote-ol.
# ============================================================================
set -uo pipefail

HEALTH_PATH="/api/v1/auth/bootstrap-status"
HEALTH_URL="https://excvaluta.com${HEALTH_PATH}"
ORIGIN_IP="95.216.191.162"
FAIL_THRESHOLD=3                                   # ennyi bukas utan RIASZT (~3 perc @1perc timer)
PROMOTE_THRESHOLD=6                                # ennyi bukas utan AUTO-PROMOTE (~6 perc)
STATE_FILE="/var/lib/primary-watchdog/state"
STANDBY_IP="163.172.152.234"
# Scaleway BLOKKOLJA a kimeno SMTP-t (25/465/587) -> Resend HTTP API (443).
RESEND_API="https://api.resend.com/emails"
RESEND_KEY_FILE="/etc/primary-watchdog/resend_api_key"
MAIL_FROM="excvaluta watchdog <watchdog@ebciroda.com>"
RCPTS=( "kosa.zoltan.ebc@gmail.com" "borsi.tamas.ebc@gmail.com" "kasza.helga.ebc@gmail.com" "bali.henriett.ebc@gmail.com" )
# AUTO-FAILOVER: a user 2026-06-05 dontese alapjan BE. A split-brain-vedelem fent.
AUTO_FAILOVER="yes"
FAILOVER_SCRIPT="/opt/valutavalto/deploy/hetzner/ha/failover-to-standby.sh"
DNS_SCRIPT="/opt/valutavalto/deploy/hetzner/ha/cloudflare-dns-failover.sh"
CF_ENV_FILE="/etc/primary-watchdog/cf_env"         # CF_API_TOKEN + CF_ZONE_ID (root:600)
FAILOVER_LOG="/var/log/primary-watchdog-failover.log"
# WATCHDOG_DRY_RUN=1 -> a promote-ot CSAK naplozza, nem hajtja vegre (teszteleshez).

mkdir -p "$(dirname "$STATE_FILE")"

send_email() {
  local subject="$1" body="$2"
  if [ ! -f "$RESEND_KEY_FILE" ]; then echo "watchdog: hianyzik a Resend kulcs ($RESEND_KEY_FILE)" >&2; return 1; fi
  local key payload code; key="$(cat "$RESEND_KEY_FILE")"
  local to_json; to_json="$(printf '"%s",' "${RCPTS[@]}")"; to_json="[${to_json%,}]"
  payload="$(python3 -c 'import json,sys; print(json.dumps({"from":sys.argv[1],"to":json.loads(sys.argv[2]),"subject":sys.argv[3],"text":sys.argv[4]}))' \
            "$MAIL_FROM" "$to_json" "$subject" "$body")" || { echo "watchdog: JSON-build hiba" >&2; return 1; }
  code="$(curl -s -o /tmp/wd_resend.out -w '%{http_code}' --max-time 15 -X POST "$RESEND_API" \
         -H "Authorization: Bearer ${key}" -H 'Content-Type: application/json' -d "$payload")"
  if [ "$code" = "200" ] || [ "$code" = "201" ]; then rm -f /tmp/wd_resend.out; return 0; fi
  echo "watchdog: Resend HTTP ${code}: $(cat /tmp/wd_resend.out 2>/dev/null)" >&2; rm -f /tmp/wd_resend.out; return 1
}

probe() { curl -s -o /dev/null -w '%{http_code}' --max-time 12 "$1" "${@:2}"; }

# check_once GLOBALOKBA ir (STATUS/LAST_PUB/LAST_ORIG), NEM echo-z — kulonben
# command-substitution ($(...)) subshellben futna es a globalok nem propagalnanak
# a szulo shellbe (set -u -> unbound variable). Kozvetlenul kell hivni.
STATUS="down"; LAST_PUB="?"; LAST_ORIG="?"
check_once() {
  if [ "${SIMULATE_DOWN:-0}" = "1" ]; then LAST_PUB="SIM"; LAST_ORIG="SIM"; STATUS="down"; return; fi
  LAST_PUB="$(probe "$HEALTH_URL" || echo 000)"
  LAST_ORIG="$(probe "$HEALTH_URL" --resolve "excvaluta.com:443:${ORIGIN_IP}" || echo 000)"
  if [ "$LAST_PUB" = "200" ] || [ "$LAST_ORIG" = "200" ]; then STATUS="up"; else STATUS="down"; fi
}

do_auto_failover() {
  # --- Pre-promote friss ujra-ellenorzes: 3 burst, BOTH path. Ha barmelyik 200 -> abort. ---
  local i
  for i in 1 2 3; do
    check_once
    if [ "$STATUS" = "up" ]; then
      echo "watchdog: auto-failover MEGSZAKITVA - a primary ujra valaszol (pub=$LAST_PUB origin=$LAST_ORIG)" >&2
      return 1
    fi
    sleep 5
  done

  if [ "${WATCHDOG_DRY_RUN:-0}" = "1" ]; then
    echo "watchdog: [DRY-RUN] MOST failover-t inditanek (pub=$LAST_PUB origin=$LAST_ORIG). Valodi promote KIHAGYVA." >&2
    return 0
  fi

  send_email "[excvaluta AUTO-FAILOVER] indul" \
    "A Hetzner primary tartosan NEM elerheto (pub=$LAST_PUB, origin=$LAST_ORIG). Automatikus failover indul a Scaleway-re. Ido: $(date -u)"

  # --- 1. Promote (FAILOVER_AUTO=1: non-interaktiv + max-lag abort) ---
  if ! FAILOVER_AUTO=1 bash "$FAILOVER_SCRIPT" >>"$FAILOVER_LOG" 2>&1; then
    send_email "[excvaluta AUTO-FAILOVER] HIBA a promote-nal" \
      "A failover-to-standby.sh NEM futott le sikeresen (lehet tul nagy lag, vagy mar nem standby). Lasd $FAILOVER_LOG a Scaleway-en. KEZI beavatkozas kell!"
    return 1
  fi

  # --- 2. Cloudflare DNS swap (CF_AUTO=1: non-interaktiv) ---
  if [ ! -f "$CF_ENV_FILE" ]; then
    send_email "[excvaluta AUTO-FAILOVER] promote OK, DNS kihagyva" \
      "A standby promote-olt, de nincs CF-credential ($CF_ENV_FILE). A DNS-t KEZILEG kell a Scaleway IP-re allitani ($STANDBY_IP)."
    return 1
  fi
  if ! ( set -a; . "$CF_ENV_FILE"; set +a; CF_AUTO=1 STANDBY_IP="$STANDBY_IP" bash "$DNS_SCRIPT" apply ) >>"$FAILOVER_LOG" 2>&1; then
    send_email "[excvaluta AUTO-FAILOVER] promote OK, DNS HIBA" \
      "A standby promote-olt, de a Cloudflare DNS-swap NEM sikerult. KEZI DNS-atallitas kell a Scaleway IP-re ($STANDBY_IP)! Lasd $FAILOVER_LOG."
    return 1
  fi

  send_email "[excvaluta AUTO-FAILOVER] KESZ" \
    "A Scaleway ($STANDBY_IP) most a PRIMARY, a Cloudflare DNS atkapcsolt. FONTOS: a regi Hetzner primary-t NE inditsd ujra pg_rewind nelkul (split-brain)! Restore: scaleway-failover-runbook.md"
  return 0
}

# --- teszt mod: azonnali teszt-email ---
if [ "${1:-}" = "--test" ]; then
  send_email "[excvaluta watchdog] TESZT (off-host)" \
    "Ez a Scaleway off-host watchdog teszt-uzenete. Ha megkaptad, a kulso (Hetzner-fuggetlen) figyeles MUKODIK. Ido: $(date -u)" \
    && echo "teszt email elkuldve a 4 cimzettnek" || { echo "teszt email HIBA"; exit 1; }
  exit 0
fi

# --- allapot betoltes ---
fails=0; alerted=0; promoted=0
if [ -f "$STATE_FILE" ]; then
  fails="$(sed -n '1p' "$STATE_FILE" 2>/dev/null | grep -oE '^[0-9]+' || echo 0)"
  grep -q '^alerted=1$'  "$STATE_FILE" 2>/dev/null && alerted=1
  grep -q '^promoted=1$' "$STATE_FILE" 2>/dev/null && promoted=1
fi

save_state() {
  { printf '%s\n' "$fails"
    [ "$alerted" = "1" ]  && echo "alerted=1"
    [ "$promoted" = "1" ] && echo "promoted=1"
  } > "$STATE_FILE"
}

# --- health check (--simulate-down: erolteti a down-agat a TELJES lancra, teszteleshez) ---
if [ "${1:-}" = "--simulate-down" ]; then export SIMULATE_DOWN=1; fi
check_once; status="$STATUS"

if [ "$status" = "up" ]; then
  # ----- UP -----
  if [ "$alerted" = "1" ] || [ "$promoted" = "1" ]; then
    send_email "[excvaluta RECOVERED] a primary ujra elerheto" \
      "Az excvaluta.com ismet HTTP 200 (pub=${LAST_PUB}, origin=${LAST_ORIG}). Ido: $(date -u)$([ "$promoted" = "1" ] && echo ' — MEGJEGYZES: korabban auto-failover tortent, ellenorizd melyik node a primary!')"
  fi
  fails=0; alerted=0; promoted=0; save_state
else
  # ----- DOWN -----
  fails=$(( fails + 1 ))
  if [ "$fails" -ge "$FAIL_THRESHOLD" ] && [ "$alerted" = "0" ]; then
    send_email "[excvaluta DOWN] a primary NEM elerheto" \
      "A Hetzner primary (excvaluta.com) ${fails} egymast koveto ellenorzesnel NEM elerheto (pub=${LAST_PUB}, origin=${LAST_ORIG}). Ido: $(date -u). $([ "$AUTO_FAILOVER" = yes ] && echo "Ha tartos (${PROMOTE_THRESHOLD} ellenorzes), automatikus failover indul." || echo "Kezi failover: scaleway-failover-runbook.md")"
    alerted=1
  fi
  if [ "$AUTO_FAILOVER" = "yes" ] && [ "$fails" -ge "$PROMOTE_THRESHOLD" ] && [ "$promoted" = "0" ]; then
    if do_auto_failover; then promoted=1; fi
  fi
  save_state
fi
