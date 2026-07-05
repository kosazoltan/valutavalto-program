#!/usr/bin/env bash
# ============================================================================
# Failover playbook - manualis promote (BOVITETT v2.5.49+)
# ============================================================================
# 2-regios setup: Primary (Hetzner) <-> Scaleway (warm standby)
# Failover sorrend: ha primary leall, ez a script promote-olja a standby-t
# es teljes szolgaltatasi szintre allitja (Redis on, backend irhato modra).
#
# Hasznalat ezen a standby-n (mint root):
#   bash failover-to-standby.sh
#
# Lepesek:
#   1. Pre-flight ellenorzes (recovery? lag? confirm?)
#   2. pg_ctl promote (DB -> primary)
#   3. Backend .env atallitas (read-only flag torles + Redis enable)
#   4. Redis service start
#   5. valuta-backend service restart
#   6. Health check (HTTP 200 + write smoke)
#   7. Cloudflare DNS atkapcsolas instrukcio
#
# Idotartam: ~60-90 masodperc end-to-end
# ============================================================================
set -euo pipefail

ENV_FILE="/opt/valutavalto/backend/.env"
BACKEND_URL="http://localhost:8080/api/v1/auth/bootstrap-status"
HEALTH_TIMEOUT=120  # max sec to wait for backend after restart

log() { echo "[failover $(date +%T)] $*"; }
err() { echo "[failover ERROR] $*" >&2; }

# ----- 1. Pre-flight -----
log "=== 1. Pre-flight: ez tenyleg standby? ==="
if ! sudo -u postgres psql -c "SELECT pg_is_in_recovery();" | grep -q ' t'; then
    err "Ez a node NEM standby (mar primary, vagy recovery kikapcsolva)"
    exit 1
fi

log "=== Replication lag check ==="
LAG=$(sudo -u postgres psql -tA -c "SELECT COALESCE(EXTRACT(EPOCH FROM (NOW() - pg_last_xact_replay_timestamp()))::int, 0);")
log "Replikacios lag: ${LAG} masodperc"
if [[ "$LAG" -gt 60 ]]; then
    log "FIGYELEM: lag > 60s, lehet adatvesztes (utolso ${LAG} mp tranzakciok)"
fi

# Non-interaktiv (auto-failover) mod: FAILOVER_AUTO=1 (a watchdog hasznalja).
# Ilyenkor a MAX-LAG VEDELEM abortal, ha tul nagy az adatvesztes -> inkabb riaszt
# egy embert, mint vakon promote-olni elveszett tranzakciokkal.
FAILOVER_MAX_LAG="${FAILOVER_MAX_LAG:-300}"
if [[ "${FAILOVER_AUTO:-0}" == "1" ]]; then
    if [[ "$LAG" -gt "$FAILOVER_MAX_LAG" ]]; then
        err "AUTO-FAILOVER ABORT: lag ${LAG}s > max ${FAILOVER_MAX_LAG}s (tul nagy adatvesztes) - kezi dontes kell"
        exit 2
    fi
    log "AUTO-FAILOVER mod: interaktiv megerosites kihagyva (lag ${LAG}s <= ${FAILOVER_MAX_LAG}s OK)"
else
    read -t 10 -p "Folytatod a failover-t? (y/N, 10s timeout = N): " confirm || confirm=""
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Megszakitva - nincs promote"
        exit 0
    fi
fi

# ----- 2. PG promote -----
log "=== 2. pg_ctl promote ==="
sudo -u postgres pg_ctlcluster 16 main promote
sleep 3

if sudo -u postgres psql -c "SELECT pg_is_in_recovery();" | grep -q ' t'; then
    err "Promote sikertelen! Meg mindig recovery modban"
    exit 1
fi
log "PG promote OK - DB most irhato"

# Replication slot cleanup — defenzív no-op ezen a node-on.
# A standby_slot% slotok a RÉGI primary-n (Hetzner) vannak, nem itt.
# A promote után ez a node új primary, de nem örökli a régi slotokat.
# A tényleges slot-cleanup a #1319 guard feladata a Hetzner primary-n.
# Ez a loop biztonsági háló: ha valamiért lennének lokális standby_slot% slotok.
sudo -u postgres psql -tA -c "SELECT slot_name FROM pg_replication_slots WHERE slot_name LIKE 'standby_slot%';" | while read -r slot; do
    [[ -n "$slot" ]] && sudo -u postgres psql -c "SELECT pg_drop_replication_slot('$slot');" || true
done

# ----- 3. .env atallitas -----
log "=== 3. Backend .env atallitas (read-only flag torles + Redis enable) ==="
[[ -f "$ENV_FILE.bak.before-failover" ]] || cp "$ENV_FILE" "$ENV_FILE.bak.before-failover"

