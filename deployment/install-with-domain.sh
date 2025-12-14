#!/bin/bash
# Telepítési script domain-nel (excbesttest.com)

DOMAIN="excbesttest.com"

echo "=========================================="
echo "Valuta Váltó Telepítése: $DOMAIN"
echo "=========================================="

# Telepítés domain-nel
./deployment/install.sh $DOMAIN

# SSL telepítése
echo ""
echo "=========================================="
echo "SSL Tanúsítvány Telepítése"
echo "=========================================="

# Certbot telepítése (ha még nincs)
if ! command -v certbot &> /dev/null; then
    apt install -y certbot python3-certbot-nginx
fi

# SSL tanúsítvány kérése
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ SSL tanúsítvány telepítve!"
    echo ""
    echo "Az alkalmazás elérhető:"
    echo "  https://$DOMAIN"
    echo "  https://www.$DOMAIN"
else
    echo ""
    echo "⚠ SSL tanúsítvány telepítése sikertelen."
    echo "Futtasd kézzel: certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi

echo ""
echo "=========================================="
echo "Telepítés befejezve!"
echo "=========================================="

