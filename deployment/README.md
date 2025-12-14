# VPS Telepítési Útmutató

Ez az útmutató bemutatja, hogyan telepítsd a Valuta Váltó programot egy VPS-re, hogy messziről elérhető legyen.

## Előfeltételek

- Hetzner VPS (vagy más VPS szolgáltató)
- Ubuntu 20.04+ vagy Debian 11+
- Root hozzáférés
- Domain név (opcionális, SSL-hez)

## Telepítési Lépések

### 1. VPS kapcsolat

```bash
ssh root@YOUR_VPS_IP
```

### 2. Projekt klónozása

```bash
cd /var/www
git clone https://github.com/kosazoltan/valutavalto-program.git valutavalto
cd valutavalto
```

### 3. Telepítési script futtatása

```bash
chmod +x deployment/install.sh

# Domain nélkül (IP címmel)
sudo ./deployment/install.sh

# Domain-nel (SSL-lel)
sudo ./deployment/install.sh valuta.example.com
```

### 4. Environment változók beállítása

```bash
chmod +x deployment/setup-env.sh
sudo ./deployment/setup-env.sh
```

Vagy manuálisan szerkeszd a `.env` fájlt:

```bash
nano /var/www/valutavalto/.env
```

### 5. Adatbázis séma importálása

```bash
# Ha még nincs séma, exportáld először lokálisan:
# .\scripts\export-database-schema-only.ps1

# Majd importáld a VPS-re:
sudo -u postgres psql -d valuta -f /var/www/valutavalto/database/schema/valuta_schema.sql
```

### 6. Backend indítása

```bash
sudo systemctl start valutavalto-backend
sudo systemctl status valutavalto-backend
```

### 7. Szolgáltatások ellenőrzése

```bash
# Backend státusz
sudo systemctl status valutavalto-backend

# Nginx státusz
sudo systemctl status nginx

# Portok ellenőrzése
sudo netstat -tlnp | grep -E '(80|443|8080)'
```

## SSL Tanúsítvány (Let's Encrypt)

Ha domain neved van:

```bash
sudo certbot --nginx -d valuta.example.com
```

A tanúsítvány automatikusan megújul 90 naponként.

## Hasznos Parancsok

### Backend kezelés

```bash
# Indítás
sudo systemctl start valutavalto-backend

# Leállítás
sudo systemctl stop valutavalto-backend

# Újraindítás
sudo systemctl restart valutavalto-backend

# Státusz
sudo systemctl status valutavalto-backend

# Logok
sudo journalctl -u valutavalto-backend -f
```

### Nginx kezelés

```bash
# Újraindítás
sudo systemctl restart nginx

# Konfiguráció tesztelése
sudo nginx -t

# Logok
sudo tail -f /var/log/nginx/valutavalto-*.log
```

### Frissítés (Deploy)

```bash
cd /var/www/valutavalto

# Kód frissítése
git pull origin main

# Backend újra build-elése
cd backend
mvn clean package -DskipTests

# Frontend újra build-elése
cd ../frontend-react
npm install
npm run build

# Backend újraindítása
sudo systemctl restart valutavalto-backend

# Nginx újraindítása (általában nem kell)
sudo systemctl reload nginx
```

## Hálózati Beállítások

### Firewall (UFW)

```bash
# Portok megnyitása
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp # HTTPS

# Státusz
sudo ufw status
```

### Hetzner Firewall

Ha Hetzner VPS-et használsz, be kell állítanod a Firewall szabályokat a Hetzner Cloud Console-ban:

1. Nyisd meg a Hetzner Cloud Console-t
2. Válaszd ki a VPS-edet
3. Menj a "Firewalls" fülre
4. Adj hozzá egy új firewall szabályt:
   - SSH: Port 22, TCP
   - HTTP: Port 80, TCP
   - HTTPS: Port 443, TCP

## Hibakeresés

### Backend nem indul el

```bash
# Logok ellenőrzése
sudo journalctl -u valutavalto-backend -n 50

# Java verzió ellenőrzése
java -version

# Port ellenőrzése (8080 foglalt-e)
sudo netstat -tlnp | grep 8080
```

### Frontend nem töltődik be

```bash
# Nginx logok
sudo tail -f /var/log/nginx/valutavalto-error.log

# Build ellenőrzése
ls -la /var/www/valutavalto/frontend-react/dist

# Nginx konfiguráció tesztelése
sudo nginx -t
```

### Adatbázis kapcsolat hiba

```bash
# PostgreSQL státusz
sudo systemctl status postgresql

# Kapcsolat tesztelése
sudo -u postgres psql -d valuta -c "SELECT version();"

# .env fájl ellenőrzése
cat /var/www/valutavalto/.env
```

## Biztonsági Megjegyzések

1. **JWT Secret**: Változtasd meg az alapértelmezett JWT secret-et éles környezetben!
2. **Adatbázis jelszó**: Használj erős jelszót
3. **Firewall**: Csak a szükséges portokat nyisd meg
4. **SSL**: Mindig használj SSL-t éles környezetben
5. **Backup**: Állíts be rendszeres adatbázis backup-ot

## Elérés

- **HTTP**: `http://YOUR_VPS_IP` vagy `http://valuta.example.com`
- **HTTPS**: `https://valuta.example.com` (ha SSL be van állítva)
- **API**: `http://YOUR_VPS_IP/api` vagy `https://valuta.example.com/api`
- **Swagger UI**: `http://YOUR_VPS_IP/swagger-ui.html`

## Támogatás

Ha problémád van a telepítéssel, ellenőrizd:
1. A logokat (lásd fent)
2. A firewall beállításokat
3. A DNS beállításokat (ha domain-t használsz)
4. A portok elérhetőségét

