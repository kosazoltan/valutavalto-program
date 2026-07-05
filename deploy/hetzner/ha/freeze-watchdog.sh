#!/usr/bin/env bash
# freeze-watchdog.sh — ON-HOST anti-freeze ÖNGYÓGYÍTÓ watchdog a Hetzner primary
# backend (valuta-backend.service) + Postgres (postgresql@16-main) szolgáltatásra.
#
# Cél (P-FREEZE-A, Kósa Zoltán direktíva 2026-06-15): NE csak JELEZZE a fagyást, hanem
# AUTOMATIKUSAN JAVÍTSA is (újraindítás), és értesítsen — hogy LEÁLLT, és hogy ÚJRAINDÍTOTTA.
# Indok: sok idő telhet el, mire kézzel észrevennénk a fagyást, és addig sok adat veszhet el.
#
# BIZTONSÁGOS — szándékosan KORLÁTOZOTT hatókör:
#   * KIZÁRÓLAG a LOKÁLIS valuta-backend.service + postgresql@16-main szolgáltatást indítja újra.
#     A service-restart NEM veszít commitált adatot (a Postgres a WAL-ból konzisztensen feláll).
#   * NEM csinál failovert / promote-ot / DNS-átkapcsolást / datasource-váltást — ellentétben a
#     primary-watchdog.sh-val, amit épp ezen kockázatok miatt LEKAPCSOLTUNK (2026-06-15).
#     (A „rossz DB-be ír" eset = P-FREEZE-B, sync-before-flip + auto-rollback — KÜLÖN, nem itt.)
#
# Deploy-barát: FAIL_THRESHOLD egymás utáni sikertelen health-check kell a beavatkozáshoz, így egy
# normál deploy-restart (rövid leállás) NEM váltja ki. Rate-limit + flap-védelem a restart-hurok ellen.
#
# Telepítés: systemd timer (freeze-watchdog.timer), percenként fut, root-ként.
set -uo pipefail

HEALTH_URL="http://localhost:8080/api/v1/auth/bootstrap-status"
BACKEND_SVC="valuta-backend.service"
PG_SVC="postgresql@16-main"
STATE_FILE="/var/lib/freeze-watchdog/state"
RESEND_API="https://api.resend.com/emails"
RESEND_KEY_FILE="/etc/primary-watchdog/resend_api_key"   # KÖZÖS a primary-watchdog-gal
MAIL_FROM="excvaluta freeze-watchdog <watchdog@ebciroda.com>"
# Címzettek — a primary-watchdog.sh-val azonos lista (konzisztencia).
RCPTS=( "kosa.zoltan.ebc@gmail.com" "borsi.tamas.ebc@gmail.com" "kasza.helga.ebc@gmail.com" "bali.henriett.ebc@gmail.com" )
FAIL_THRESHOLD=3                                          # ennyi egymás utáni down-check után JAVÍT (~3 perc @1p timer)
MAX_RESTARTS_PER_HOUR=4                                   # rate-limit: ennyi auto-restart/óra felett STOP
MAX_CONSECUTIVE_FAILURES=3                                # ennyi sikertelen javítás után STOP + ember
HEALTH_TIMEOUT=12
POST_RESTART_WAIT=20
POST_RESTART_TRIES=8

mkdir -p "$(dirname "$STATE_FILE")"
log() { echo "[freeze-watchdog $(date -u '+%F %T')] $*"; }

# A primary-watchdog.sh-val azonos minta: python3-mal épített, helyesen escape-elt JSON-payload.
send_email() {
  local subject="$1" body="$2" key payload code to_json
  [ -f "$RESEND_KEY_FILE" ] || { log "nincs Resend kulcs ($RESEND_KEY_FILE) — email kihagyva"; return 1; }
  key="$(cat "$RESEND_KEY_FILE")"
  to_json="$(printf '"%s",' "${RCPTS[@]}")"; to_json="[${to_json%,}]"
  payload="$(python3 -c 'import json,sys; print(json.dumps({"from":sys.argv[1],"to":json.loads(sys.argv[2]),"subject":sys.argv[3],"text":sys.argv[4]}))' \
            "$MAIL_FROM" "$to_json" "$subject" "$body" 2>/dev/null)" || { log "JSON-build hiba"; return 1; }
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 -X POST "$RESEND_API" \
        -H "Authorization: Bearer ${key}" -H 'Content-Type: application/json' -d "$payload" 2>/dev/null || echo 000)"
  { [ "$code" = "200" ] || [ "$code" = "201" ]; } && return 0
  log "Resend HTTP $code"; return 1
}

REASON=""
# Health = 3 rétegű (systemd aktív + Postgres válaszol + HTTP 200). Bármelyik bukik → fagyás/leállás.
health_ok() {
  systemctl is-active --quiet "$BACKEND_SVC" || { REASON="$BACKEND_SVC nem aktív"; return 1; }
  sudo -u postgres pg_isready -q 2>/dev/null   || { REASON="Postgres nem válaszol (pg_isready)"; return 1; }
  local code; code="$(curl -s -o /dev/null -w '%{http_code}' --max-time "$HEALTH_TIMEOUT" "$HEALTH_URL" 2>/dev/null || echo 000)"
  [ "$code" = "200" ] || { REASON="health HTTP $code (nem 200)"; return 1; }
  return 0
}

