#!/bin/bash
# =============================================================================
# Valutavalto health monitor (5 percenkent fut)
# =============================================================================
set -euo pipefail

LOG=/var/log/valutavalto/health.log
ENDPOINT="https://excvaluta.com/api/v1/auth/bootstrap-status"
ALERT_EMAIL=""
CONSECUTIVE_FAIL_FILE=/tmp/valuta-health-fails

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

if [ -f /opt/valutavalto/.backup.env ]; then
    source /opt/valutavalto/.backup.env 2>/dev/null || true
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$ENDPOINT" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
    log "OK: $ENDPOINT ($HTTP_CODE)"
    rm -f "$CONSECUTIVE_FAIL_FILE"
else
    log "HIBA: $ENDPOINT (HTTP $HTTP_CODE)"
    
    FAILS=1
    if [ -f "$CONSECUTIVE_FAIL_FILE" ]; then
        FAILS=$(cat "$CONSECUTIVE_FAIL_FILE")
        FAILS=$((FAILS + 1))
    fi
    echo "$FAILS" > "$CONSECUTIVE_FAIL_FILE"
    
    log "Egymast koveto hibak: $FAILS"
    
    if [[ $FAILS -ge 3 ]]; then
        log "ALERT: $FAILS egymast koveto hiba! Szolgaltatas valoszinuleg le van allva."
        
        if [ -n "$ALERT_EMAIL" ] && command -v mail >/dev/null 2>&1; then
            echo "Valutavalto szerver DOWN\nEndpoint: $ENDPOINT\nHTTP: $HTTP_CODE\nHibak: $FAILS\nIdopont: $(date)" | \
                mail -s "ALERT: Valutavalto szerver DOWN" "$ALERT_EMAIL"
            log "Email alert kuldve: $ALERT_EMAIL"
        fi
        
        log "Auto-restart kiserlet: valuta-backend.service..."
        if systemctl restart valuta-backend.service 2>/dev/null; then
            sleep 15
            RECHECK=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$ENDPOINT" 2>/dev/null || echo "000")
            if [[ "$RECHECK" == "200" ]]; then
                log "Auto-restart SIKERES (HTTP $RECHECK)"
                rm -f "$CONSECUTIVE_FAIL_FILE"
            else
                log "Auto-restart utan sem valaszol (HTTP $RECHECK) - manualis beavatkozas szukseges"
            fi
        fi
    fi
fi
