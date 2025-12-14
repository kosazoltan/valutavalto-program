# Hibaelhárítási Útmutató

## Általános Hibák

### Backend nem indul el

**Tünet:** `sudo systemctl status valutavalto-backend` hibát mutat

**Megoldás:**
```bash
# Logok ellenőrzése
sudo journalctl -u valutavalto-backend -n 50

# Gyakori okok:
# 1. Adatbázis nem elérhető
sudo systemctl status postgresql
sudo -u postgres psql -d valuta -c "SELECT 1;"

# 2. Port foglalt
sudo netstat -tlnp | grep 8080

# 3. .env fájl hiányzik vagy hibás
cat /var/www/valutavalto/.env

# 4. Java nincs telepítve
java -version
```

### Frontend nem töltődik be

**Tünet:** 404 vagy üres oldal

**Megoldás:**
```bash
# Nginx logok
sudo tail -f /var/log/nginx/valutavalto-error.log

# Frontend build ellenőrzése
ls -la /var/www/valutavalto/frontend-react/dist

# Ha nincs dist, rebuild:
cd /var/www/valutavalto/frontend-react
npm install
npm run build

# Nginx újratöltése
sudo systemctl reload nginx
```

### SSL tanúsítvány hiba

**Tünet:** `certbot` hibát ad

**Megoldás:**
```bash
# DNS ellenőrzés
dig excbesttest.com
nslookup excbesttest.com

# Port 80 elérhetőség
sudo ufw status
sudo ufw allow 80/tcp

# Nginx fut
sudo systemctl status nginx

# Certbot logok
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Kézi certbot futtatás részletes output-tal
sudo certbot --nginx -d excbesttest.com -d www.excbesttest.com --verbose
```

### Adatbázis kapcsolat hiba

**Tünet:** Backend nem tud csatlakozni az adatbázishoz

**Megoldás:**
```bash
# PostgreSQL fut?
sudo systemctl status postgresql

# Adatbázis létezik?
sudo -u postgres psql -l | grep valuta

# Kapcsolat tesztelése
sudo -u postgres psql -d valuta -c "SELECT version();"

# .env ellenőrzése
cat /var/www/valutavalto/.env | grep DB_

# Ha Neon PostgreSQL-t használsz, ellenőrizd:
# - SSL beállítások
# - Kapcsolati string
# - Firewall szabályok
```

### DNS nem működik

**Tünet:** Domain nem mutat a VPS-re

**Megoldás:**
```bash
# DNS propagáció ellenőrzése
dig excbesttest.com
nslookup excbesttest.com

# Online ellenőrzés
# https://www.whatsmydns.net/#A/excbesttest.com

# Ha még mindig nem jó:
# 1. Várj tovább (akár 1-2 óra)
# 2. Ellenőrizd a Hostinger DNS beállításokat
# 3. Töröld a böngésző cache-t
```

### 502 Bad Gateway

**Tünet:** Nginx 502 hibát ad

**Megoldás:**
```bash
# Backend fut?
sudo systemctl status valutavalto-backend

# Backend logok
sudo journalctl -u valutavalto-backend -n 50

# Port 8080 elérhető?
sudo netstat -tlnp | grep 8080

# Nginx proxy beállítások ellenőrzése
sudo nginx -t
cat /etc/nginx/sites-available/valutavalto | grep proxy_pass
```

### 503 Service Unavailable

**Tünet:** Szolgáltatás nem elérhető

**Megoldás:**
```bash
# Minden szolgáltatás fut?
sudo systemctl status valutavalto-backend
sudo systemctl status nginx
sudo systemctl status postgresql

# Restart minden szolgáltatás
sudo systemctl restart valutavalto-backend
sudo systemctl restart nginx
sudo systemctl restart postgresql
```

## Teljesítmény Problémák

### Lassú válaszidő

**Megoldás:**
```bash
# Adatbázis kapcsolatok ellenőrzése
sudo -u postgres psql -d valuta -c "SELECT count(*) FROM pg_stat_activity;"

# Nginx logok (lassú kérések)
sudo tail -f /var/log/nginx/valutavalto-access.log

# Backend memória használat
free -h
ps aux | grep java

# Ha szükséges, növeld a Java heap size-t:
# Szerkeszd: /etc/systemd/system/valutavalto-backend.service
# ExecStart=/usr/bin/java -Xmx2g -jar ...
```

### Túl sok memória használat

**Megoldás:**
```bash
# Java heap size csökkentése
sudo nano /etc/systemd/system/valutavalto-backend.service
# Módosítsd: -Xmx512m (512MB heap)
sudo systemctl daemon-reload
sudo systemctl restart valutavalto-backend
```

## Biztonsági Problémák

### JWT secret default

**Tünet:** Alapértelmezett JWT secret használata

**Megoldás:**
```bash
# .env fájl szerkesztése
sudo nano /var/www/valutavalto/.env
# Változtasd meg: JWT_SECRET=erős_random_string_itt

# Backend újraindítása
sudo systemctl restart valutavalto-backend
```

### Portok nem védettek

**Megoldás:**
```bash
# Firewall beállítása
sudo ufw status
sudo ufw enable
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
```

## Telepítési Hibák

### Maven build hiba

**Megoldás:**
```bash
# Java verzió ellenőrzése (Java 21 kell)
java -version

# Maven verzió
mvn --version

# Tiszta build
cd /var/www/valutavalto/backend
mvn clean
mvn package -DskipTests
```

### NPM build hiba

**Megoldás:**
```bash
# Node.js verzió (v18+ kell)
node --version
npm --version

# node_modules törlése és újratelepítés
cd /var/www/valutavalto/frontend-react
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Permission denied hibák

**Megoldás:**
```bash
# Jogosultságok javítása
sudo chown -R www-data:www-data /var/www/valutavalto
sudo chmod +x deployment/*.sh
```

## Kapcsolódó Fájlok

- `deployment/README.md` - Telepítési útmutató
- `deployment/CHECKLIST.md` - Telepítési checklist
- `deployment/HOSTINGER_DNS_SETUP.md` - DNS beállítások

## További Segítség

Ha a fenti megoldások nem segítenek:

1. **Logok gyűjtése:**
   ```bash
   # Backend
   sudo journalctl -u valutavalto-backend > backend.log
   
   # Nginx
   sudo tail -100 /var/log/nginx/valutavalto-error.log > nginx-error.log
   sudo tail -100 /var/log/nginx/valutavalto-access.log > nginx-access.log
   ```

2. **Rendszer információ:**
   ```bash
   uname -a
   java -version
   mvn --version
   node --version
   npm --version
   sudo systemctl list-units --type=service | grep -E '(nginx|postgresql|valutavalto)'
   ```

3. **GitHub Issues:** Ha problémád van, nyiss egy issue-t a GitHub repository-ban

