# Valutavalto — Production Deployment (Hetzner)

## Elofeltetelek

- Hetzner szerver (CPX31+): Docker + Docker Compose telepitve
- DNS: `excvaluta.com` -> szerver IP (A record, TTL: 300)
- SSH hozzaferes a szerverhez

## Elso telepites

### 1. Szerver elokeszites

```bash
# Repo klonozas
git clone <repo-url> /opt/valuta-repo
cd /opt/valuta-repo

# Deploy fajlok masolasa
cp -r deploy/* /opt/valuta/
cp -r backend/ /opt/valuta/backend/

# Setup szkript futtatasa (firewall, cron, konyvtarak)
sudo bash /opt/valuta/scripts/setup.sh
```

### 2. Environment beallitas

```bash
cd /opt/valuta
cp .env.example .env
nano .env  # Toltsd ki az OSSZES CHANGE_ME erteket!
```

### 3. SSL Bootstrap

```bash
cd /opt/valuta

# Eloszor HTTP-only Nginx-szel inditunk (nincs meg cert)
cp nginx/nginx.conf nginx/nginx.conf.ssl-backup
cp nginx/nginx-initial.conf nginx/nginx.conf

# Inditas
docker compose -f docker-compose.prod.yml up -d

# Certbot — elso tanusitvany beszerzese
docker compose -f docker-compose.prod.yml run --rm certbot \
    certonly --webroot -w /var/www/certbot -d excvaluta.com \
    --email admin@excvaluta.com --agree-tos --no-eff-email

# Nginx atkapcsolas SSL-re
cp nginx/nginx.conf.ssl-backup nginx/nginx.conf
docker compose -f docker-compose.prod.yml restart nginx
```

### 4. Ellenorzes

```bash
# Health check
curl -s https://excvaluta.com/actuator/health
# Elvart: {"status":"UP"}

# Backend logok
docker compose -f docker-compose.prod.yml logs -f valuta-backend
```

## Adatmigracio (Render -> Hetzner)

**FONTOS: A Render backend-et LE KELL allitani a dump elott!**

```bash
# 1. Render backend leallitasa (Render Dashboard -> Manual Deploy -> Suspend)

# 2. pg_dump a Render DB-bol
# (Render Dashboard -> Database -> External Connection -> Connection string)
pg_dump "CONNECTION_STRING_FROM_RENDER" | gzip > render_dump.sql.gz

# 3. Restore a Hetzner DB-be
source /opt/valuta/.env
gunzip -c render_dump.sql.gz | docker compose -f docker-compose.prod.yml exec -T postgres \
    psql -U "${DB_USER}" valuta

# 4. Ellenorzes
docker compose -f docker-compose.prod.yml exec postgres \
    psql -U "${DB_USER}" -d valuta -c "SELECT count(*) FROM transactions;"
```

## Napi uzemeltetes

```bash
# Logok megtekintese
docker compose -f docker-compose.prod.yml logs -f valuta-backend --tail=100

# Ujrainditas
docker compose -f docker-compose.prod.yml restart valuta-backend

# Frissites (uj verzio deploy)
cd /opt/valuta-repo && git pull
cp -r backend/ /opt/valuta/backend/
cd /opt/valuta
docker compose -f docker-compose.prod.yml build valuta-backend
docker compose -f docker-compose.prod.yml up -d valuta-backend

# Manualis backup
/opt/valuta/scripts/backup.sh

# Backup restore
source /opt/valuta/.env
gunzip -c /backups/valuta/valuta_YYYYMMDD_HHMMSS.sql.gz | \
    docker compose -f docker-compose.prod.yml exec -T postgres psql -U "${DB_USER}" valuta
```

## Monitoring

- **UptimeRobot:** `https://excvaluta.com/actuator/health` (5 perces intervallum)
- **Logok:** `docker compose -f docker-compose.prod.yml logs -f valuta-backend`
- **Backup log:** `tail -f /var/log/valuta-backup.log`
- **Disk:** `df -h /`

## Rollback (ha valami nem mukodik)

1. Render backend ujrainditasa (Render Dashboard)
2. DNS `excvaluta.com` visszairanyitas Render-re
3. Frontend VITE_API_URL visszaallitas
