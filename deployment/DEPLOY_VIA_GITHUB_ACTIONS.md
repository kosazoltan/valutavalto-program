# Telepítés GitHub Actions-szal

A legegyszerűbb módszer a telepítéshez, ha a GitHub Actions workflow-t használod, ami automatikusan hozzáfér a GitHub Secrets-hez.

## Előfeltételek

✅ **GitHub Secrets beállítva:**
- `HETZNER_SSH_PRIVATE_KEY` - SSH private key
- `HETZNER_SERVER_IP` - VPS IP cím
- `HETZNER_SSH_USER` - SSH felhasználó (általában: root)
- `DB_USERNAME` - Adatbázis felhasználó (opcionális)
- `DB_PASSWORD` - Adatbázis jelszó (opcionális)
- `DB_NAME` - Adatbázis név (opcionális)

## Telepítés Lépései

### 1. GitHub Actions Workflow Indítása

1. **Menj a GitHub repository Actions oldalára:**
   ```
   https://github.com/kosazoltan/valutavalto-program/actions
   ```

2. **Válaszd ki a workflow-t:**
   - Kattints a bal oldali menüben a **"Deploy to Hetzner VPS"** workflow-ra

3. **Indítsd el a workflow-t:**
   - Kattints a **"Run workflow"** gombra (jobb felső sarok)
   - Válaszd ki a **"main"** branch-et
   - Kattints a zöld **"Run workflow"** gombra

### 2. Workflow Futtatás Követése

A workflow automatikusan:

1. ✅ **SSH kapcsolat létrehozása** a VPS-hez
2. ✅ **Adatbázis séma deploy** (törlés + újraimportálás)
3. ✅ **Backend deploy** (git pull + build + restart)

### 3. VPS-en Manuális Lépések

Miután a workflow lefutott, SSH-zz be a VPS-re és végezd el:

```bash
# SSH kapcsolat
ssh root@YOUR_VPS_IP

# Projekt könyvtár
cd /var/www/valutavalto

# Ha még nincs klónozva, klónozd:
git clone https://github.com/kosazoltan/valutavalto-program.git .

# Telepítési script futtatása
chmod +x deployment/*.sh
sudo ./deployment/install-with-domain.sh

# Environment beállítása
sudo ./deployment/setup-env.sh

# Backend indítása
sudo systemctl start valutavalto-backend
```

## GitHub Secrets Ellenőrzése

Ha nem vagy biztos benne, hogy a secrets be vannak-e állítva:

1. **Menj a GitHub repository Settings oldalára:**
   ```
   https://github.com/kosazoltan/valutavalto-program/settings/secrets/actions
   ```

2. **Ellenőrizd, hogy ezek a secrets léteznek:**
   - `HETZNER_SSH_PRIVATE_KEY`
   - `HETZNER_SERVER_IP`
   - `HETZNER_SSH_USER`

## Workflow Logok

A workflow futtatás után:

1. Kattints a futó/futott workflow-ra
2. Kattints a job-ra (pl: "deploy")
3. Nézd meg a lépések logjait

Ha hiba van, a logokban látszódni fog.

## Hibaelhárítás

### "Permission denied (publickey)"

**Ok:** Az SSH private key nem megfelelő vagy nincs beállítva

**Megoldás:**
- Ellenőrizd a `HETZNER_SSH_PRIVATE_KEY` secret-et
- A teljes private key-t tartalmaznia kell (BEGIN/END sorokkal)
- Ellenőrizd, hogy a public key hozzá van-e adva a Hetzner szerverhez

### "Connection timeout"

**Ok:** A VPS IP nem elérhető

**Megoldás:**
- Ellenőrizd a `HETZNER_SERVER_IP` secret értékét
- Teszteld: `ping YOUR_VPS_IP`
- Ellenőrizd a Hetzner Firewall beállításokat

### "Project directory not found"

**Ok:** A projekt még nincs klónozva a VPS-re

**Megoldás:**
- SSH-zz be a VPS-re
- Klónozd a projektet: `git clone https://github.com/kosazoltan/valutavalto-program.git /var/www/valutavalto`

## Alternatíva: Manuális Telepítés

Ha nem szeretnéd a GitHub Actions-t használni, lásd:
- `deployment/INSTALL_NOW.md` - Lépésről lépésre telepítés
- `deployment/README.md` - Részletes útmutató

