#!/usr/bin/env bash
# PgBouncer telepit + konfig elhelyez + systemd enable
# Futtat: bash install-pgbouncer.sh
set -euo pipefail

log() { echo "[pgbouncer] $*"; }

log "=== apt-get install pgbouncer ==="
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -yq pgbouncer

log "=== Konfig telepites ==="
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cp "$SCRIPT_DIR/pgbouncer.ini" /etc/pgbouncer/pgbouncer.ini

log "=== userlist.txt: a production secret NINCS git-ben ==="
if [[ ! -f /etc/pgbouncer/userlist.txt ]]; then
    log "HIBA: /etc/pgbouncer/userlist.txt hianyzik."
    log "Generalj: su - postgres -c "psql -tAc \"COPY (SELECT rolname, rolpassword FROM pg_authid WHERE rolname IN (\$\$valuta_user\$\$)) TO STDOUT\"" | awk -F\t '"'"'{printf "\"%s\" \"%s\"
", $1, $2}'"'"' > /etc/pgbouncer/userlist.txt"
    log "Aztan chmod 600 /etc/pgbouncer/userlist.txt; chown postgres:postgres /etc/pgbouncer/userlist.txt"
    exit 1
fi

log "=== systemctl enable + restart ==="
systemctl enable --now pgbouncer
systemctl restart pgbouncer
systemctl status pgbouncer --no-pager | head -5

log "=== Smoke test ==="
psql -h 127.0.0.1 -p 6432 -U valuta_user -d valuta -c "SELECT 1" || log "WARN: smoke fail - a Spring Boot HikariCP config-ot kell frissiteni"

log ""
log "HikariCP config change (spring application-production.properties):"
log "  spring.datasource.url=jdbc:postgresql://localhost:6432/valuta"
log "  spring.datasource.hikari.data-source-properties.prepareThreshold=0"
log "  # KRITIKUS! Transaction pool mode + prepared statement nem osszeferheto."
log ""
log "=== KESZ ==="
