#!/bin/bash
# One-shot: health monitor telepitese Hetzner VPS-re
# Hasznalat: bash setup-healthcheck.sh
# Javitas (Eszter review):
#   - /opt/valutavalto/scripts + /var/log/valutavalto letrehozasa (CRITICAL fix)
#   - .health.env letrehozasa (MAJOR fix - email konfig fuggetlenseg)
set -euo pipefail

SCRIPTS_DIR=/opt/valutavalto/scripts
MONITOR_SCRIPT="$SCRIPTS_DIR/health-monitor.sh"
HEALTH_ENV=/opt/valutavalto/.health.env
LOG_DIR=/var/log/valutavalto

# Konyvtarak letrehozasa (idempotens - CRITICAL fix)
mkdir -p "$SCRIPTS_DIR" "$LOG_DIR"
chown -R root:root "$SCRIPTS_DIR"
chmod 700 "$SCRIPTS_DIR"

# Sajat health env letrehozasa (MAJOR fix - fuggetlenseg backup env-tol)
if [ ! -f "$HEALTH_ENV" ]; then
    cat > "$HEALTH_ENV" << 'ENVEOF'
# Valutavalto health monitor konfiguracio
# Email ertesites ha a szerver 3 egymast koveto ellenorzesnel nem valaszol
# (mail csomag szukseges: apt install mailutils)
ALERT_EMAIL=
ENVEOF
    chmod 600 "$HEALTH_ENV"
    echo "  .health.env letrehozva: $HEALTH_ENV"
    echo "  Opcionalis: nano $HEALTH_ENV (ALERT_EMAIL megadasa)"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/health-monitor.sh" "$MONITOR_SCRIPT"
chmod 750 "$MONITOR_SCRIPT"

cp "$SCRIPT_DIR/../systemd/valuta-health.service" /etc/systemd/system/
cp "$SCRIPT_DIR/../systemd/valuta-health.timer" /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now valuta-health.timer

echo ""
echo "Health monitor telepitve."
echo "Timer allapota:"
systemctl status valuta-health.timer --no-pager | head -6
echo ""
echo "Log: journalctl -u valuta-health -f"
echo "Log fajl: /var/log/valutavalto/health.log"
