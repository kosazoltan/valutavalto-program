# Telepítés Most - Lépésről Lépésre Útmutató

## 1. VPS SSH Kapcsolat

Ha még nincs SSH kapcsolatod:

```bash
ssh root@YOUR_VPS_IP
```

Ahol `YOUR_VPS_IP` a VPS-ed IP címe.

## 2. Projekt Klónozása

```bash
cd /var/www
git clone https://github.com/kosazoltan/valutavalto-program.git valutavalto
cd valutavalto
```

## 3. Telepítés Futtatása

```bash
# Jogosultságok
chmod +x deployment/*.sh

# Telepítés domain-nel és SSL-lel
sudo ./deployment/install-with-domain.sh
```

Ez a script:
- Telepíti az összes szükséges csomagot
- Build-eli a backend-et és frontend-et
- Beállítja a Nginx-et
- Telepíti az SSL tanúsítványt
- Elindítja a szolgáltatásokat

## 4. Environment Beállítása

```bash
sudo ./deployment/setup-env.sh
```

Vagy manuálisan szerkeszd a `.env` fájlt:

```bash
sudo nano /var/www/valutavalto/.env
```

## 5. Adatbázis Séma Importálása

```bash
# Ha lokális PostgreSQL-t használsz
sudo -u postgres psql -d valuta -f database/schema/valuta_schema.sql

# Ha Neon PostgreSQL-t használsz, a .env fájlban állítsd be a connection string-et
```

## 6. Backend Indítása

```bash
sudo systemctl start valutavalto-backend
sudo systemctl status valutavalto-backend
```

## 7. Ellenőrzés

```bash
# Backend fut?
sudo systemctl status valutavalto-backend

# Nginx fut?
sudo systemctl status nginx

# Portok nyitva?
sudo ufw status
```

## 8. Webes Elérés

Nyisd meg böngészőben:
- **HTTPS:** https://excbesttest.com
- **API:** https://excbesttest.com/api
- **Swagger:** https://excbesttest.com/swagger-ui.html

## Hibák esetén

Nézd meg: `deployment/TROUBLESHOOTING.md`

## Teljes Telepítési Script (Copy-Paste)

```bash
#!/bin/bash
# Teljes telepítési script - copy-paste és futtasd

# 1. Projekt klónozása
cd /var/www
git clone https://github.com/kosazoltan/valutavalto-program.git valutavalto
cd valutavalto

# 2. Jogosultságok
chmod +x deployment/*.sh

# 3. Telepítés
sudo ./deployment/install-with-domain.sh

# 4. Environment beállítása
sudo ./deployment/setup-env.sh

# 5. Adatbázis séma importálása (lokális PostgreSQL esetén)
sudo -u postgres psql -d valuta -f database/schema/valuta_schema.sql

# 6. Backend indítása
sudo systemctl start valutavalto-backend

# 7. Státusz ellenőrzése
sudo systemctl status valutavalto-backend
sudo systemctl status nginx

echo "Telepítés kész! Nyisd meg: https://excbesttest.com"
```

