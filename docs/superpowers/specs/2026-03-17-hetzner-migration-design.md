# Valutaváltó Backend Migráció: Render.com → Hetzner Docker

**Dátum:** 2026-03-17
**Státusz:** Jóváhagyva

## Összefoglaló

A valutaváltó ERP backend áthelyezése Render.com free tier-ről a meglévő Hetzner CPX31 szerverre (135.181.39.206), Docker Compose-ban. Ezzel egyidejűleg a kód szintű bottleneck-ek javítása 75 pénztár egyidejű kiszolgálásához.

## Motiváció

- Render.com free tier nem alkalmas 75 pénztár folyamatos üzemeltetésére (512 MB RAM, korlátozott CPU)
- DB connection pool (15) szűk a 75 egyidejű terminálhoz
- Meglévő Hetzner CPX31 szerveren van szabad kapacitás (4 vCPU, 8 GB RAM)
- Költséghatékonyabb: ~€15/hó vs Render Pro ~$85/hó

## Architektúra

```
                    Internet
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   excvaluta.com   api.excvaluta.com  Electron pénztárak (75x)
   (Vercel CDN)        │              │
   frontend-react      │              │
        │              ▼              │
        │     ┌─── Hetzner CPX31 ─────┤
        │     │   135.181.39.206      │
        │     │                       │
        │     │  ┌──────────────┐     │
        └─────┼─►│    Nginx     │◄────┘
              │  │  :443 (SSL)  │
              │  │  :80 → 443   │
              │  └──────┬───────┘
              │         │
              │  ┌──────▼───────┐
              │  │ valuta-backend│
              │  │  :8080 (Java)│
              │  └──────┬───────┘
              │         │
              │  ┌──────▼───────┐
              │  │  PostgreSQL  │
              │  │  :5432       │
              │  └──────────────┘
              │
              │  (newugyvitel-prod
              │   már fut mellette)
              └───────────────────
```

### Komponensek

| Komponens | Image | Port | RAM limit |
|-----------|-------|------|-----------|
| Nginx | nginx:alpine | 443, 80 (host) | 64 MB |
| valuta-backend | custom (Dockerfile) | 8080 (internal) | 768 MB |
| PostgreSQL | postgres:16-alpine | 5432 (internal only!) | 512 MB |
| **Összesen** | | | **~1344 MB** |

**Biztonsági megjegyzés:** A PostgreSQL CSAK a Docker belső hálózaton érhető el — NINCS host port mapping. A backend a Docker network-ön keresztül éri el a `postgres:5432` címen.

### Mi marad változatlanul

- **Frontend (excvaluta.com):** Vercel CDN-en marad — ingyenes, gyors, automatikus deploy
- **Electron pénztárak:** Változatlan architektúra — szerver URL frissítés szükséges
- **WebSocket broker:** In-memory simple broker marad (75 connection-höz egyetlen szerveren elég)

### Izoláció a newugyvitel-prod-tól

- Külön Docker Compose projekt (külön mappa, külön network)
- Nginx a 443/80 porton — ha a newugyvitel is Nginx-et használ, port konfiguráció szükséges (pl. a valuta Nginx egy másik IP-n vagy SNI-alapú routing)
- Nincs közös adatbázis — teljesen külön PostgreSQL instance

## Kód módosítások

### 1. DB Connection Pool — `application-production.properties`

```properties
# Jelenlegi
spring.datasource.hikari.maximum-pool-size=15
spring.datasource.hikari.minimum-idle=2

# Új
spring.datasource.hikari.maximum-pool-size=40
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
```

**Indoklás:** 75 pénztár × 2-3 egyidejű query, de a legtöbb query <50ms → 40 connection elég a burst kezelésre. PostgreSQL `max_connections` alapértelmezetten 100, a 40 pool bőven belefér.

**Megjegyzés:** A PostgreSQL oldalon 40 connection × ~5-10 MB = 200-400 MB. Ez belefér az 512 MB-os konténer limitbe, de érdemes benchmarkkal validálni. Ha szükséges, pool méretet 25-30-ra lehet csökkenteni.

### 2. Rate Limiting — már IP-alapú, nincs teendő ✅

A `RateLimitFilter.java` már `ConcurrentHashMap<String, RateLimitEntry>` alapú, `resolveClientIp()` függvénnyel. A jelenlegi 30 req/60s per IP limit 75 pénztárnál megfelelő (minden pénztár saját limitet kap).

### 3. Dockerfile módosítás — JVM memória

