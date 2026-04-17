#!/bin/bash
# One-shot: backup infrastruktura telepitese Hetzner VPS-re
# Hasznalat: bash setup-backup.sh
# Utan: nano /opt/valutavalto/.backup.env (Nextcloud adatok)
set -euo pipefail

BACKUP_SCRIPT=/opt/valutavalto/scripts/backup-pg.sh
BACKUP_ENV=/opt/valutavalto/.backup.env
BACKUP_DIR=/opt/valutavalto/backups
LOG_DIR=/var/log/valutavalto

mkdir -p "$BACKUP_DIR" "$LOG_DIR"
chown -R root:root "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

if [ ! -f "$BACKUP_ENV" ]; then
    cat > "$BACKUP_ENV" << 'ENVEOF'
# Nextcloud WebDAV adatok
NEXTCLOUD_URL=https://YOUR-NEXTCLOUD-HOST/remote.php/dav/files/YOUR-USER/ValutaBackup
NEXTCLOUD_USER=YOUR-NEXTCLOUD-USER
NEXTCLOUD_PASS=YOUR-NEXTCLOUD-APP-PASSWORD
BACKUP_RETENTION_DAYS=30
ALERT_EMAIL=
ENVEOF
    chmod 600 "$BACKUP_ENV"
    echo "  .backup.env letrehozva: $BACKUP_ENV"
fi

cp "$(dirname $0)/backup-pg.sh" "$BACKUP_SCRIPT"
chmod 750 "$BACKUP_SCRIPT"

cp "$(dirname $0)/../systemd/valuta-backup.service" /etc/systemd/system/
cp "$(dirname $0)/../systemd/valuta-backup.timer" /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now valuta-backup.timer

echo "Backup infrastruktura telepitve."
echo "KOVETKEZO: nano $BACKUP_ENV"
