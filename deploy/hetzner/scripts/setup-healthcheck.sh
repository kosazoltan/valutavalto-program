#!/bin/bash
# One-shot: health monitor telepitese Hetzner VPS-re
# Hasznalat: bash setup-healthcheck.sh
set -euo pipefail

MONITOR_SCRIPT=/opt/valutavalto/scripts/health-monitor.sh

cp "$(dirname $0)/health-monitor.sh" "$MONITOR_SCRIPT"
chmod 750 "$MONITOR_SCRIPT"

cp "$(dirname $0)/../systemd/valuta-health.service" /etc/systemd/system/
cp "$(dirname $0)/../systemd/valuta-health.timer" /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now valuta-health.timer

echo "Health monitor telepitve. Log: journalctl -u valuta-health -f"