# Read-only flag-ek torlese / FALSE-ra
sed -i -E 's|^SPRING_FLYWAY_ENABLED=.*|SPRING_FLYWAY_ENABLED=true|' "$ENV_FILE"
# 2026-06-05 BUGFIX: NEM 'validate'! A production Hetzner DDL_AUTO=none (default),
# es a semaban van latens elteres (commission_rule.company_id int4 vs entity uuid),
# ami 'validate' alatt MEGAKADALYOZZA a backend indulasat failovernel. A promote-olt
# node-nak ugyanugy 'none'-nal kell futnia, mint a production primary-nek.
sed -i -E 's|^SPRING_JPA_HIBERNATE_DDL_AUTO=.*|SPRING_JPA_HIBERNATE_DDL_AUTO=none|' "$ENV_FILE"
sed -i -E 's|^SPRING_JPA_PROPERTIES_HIBERNATE_CONNECTION_DEFAULT_READ_ONLY=.*|SPRING_JPA_PROPERTIES_HIBERNATE_CONNECTION_DEFAULT_READ_ONLY=false|' "$ENV_FILE"

# Redis bekapcsolas
sed -i -E 's|^REDIS_ENABLED=.*|REDIS_ENABLED=true|' "$ENV_FILE"

log ".env modositva (backup: $ENV_FILE.bak.before-failover)"

# ----- 4. Redis start -----
log "=== 4. Redis service start ==="
systemctl is-active redis-server >/dev/null 2>&1 || systemctl start redis-server
systemctl is-active redis-server | head -1

# Verify Redis reachable with password from .env
REDIS_PWD=$(grep -E '^REDIS_PASSWORD=' "$ENV_FILE" | head -1 | cut -d'=' -f2-)
if [[ -n "$REDIS_PWD" ]]; then
    redis-cli -a "$REDIS_PWD" ping 2>&1 | grep -q PONG || err "Redis PING sikertelen (jelszo gond?)"
fi

# ----- 5. Backend restart -----
log "=== 5. valuta-backend service restart ==="
systemctl restart valuta-backend

# ----- 6. Health check -----
log "=== 6. Backend health check (max ${HEALTH_TIMEOUT}s) ==="
START=$(date +%s)
while true; do
    if [[ $(($(date +%s) - START)) -gt $HEALTH_TIMEOUT ]]; then
        err "Backend nem indult el ${HEALTH_TIMEOUT}s alatt - kezi beavatkozas szukseges"
        log "Logok: journalctl -u valuta-backend -n 50"
        exit 1
    fi
    HTTP=$(curl -s -o /dev/null -w '%{http_code}' "$BACKEND_URL" || echo "000")
    if [[ "$HTTP" == "200" ]]; then
        log "Backend HTTP 200 - OK"
        break
    fi
    sleep 3
done

# Write smoke test: DB irhato-e (csak SELECT, de a backend mar nem read-only)
log "=== Smoke test: backend kovetkezetes ==="
sudo -u postgres psql -d valuta -c "SELECT 'WRITABLE' AS state WHERE NOT pg_is_in_recovery();" 2>&1 | head -3

# ----- 7. Cloudflare DNS instrukcio -----
LOCAL_IP=$(hostname -I | awk '{print $1}' | head -1)
[[ -z "$LOCAL_IP" ]] && LOCAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "?")

log ""
log "==================================================================="
log "  KESZ - ez a node most TELJES PRIMARY"
log "==================================================================="
log ""
log "KOVETKEZO LEPES: Cloudflare DNS atkapcsolas"
log ""
log "  Mod 1 - automatizalt script (env-bol vesz token-t):"
log "    export CF_API_TOKEN=<token>  CF_ZONE_ID=<zone>  STANDBY_IP=$LOCAL_IP"
log "    bash /opt/valutavalto/deploy/hetzner/ha/cloudflare-dns-failover.sh"
log ""
log "  Mod 2 - manualis curl:"
log "    curl -X PATCH 'https://api.cloudflare.com/client/v4/zones/<ZONE>/dns_records/<REC>' \\"
log "      -H 'Authorization: Bearer <TOKEN>' \\"
log "      -H 'Content-Type: application/json' \\"
log "      -d '{\"content\":\"$LOCAL_IP\",\"ttl\":60}'"
log ""
log "FONTOS:"
log "  - Az eredeti primary-t NE inditsd el (split-brain veszely)"
log "  - amig pg_rewind + uj standby-setup nem tortent meg"
log "  - Restore eljaras: vault/operations/scaleway-failover-runbook.md"
log ""
log "Aktualis allapot:"
log "  Backend:    $(systemctl is-active valuta-backend)"
log "  PostgreSQL: $(sudo -u postgres psql -tA -c 'SELECT CASE WHEN pg_is_in_recovery() THEN '\''STANDBY'\'' ELSE '\''PRIMARY'\'' END;')"
log "  Redis:      $(systemctl is-active redis-server)"
log "  Nginx:      $(systemctl is-active nginx)"
log "  Public IP:  $LOCAL_IP"
