#!/bin/bash
# Valuta Váltó program telepítési script VPS-re
# Használat: sudo ./install.sh

set -e

echo "=========================================="
echo "Valuta Váltó Program Telepítése"
echo "=========================================="

# Színkódok
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Változók
PROJECT_DIR="/var/www/valutavalto"
DOMAIN="${1:-}"  # Opcionális domain név argumentumként

# Ellenőrzések
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Kérlek futtasd root-ként: sudo ./install.sh${NC}"
    exit 1
fi

# 1. Rendszer frissítés
echo -e "${GREEN}[1/10] Rendszer frissítése...${NC}"
apt update && apt upgrade -y

# 2. Szükséges csomagok telepítése
echo -e "${GREEN}[2/10] Szükséges csomagok telepítése...${NC}"
apt install -y \
    openjdk-21-jdk \
    maven \
    nginx \
    postgresql \
    postgresql-contrib \
    git \
    curl \
    certbot \
    python3-certbot-nginx \
    ufw

# 3. Java verzió ellenőrzés
echo -e "${GREEN}[3/10] Java verzió ellenőrzése...${NC}"
java -version || { echo -e "${RED}Java telepítése sikertelen!${NC}"; exit 1; }

# 4. Projekt könyvtár létrehozása
echo -e "${GREEN}[4/10] Projekt könyvtár létrehozása...${NC}"
mkdir -p $PROJECT_DIR
chown -R $SUDO_USER:$SUDO_USER $PROJECT_DIR

# 5. Git repository klónozása (ha még nincs)
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo -e "${YELLOW}Git repository nincs klónozva. Kérlek klónozd manuálisan:${NC}"
    echo "cd $PROJECT_DIR && git clone https://github.com/kosazoltan/valutavalto-program.git ."
    read -p "Nyomj Enter-t a folytatáshoz, miután klónoztad..."
fi

# 6. PostgreSQL adatbázis beállítása
echo -e "${GREEN}[5/10] PostgreSQL adatbázis beállítása...${NC}"
sudo -u postgres psql <<EOF
-- Adatbázis létrehozása
CREATE DATABASE valuta;

-- Felhasználó létrehozása
CREATE USER valuta_user WITH PASSWORD 'valuta_pass';
ALTER USER valuta_user CREATEDB;

-- Jogosultságok
GRANT ALL PRIVILEGES ON DATABASE valuta TO valuta_user;

-- Ha még nincs séma, importáld
-- \c valuta
-- \i $PROJECT_DIR/database/schema/valuta_schema.sql
EOF

echo -e "${YELLOW}PostgreSQL adatbázis létrehozva.${NC}"
echo -e "${YELLOW}Ha szükséges, importáld a sémát:${NC}"
echo "sudo -u postgres psql -d valuta -f $PROJECT_DIR/database/schema/valuta_schema.sql"

# 7. Backend build
echo -e "${GREEN}[6/10] Backend build...${NC}"
cd $PROJECT_DIR/backend
mvn clean package -DskipTests || { echo -e "${RED}Backend build sikertelen!${NC}"; exit 1; }

# 8. Frontend build
echo -e "${GREEN}[7/10] Frontend build...${NC}"
cd $PROJECT_DIR/frontend-react
npm install || { echo -e "${RED}npm install sikertelen!${NC}"; exit 1; }
npm run build || { echo -e "${RED}Frontend build sikertelen!${NC}"; exit 1; }

# 9. Nginx konfiguráció
echo -e "${GREEN}[8/10] Nginx konfiguráció beállítása...${NC}"
cp $PROJECT_DIR/deployment/nginx.conf /etc/nginx/sites-available/valutavalto

# Domain név beállítása, ha megadták
if [ -n "$DOMAIN" ]; then
    sed -i "s/server_name _;/server_name $DOMAIN;/g" /etc/nginx/sites-available/valutavalto
fi

# Link létrehozása
ln -sf /etc/nginx/sites-available/valutavalto /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default  # Töröld az alapértelmezettet

# Nginx teszt és újraindítás
nginx -t && systemctl reload nginx

# 10. Systemd service beállítása
echo -e "${GREEN}[9/10] Systemd service beállítása...${NC}"
cp $PROJECT_DIR/deployment/backend.service /etc/systemd/system/valutavalto-backend.service
systemctl daemon-reload
systemctl enable valutavalto-backend.service

# 11. Firewall beállítása
echo -e "${GREEN}[10/10] Firewall beállítása...${NC}"
ufw allow 22/tcp  # SSH
ufw allow 80/tcp  # HTTP
ufw allow 443/tcp # HTTPS
ufw --force enable

# 12. SSL tanúsítvány (opcionális, ha domain van)
if [ -n "$DOMAIN" ]; then
    echo -e "${GREEN}[11/11] SSL tanúsítvány telepítése (Let's Encrypt)...${NC}"
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN || {
        echo -e "${YELLOW}SSL tanúsítvány telepítése sikertelen. Futtasd kézzel:${NC}"
        echo "certbot --nginx -d $DOMAIN"
    }
fi

# Összefoglaló
echo ""
echo -e "${GREEN}=========================================="
echo "Telepítés befejezve!"
echo "==========================================${NC}"
echo ""
echo "Következő lépések:"
echo "1. Állítsd be a .env fájlt: $PROJECT_DIR/.env"
echo "2. Importáld az adatbázis sémát (ha még nem tetted):"
echo "   sudo -u postgres psql -d valuta -f $PROJECT_DIR/database/schema/valuta_schema.sql"
echo "3. Indítsd el a backend szolgáltatást:"
echo "   sudo systemctl start valutavalto-backend"
echo "4. Ellenőrizd a státuszt:"
echo "   sudo systemctl status valutavalto-backend"
echo "   sudo systemctl status nginx"
echo ""
if [ -n "$DOMAIN" ]; then
    echo "Az alkalmazás elérhető: http://$DOMAIN"
else
    echo "Az alkalmazás elérhető: http://$(hostname -I | awk '{print $1}')"
fi
echo ""
echo "Logok:"
echo "  Backend: sudo journalctl -u valutavalto-backend -f"
echo "  Nginx: sudo tail -f /var/log/nginx/valutavalto-*.log"
echo ""

