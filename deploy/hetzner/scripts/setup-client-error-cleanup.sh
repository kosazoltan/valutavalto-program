#!/bin/bash
# One-shot: client_error_log 90 napos retention cleanup telepitese.
# Hasznalat: bash setup-client-error-cleanup.sh
set -euo pipefail

SCRIPTS_DIR=/opt/valutavalto/scripts
CLEANUP_SCRIPT="$SCRIPTS_DIR/cleanup-client-error-log.sh"
LOG_DIR=/var/log/valutavalto

mkdir -p "$SCRIPTS_DIR" "$LOG_DIR"
chown -R root:root "$SCRIPTS_DIR"
chmod 755 "$SCRIPTS_DIR"
chown postgres:postgres "$LOG_DIR"
chmod 750 "$LOG_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/cleanup-client-error-log.sh" "$CLEANUP_SCRIPT"
chown root:root "$CLEANUP_SCRIPT"
chmod 755 "$CLEANUP_SCRIPT"

cp "$SCRIPT_DIR/../systemd/valuta-client-error-cleanup.service" /etc/systemd/system/
cp "$SCRIPT_DIR/../systemd/valuta-client-error-cleanup.timer" /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now valuta-client-error-cleanup.timer

echo ""
echo "client_error_log cleanup telepitve."
echo "Timer allapota:"
systemctl status valuta-client-error-cleanup.timer --no-pager --lines=6
echo ""
echo "Teszt: systemctl start valuta-client-error-cleanup.service && journalctl -u valuta-client-error-cleanup -n 20 --no-pager"
