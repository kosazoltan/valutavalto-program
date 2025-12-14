# Domain Beállítás: excbesttest.com

## DNS Beállítások

A domain DNS beállításainál állítsd be az alábbi A rekordokat:

```
A    @          ->  YOUR_VPS_IP
A    www        ->  YOUR_VPS_IP
```

## Telepítés Domain-nel

### Automatikus telepítés SSL-lel:

```bash
cd /var/www/valutavalto
chmod +x deployment/install-with-domain.sh
sudo ./deployment/install-with-domain.sh
```

### Vagy lépésről lépésre:

1. **Telepítés domain névvel:**
```bash
sudo ./deployment/install.sh excbesttest.com
```

2. **SSL tanúsítvány telepítése:**
```bash
sudo certbot --nginx -d excbesttest.com -d www.excbesttest.com
```

3. **Ellenőrzés:**
```bash
# Nginx konfiguráció teszt
sudo nginx -t

# SSL tanúsítvány ellenőrzése
sudo certbot certificates
```

## Elérés

Miután a DNS beállítások propagálódtak (általában 5-30 perc):

- **HTTPS (ajánlott):** https://excbesttest.com
- **HTTPS (www):** https://www.excbesttest.com
- **HTTP (átirányítva HTTPS-re):** http://excbesttest.com

## SSL Tanúsítvány Megújítás

A Let's Encrypt tanúsítvány automatikusan megújul, de ellenőrizheted:

```bash
# Teszt megújítás
sudo certbot renew --dry-run

# Kézi megújítás (ha szükséges)
sudo certbot renew
```

## Nginx Konfiguráció

A Nginx konfiguráció automatikusan frissül a certbot által az SSL beállításokkal.

A fájl helye: `/etc/nginx/sites-available/valutavalto`

## Troubleshooting

### DNS nem működik

```bash
# DNS ellenőrzés
dig excbesttest.com
nslookup excbesttest.com

# Várj 5-30 percet a DNS propagációra
```

### SSL tanúsítvány hiba

```bash
# Certbot logok
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Nginx logok
sudo tail -f /var/log/nginx/valutavalto-error.log
```

### Port 80/443 nem elérhető

```bash
# Firewall ellenőrzés
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Hetzner Firewall: állítsd be a Cloud Console-ban
```

