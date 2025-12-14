# Hostinger DNS Beállítások - excbesttest.com

## DNS Rekordok Beállítása Hostinger-ben

### 1. Bejelentkezés a Hostinger Control Panel-be

1. Menj a [Hostinger Control Panel](https://hpanel.hostinger.com/)-be
2. Jelentkezz be a fiókodba
3. Válaszd ki a **Domains** menüpontot

### 2. DNS Zóna Módosítása

1. Keress rá az **excbesttest.com** domain-re
2. Kattints a **Manage** vagy **DNS Zone Editor** gombra
3. Vagy menj a **Advanced** → **DNS Zone Editor** menüpontra

### 3. A Rekordok Hozzáadása/Módosítása

Az alábbi A rekordokat add hozzá vagy módosítsd:

#### Fő domain (excbesttest.com):
```
Type: A
Name: @ (vagy üres)
Value: YOUR_VPS_IP
TTL: 3600 (vagy Auto)
```

#### www subdomain:
```
Type: A
Name: www
Value: YOUR_VPS_IP
TTL: 3600 (vagy Auto)
```

### 4. Meglévő Rekordok Kezelése

Ha már vannak rekordok (pl. Hostinger alapértelmezett rekordok):

1. **Törölheted** a következő típusú rekordokat (ha vannak):
   - `A` rekordok, amelyek más IP-t mutatnak
   - `CNAME` rekordok a www-re (ha A rekordot használsz)

2. **Megtarthatod** (ha szükséges):
   - `MX` rekordok (email)
   - `TXT` rekordok (SPF, DKIM, stb.)
   - `NS` rekordok (névszolgáltatók)

### 5. VPS IP Cím Megkeresése

Ha nem tudod a VPS IP címedet:

```bash
# SSH-vel kapcsolódj a VPS-hez
ssh root@YOUR_VPS_IP

# IP cím ellenőrzése
hostname -I
# vagy
ip addr show
```

### 6. DNS Propagáció Várakozás

Miután beállítottad a DNS rekordokat:

1. **Várj 5-30 percet** a DNS propagációra
2. Ellenőrizd a DNS propagációt:

```bash
# Windows PowerShell
nslookup excbesttest.com
nslookup www.excbesttest.com

# Linux/Mac
dig excbesttest.com
dig www.excbesttest.com
```

Vagy online eszközökkel:
- https://www.whatsmydns.net/#A/excbesttest.com
- https://dnschecker.org/#A/excbesttest.com

### 7. VPS Telepítés (Miután a DNS propagálódott)

```bash
cd /var/www/valutavalto
git pull origin main
chmod +x deployment/install-with-domain.sh
sudo ./deployment/install-with-domain.sh
```

## Részletes Lépések Képernyőképekkel

### Hostinger DNS Zone Editor Elérése:

1. **Login** → **Domains** → **excbesttest.com**
2. Kattints a **Manage** gombra
3. Válaszd a **Advanced** fület
4. Kattints a **DNS Zone Editor**-re

### Rekord Hozzáadása:

1. Kattints az **Add Record** vagy **+** gombra
2. Válaszd ki a **Type: A**
3. **Name:** `@` vagy üresen hagyd (fő domain)
4. **Points to:** Add meg a VPS IP címedet
5. **TTL:** 3600 (vagy Auto)
6. Kattints a **Save** vagy **Add** gombra

7. Ismételd meg a www subdomain-hoz:
   - **Type:** A
   - **Name:** `www`
   - **Points to:** Ugyanaz a VPS IP
   - **TTL:** 3600

## Troubleshooting

### A domain nem mutat a VPS-re

1. **Ellenőrizd a DNS rekordokat:**
   ```bash
   nslookup excbesttest.com
   ```
   Az eredménynek a VPS IP címedet kell mutatnia.

2. **Töröld a böngésző cache-t** vagy használj Incognito módot

3. **Várj tovább** - néha 1-2 óra is eltarthat

### SSL tanúsítvány nem telepíthető

Ha a certbot hibát ad, ellenőrizd:

1. **DNS propagáció:**
   ```bash
   dig excbesttest.com
   ```

2. **Port 80 elérhető:**
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   ```

3. **Nginx fut:**
   ```bash
   sudo systemctl status nginx
   ```

### Hostinger Email Szolgáltatás

Ha email-t is használsz a domain-en:

- **Ne töröld** az MX rekordokat!
- Az email továbbra is működni fog a Hostinger email szolgáltatással
- Csak a weboldal (HTTP/HTTPS) forgalom megy a VPS-re

## Kapcsolódó Fájlok

- `deployment/DOMAIN_SETUP.md` - Általános domain beállítás
- `deployment/install-with-domain.sh` - Telepítési script
- `deployment/README.md` - Teljes telepítési útmutató

