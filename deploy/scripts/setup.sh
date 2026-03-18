#!/bin/bash
# Valutavalto — Hetzner szerver initial setup + security hardening
# Futtatas: sudo bash setup.sh
set -euo pipefail

echo "=== Valutavalto Hetzner Setup + Security Hardening ==="

# 1. Rendszer frissítés
echo "[1/9] Rendszer frissites..."
apt-get update -q && apt-get upgrade -y -q

# 2. Firewall (UFW) — CSAK 22/80/443
echo "[2/9] Firewall beallitas (UFW)..."
apt-get install -y -q ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP (ACME + redirect)'
ufw allow 443/tcp comment 'HTTPS'
echo "y" | ufw enable
ufw status verbose

# 3. Fail2ban — SSH + Nginx brute force vedelem
echo "[3/9] Fail2ban telepites es konfiguracio..."
apt-get install -y -q fail2ban

cat > /etc/fail2ban/jail.local << 'JAIL'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
banaction = ufw

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /opt/valuta/logs/nginx-access.log
maxretry = 5
bantime = 3600

[nginx-botsearch]
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /opt/valuta/logs/nginx-access.log
maxretry = 3
bantime = 86400

[nginx-req-limit]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /opt/valuta/logs/nginx-error.log
maxretry = 5
bantime = 3600
JAIL

systemctl enable fail2ban
systemctl restart fail2ban
echo "  Fail2ban aktiv — SSH: 3 proba/10 perc, ban 2 ora"

# 4. SSH hardening
echo "[4/9] SSH hardening..."
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%Y%m%d)"

sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSHD_CONFIG"
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSHD_CONFIG"

grep -q "^ClientAliveInterval" "$SSHD_CONFIG" || echo "ClientAliveInterval 300" >> "$SSHD_CONFIG"
grep -q "^ClientAliveCountMax" "$SSHD_CONFIG" || echo "ClientAliveCountMax 3" >> "$SSHD_CONFIG"

systemctl restart sshd
echo "  SSH: jelszo letiltva, root login korlatozva, max 3 proba"

# 5. Konyvtarak
echo "[5/9] Konyvtarak letrehozasa..."
mkdir -p /opt/valuta /backups/valuta /opt/valuta/logs

# 6. Backup cron (napi 03:00)
echo "[6/9] Backup cron beallitas..."
CRON_LINE="0 3 * * * /opt/valuta/scripts/backup.sh >> /var/log/valuta-backup.log 2>&1"
(crontab -l 2>/dev/null | grep -v "valuta-backup"; echo "${CRON_LINE}") | crontab -

# 7. Nginx reload cron (cert megujitas utan, 12 oranként)
echo "[7/9] Certbot reload cron..."
RELOAD_LINE="0 */12 * * * cd /opt/valuta && docker compose -f docker-compose.prod.yml exec -T nginx nginx -s reload >> /var/log/valuta-certbot-reload.log 2>&1"
(crontab -l 2>/dev/null | grep -v "certbot-reload"; echo "${RELOAD_LINE}") | crontab -

# 8. Monitoring
echo "[8/9] Monitoring cron-ok..."
DISK_LINE="0 */6 * * * df -h / | awk 'NR==2 && \$5+0 > 80 {print \"DISK WARNING: \" \$5 \" used\"}' >> /var/log/valuta-disk.log 2>&1"
(crontab -l 2>/dev/null | grep -v "valuta-disk"; echo "${DISK_LINE}") | crontab -

F2B_LINE="0 8 * * * fail2ban-client status sshd >> /var/log/valuta-security.log 2>&1"
(crontab -l 2>/dev/null | grep -v "valuta-security"; echo "${F2B_LINE}") | crontab -

# 9. Automatikus biztonsagi frissitesek
echo "[9/9] Automatikus biztonsagi frissitesek..."
apt-get install -y -q unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true

echo ""
echo "=== Security Setup kesz! ==="
echo ""
echo "UFW firewall: 22/80/443 only"
echo "Fail2ban: SSH (3x -> 2h ban), Nginx brute force"
echo "SSH: jelszo letiltva, max 3 proba, idle timeout 15 perc"
echo "Automatikus biztonsagi frissitesek bekapcsolva"
echo "Napi backup cron: 03:00"
echo "Disk monitoring: 6 oranként"
echo ""
echo "Kovetkezo lepesek:"
echo "  1. cd /opt/valuta"
echo "  2. cp .env.example .env && nano .env"
echo "  3. Lasd README.md a teljes inditasi folyamathoz"
echo ""
echo "FONTOS: Ellenorizd, hogy az SSH kulcsod mukodik,"
echo "mielott bezarod ezt a session-t! (jelszo le van tiltva)"
