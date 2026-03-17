# Hetzner Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate valutaváltó backend from Render.com free tier to Hetzner CPX31 Docker Compose, fixing bottlenecks for 75 concurrent POS terminals.

**Architecture:** Docker Compose on existing Hetzner VPS (135.181.39.206) with Nginx reverse proxy (SSL), Spring Boot backend, PostgreSQL. Frontend stays on Vercel.

**Tech Stack:** Docker Compose, Nginx, Let's Encrypt/Certbot, PostgreSQL 16, Java 21, Spring Boot 3.2

**Spec:** `docs/superpowers/specs/2026-03-17-hetzner-migration-design.md`

---

## File Structure

### New files (deployment)
- `deploy/docker-compose.prod.yml` — Production Docker Compose (Nginx + backend + PostgreSQL + Certbot)
- `deploy/.env.example` — Template for all required environment variables
- `deploy/nginx/nginx-initial.conf` — Nginx config for initial SSL bootstrap (HTTP only)
- `deploy/nginx/nginx.conf` — Full Nginx config with SSL + WebSocket
- `deploy/scripts/backup.sh` — Daily PostgreSQL backup script
- `deploy/scripts/setup.sh` — Server initial setup script (firewall, dirs, cron)
- `deploy/README.md` — Deployment guide for the Hetzner server

### Modified files (code bottleneck fixes)
- `backend/Dockerfile` — Add `${JAVA_OPTS}` support to ENTRYPOINT
- `backend/src/main/resources/application-production.properties` — DB pool size, credentials format, OAuth redirect URI

---

## Task 1: Backend kód módosítások (bottleneck fix + Docker support)

**Files:**
- Modify: `backend/src/main/resources/application-production.properties`
- Modify: `backend/Dockerfile`

- [ ] **Step 1: Update application-production.properties — DB pool size**

In `backend/src/main/resources/application-production.properties`, change:
```properties
spring.datasource.hikari.maximum-pool-size=15
spring.datasource.hikari.minimum-idle=2
```
To:
```properties
spring.datasource.hikari.maximum-pool-size=40
spring.datasource.hikari.minimum-idle=5
```

- [ ] **Step 2: Update application-production.properties — DB credentials format**

Add these two lines after the existing `spring.datasource.url` line:
```properties
spring.datasource.username=${DATABASE_USERNAME:}
spring.datasource.password=${DATABASE_PASSWORD:}
```

This allows Docker Compose to pass credentials separately (Render embeds them in DATABASE_URL, Docker Compose does not).

- [ ] **Step 3: Update application-production.properties — Google OAuth redirect URI**

Change:
```properties
google.redirect.uri=${GOOGLE_REDIRECT_URI:https://valuta-backend-spbx.onrender.com/api/v1/email/accounts/callback}
```
To:
```properties
google.redirect.uri=${GOOGLE_REDIRECT_URI:https://api.excvaluta.com/api/v1/email/accounts/callback}
```

- [ ] **Step 4: Update Dockerfile — JAVA_OPTS support**

In `backend/Dockerfile`, change the ENTRYPOINT line:
```dockerfile
ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT:-8080} -Dspring.profiles.active=production -jar app.jar"]
```
To:
```dockerfile
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS:--Xmx512m -Xms256m} -Dserver.port=${PORT:-8080} -Dspring.profiles.active=production -jar app.jar"]
```

- [ ] **Step 5: Verify backend still builds**

Run:
```bash
cd backend && JAVA_HOME="C:/Program Files/Eclipse Adoptium/jdk-21.0.10.7-hotspot" ./mvnw package -Dmaven.test.skip=true -q
```
Expected: BUILD SUCCESS

- [ ] **Step 6: Run backend tests**

