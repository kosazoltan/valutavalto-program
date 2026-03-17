#!/bin/bash
# Valutavalto — Napi PostgreSQL backup
# Crontab: 0 3 * * * /opt/valuta/scripts/backup.sh >> /var/log/valuta-backup.log 2>&1
set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/opt/valuta}"
source "${DEPLOY_DIR}/.env"

BACKUP_DIR=/backups/valuta
mkdir -p "${BACKUP_DIR}"
DATE=$(date +%Y%m%d_%H%M%S)

echo "[$(date)] Backup inditas..."
docker compose -f "${DEPLOY_DIR}/docker-compose.prod.yml" exec -T postgres \
    pg_dump -U "${DB_USER}" valuta | gzip > "${BACKUP_DIR}/valuta_${DATE}.sql.gz"

# Meret ellenorzes (ha 0 byte, hiba)
FILESIZE=$(stat -c%s "${BACKUP_DIR}/valuta_${DATE}.sql.gz" 2>/dev/null || echo "0")
if [ "${FILESIZE}" -lt 100 ]; then
    echo "[$(date)] HIBA: Backup fajl tul kicsi (${FILESIZE} byte)!"
    exit 1
fi

echo "[$(date)] Backup kesz: valuta_${DATE}.sql.gz (${FILESIZE} byte)"

# 7 napnal regebbi backup torlese
DELETED=$(find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +7 -delete -print | wc -l)
echo "[$(date)] ${DELETED} regi backup torolve."