A jelenlegi Dockerfile ENTRYPOINT nem használja a `JAVA_OPTS` env var-t:
```dockerfile
# Jelenlegi
ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT:-8080} -Dspring.profiles.active=production -jar app.jar"]

# Új
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS:--Xmx512m -Xms256m} -Dserver.port=${PORT:-8080} -Dspring.profiles.active=production -jar app.jar"]
```

Ez lehetővé teszi a JVM memória beállítást env var-ból, fallback-kel ha nincs megadva.

### 4. Database credentials — `application-production.properties`

A jelenlegi konfiguráció a `DATABASE_URL`-ben várja a credentials-t (Render formátum). Docker Compose-ban külön env var-okban adjuk meg, ezért a properties-t frissíteni kell:

```properties
# Jelenlegi (Render formátum — credentials a URL-ben)
spring.datasource.url=${DATABASE_URL}

# Új (Docker Compose formátum — külön credentials)
spring.datasource.url=${DATABASE_URL}
spring.datasource.username=${DATABASE_USERNAME:}
spring.datasource.password=${DATABASE_PASSWORD:}
```

A `DATABASE_URL` Docker Compose-ban credentials nélküli JDBC URL: `jdbc:postgresql://postgres:5432/valuta`

### 5. Google OAuth redirect URI frissítés

```properties
# Jelenlegi
google.redirect.uri=${GOOGLE_REDIRECT_URI:https://valuta-backend-spbx.onrender.com/api/v1/email/accounts/callback}

# Új
google.redirect.uri=${GOOGLE_REDIRECT_URI:https://api.excvaluta.com/api/v1/email/accounts/callback}
```

### 6. Összes szükséges environment variable

A Docker Compose `.env` fájlban (vagy secrets manager-ben) kell lennie:

```env
# Database
DB_USER=valuta
DB_PASSWORD=<erős jelszó>

# JWT
JWT_SECRET=<min 256 bit>

# Google OAuth (opcionális)
GOOGLE_CLIENT_ID=<...>
GOOGLE_CLIENT_SECRET=<...>

# Encryption
ENCRYPTION_KEY=<...>
ENCRYPTION_SALT=<...>

# SMTP (opcionális)
SMTP_HOST=<...>
SMTP_PORT=<...>
SMTP_USERNAME=<...>
SMTP_PASSWORD=<...>

# Error log HMAC
ERRORLOG_HMAC_SECRET=<...>

# JVM
JAVA_OPTS=-Xmx512m -Xms256m
```

## Docker Compose konfiguráció