Run:
```bash
cd backend && JAVA_HOME="C:/Program Files/Eclipse Adoptium/jdk-21.0.10.7-hotspot" ./mvnw test -q
```
Expected: All 522 tests pass, BUILD SUCCESS

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/resources/application-production.properties backend/Dockerfile
git commit -m "feat: Hetzner Docker deployment előkészítés — DB pool 40, JAVA_OPTS, OAuth URI"
```

---

## Task 2: Docker Compose production konfiguráció

**Files:**
- Create: `deploy/docker-compose.prod.yml`
- Create: `deploy/.env.example`

- [ ] **Step 1: Create deploy directory**

```bash
mkdir -p deploy/nginx deploy/scripts
```

- [ ] **Step 2: Create deploy/.env.example**

```env
# Valutaváltó ERP — Production Environment Variables
# Másold .env néven és töltsd ki az értékeket!

# Database
DB_USER=valuta
DB_PASSWORD=CHANGE_ME_STRONG_PASSWORD

# JWT (min 256 bit / 32+ karakter)
JWT_SECRET=CHANGE_ME_JWT_SECRET_MIN_32_CHARS

# Google OAuth (opcionális — Gmail integráció)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Encryption (AES kulcsok)
ENCRYPTION_KEY=CHANGE_ME
ENCRYPTION_SALT=CHANGE_ME

# SMTP (opcionális — email küldés)
SMTP_HOST=
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=

# Error log HMAC
ERRORLOG_HMAC_SECRET=

# JVM beállítások
JAVA_OPTS=-Xmx512m -Xms256m

# Domain
DOMAIN=api.excvaluta.com
```

- [ ] **Step 3: Create deploy/docker-compose.prod.yml**

```yaml
# Valutaváltó ERP — Production Docker Compose
# Hetzner CPX31 (135.181.39.206)
#
# Használat:
#   1. cp .env.example .env && nano .env  (kitölteni!)
#   2. docker compose -f docker-compose.prod.yml up -d
#
# Első indítás (SSL bootstrap):
#   1. Nginx HTTP-only módban indul (nginx-initial.conf)
#   2. Certbot beszerzi a tanúsítványt
#   3. Nginx átkapcsol SSL módra (nginx.conf)
#   Részletek: README.md

services:
  nginx:
    image: nginx:alpine
    container_name: valuta-nginx
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - certbot-data:/etc/letsencrypt:ro
      - certbot-webroot:/var/www/certbot:ro
    depends_on:
      - valuta-backend
    restart: unless-stopped
    mem_limit: 64m
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  valuta-backend:
    build:
      context: ../backend
      dockerfile: Dockerfile
    container_name: valuta-backend
    environment:
      - SPRING_PROFILES_ACTIVE=production
      - DATABASE_URL=jdbc:postgresql://postgres:5432/valuta
      - DATABASE_USERNAME=${DB_USER}
      - DATABASE_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - JAVA_OPTS=${JAVA_OPTS:--Xmx512m -Xms256m}
      - GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-}
      - GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET:-}
      - GOOGLE_REDIRECT_URI=https://${DOMAIN:-api.excvaluta.com}/api/v1/email/accounts/callback
      - ENCRYPTION_KEY=${ENCRYPTION_KEY:-}
      - ENCRYPTION_SALT=${ENCRYPTION_SALT:-}
      - ERRORLOG_HMAC_SECRET=${ERRORLOG_HMAC_SECRET:-}
      - CORS_ALLOWED_ORIGINS=https://excvaluta.com,https://www.excvaluta.com,https://valutavalto.vercel.app
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
    mem_limit: 768m
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"

  postgres:
    image: postgres:16-alpine
    container_name: valuta-postgres
    environment:
      - POSTGRES_DB=valuta
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    # BIZTONSAG: NINCS host port mapping — csak Docker network-ön érhető el!
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    mem_limit: 512m
    logging:
      driver: json-file
      options:
        max-size: "20m"
        max-file: "3"

  certbot:
    image: certbot/certbot
    container_name: valuta-certbot
    volumes:
      - certbot-data:/etc/letsencrypt
      - certbot-webroot:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew --webroot -w /var/www/certbot --quiet; sleep 12h & wait $${!}; done;'"
    restart: unless-stopped

volumes:
  pgdata:
  certbot-data:
  certbot-webroot:
