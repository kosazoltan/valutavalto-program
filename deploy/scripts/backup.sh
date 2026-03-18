#!/bin/bash
# Valutavalto — Napi PostgreSQL backup + GPG titkositas
# Crontab: 0 3 * * * /opt/valuta/scripts/backup.sh >> /var/log/valuta-backup.log 2>&1
set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/opt/valuta}"
source "${DEPLOY_DIR}/.env"

BACKUP_DIR=/backups/valuta
mkdir -p "${BACKUP_DIR}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/valuta_${DATE}.sql.gz"

echo "[$(date)] Backup inditas..."
docker compose -f "${DEPLOY_DIR}/docker-compose.prod.yml" exec -T postgres \
    pg_dump -U "${DB_USER}" valuta | gzip > "${BACKUP_FILE}"

# Meret ellenorzes (ha 0 byte, hiba)
FILESIZE=$(stat -c%s "${BACKUP_FILE}" 2>/dev/null || echo "0")
if [ "${FILESIZE}" -lt 100 ]; then
    echo "[$(date)] HIBA: Backup fajl tul kicsi (${FILESIZE} byte)!"
    exit 1
fi

echo "[$(date)] Backup kesz: valuta_${DATE}.sql.gz (${FILESIZE} byte)"

# GPG titkositas (ha BACKUP_GPG_KEY be van allitva a .env-ben)
if [ -n "${BACKUP_GPG_KEY:-}" ]; then
    gpg --batch --yes --symmetric --cipher-algo AES256 \
        --passphrase "${BACKUP_GPG_KEY}" \
        -o "${BACKUP_FILE}.gpg" \
        "${BACKUP_FILE}"

    # Titkositatlan fajl torlese
    rm -f "${BACKUP_FILE}"
    ENCRYPTED_SIZE=$(stat -c%s "${BACKUP_FILE}.gpg" 2>/dev/null || echo "0")
    echo "[$(date)] Titkositott backup: valuta_${DATE}.sql.gz.gpg (${ENCRYPTED_SIZE} byte)"
else
    echo "[$(date)] FIGYELMEZETES: BACKUP_GPG_KEY nincs beallitva — backup TITKOSITATLAN!"
fi

# 7 napnal regebbi backup torlese (gpg es gz egyarant)
DELETED=$(find "${BACKUP_DIR}" -name "valuta_*.sql.gz*" -mtime +7 -delete -print | wc -l)
echo "[$(date)] ${DELETED} regi backup torolve."

# Aktiv backupok kiirasa
echo "[$(date)] Aktiv backupok:"
ls -lh "${BACKUP_DIR}"/valuta_*.sql.gz* 2>/dev/null | tail -3
