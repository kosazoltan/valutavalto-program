#!/bin/bash
# One-shot: backup infrastruktura telepitese Hetzner VPS-re
# Hasznalat: bash setup-backup.sh
# Utan: nano /opt/valutavalto/.backup.env (Nextcloud adatok)
# Javitas (Eszter review): /opt/valutavalto/scripts konyvtar letrehozasa (MAJOR fix)
set -euo pipefail

SCRIPTS_DIR=/opt/valutavalto/scripts
BACKUP_SCRIPT="$SCRIPTS_DIR/backup-pg.sh"
BACKUP_ENV=/opt/valutavalto/.backup.env
BACKUP_DIR=/opt/valutavalto/backups
LOG_DIR=/var/log/valutavalto

# Konyvtarak letrehozasa (idempotens - MAJOR fix)
mkdir -p "$SCRIPTS_DIR" "$BACKUP_DIR" "$LOG_DIR"
chown -R root:root "$SCRIPTS_DIR" "$BACKUP_DIR"
chmod 700 "$SCRIPTS_DIR" "$BACKUP_DIR"

if [ ! -f "$BACKUP_ENV" ]; then
    cat > "$BACKUP_ENV" << 'ENVEOF'
# Nextcloud WebDAV adatok - KOTELEZO kitolteni!
NEXTCLOUD_URL=https://YOUR-NEXTCLOUD-HOST/remote.php/dav/files/YOUR-USER/ValutaBackup
NEXTCLOUD_USER=YOUR-NEXTCLOUD-USER
NEXTCLOUD_PASS=YOUR-NEXTCLOUD-APP-PASSWORD
# Backup megorzesi ido (napokban)
BACKUP_RETENTION_DAYS=30
# Email ertesites hiba eseten (opcionalis, mail csomag szukseges)
ALERT_EMAIL=
ENVEOF
    chmod 600 "$BACKUP_ENV"
    echo "  .backup.env letrehozva: $BACKUP_ENV"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/backup-pg.sh" "$BACKUP_SCRIPT"
chmod 750 "$BACKUP_SCRIPT"

cp "$SCRIPT_DIR/../systemd/valuta-backup.service" /etc/systemd/system/
cp "$SCRIPT_DIR/../systemd/valuta-backup.timer" /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now valuta-backup.timer

echo ""
echo "Backup infrastruktura telepitve."
echo "Timer allapota:"
systemctl status valuta-backup.timer --no-pager | head -6
echo ""
echo "KOVETKEZO LEPES: nano $BACKUP_ENV"
echo "Majd teszt: systemctl start valuta-backup.service && journalctl -u valuta-backup -f"
