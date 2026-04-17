#!/bin/bash
# =============================================================================
# Valutavalto PostgreSQL backup -> Nextcloud WebDAV
# =============================================================================
set -euo pipefail

BACKUP_ENV=/opt/valutavalto/.backup.env
BACKUP_DIR=/opt/valutavalto/backups
LOG=/var/log/valutavalto/backup.log
DB_NAME=valuta
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/valuta_${TIMESTAMP}.sql.gz"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

if [ ! -f "$BACKUP_ENV" ]; then
    log "HIBA: Hianyzo backup env: $BACKUP_ENV"
    exit 1
fi
source "$BACKUP_ENV"

if [[ "$NEXTCLOUD_URL" == *"YOUR-NEXTCLOUD"* ]]; then
    log "HIBA: Nextcloud meg nincs beallitva. Toeltsd ki: $BACKUP_ENV"
    exit 1
fi

log "=== Backup inditas: $DB_NAME ==="

log "pg_dump futtatasa..."
if ! su -s /bin/bash postgres -c "pg_dump -Fp -d $DB_NAME" | gzip -9 > "$BACKUP_FILE"; then
    log "HIBA: pg_dump sikertelen"
    rm -f "$BACKUP_FILE"
    exit 2
fi

BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
log "Backup kesz: $BACKUP_FILE ($BACKUP_SIZE)"

log "Nextcloud feltoltes: $NEXTCLOUD_URL/$(basename $BACKUP_FILE)"
HTTP_CODE=$(curl -s -o /tmp/nc_upload_result.txt -w "%{http_code}" \
    -X PUT \
    -u "$NEXTCLOUD_USER:$NEXTCLOUD_PASS" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"$BACKUP_FILE" \
    "$NEXTCLOUD_URL/$(basename $BACKUP_FILE)")

if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "204" ]]; then
    log "Nextcloud feltoltes OK (HTTP $HTTP_CODE)"
    rm -f "$BACKUP_FILE"
else
    log "HIBA: Nextcloud feltoltes sikertelen (HTTP $HTTP_CODE)"
    cat /tmp/nc_upload_result.txt >> "$LOG" 2>/dev/null || true
    log "Helyi backup megtartva: $BACKUP_FILE"
    exit 3
fi

RETENTION=${BACKUP_RETENTION_DAYS:-30}
find "$BACKUP_DIR" -name "valuta_*.sql.gz" -mtime +$RETENTION -delete 2>/dev/null && \
    log "Regi backupok torolve (>${RETENTION} nap)" || true

log "Nextcloud regi backupok ellenorzese..."
CUTOFF=$(date -d "$RETENTION days ago" +%Y%m%d)
curl -s -o /tmp/nc_list.xml \
    -X PROPFIND \
    -u "$NEXTCLOUD_USER:$NEXTCLOUD_PASS" \
    -H "Depth: 1" \
    "$NEXTCLOUD_URL/" 2>/dev/null || true

if [ -f /tmp/nc_list.xml ]; then
    grep -oP 'valuta_\K[0-9]{8}(?=_[0-9]{6}\.sql\.gz)' /tmp/nc_list.xml 2>/dev/null | while read DATE; do
        if [[ "$DATE" < "$CUTOFF" ]]; then
            FNAME=$(grep -oP "valuta_${DATE}_[0-9]{6}\.sql\.gz" /tmp/nc_list.xml | head -1)
            [ -z "$FNAME" ] && continue
            log "Regi Nextcloud backup torles: $FNAME"
            curl -s -X DELETE \
                -u "$NEXTCLOUD_USER:$NEXTCLOUD_PASS" \
                "$NEXTCLOUD_URL/$FNAME" 2>/dev/null || true
        fi
    done
fi

log "=== Backup befejezve: $DB_NAME ==="
