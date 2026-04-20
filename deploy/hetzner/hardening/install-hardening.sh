#!/usr/bin/env bash
# ============================================================================
# Hetzner VPS hardening bootstrap
# ============================================================================
# Futtatas: ssh root@excvaluta.com "bash -s" < install-hardening.sh
#
# Telepit:
#   1. fail2ban - SSH brute-force vedelem
#   2. unattended-upgrades - automatikus security patchek (weekly)
#   3. Kernel hardening sysctl (vezerlokonyv par.30.3)
#
# Idempotens: tobbszor is futtathato ugyanabbal az eredmennyel.
# ============================================================================

set -euo pipefail

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== 1/3 fail2ban telepites ==="

DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -yq fail2ban

mkdir -p /etc/fail2ban/jail.d
cat > /etc/fail2ban/jail.d/sshd.conf <<'JAILCONF'
[sshd]
enabled   = true
port      = ssh
filter    = sshd
logpath   = %(sshd_log)s
backend   = systemd
maxretry  = 5
findtime  = 10m
bantime   = 1h
ignoreip  = 127.0.0.1/8 ::1

[sshd-ddos]
enabled   = true
port      = ssh
filter    = sshd
logpath   = %(sshd_log)s
maxretry  = 10
findtime  = 60
bantime   = 24h
JAILCONF

systemctl enable --now fail2ban
systemctl restart fail2ban
log "fail2ban status:"
fail2ban-client status sshd || true

log "=== 2/3 unattended-upgrades ==="

DEBIAN_FRONTEND=noninteractive apt-get install -yq unattended-upgrades apt-listchanges

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'AUTOCONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
AUTOCONF

cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'UUCONF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
    "postgresql-*";     // DB upgrade manualis (pg_upgrade kell major verzion)
    "docker-*";         // Docker upgrade csak controlled leallassal
};
Unattended-Upgrade::DevRelease "auto";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "false";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:30";
Unattended-Upgrade::Mail "";
Unattended-Upgrade::MailReport "on-change";
UUCONF

systemctl enable --now unattended-upgrades
log "unattended-upgrades aktiv. Teszt:"
unattended-upgrade --dry-run --debug 2>&1 | tail -5 || true

log "=== 3/3 Kernel hardening sysctl ==="

cat > /etc/sysctl.d/99-valuta-hardening.conf <<'SYSCTLCONF'
# Vezerlokonyv par.30.3 - production hardening sysctl
# Network: SYN flood + source route + martian packets vedelem
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# IPv6
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0

# Kernel
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.randomize_va_space = 2
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
SYSCTLCONF

sysctl -p /etc/sysctl.d/99-valuta-hardening.conf

log "=== KESZ ==="
log "fail2ban:            systemctl status fail2ban"
log "unattended-upgrades: tail -f /var/log/unattended-upgrades/unattended-upgrades.log"
log "sysctl:              sysctl -a | grep -E 'syncookies|rp_filter|ptrace'"