```yaml
services:
  nginx:
    image: nginx:alpine
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
    build: ./backend
    environment:
      - SPRING_PROFILES_ACTIVE=production
      - DATABASE_URL=jdbc:postgresql://postgres:5432/valuta
      - DATABASE_USERNAME=${DB_USER}
      - DATABASE_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - JAVA_OPTS=${JAVA_OPTS:--Xmx512m -Xms256m}
      - GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-}
      - GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET:-}
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - ENCRYPTION_SALT=${ENCRYPTION_SALT}
      - ERRORLOG_HMAC_SECRET=${ERRORLOG_HMAC_SECRET:-}
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
    environment:
      - POSTGRES_DB=valuta
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    # NINCS ports mapping — csak Docker network-ön érhető el!
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
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

## Nginx konfiguráció (minimális követelmények)

```nginx
server {
    listen 80;
    server_name api.excvaluta.com;

    # Certbot challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # HTTP → HTTPS redirect
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name api.excvaluta.com;

    ssl_certificate /etc/letsencrypt/live/api.excvaluta.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.excvaluta.com/privkey.pem;

    # Proxy a Spring Boot backend felé
    location / {
        proxy_pass http://valuta-backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Kamera upload támogatás
        client_max_body_size 50m;
    }

    # WebSocket upgrade kezelés
    location /ws {
        proxy_pass http://valuta-backend:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }
}
```

## SSL / Domain

1. **DNS:** `api.excvaluta.com` → `135.181.39.206` (A record)
2. **Certbot:** Docker konténerként fut, 12 óránként próbálja megújítani
3. **Első tanúsítvány bootstrap:**
   - Az Nginx először SSL nélkül indul (csak 80-as port, ACME challenge kiszolgálás)
   - `docker compose run certbot certonly --webroot -w /var/www/certbot -d api.excvaluta.com`
   - Cert megvan → Nginx konfig átkapcsolása SSL-re → `docker compose restart nginx`
4. **Nginx reload cert megújítás után:** Cron a host gépen: `0 */12 * * * cd /opt/valuta && docker compose exec nginx nginx -s reload`
   - A certbot 30 nappal lejárat előtt újít — a max 12 órás delay nem jelent kockázatot

## Backup stratégia

- **Napi** `pg_dump` → `/backups/valuta/` mappa (cron job, 03:00 UTC)
- **7 napos rotáció** — régebbi dump-ok automatikus törlése
- Docker volume persistent → konténer újraindítás nem törli az adatot
- **Offsite:** Érdemes Hetzner Object Storage-ba (S3-kompatibilis) is másolni — ha a szerver meghal, a helyi backup is elvész

### Backup cron script

```bash
#!/bin/bash
# /opt/valuta/backup.sh
set -euo pipefail
source /opt/valuta/.env  # DB_USER betöltése a Docker Compose env fájlból
BACKUP_DIR=/backups/valuta
mkdir -p "${BACKUP_DIR}"
DATE=$(date +%Y%m%d_%H%M%S)
docker compose -f /opt/valuta/docker-compose.yml exec -T postgres pg_dump -U "${DB_USER}" valuta | gzip > "${BACKUP_DIR}/valuta_${DATE}.sql.gz"
# 7 napnál régebbi backup törlése
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +7 -delete
```

## Monitoring

- **Uptime check:** UptimeRobot (ingyenes) → `https://api.excvaluta.com/actuator/health` (5 perces intervallum)
- **Logok:** `docker compose logs -f valuta-backend` — a json-file driver korlátozza a méretet
- **Disk space:** Cron alert ha a disk 80% felett: `df -h / | awk 'NR==2 && $5+0 > 80 {print "DISK FULL"}'`
- **Alerting:** Email értesítés UptimeRobot-ból ha a health check sikertelen

## Firewall (UFW)

A Hetzner szerveren csak a szükséges portok legyenek nyitva:
```bash
ufw default deny incoming   # alapértelmezetten mindent tilt
ufw default allow outgoing  # kimenő forgalom engedélyezve
ufw allow 22/tcp            # SSH
ufw allow 80/tcp            # HTTP (redirect)
ufw allow 443/tcp           # HTTPS
ufw enable
```

## Adatmigráció terv (Render → Hetzner)

| Lépés | Művelet | Downtime |
|-------|---------|----------|
| 1 | Docker Compose felállítás + teszt a Hetzner-en (üres DB) | 0 |
| 2 | DNS beállítás (`api.excvaluta.com` → Hetzner) — TTL alacsonyra | 0 |
| 3 | **Render backend leállítása** (maintenance mode) | ⚠️ START |
| 4 | `pg_dump` a Render PostgreSQL-ből (utolsó konzisztens állapot) | ⚠️ |
| 5 | `pg_restore` a Hetzner PostgreSQL-be | ⚠️ |
| 6 | Backend indítás a Hetzner-en + API smoke test | ⚠️ |
| 7 | Frontend env var frissítés Vercel-en (`VITE_API_URL`) | ⚠️ END |
| 8 | Electron kliensek `server_url` frissítés (SQLite config) | 0 |

**Becsült teljes downtime:** ~15-30 perc (Render leállítás → Hetzner indulás)

**FONTOS:** A Render backend-et LE KELL állítani a dump előtt, különben a dump és a DNS átállás közötti tranzakciók elveszhetnek!

### Electron kliensek frissítése

A 75 Electron kliens `server_url` frissítése:
- A SyncEngine a SQLite `config` táblából olvassa a `server_url` értéket
- Opciók: (a) auto-updater push, (b) manuális config update minden pénztárnál, (c) a backend-ben egy "config endpoint" ami visszaadja az aktuális URL-t
- Ha egy kliens még a régi Render URL-t használja a Render leállítás után → offline módra vált → SyncEngine a következő sikeres csatlakozásnál szinkronizál

## Rollback terv

Ha bármi hiba van a Hetzner-en:
1. Render backend újraindítása
2. DNS vissza a Render-re (ha volt DNS változás)
3. A Render szolgáltatás nem lesz törölve az első 2 hétben

## Kockázatok

| Kockázat | Valószínűség | Hatás | Mitigáció |
|----------|-------------|-------|-----------|
| Hetzner szerver túlterhelése (newugyvitel + valuta) | Alacsony | Magas | Docker resource limit, monitoring |
| SSL certifikát lejárat | Alacsony | Magas | Certbot auto-renewal + UptimeRobot |
| Adatvesztés migráció közben | Alacsony | Kritikus | Render leállítás dump előtt + Render megtartása 2 hétig |
| Port konfliktus newugyvitel-tel | Közepes | Alacsony | Külön Docker Compose projekt, SNI routing ha kell |
| Disk tele (logok, backup, pgdata) | Közepes | Magas | Log rotation, backup rotation, disk monitoring |
