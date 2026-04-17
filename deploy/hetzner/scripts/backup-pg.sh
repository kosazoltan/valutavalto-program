#!/bin/bash
# =============================================================================
# Valutavalto PostgreSQL backup -> Nextcloud WebDAV
# Javitasok (Eszter review):
#   - Atomikus iras: tmp fajl + mv (CRITICAL fix)
#   - Nextcloud retention: HTTP statusz ellenorzese (MINOR fix)
# =============================================================================
set -euo pipefail

BACKUP_ENV=/opt/valutavalto/.backup.env
BACKUP_DIR=/opt/valutavalto/backups
LOG_DIR=/var/log/valutavalto
LOG="$LOG_DIR/backup.log"
DB_NAME=valuta
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/valuta_${TIMESTAMP}.sql.gz"
BACKUP_TMP="$BACKUP_DIR/.valuta_${TIMESTAMP}.sql.gz.tmp"

# Konyvtarak biztonsagos letrehozasa (idempotens)
mkdir -p "$BACKUP_DIR" "$LOG_DIR"
chmod 700 "$BACKUP_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

if [ ! -f "$BACKUP_ENV" ]; then
    log "HIBA: Hianyzo backup env: $BACKUP_ENV"
    exit 1
fi
# shellcheck source=/dev/null
source "$BACKUP_ENV"

if [[ "${NEXTCLOUD_URL:-}" == *"YOUR-NEXTCLOUD"* || -z "${NEXTCLOUD_URL:-}" ]]; then
    log "HIBA: Nextcloud meg nincs beallitva. Toeltsd ki: $BACKUP_ENV"
    exit 1
fi

log "=== Backup inditas: $DB_NAME ==="

# pg_dump atomikusan: tmp fajlba, majd mv -> vegleges nev
log "pg_dump futtatasa (atomikus)..."
if ! su -s /bin/bash postgres -c "pg_dump -Fp -d $DB_NAME" | gzip -9 > "$BACKUP_TMP"; then
    log "HIBA: pg_dump sikertelen"
    rm -f "$BACKUP_TMP"
    exit 2
fi
mv "$BACKUP_TMP" "$BACKUP_FILE"

BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
log "Backup kesz: $BACKUP_FILE ($BACKUP_SIZE)"

# Nextcloud feltoltes (WebDAV PUT)
log "Nextcloud feltoltes: $NEXTCLOUD_URL/$(basename "$BACKUP_FILE")"
NC_RESULT_FILE=$(mktemp)
HTTP_CODE=$(curl -s -o "$NC_RESULT_FILE" -w "%{http_code}" \
    -X PUT \
    -u "$NEXTCLOUD_USER:$NEXTCLOUD_PASS" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"$BACKUP_FILE" \
    "$NEXTCLOUD_URL/$(basename "$BACKUP_FILE")")

if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "204" ]]; then
    log "Nextcloud feltoltes OK (HTTP $HTTP_CODE)"
    rm -f "$BACKUP_FILE" "$NC_RESULT_FILE"
else
    log "HIBA: Nextcloud feltoltes sikertelen (HTTP $HTTP_CODE)"
    cat "$NC_RESULT_FILE" >> "$LOG" 2>/dev/null || true
    rm -f "$NC_RESULT_FILE"
    log "Helyi backup megtartva: $BACKUP_FILE"
    exit 3
fi

# Regi helyi backupok torles (retention)
RETENTION=${BACKUP_RETENTION_DAYS:-30}
find "$BACKUP_DIR" -name "valuta_*.sql.gz" -mtime +"$RETENTION" -delete 2>/dev/null && \
    log "Regi helyi backupok torolve (>${RETENTION} nap)" || true

# Nextcloud regi fajlok torles (WebDAV PROPFIND + DELETE) - HTTP statusz ellenorzese
log "Nextcloud regi backupok ellenorzese..."
CUTOFF=$(date -d "$RETENTION days ago" +%Y%m%d)
NC_LIST_FILE=$(mktemp)
PROPFIND_CODE=$(curl -s -o "$NC_LIST_FILE" -w "%{http_code}" \
    -X PROPFIND \
    -u "$NEXTCLOUD_USER:$NEXTCLOUD_PASS" \
    -H "Depth: 1" \
    "$NEXTCLOUD_URL/" 2>/dev/null || echo "000")

if [[ "$PROPFIND_CODE" == "207" ]]; then
    grep -oP 'valuta_\K[0-9]{8}(?=_[0-9]{6}\.sql\.gz)' "$NC_LIST_FILE" 2>/dev/null | \
    while read -r DATE; do
        if [[ "$DATE" < "$CUTOFF" ]]; then
            FNAME=$(grep -oP "valuta_${DATE}_[0-9]{6}\.sql\.gz" "$NC_LIST_FILE" | head -1)
            [ -z "$FNAME" ] && continue
            log "Regi Nextcloud backup torles: $FNAME"
            DEL_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                -X DELETE \
                -u "$NEXTCLOUD_USER:$NEXTCLOUD_PASS" \
                "$NEXTCLOUD_URL/$FNAME" 2>/dev/null || echo "000")
            if [[ "$DEL_CODE" == "204" || "$DEL_CODE" == "200" ]]; then
                log "Torles OK: $FNAME (HTTP $DEL_CODE)"
            else
                log "FIGYELEM: Torles sikertelen: $FNAME (HTTP $DEL_CODE)"
            fi
        fi
    done
else
    log "FIGYELEM: PROPFIND sikertelen (HTTP $PROPFIND_CODE) - retention cleanup kihagyva"
fi
rm -f "$NC_LIST_FILE"

log "=== Backup befejezve: $DB_NAME ==="
