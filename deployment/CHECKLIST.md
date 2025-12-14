# Telepítési Checklist - excbesttest.com

## Előzetes Feladatok

### ✅ VPS előkészítés
- [ ] VPS rendelés (Hetzner vagy más)
- [ ] SSH hozzáférés biztosítva
- [ ] Root vagy sudo jogosultságok
- [ ] VPS IP cím megjegyezve

### ✅ Domain előkészítés
- [ ] Domain regisztrálva: excbesttest.com
- [ ] Domain szolgáltató: Hostinger
- [ ] Hostinger Control Panel hozzáférés

### ✅ DNS beállítások
- [ ] Hostinger DNS Zone Editor megnyitva
- [ ] A rekord hozzáadva: `@` → VPS_IP
- [ ] A rekord hozzáadva: `www` → VPS_IP
- [ ] DNS propagáció ellenőrizve (5-30 perc)
  ```bash
  nslookup excbesttest.com
  ```

## Telepítés VPS-en

### 1. Kapcsolódás
- [ ] SSH kapcsolat VPS-hez
  ```bash
  ssh root@VPS_IP
  ```

### 2. Projekt klónozása
- [ ] Projekt könyvtár létrehozva
  ```bash
  cd /var/www
  git clone https://github.com/kosazoltan/valutavalto-program.git valutavalto
  cd valutavalto
  ```

### 3. Telepítés futtatása
- [ ] Script jogosultságok beállítva
  ```bash
  chmod +x deployment/*.sh
  ```
- [ ] Telepítési script futtatva
  ```bash
  sudo ./deployment/install-with-domain.sh
  ```

### 4. Environment beállítás
- [ ] .env fájl létrehozva
  ```bash
  sudo ./deployment/setup-env.sh
  ```
- [ ] Adatbázis hitelesítő adatok beállítva
- [ ] JWT secret megváltoztatva (élesben!)

### 5. Adatbázis előkészítés
- [ ] PostgreSQL telepítve és fut
  ```bash
  sudo systemctl status postgresql
  ```
- [ ] Adatbázis séma importálva
  ```bash
  sudo -u postgres psql -d valuta -f database/schema/valuta_schema.sql
  ```

### 6. Szolgáltatások indítása
- [ ] Backend service indítva
  ```bash
  sudo systemctl start valutavalto-backend
  sudo systemctl status valutavalto-backend
  ```
- [ ] Nginx indítva
  ```bash
  sudo systemctl status nginx
  ```

### 7. SSL Tanúsítvány
- [ ] SSL tanúsítvány telepítve
  ```bash
  sudo certbot certificates
  ```
- [ ] HTTPS működik: https://excbesttest.com
- [ ] HTTP → HTTPS redirect működik

### 8. Firewall beállítás
- [ ] Port 22 (SSH) nyitva
- [ ] Port 80 (HTTP) nyitva
- [ ] Port 443 (HTTPS) nyitva
  ```bash
  sudo ufw status
  ```

## Ellenőrzés

### Funkcionalitás
- [ ] Főoldal betöltődik: https://excbesttest.com
- [ ] Frontend működik
- [ ] API elérhető: https://excbesttest.com/api
- [ ] Swagger UI elérhető: https://excbesttest.com/swagger-ui.html
- [ ] Bejelentkezés működik

### Biztonság
- [ ] HTTPS működik (zöld lakat)
- [ ] JWT secret változtatva (nem default)
- [ ] Adatbázis jelszó erős
- [ ] Firewall beállítva

### Logok
- [ ] Backend logok ellenőrizve
  ```bash
  sudo journalctl -u valutavalto-backend -f
  ```
- [ ] Nginx logok ellenőrizve
  ```bash
  sudo tail -f /var/log/nginx/valutavalto-*.log
  ```

## Post-Telepítés

### Optimalizálás
- [ ] SSL tanúsítvány auto-renewal működik
- [ ] Backend auto-restart beállítva (systemd)
- [ ] Log rotation beállítva

### Dokumentáció
- [ ] Dolgozók megkapták a hozzáférési URL-t
- [ ] Admin felhasználó létrehozva
- [ ] Használati útmutató elérhető

## Gyors Referencia

### Szolgáltatás kezelés
```bash
# Backend
sudo systemctl start/stop/restart/status valutavalto-backend

# Nginx
sudo systemctl start/stop/restart/reload nginx

# PostgreSQL
sudo systemctl start/stop/restart/status postgresql
```

### Logok
```bash
# Backend logok
sudo journalctl -u valutavalto-backend -f

# Nginx access log
sudo tail -f /var/log/nginx/valutavalto-access.log

# Nginx error log
sudo tail -f /var/log/nginx/valutavalto-error.log
```

### Frissítés
```bash
cd /var/www/valutavalto
sudo ./deployment/update.sh
```

### SSL megújítás
```bash
# Teszt
sudo certbot renew --dry-run

# Kézi
sudo certbot renew
```

## Hibaelhárítás

Ha valami nem működik, nézd meg:
1. `deployment/README.md` - Részletes telepítési útmutató
2. `deployment/HOSTINGER_DNS_SETUP.md` - DNS beállítások
3. `deployment/DOMAIN_SETUP.md` - Domain konfiguráció
4. Logok ellenőrzése (lásd fent)

