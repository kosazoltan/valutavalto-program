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
FAILBACK_REMIND_SECS=86400                         # promoted+drift allapotban 24 orankent ismetlo riasztas
FAILBACK_CMD="( set -a; . $CF_ENV_FILE; set +a; CF_AUTO=1 PRIMARY_IP=$ORIGIN_IP bash $DNS_SCRIPT apply )"
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

# Kimenet stdout-ra: az apex A rekord content IP-je, vagy ures string ha nem megallapithato.
# FAIL-OPEN a riasztas fele: ures eredmenyt a hivo drift-kent kezel.
cf_apex_ip() {
  [ -f "$CF_ENV_FILE" ] || { echo ""; return 0; }
  ( set -a; . "$CF_ENV_FILE"; set +a
    curl -s --max-time 15 -H "Authorization: Bearer $CF_API_TOKEN" \
      "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=A&name=excvaluta.com" \
    | python3 -c 'import sys,json
d=json.load(sys.stdin)
r=d.get("result") or []
print(r[0].get("content","") if (d.get("success") and r) else "")' ) 2>/dev/null || echo ""
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
fails=0; alerted=0; promoted=0; failback_notified=0; failover_failed=0
if [ -f "$STATE_FILE" ]; then
  fails="$(sed -n '1p' "$STATE_FILE" 2>/dev/null | grep -oE '^[0-9]+' || echo 0)"
  grep -q '^alerted=1$'  "$STATE_FILE" 2>/dev/null && alerted=1
  grep -q '^promoted=1$' "$STATE_FILE" 2>/dev/null && promoted=1
  grep -q '^failover_failed=1$' "$STATE_FILE" 2>/dev/null && failover_failed=1
fi
fb=$(grep -oE '^failback_notified=[0-9]+$' "$STATE_FILE" 2>/dev/null | cut -d= -f2 || true)
[ -n "$fb" ] && failback_notified="$fb"

save_state() {
  { printf '%s\n' "$fails"
    [ "$alerted" = "1" ]  && echo "alerted=1"
    [ "$promoted" = "1" ] && echo "promoted=1"
    [ "$failover_failed" = "1" ] && echo "failover_failed=1"
    [ "$failback_notified" != "0" ] && echo "failback_notified=$failback_notified"
    # a rovidzart [ ] && ... utolso parancskent 1-et adna -> a compound (es a save_state-tel
    # zarulo script) hibas exit-koddal terne vissza a happy-path-on -> systemd oneshot "failed".
    true
  } > "$STATE_FILE"
}

# --- health check (--simulate-down: erolteti a down-agat a TELJES lancra, teszteleshez) ---
if [ "${1:-}" = "--simulate-down" ]; then export SIMULATE_DOWN=1; fi
check_once; status="$STATUS"

if [ "$status" = "up" ]; then
  # ----- UP -----
  if [ "$promoted" = "1" ]; then
    APEX_IP="$(cf_apex_ip)"
    if [ "$APEX_IP" = "$ORIGIN_IP" ]; then
      send_email "[excvaluta RECOVERED] failback KESZ — Hetzner a primary" \
        "A primary ujra elerheto (pub=${LAST_PUB}, origin=${LAST_ORIG}) ES a Cloudflare DNS mar a Hetzner originre ($ORIGIN_IP) mutat. Ido: $(date -u). Ellenorizd, hogy a Scaleway PG nem maradt-e promotalt primary (split-brain runbook)."
      fails=0; alerted=0; promoted=0; failback_notified=0; failover_failed=0; save_state
    else
      now=$(date +%s)
      if [ $(( now - failback_notified )) -ge "$FAILBACK_REMIND_SECS" ]; then
        send_email "[excvaluta FAILBACK SZUKSEGES] a primary el, de a DNS meg a standbyn ragadt" \
          "A Hetzner primary HELYREALLT (pub=${LAST_PUB}, origin=${LAST_ORIG}), de a Cloudflare apex A rekord jelenleg '${APEX_IP:-NEM MEGALLAPITHATO}' — NEM a Hetzner origin ($ORIGIN_IP). Amig ez igy marad, a publikus forgalom a Scaleway-t (${STANDBY_IP}) eri, es MINDEN deploy ellenere ELAVULT verzio fut publikusan (lasd 2026-07-05 PROD-VERSION-STALE). FAILBACK ELOTT: gyozodj meg rola, hogy a Hetzner DB naprakesz es a Scaleway PG nem streaming-primary (runbook: scaleway-failover-runbook.md). Futtatando parancs a Scaleway-en (root):  ${FAILBACK_CMD}  Ez a riasztas 24 orankent ismetlodik, amig a DNS vissza nem all. Ido: $(date -u)"
        failback_notified="$now"
      fi
      fails=0; save_state   # promoted=1 MEGMARAD; alerted marad ahogy volt
    fi
  else
    if [ "$alerted" = "1" ]; then
      send_email "[excvaluta RECOVERED] a primary ujra elerheto" \
        "Az excvaluta.com ismet HTTP 200 (pub=${LAST_PUB}, origin=${LAST_ORIG}). Ido: $(date -u)"
    fi
    fails=0; alerted=0; promoted=0; failback_notified=0; failover_failed=0; save_state
  fi
else
  # ----- DOWN -----
  fails=$(( fails + 1 ))
  if [ "$fails" -ge "$FAIL_THRESHOLD" ] && [ "$alerted" = "0" ]; then
    send_email "[excvaluta DOWN] a primary NEM elerheto" \
      "A Hetzner primary (excvaluta.com) ${fails} egymast koveto ellenorzesnel NEM elerheto (pub=${LAST_PUB}, origin=${LAST_ORIG}). Ido: $(date -u). $([ "$AUTO_FAILOVER" = yes ] && echo "Ha tartos (${PROMOTE_THRESHOLD} ellenorzes), automatikus failover indul." || echo "Kezi failover: scaleway-failover-runbook.md")"
    alerted=1
  fi
  if [ "$AUTO_FAILOVER" = "yes" ] && [ "$fails" -ge "$PROMOTE_THRESHOLD" ] && [ "$promoted" = "0" ] && [ "$failover_failed" = "0" ]; then
    if do_auto_failover; then
      promoted=1
    else
      # A6: sikertelen failover — ne probalkozzon ujra percenkent
      failover_failed=1
      send_email "[excvaluta AUTO-FAILOVER] SIKERTELEN — kézi beavatkozás kell" \
        "Az automatikus failover (${fails} bukas után) SIKERTELEN volt. A retry-vihar megállítva. \
KÉZI beavatkozás szükséges: 1) ellenőrizd a Scaleway standby állapotát, 2) ha a primary helyreállt, \
töröld a state file-t ($STATE_FILE) a failover_failed flag eltávolításához, 3) runbook: scaleway-failover-runbook.md. \
Ido: $(date -u)"
    fi
  fi
  save_state
fi
