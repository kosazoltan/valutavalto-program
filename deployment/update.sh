#!/bin/bash
# Gyors frissítési script (deploy)

set -e

PROJECT_DIR="/var/www/valutavalto"

echo "=========================================="
echo "Valuta Váltó Program Frissítése"
echo "=========================================="

cd "$PROJECT_DIR"

# Git pull
echo "Kód frissítése..."
git pull origin main

# Backend build
echo "Backend build..."
cd backend
mvn clean package -DskipTests

# Frontend build
echo "Frontend build..."
cd ../frontend-react
npm install
npm run build

# Backend újraindítás
echo "Backend újraindítása..."
sudo systemctl restart valutavalto-backend

# Nginx újratöltése
echo "Nginx újratöltése..."
sudo systemctl reload nginx

echo ""
echo "✓ Frissítés befejezve!"
echo ""
echo "Státusz ellenőrzése:"
sudo systemctl status valutavalto-backend --no-pager -l

