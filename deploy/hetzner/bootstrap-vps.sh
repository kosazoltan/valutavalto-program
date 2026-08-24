#!/usr/bin/env bash
# ============================================================================
# Valuta VPS bootstrap - egyetlen belepesi pont a 12 vezerlokonyv-gap telepitesehez
# ============================================================================
# Futtatas (root-kent a Hetzner VPS-en):
#   curl -fsSL https://raw.githubusercontent.com/kosazoltan/valutavalto-program/main/deploy/hetzner/bootstrap-vps.sh | bash
# VAGY helyben (miutan git pull megtortent):
#   cd /opt/valutavalto/deploy/hetzner && bash bootstrap-vps.sh
#
# Lepesek (mindegyik opcionalis, Y/N prompt):
#   1. SSH hardening         (fail2ban + unattended-upgrades + sysctl)
#   2. Caddy reverse proxy   (Let's Encrypt + HTTP/3 + rate limit)
#   3. PgBouncer             (transaction pool, userlist.txt auto-generalas)
#   4. Redis JWT blacklist   (OPCIONALIS - docker redis:7-alpine)
#   5. Tailscale SSH bastion (kell: TAILSCALE_AUTHKEY)
#   6. Backblaze B2 backup   (kell: B2_KEY_ID + B2_APP_KEY)
#   7. Monitoring stack      (Prometheus + Grafana + Loki + Alertmanager)
#                            (kell: GRAFANA_ADMIN_PASSWORD + TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID)
#   8. client_error_log cleanup timer (90 napos GDPR retention)
#
# Automatikus secret-generalas (openssl rand):
#   - JWT_SECRET, APP_JWT_SECRET (hex 32)
#   - ENCRYPTION_SALT (hex 32), ENCRYPTION_KEY (hex 16 = 32 char)
#   - DATABASE_PASSWORD (hex 24 - ha meg nincs .env-ben)
#   - REDIS_PASSWORD (hex 16 - ha a Redis lepest valasztod)
#
# Idempotens: minden lepes ellenorzi, hogy mar telepitve van-e, es skip-el.
# ============================================================================

set -euo pipefail

# -------------------------- Seged funkciok -----------------------------------

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BACKEND_ENV_FILE="/opt/valutavalto/backend/.env"
BOOTSTRAP_LOG="/var/log/valuta-bootstrap.log"

c_red()    { printf '\033[31m%s\033[0m' "$*"; }
c_green()  { printf '\033[32m%s\033[0m' "$*"; }
c_yellow() { printf '\033[33m%s\033[0m' "$*"; }
c_bold()   { printf '\033[1m%s\033[0m' "$*"; }

log()      { echo -e "[bootstrap] $*" | tee -a "$BOOTSTRAP_LOG"; }
log_ok()   { echo -e "[bootstrap] $(c_green OK) $*" | tee -a "$BOOTSTRAP_LOG"; }
log_warn() { echo -e "[bootstrap] $(c_yellow WARN) $*" | tee -a "$BOOTSTRAP_LOG" >&2; }
log_err()  { echo -e "[bootstrap] $(c_red FAIL) $*" | tee -a "$BOOTSTRAP_LOG" >&2; }
log_step() { echo -e "\n$(c_bold "=== $* ===")" | tee -a "$BOOTSTRAP_LOG"; }

die() { log_err "$*"; exit 1; }

ask_yn() {
    local prompt="$1"
    local default="${2:-Y}"
    local hint="[Y/n]"
    [[ "$default" == "N" ]] && hint="[y/N]"
    local answer
    read -r -p "$(c_bold "$prompt $hint: ")" answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy]$ ]]
}

