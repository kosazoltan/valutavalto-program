#!/bin/bash
# Valutavalto — Hetzner szerver initial setup
# Futtatas: sudo bash setup.sh
set -euo pipefail

echo "=== Valutavalto Hetzner Setup ==="

# 1. Firewall
echo "[1/5] Firewall beallitas..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable
ufw status

# 2. Konyvtarak
echo "[2/5] Konyvtarak letrehozasa..."
mkdir -p /opt/valuta /backups/valuta

# 3. Backup cron
echo "[3/5] Backup cron beallitas..."
CRON_LINE="0 3 * * * /opt/valuta/scripts/backup.sh >> /var/log/valuta-backup.log 2>&1"
(crontab -l 2>/dev/null | grep -v "valuta-backup"; echo "${CRON_LINE}") | crontab -

# 4. Nginx reload cron (cert megujitas utan)
echo "[4/5] Certbot reload cron..."
RELOAD_LINE="0 */12 * * * cd /opt/valuta && docker compose -f docker-compose.prod.yml exec -T nginx nginx -s reload >> /var/log/valuta-certbot-reload.log 2>&1"
(crontab -l 2>/dev/null | grep -v "certbot-reload"; echo "${RELOAD_LINE}") | crontab -

# 5. Disk monitoring cron
echo "[5/5] Disk monitoring..."
DISK_LINE="0 */6 * * * df -h / | awk 'NR==2 && \$5+0 > 80 {print \"DISK WARNING: \" \$5 \" used\"}' >> /var/log/valuta-disk.log 2>&1"
(crontab -l 2>/dev/null | grep -v "valuta-disk"; echo "${DISK_LINE}") | crontab -

echo ""
echo "=== Setup kesz! ==="
echo "Kovetkezo lepesek:"
echo "  1. cd /opt/valuta"
echo "  2. cp .env.example .env && nano .env"
echo "  3. Lasd README.md a teljes inditasi folyamathoz"
