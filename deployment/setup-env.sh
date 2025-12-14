#!/bin/bash
# .env fájl létrehozása a VPS-en

PROJECT_DIR="/var/www/valutavalto"
ENV_FILE="$PROJECT_DIR/.env"

echo "=========================================="
echo "Environment változók beállítása"
echo "=========================================="

# Kérdések
read -p "Adatbázis host [localhost]: " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Adatbázis port [5432]: " DB_PORT
DB_PORT=${DB_PORT:-5432}

read -p "Adatbázis név [valuta]: " DB_NAME
DB_NAME=${DB_NAME:-valuta}

read -p "Adatbázis felhasználó [valuta_user]: " DB_USERNAME
DB_USERNAME=${DB_USERNAME:-valuta_user}

read -sp "Adatbázis jelszó: " DB_PASSWORD
echo ""

read -p "Backend port [8080]: " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-8080}

read -sp "JWT secret (vagy Enter a default-ért): " JWT_SECRET
JWT_SECRET=${JWT_SECRET:-DefaultSecretKeyForDevelopmentOnlyChangeInProduction123456}
echo ""

read -p "JWT expiration (ms) [86400000]: " JWT_EXPIRATION
JWT_EXPIRATION=${JWT_EXPIRATION:-86400000}

read -p "SSL engedélyezve? (true/false) [false]: " DB_SSL
DB_SSL=${DB_SSL:-false}

read -p "SSL mode [prefer]: " DB_SSLMODE
DB_SSLMODE=${DB_SSLMODE:-prefer}

# JDBC URL összeállítása
if [ "$DB_SSL" = "true" ]; then
    DATABASE_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"
else
    DATABASE_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
fi

# .env fájl létrehozása
cat > "$ENV_FILE" <<EOF
# Database Configuration
DATABASE_URL=$DATABASE_URL
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_SSL=$DB_SSL
DB_SSLMODE=$DB_SSLMODE

# Server Configuration
SERVER_PORT=$SERVER_PORT

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRATION=$JWT_EXPIRATION
EOF

chmod 600 "$ENV_FILE"
chown $SUDO_USER:$SUDO_USER "$ENV_FILE"

echo ""
echo "✓ .env fájl létrehozva: $ENV_FILE"
echo ""
echo "Tartalom:"
cat "$ENV_FILE" | sed 's/\(PASSWORD\|SECRET\)=.*/\1=***/'
echo ""

