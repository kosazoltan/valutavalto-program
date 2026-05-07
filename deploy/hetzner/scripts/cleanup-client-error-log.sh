#!/bin/bash
# Valutavalto client_error_log retention cleanup
# Default: delete diagnostic reports older than 90 days.
set -euo pipefail

LOG_DIR=/var/log/valutavalto
LOG_FILE="$LOG_DIR/client-error-cleanup.log"
DB_NAME="${DB_NAME:-valuta}"
RETENTION_DAYS="${CLIENT_ERROR_LOG_RETENTION_DAYS:-90}"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG_FILE"
}

if ! [[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]]; then
    log "HIBA: ervenytelen DB_NAME: $DB_NAME"
    exit 1
fi

if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]] || [ "$RETENTION_DAYS" -lt 1 ] || [ "$RETENTION_DAYS" -gt 3650 ]; then
    log "HIBA: ervenytelen CLIENT_ERROR_LOG_RETENTION_DAYS: $RETENTION_DAYS"
    exit 1
fi

log "client_error_log cleanup indul: db=$DB_NAME retention_days=$RETENTION_DAYS"

su -s /bin/bash postgres -c "psql -d \"$DB_NAME\" -v ON_ERROR_STOP=1 -c \"DELETE FROM client_error_log WHERE created_at < NOW() - INTERVAL '$RETENTION_DAYS days';\""

log "client_error_log cleanup kesz"
