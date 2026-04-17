#!/bin/bash
# =============================================================================
# Valutavalto health monitor (5 percenkent fut)
# Javitasok (Eszter review):
#   - Log konyvtar letrehozasa inditaskor (CRITICAL fix)
#   - Fail counter: flock alapu vedelem race condition ellen (MINOR fix)
#   - Email konfig: sajat .health.env, NEM a backup env-re tamaszkodik (MAJOR fix)
# =============================================================================
set -euo pipefail

LOG_DIR=/var/log/valutavalto
LOG="$LOG_DIR/health.log"
ENDPOINT="https://excvaluta.com/api/v1/auth/bootstrap-status"
ALERT_EMAIL=""
BACKUP_ENV=/opt/valutavalto/.backup.env
CONSECUTIVE_FAIL_FILE=/tmp/valuta-health-fails
LOCK_FILE=/tmp/valuta-health-fails.lock

# Log konyvtar letrehozasa (idempotens, CRITICAL fix)
mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

# Alert email betoltese: sajat .health.env ha letezik, fallback .backup.env
HEALTH_ENV=/opt/valutavalto/.health.env
if [ -f "$HEALTH_ENV" ]; then
    # shellcheck source=/dev/null
    source "$HEALTH_ENV" 2>/dev/null || true
elif [ -f "$BACKUP_ENV" ]; then
    # shellcheck source=/dev/null
    source "$BACKUP_ENV" 2>/dev/null || true
fi

# Health check
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$ENDPOINT" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
    log "OK: $ENDPOINT ($HTTP_CODE)"
    # Reset fail counter (flock vedett)
    (
        flock -x 9
        rm -f "$CONSECUTIVE_FAIL_FILE"
    ) 9>"$LOCK_FILE"
else
    log "HIBA: $ENDPOINT (HTTP $HTTP_CODE)"

    # Fail szamlalo novelese (flock vedett - race condition fix)
    FAILS=1
    (
        flock -x 9
        if [ -f "$CONSECUTIVE_FAIL_FILE" ]; then
            PREV=$(cat "$CONSECUTIVE_FAIL_FILE")
            FAILS=$((PREV + 1))
        fi
        echo "$FAILS" > "$CONSECUTIVE_FAIL_FILE"
    ) 9>"$LOCK_FILE"
    FAILS=$(cat "$CONSECUTIVE_FAIL_FILE" 2>/dev/null || echo "1")

    log "Egymast koveto hibak: $FAILS"

    if [[ $FAILS -ge 3 ]]; then
        log "ALERT: $FAILS egymast koveto hiba! Szolgaltatas valoszinuleg le van allva."

        if [ -n "${ALERT_EMAIL:-}" ] && command -v mail >/dev/null 2>&1; then
            printf "Valutavalto szerver DOWN\nEndpoint: %s\nHTTP: %s\nHibak: %s\nIdopont: %s\n" \
                "$ENDPOINT" "$HTTP_CODE" "$FAILS" "$(date)" | \
                mail -s "ALERT: Valutavalto szerver DOWN" "$ALERT_EMAIL"
            log "Email alert kuldve: $ALERT_EMAIL"
        fi

        log "Auto-restart kiserlet: valuta-backend.service..."
        if systemctl restart valuta-backend.service 2>/dev/null; then
            sleep 15
            RECHECK=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$ENDPOINT" 2>/dev/null || echo "000")
            if [[ "$RECHECK" == "200" ]]; then
                log "Auto-restart SIKERES (HTTP $RECHECK)"
                (flock -x 9; rm -f "$CONSECUTIVE_FAIL_FILE") 9>"$LOCK_FILE"
            else
                log "Auto-restart utan sem valaszol (HTTP $RECHECK) - manualis beavatkozas szukseges"
            fi
        else
            log "FIGYELEM: systemctl restart sikertelen"
        fi
    fi
fi