# --- állapot betöltés ---
DOWN=0; CONSEC_FAIL=0; RESTART_TS=""
if [ -f "$STATE_FILE" ]; then
  DOWN="$(grep -oE '^down=[0-9]+' "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo 0)"
  CONSEC_FAIL="$(grep -oE '^consecfail=[0-9]+' "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo 0)"
  RESTART_TS="$(grep -oE '^restarts=.*' "$STATE_FILE" 2>/dev/null | cut -d= -f2- || echo '')"
fi
NOW=$(date +%s); HOUR_AGO=$((NOW-3600))
RECENT=""; RCNT=0
for ts in $RESTART_TS; do [ "$ts" -ge "$HOUR_AGO" ] 2>/dev/null && { RECENT="$RECENT $ts"; RCNT=$((RCNT+1)); }; done

# === EGÉSZSÉGES ===
if health_ok; then
  [ "${DOWN:-0}" -gt 0 ] && log "újra egészséges (előző down-count: $DOWN)"
  printf 'down=0\nconsecfail=0\nrestarts=%s\n' "$RECENT" > "$STATE_FILE"
  exit 0
fi

# === NEM EGÉSZSÉGES ===
DOWN=$(( ${DOWN:-0} + 1 ))
log "down-check #$DOWN: $REASON"
if [ "$DOWN" -lt "$FAIL_THRESHOLD" ]; then
  # tranziens / deploy-ablak — még nem avatkozunk be (csak számolunk)
  printf 'down=%s\nconsecfail=%s\nrestarts=%s\n' "$DOWN" "$CONSEC_FAIL" "$RECENT" > "$STATE_FILE"
  exit 0
fi

# elérte a küszöböt → FAGYÁS megerősítve
if [ "$RCNT" -ge "$MAX_RESTARTS_PER_HOUR" ]; then
  log "rate-limit: már $RCNT auto-restart az elmúlt órában — auto-javítás LEÁLLÍTVA, ember kell"
  send_email "[excvaluta FREEZE-WATCHDOG] RATE-LIMIT — kézi beavatkozás kell" \
    "A Hetzner backend/Postgres fagyott (ok: $REASON), de már $RCNT automatikus újraindítás történt az elmúlt órában. További auto-restart leállítva (flap-védelem). KÉZI beavatkozás szükséges."
  printf 'down=%s\nconsecfail=%s\nrestarts=%s\n' "$DOWN" "$(( ${CONSEC_FAIL:-0} + 1 ))" "$RECENT" > "$STATE_FILE"
  exit 1
fi

# === AUTO-JAVÍTÁS: a lokális szolgáltatások újraindítása ===
log "AUTO-RESTART indul (ok: $REASON, down#$DOWN)"
send_email "[excvaluta FREEZE-WATCHDOG] LEÁLLT — automatikus újraindítás indul" \
  "A Hetzner primary backend/Postgres fagyott/leállt. Ok: $REASON (megerősítve $DOWN egymás utáni ellenőrzéssel). Az automatikus újraindítás MOST indul."
T0=$(date +%s)
if ! sudo -u postgres pg_isready -q 2>/dev/null; then
  log "Postgres újraindítás ($PG_SVC)"
  systemctl restart "$PG_SVC" || log "postgres restart hiba"
  sleep 5
fi
log "backend újraindítás ($BACKEND_SVC)"
systemctl restart "$BACKEND_SVC" || log "backend restart hiba"

RECOVERED=0
for i in $(seq 1 "$POST_RESTART_TRIES"); do
  sleep "$POST_RESTART_WAIT"
  if health_ok; then RECOVERED=1; break; fi
  log "helyreállás-ellenőrzés $i: még nem ($REASON)"
done
T1=$(date +%s); DUR=$((T1-T0))
NEW_RESTARTS="$RECENT $NOW"

if [ "$RECOVERED" = "1" ]; then
  log "HELYREÁLLT ${DUR}s alatt"
  send_email "[excvaluta FREEZE-WATCHDOG] HELYREÁLLT — automatikusan újraindítva" \
    "A Hetzner primary backend/Postgres automatikusan újraindult és HELYREÁLLT (${DUR}s alatt). Eredeti ok: $REASON. Nincs teendő, csak tájékoztatás."
  printf 'down=0\nconsecfail=0\nrestarts=%s\n' "$NEW_RESTARTS" > "$STATE_FILE"
  exit 0
fi

NEWCONSEC=$(( ${CONSEC_FAIL:-0} + 1 ))
log "AUTO-RESTART után sem egészséges ($REASON), consecfail=$NEWCONSEC"
printf 'down=%s\nconsecfail=%s\nrestarts=%s\n' "$DOWN" "$NEWCONSEC" "$NEW_RESTARTS" > "$STATE_FILE"
if [ "$NEWCONSEC" -ge "$MAX_CONSECUTIVE_FAILURES" ]; then
  send_email "[excvaluta FREEZE-WATCHDOG] AUTO-RESTART SIKERTELEN — KÉZI beavatkozás kell" \
    "A Hetzner backend/Postgres $NEWCONSEC egymás utáni automatikus újraindítás után sem áll helyre (ok: $REASON). Az auto-javítás nem elég — KÉZI beavatkozás szükséges."
fi
exit 1