```

- [ ] **Step 4: Commit**

```bash
git add deploy/docker-compose.prod.yml deploy/.env.example
git commit -m "feat: production Docker Compose konfiguráció (Hetzner)"
```

---

## Task 3: Nginx konfiguráció

**Files:**
- Create: `deploy/nginx/nginx-initial.conf`
- Create: `deploy/nginx/nginx.conf`

- [ ] **Step 1: Create deploy/nginx/nginx-initial.conf (SSL bootstrap — HTTP only)**

```nginx
# Nginx — SSL Bootstrap konfiguráció
# Csak az első certbot futtatáshoz — utána cseréld nginx.conf-ra!

events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name api.excvaluta.com;

        # Certbot ACME challenge
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        # Health check (amíg nincs SSL)
        location /actuator/health {
            proxy_pass http://valuta-backend:8080;
        }

        # Minden más → 503 (még nincs SSL)
        location / {
            return 503 '{"error":"SSL bootstrap in progress"}';
            add_header Content-Type application/json;
        }
    }
}
```

- [ ] **Step 2: Create deploy/nginx/nginx.conf (full production config)**

```nginx
# Nginx — Production konfiguráció
# SSL termination + reverse proxy + WebSocket support

events {
    worker_connections 1024;
}

http {
    # Alap beállítások
    sendfile on;
    keepalive_timeout 65;
    client_max_body_size 50m;

    # Gzip tömörítés
    gzip on;
    gzip_types application/json text/plain application/javascript;

    # Rate limiting zone (opcionális extra védelem)
    limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;

    # Upstream
    upstream backend {
        server valuta-backend:8080;
    }

    # HTTP → HTTPS redirect + ACME challenge
    server {
        listen 80;
        server_name api.excvaluta.com;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$host$request_uri;
        }
    }

    # HTTPS szerver
    server {
        listen 443 ssl;
        http2 on;
        server_name api.excvaluta.com;

        # SSL tanúsítványok (Let's Encrypt)
        ssl_certificate /etc/letsencrypt/live/api.excvaluta.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/api.excvaluta.com/privkey.pem;

        # SSL beállítások
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # API proxy
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Timeout beállítások
            proxy_connect_timeout 30s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # WebSocket endpoint
        location /ws {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_read_timeout 86400;
        }

        # Actuator health (monitoring)
        location /actuator/health {
            proxy_pass http://backend;
            proxy_set_header Host $host;
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add deploy/nginx/nginx-initial.conf deploy/nginx/nginx.conf
git commit -m "feat: Nginx reverse proxy konfiguráció (SSL + WebSocket)"
```

---

## Task 4: Deployment szkriptek

**Files:**
- Create: `deploy/scripts/backup.sh`
- Create: `deploy/scripts/setup.sh`

- [ ] **Step 1: Create deploy/scripts/backup.sh**

```bash
#!/bin/bash
# Valutaváltó — Napi PostgreSQL backup
# Crontab: 0 3 * * * /opt/valuta/scripts/backup.sh >> /var/log/valuta-backup.log 2>&1
set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/opt/valuta}"
source "${DEPLOY_DIR}/.env"

BACKUP_DIR=/backups/valuta
mkdir -p "${BACKUP_DIR}"
DATE=$(date +%Y%m%d_%H%M%S)

echo "[$(date)] Backup indítás..."
docker compose -f "${DEPLOY_DIR}/docker-compose.prod.yml" exec -T postgres \
    pg_dump -U "${DB_USER}" valuta | gzip > "${BACKUP_DIR}/valuta_${DATE}.sql.gz"

# Méret ellenőrzés (ha 0 byte, hiba)
FILESIZE=$(stat -c%s "${BACKUP_DIR}/valuta_${DATE}.sql.gz" 2>/dev/null || echo "0")
if [ "${FILESIZE}" -lt 100 ]; then
    echo "[$(date)] HIBA: Backup fájl túl kicsi (${FILESIZE} byte)!"
    exit 1
fi

echo "[$(date)] Backup kész: valuta_${DATE}.sql.gz (${FILESIZE} byte)"

# 7 napnál régebbi backup törlése
DELETED=$(find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +7 -delete -print | wc -l)
echo "[$(date)] ${DELETED} régi backup törölve."
```

- [ ] **Step 2: Create deploy/scripts/setup.sh**

```bash
#!/bin/bash
# Valutaváltó — Hetzner szerver initial setup
# Futtatás: sudo bash setup.sh
set -euo pipefail

echo "=== Valutaváltó Hetzner Setup ==="

# 1. Firewall
echo "[1/5] Firewall beállítás..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable
ufw status

# 2. Könyvtárak
echo "[2/5] Könyvtárak létrehozása..."
mkdir -p /opt/valuta /backups/valuta

# 3. Backup cron
echo "[3/5] Backup cron beállítás..."
CRON_LINE="0 3 * * * /opt/valuta/scripts/backup.sh >> /var/log/valuta-backup.log 2>&1"
(crontab -l 2>/dev/null | grep -v "valuta-backup"; echo "${CRON_LINE}") | crontab -

# 4. Nginx reload cron (cert megújítás után)
echo "[4/5] Certbot reload cron..."
RELOAD_LINE="0 */12 * * * cd /opt/valuta && docker compose -f docker-compose.prod.yml exec -T nginx nginx -s reload >> /var/log/valuta-certbot-reload.log 2>&1"
(crontab -l 2>/dev/null | grep -v "certbot-reload"; echo "${RELOAD_LINE}") | crontab -

# 5. Disk monitoring cron
echo "[5/5] Disk monitoring..."
DISK_LINE="0 */6 * * * df -h / | awk 'NR==2 && \$5+0 > 80 {print \"DISK WARNING: \" \$5 \" used\"}' >> /var/log/valuta-disk.log 2>&1"
(crontab -l 2>/dev/null | grep -v "valuta-disk"; echo "${DISK_LINE}") | crontab -

echo ""
echo "=== Setup kész! ==="
echo "Következő lépések:"
echo "  1. cd /opt/valuta"
echo "  2. cp .env.example .env && nano .env"
echo "  3. Lásd README.md a teljes indítási folyamathoz"
```

- [ ] **Step 3: Make scripts executable and commit**

```bash
git add deploy/scripts/backup.sh deploy/scripts/setup.sh
git commit -m "feat: deployment szkriptek (backup + szerver setup)"
```

---

## Task 5: Deployment README

**Files:**
- Create: `deploy/README.md`

- [ ] **Step 1: Create deploy/README.md**

```markdown
# Valutaváltó — Production Deployment (Hetzner)

## Előfeltételek

- Hetzner szerver (CPX31+): Docker + Docker Compose telepítve
- DNS: `api.excvaluta.com` → szerver IP (A record, TTL: 300)
- SSH hozzáférés a szerverhez

## Első telepítés

### 1. Szerver előkészítés

```bash
# Repo klónozás
git clone <repo-url> /opt/valuta-repo
cd /opt/valuta-repo

# Deploy fájlok másolása
cp -r deploy/* /opt/valuta/
cp -r backend/ /opt/valuta/backend/

# Setup szkript futtatása (firewall, cron, könyvtárak)
sudo bash /opt/valuta/scripts/setup.sh
```

### 2. Environment beállítás

```bash
cd /opt/valuta
cp .env.example .env
nano .env  # Töltsd ki az ÖSSZES CHANGE_ME értéket!
```

### 3. SSL Bootstrap

```bash
cd /opt/valuta

# Először HTTP-only Nginx-szel indítunk (nincs még cert)
cp nginx/nginx-initial.conf nginx/nginx.conf.bak
cp nginx/nginx-initial.conf nginx/nginx.conf

# Indítás
docker compose -f docker-compose.prod.yml up -d

# Certbot — első tanúsítvány beszerzése
docker compose -f docker-compose.prod.yml run --rm certbot \
    certonly --webroot -w /var/www/certbot -d api.excvaluta.com \
    --email admin@excvaluta.com --agree-tos --no-eff-email

# Nginx átkapcsolás SSL-re
cp nginx/nginx.conf.bak nginx/nginx.conf.initial-backup
cp nginx/nginx.conf.prod nginx/nginx.conf
# (a nginx.conf.prod = a repo-ban lévő teljes SSL-es konfig)

docker compose -f docker-compose.prod.yml restart nginx
```

### 4. Ellenőrzés

```bash
# Health check
curl -s https://api.excvaluta.com/actuator/health

# Backend logok
docker compose -f docker-compose.prod.yml logs -f valuta-backend
```

## Adatmigráció (Render → Hetzner)

### FONTOS: A Render backend-et LE KELL állítani a dump előtt!

```bash
# 1. Render backend leállítása (Render Dashboard → Manual Deploy → Suspend)

# 2. pg_dump a Render DB-ből
# (Render Dashboard → Database → External Connection → Connection string)
pg_dump "CONNECTION_STRING_FROM_RENDER" | gzip > render_dump.sql.gz

# 3. Restore a Hetzner DB-be
gunzip -c render_dump.sql.gz | docker compose -f docker-compose.prod.yml exec -T postgres \
    psql -U ${DB_USER} valuta

# 4. Ellenőrzés
docker compose -f docker-compose.prod.yml exec postgres \
    psql -U ${DB_USER} -d valuta -c "SELECT count(*) FROM transactions;"
```

## Napi üzemeltetés

```bash
# Logok megtekintése
docker compose -f docker-compose.prod.yml logs -f valuta-backend --tail=100

# Újraindítás
docker compose -f docker-compose.prod.yml restart valuta-backend

# Frissítés (új verzió deploy)
cd /opt/valuta-repo && git pull
cp -r backend/ /opt/valuta/backend/
cd /opt/valuta
docker compose -f docker-compose.prod.yml build valuta-backend
docker compose -f docker-compose.prod.yml up -d valuta-backend

# Manuális backup
/opt/valuta/scripts/backup.sh

# Backup restore
gunzip -c /backups/valuta/valuta_YYYYMMDD_HHMMSS.sql.gz | \
    docker compose -f docker-compose.prod.yml exec -T postgres psql -U ${DB_USER} valuta
```
```

- [ ] **Step 2: Commit**

```bash
git add deploy/README.md
git commit -m "docs: Hetzner deployment útmutató"
```

---

## Task 6: Végső ellenőrzés és commit

- [ ] **Step 1: Verify all new files exist**

```bash
ls -la deploy/
ls -la deploy/nginx/
ls -la deploy/scripts/
```

Expected:
```
deploy/
  docker-compose.prod.yml
  .env.example
  README.md
  nginx/
    nginx-initial.conf
    nginx.conf
  scripts/
    backup.sh
    setup.sh
```

- [ ] **Step 2: Run backend tests one final time**

```bash
cd backend && JAVA_HOME="C:/Program Files/Eclipse Adoptium/jdk-21.0.10.7-hotspot" ./mvnw test -q
```
Expected: 522 tests pass, BUILD SUCCESS

- [ ] **Step 3: Verify frontend type check still passes**

```bash
cd frontend-react && npx tsc --noEmit
```
Expected: No errors

---

## Post-deployment tasks (kézi, szerveren)

Ezek NEM kód feladatok — a szerveren kell végrehajtani:

1. **DNS beállítás:** `api.excvaluta.com` → `135.181.39.206` (A record, TTL 300)
2. **Szerver setup:** `sudo bash /opt/valuta/scripts/setup.sh`
3. **SSL bootstrap:** Lásd `deploy/README.md` 3. pont
4. **Adatmigráció:** Render pg_dump → Hetzner pg_restore
5. **Vercel frissítés:** `VITE_API_URL=https://api.excvaluta.com/api/v1`
6. **UptimeRobot:** Monitor hozzáadása `https://api.excvaluta.com/actuator/health`
7. **Electron kliensek:** `server_url` frissítés az SQLite config táblában