ask_secret() {
    local var="$1"
    local desc="$2"
    local min_len="${3:-8}"
    local value="${!var:-}"
    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi
    local attempt=0
    while [[ $attempt -lt 3 ]]; do
        read -r -s -p "$(c_bold "$var") ($desc, min $min_len karakter): " value
        echo >&2
        if [[ ${#value} -ge $min_len ]]; then
            echo "$value"
            return 0
        fi
        log_warn "Tul rovid (${#value} < $min_len)."
        ((attempt++))
    done
    die "3 sikertelen probalkozas a '$var' megadasakor."
}

require_root() {
    [[ $EUID -eq 0 ]] || die "Root jogok szuksegesek (sudo / ssh root@)."
}

check_prerequisite() {
    local missing=()
    for cmd in curl openssl systemctl; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Hianyzo csomagok: ${missing[*]} - elotte: apt-get install ${missing[*]}"
    fi
}

gen_secret_hex() {
    openssl rand -hex "${1:-32}"
}

# -------------------------- Lepes-implementaciok ----------------------------

step_backend_env() {
    log_step "Backend .env inicializalas (DB jelszo, JWT, encryption keys)"
    if [[ ! -f "$BACKEND_ENV_FILE" ]] || ! grep -qE "^DATABASE_PASSWORD=" "$BACKEND_ENV_FILE"; then
        log "Uj .env keszul: $BACKEND_ENV_FILE"
        local db_pass jwt_secret enc_salt enc_key rate_print_secret
        db_pass="$(gen_secret_hex 24)"
        jwt_secret="$(gen_secret_hex 32)"
        enc_salt="$(gen_secret_hex 32)"
        enc_key="$(gen_secret_hex 16)"
        rate_print_secret="$(gen_secret_hex 32)"

        log_warn "FONTOS: uj DATABASE_PASSWORD keszult. Allitsd be a PostgreSQL-ben:"
        log_warn "  sudo -u postgres psql -c \"ALTER USER valuta_user WITH PASSWORD '$db_pass';\""

        mkdir -p "$(dirname "$BACKEND_ENV_FILE")"
        cat > "$BACKEND_ENV_FILE" <<EOF
# Valuta backend .env - kezzel generalt bootstrap-pal, $(date -u +%Y-%m-%dT%H:%M:%SZ)
# FIGYELEM: ez a fajl titkos ertekeket tartalmaz - chmod 640, chown root:valuta

# --- Database (PgBouncer-en keresztul, port 6432) ---
DATABASE_URL=jdbc:postgresql://localhost:6432/valuta
DATABASE_USERNAME=valuta_user
DATABASE_PASSWORD=$db_pass

# --- JWT + titkositas ---
JWT_SECRET=$jwt_secret
APP_JWT_SECRET=$jwt_secret
ENCRYPTION_SALT=$enc_salt
ENCRYPTION_KEY=$enc_key

# --- Rate-print Proof-of-Print HMAC (RP-HA) ---
APP_RATE_PRINT_HMAC_SECRET=$rate_print_secret

# --- CORS / Spring profile ---
ALLOWED_ORIGINS=https://excvaluta.com,https://www.excvaluta.com
SPRING_PROFILES_ACTIVE=prod

# --- FK-091: HQ vészkijárat (profilfüggetlen; prod != application-production.properties) ---
EVENING_CLOSING_ARTIFACT_SUCCESS_ENABLED=true

# --- Redis (opcionalis - 4. lepes) ---
REDIS_ENABLED=false
# REDIS_HOST=127.0.0.1
# REDIS_PORT=6379
# REDIS_PASSWORD=
EOF
        chmod 640 "$BACKEND_ENV_FILE"
        if id -u valuta >/dev/null 2>&1; then
            chown root:valuta "$BACKEND_ENV_FILE"
        fi
        log_ok ".env generalva (DATABASE_PASSWORD = $db_pass - MENTSD EL!)"
    else
        log_ok ".env mar letezik - kihagyva."
    fi
}

step_hardening() {
    log_step "1. SSH hardening (fail2ban + unattended-upgrades + sysctl)"
    if ask_yn "Telepitsem?" "Y"; then
        bash "$SCRIPT_DIR/hardening/install-hardening.sh"
        log_ok "Hardening kesz."
    else
        log "Kihagyva."
    fi
}

step_caddy() {
    log_step "2. Caddy reverse proxy (Let's Encrypt TLS automatikus)"
    if systemctl is-active --quiet caddy 2>/dev/null; then
        log_ok "Caddy mar fut - kihagyva."
        return
    fi
    if ask_yn "Telepitsem?" "Y"; then
        bash "$SCRIPT_DIR/caddy/install-caddy.sh"
        log_ok "Caddy kesz."
    else
        log "Kihagyva."
    fi
}

step_pgbouncer() {
    log_step "3. PgBouncer transaction pool (port 6432)"
    if systemctl is-active --quiet pgbouncer 2>/dev/null; then
        log_ok "PgBouncer mar fut - kihagyva."
        return
    fi
    if ! ask_yn "Telepitsem?" "Y"; then
        log "Kihagyva."
        return
    fi
    if [[ ! -f /etc/pgbouncer/userlist.txt ]]; then
        log "userlist.txt generalasa a postgres pg_authid-bol..."
        mkdir -p /etc/pgbouncer
        su - postgres -c "psql -tAc \"SELECT '\\\"'||rolname||'\\\" \\\"'||rolpassword||'\\\"' FROM pg_authid WHERE rolname='valuta_user'\"" \
            > /etc/pgbouncer/userlist.txt
        if [[ ! -s /etc/pgbouncer/userlist.txt ]]; then
            log_err "Uresen jott vissza a pg_authid - valuta_user letezik? Jelszoval beallitva? (SCRAM)"
            log_err "Elotte: sudo -u postgres psql -c \"ALTER USER valuta_user WITH PASSWORD '...';\""
            return 1
        fi
        chmod 600 /etc/pgbouncer/userlist.txt
        chown postgres:postgres /etc/pgbouncer/userlist.txt
        log_ok "userlist.txt generalva ($(wc -l < /etc/pgbouncer/userlist.txt) sor)."
    fi
    bash "$SCRIPT_DIR/pgbouncer/install-pgbouncer.sh"
    log_ok "PgBouncer kesz."
}

step_redis() {
    log_step "4. Redis JWT blacklist (OPCIONALIS - docker redis:7-alpine)"
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^valuta-redis$'; then
        log_ok "valuta-redis mar fut - kihagyva."
        return
    fi
    if ! ask_yn "Telepitsem (JWT logout blacklist-hez)?" "N"; then
        log "Kihagyva - REDIS_ENABLED marad 'false' a .env-ben."
        return
    fi
    if ! command -v docker >/dev/null 2>&1; then
        log_err "Docker nincs telepitve - kihagyva. (Install: apt-get install docker-ce docker-compose-plugin)"
        return 1
    fi
    local redis_pass
    redis_pass="$(gen_secret_hex 16)"
    docker run -d --name valuta-redis --restart unless-stopped \
        -p 127.0.0.1:6379:6379 \
        -v valuta-redis-data:/data \
        redis:7-alpine \
        redis-server --requirepass "$redis_pass" --save 900 1 --save 300 10
    log_ok "Redis elinditva. Jelszo: $redis_pass (MENTSD EL!)"
    sed -i -E "s|^REDIS_ENABLED=.*|REDIS_ENABLED=true|" "$BACKEND_ENV_FILE" || true
    grep -qE "^REDIS_HOST=" "$BACKEND_ENV_FILE" || echo "REDIS_HOST=127.0.0.1" >> "$BACKEND_ENV_FILE"
    grep -qE "^REDIS_PORT=" "$BACKEND_ENV_FILE" || echo "REDIS_PORT=6379" >> "$BACKEND_ENV_FILE"
    if grep -qE "^REDIS_PASSWORD=" "$BACKEND_ENV_FILE"; then
        sed -i -E "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=$redis_pass|" "$BACKEND_ENV_FILE"
    else
        echo "REDIS_PASSWORD=$redis_pass" >> "$BACKEND_ENV_FILE"
    fi
    log_ok ".env frissitve Redis credentialokkel."
}

step_tailscale() {
    log_step "5. Tailscale SSH bastion (kell: TAILSCALE_AUTHKEY)"
    if command -v tailscale >/dev/null 2>&1 && tailscale status >/dev/null 2>&1; then
        log_ok "Tailscale mar fut - kihagyva."
        return
    fi
    if ! ask_yn "Telepitsem?" "N"; then
        log "Kihagyva."
        return
    fi
    local authkey
    authkey="$(ask_secret TAILSCALE_AUTHKEY "tskey-auth-... https://login.tailscale.com/admin/settings/keys" 20)"
    TAILSCALE_AUTHKEY="$authkey" bash "$SCRIPT_DIR/hardening/install-tailscale.sh"
    log_ok "Tailscale kesz. Az SSH most a 100.x.x.x IP-n is elerheto - tedd fel a UFW-be: ufw allow in on tailscale0"
}

step_b2_backup() {
    log_step "6. Backblaze B2 nightly backup (kell: B2_KEY_ID + B2_APP_KEY)"
    if systemctl is-enabled --quiet valuta-backup.timer 2>/dev/null; then
        log_ok "valuta-backup.timer mar aktiv - kihagyva."
        return
    fi
    if ! ask_yn "Telepitsem?" "Y"; then
        log "Kihagyva."
        return
    fi
    local b2_key_id b2_app_key
    b2_key_id="$(ask_secret B2_KEY_ID "Backblaze keyID - https://secure.backblaze.com/app_keys.htm" 10)"
    b2_app_key="$(ask_secret B2_APP_KEY "Backblaze applicationKey (csak egyszer lathato!)" 20)"
    B2_KEY_ID="$b2_key_id" B2_APP_KEY="$b2_app_key" \
        bash "$SCRIPT_DIR/backup/install-b2-backup.sh"
    log_ok "B2 backup kesz. Kovetkezo futas: 03:30 UTC (valuta-backup.timer)."
}

step_monitoring() {
    log_step "7. Monitoring stack (Prometheus + Grafana + Loki + Alertmanager)"
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qE 'valuta-grafana|^grafana$'; then
        log_ok "Grafana mar fut - kihagyva."
        return
    fi
    if ! ask_yn "Telepitsem?" "N"; then
        log "Kihagyva."
        return
    fi
    if ! command -v docker >/dev/null 2>&1; then
        log_err "Docker nincs telepitve - kihagyva."
        return 1
    fi
    local grafana_pass tg_bot_token tg_chat_id
    grafana_pass="$(ask_secret GRAFANA_ADMIN_PASSWORD "Grafana admin web UI jelszo" 8)"
    tg_bot_token="$(ask_secret TELEGRAM_BOT_TOKEN "BotFather-tol: bot token (opcionalis - ENTER a skippeleshez)" 0)"
    tg_chat_id=""
    if [[ -n "$tg_bot_token" ]]; then
        tg_chat_id="$(ask_secret TELEGRAM_CHAT_ID "Chat ID (pl. -1001234567890)" 4)"
        mkdir -p "$SCRIPT_DIR/monitoring/secrets"
        echo -n "$tg_bot_token" > "$SCRIPT_DIR/monitoring/secrets/telegram_bot_token"
        chmod 600 "$SCRIPT_DIR/monitoring/secrets/telegram_bot_token"
    fi
    (
        cd "$SCRIPT_DIR/monitoring"
        GRAFANA_ADMIN_PASSWORD="$grafana_pass" \
        TELEGRAM_CHAT_ID="${tg_chat_id:-disabled}" \
        docker compose -f docker-compose.monitoring.yml up -d
    )
    log_ok "Monitoring stack elinditva. Grafana: http://localhost:3001 (admin/$grafana_pass)"
    log_warn "Caddy mogott exponaltasd: grafana.excvaluta.com szekcio a Caddyfile-ban."
}

step_client_error_cleanup() {
    log_step "8. client_error_log retention cleanup timer"
    if systemctl is-enabled --quiet valuta-client-error-cleanup.timer 2>/dev/null; then
        log_ok "valuta-client-error-cleanup.timer mar aktiv - kihagyva."
        return
    fi
    if ! ask_yn "Telepitsem?" "Y"; then
        log "Kihagyva."
        return
    fi
    bash "$SCRIPT_DIR/scripts/setup-client-error-cleanup.sh"
    log_ok "client_error_log cleanup timer kesz. Napi futas: 02:10 UTC."
}

step_restart_backend() {
    log_step "Backend ujrainditas az uj .env-vel"
    if systemctl is-active --quiet valuta-backend.service 2>/dev/null; then
        if ask_yn "Ujraindit systemctl restart valuta-backend?" "Y"; then
            systemctl restart valuta-backend.service
            sleep 5
            if systemctl is-active --quiet valuta-backend.service; then
                log_ok "Backend ujraindult es fut."
            else
                log_err "Backend NEM indult el. Nezd meg: journalctl -u valuta-backend.service -n 50 --no-pager"
                return 1
            fi
        fi
    else
        log "valuta-backend.service nem aktiv - kihagyva az ujrainditast."
    fi
}

step_health_check() {
    log_step "Health check"
    local url="https://excvaluta.com/api/v1/auth/bootstrap-status"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" || echo 000)
    if [[ "$status" == "200" ]]; then
        log_ok "Health check PASSED ($url -> HTTP 200)"
    else
        log_warn "Health check HTTP $status ($url) - ellenorizd a Caddy / backend logokat."
    fi
}

# -------------------------- Main --------------------------------------------

main() {
    require_root
    check_prerequisite
    mkdir -p "$(dirname "$BOOTSTRAP_LOG")"

    echo "========================================================================"
    echo "           Valuta VPS Bootstrap - 7 secret, 12 gap"
    echo "========================================================================"
    echo ""
    echo "Ez a script vegigmegy a 7 opcionalis telepitesi lepesen. Minden lepest"
    echo "jova kell hagynod (Y/n). A secret-eket csak akkor kell beirnod, ha az"
    echo "adott lepest valasztod - egyebkent kihagyasra kerul."
    echo ""
    echo "Elotte beallithatod ezeket env var-kent (non-interactive mod):"
    echo "  TAILSCALE_AUTHKEY B2_KEY_ID B2_APP_KEY"
    echo "  GRAFANA_ADMIN_PASSWORD TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID"
    echo "========================================================================"
    echo ""

    step_backend_env
    step_hardening
    step_caddy
    step_pgbouncer
    step_redis
    step_tailscale
    step_b2_backup
    step_monitoring
    step_client_error_cleanup
    step_restart_backend
    step_health_check

    echo ""
    echo "========================================================================"
    echo "                       Bootstrap BEFEJEZVE"
    echo "========================================================================"
    echo ""
    echo "Log: $BOOTSTRAP_LOG"
    echo "Backend .env: $BACKEND_ENV_FILE (chmod 640)"
    echo ""
    echo "Kovetkezo lepes: ellenorzes"
    echo "  systemctl status valuta-backend.service pgbouncer caddy fail2ban"
    echo "  curl https://excvaluta.com/api/v1/auth/bootstrap-status"
    echo "========================================================================"
}

main "$@"
