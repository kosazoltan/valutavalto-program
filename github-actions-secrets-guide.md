# GitHub Actions Secrets beállítása Hetzner VPS-hez

## Szükséges Secrets a GitHub-ban

A következő secrets-eket kell beállítanod a GitHub repository-ban:

### 1. HETZNER_SSH_PRIVATE_KEY

**Mi ez?** Az SSH private key tartalma (ami a Hetzner-hez való kapcsolódáshoz kell)

**Hol találod?**
- Fájl: `%USERPROFILE%\.ssh\id_rsa` (Windows)
- Fájl: `~/.ssh/id_rsa` (Linux/Mac)

**Hogyan másold ki?**

**Windows PowerShell:**
```powershell
Get-Content "$env:USERPROFILE\.ssh\id_rsa" | Out-String
```

**Linux/Mac:**
```bash
cat ~/.ssh/id_rsa
```

**Fontos:**
- ⚠️ A TELJES tartalmat másold be (beleértve a `-----BEGIN RSA PRIVATE KEY-----` és `-----END RSA PRIVATE KEY-----` sorokat)
- ⚠️ SOHA ne commitold ezt a fájlt!
- ⚠️ Csak GitHub Secrets-ben tárold!

### 2. HETZNER_SERVER_IP

**Mi ez?** A Hetzner VPS szerver IP címe

**Példa:**
```
123.45.67.89
```

vagy ha van domain neved:
```
valuta.example.com
```

### 3. HETZNER_SSH_USER

**Mi ez?** Az SSH felhasználónév a szerveren

**Általában:**
- `root` (alapértelmezett Hetzner VPS)
- vagy egy másik felhasználó, ha létrehoztál egyet

## GitHub Secrets beállítása lépésről lépésre

### 1. Nyisd meg a GitHub repository-t

1. Menj a GitHub repository oldalára
2. Kattints a **Settings** fülre
3. A bal oldali menüben kattints a **Secrets and variables** > **Actions** menüpontra

### 2. Adj hozzá új secret-et

1. Kattints a **New repository secret** gombra
2. **Name** mezőbe add meg a secret nevét (pl: `HETZNER_SSH_PRIVATE_KEY`)
3. **Secret** mezőbe másold be az értéket
4. Kattints a **Add secret** gombra

### 3. Ismételd meg mindhárom secret-re

**Secret 1: HETZNER_SSH_PRIVATE_KEY**
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA6qqmXp2mEPu6qrGQmVigv9zDeu2gTkGIFXFK2eajeSDaV1C/
... (a teljes private key tartalma) ...
-----END RSA PRIVATE KEY-----
```

**Secret 2: HETZNER_SERVER_IP**
```
123.45.67.89
```

**Secret 3: HETZNER_SSH_USER**
```
root
```

## SSH Private Key másolása (részletes)

### Windows PowerShell:

```powershell
# 1. Nyisd meg a PowerShell-t
# 2. Másold ki a private key tartalmát
Get-Content "$env:USERPROFILE\.ssh\id_rsa"

# Vagy vágólapra másoláshoz:
Get-Content "$env:USERPROFILE\.ssh\id_rsa" | Set-Clipboard
Write-Host "Private key copied to clipboard!" -ForegroundColor Green
```

### Linux/Mac:

```bash
# Private key tartalma
cat ~/.ssh/id_rsa

# Vagy vágólapra (Linux - xclip szükséges)
cat ~/.ssh/id_rsa | xclip -selection clipboard
```

## Workflow fájl

A projekt tartalmaz egy példa workflow fájlt: `.github/workflows/deploy-to-hetzner.yml`

Ez a workflow:
- Automatikusan lefut, amikor push történik a `main` vagy `master` branch-re
- Vagy manuálisan indítható (workflow_dispatch)
- SSH-n keresztül kapcsolódik a Hetzner VPS-hez
- Végrehajt deployment műveleteket

## További opcionális Secrets

Ha szükséged van további információkre:

### HETZNER_DEPLOY_PATH
A deployment útvonal a szerveren
```
/var/www/valutavalto
```

### HETZNER_DOCKER_COMPOSE_PATH
A docker-compose.yml fájl helye
```
/var/www/valutavalto/docker-compose.yml
```

### DATABASE_URL (ha szükséges)
Adatbázis kapcsolati string (ha nem SSH-n keresztül éred el)
```
postgresql://user:password@localhost:5432/valuta
```

## Biztonsági ellenőrzések

✅ **Ellenőrizd, hogy:**
- A private key NINCS a repository-ban
- A private key NINCS a `.gitignore`-ban (de a fájl maga már excluded)
- Csak a szükséges secrets-eket adtad meg
- A secrets értékei helyesek és teljesek

## Tesztelés

### 1. Lokális SSH teszt

Először teszteld lokálisan, hogy működik-e az SSH kapcsolat:

```bash
ssh root@YOUR_SERVER_IP
```

### 2. GitHub Actions teszt

1. Commitold és pushold a workflow fájlt
2. Menj a GitHub Actions fülre
3. Várd meg, hogy a workflow lefusson
4. Ellenőrizd a logokat

### 3. Manuális workflow indítás

1. Menj a **Actions** fülre
2. Válaszd ki a **Deploy to Hetzner VPS** workflow-t
3. Kattints a **Run workflow** gombra
4. Válaszd ki a branch-et
5. Kattints a zöld **Run workflow** gombra

## Hibaelhárítás

### "Permission denied (publickey)"

**Probléma:** Az SSH private key nem megfelelő vagy nincs beállítva helyesen

**Megoldás:**
- Ellenőrizd, hogy a `HETZNER_SSH_PRIVATE_KEY` secret tartalmazza a TELJES private key-t (beleértve a BEGIN/END sorokat)
- Ellenőrizd, hogy a public key hozzá van adva a Hetzner szerverhez
- Teszteld lokálisan az SSH kapcsolatot

### "Host key verification failed"

**Megoldás:** A workflow automatikusan hozzáadja a szervert a known_hosts-hoz. Ha még mindig probléma van, ellenőrizd a `HETZNER_SERVER_IP` értékét.

### "Connection timeout"

**Probléma:** A szerver IP címe nem elérhető vagy rossz

**Megoldás:**
- Ellenőrizd a `HETZNER_SERVER_IP` secret értékét
- Teszteld, hogy a szerver elérhető-e: `ping YOUR_SERVER_IP`
- Ellenőrizd a Hetzner Firewall beállításokat

## Hasznos parancsok

### Private key másolása clipboardra (Windows)

```powershell
Get-Content "$env:USERPROFILE\.ssh\id_rsa" | Set-Clipboard
Write-Host "Private key copied to clipboard!" -ForegroundColor Green
```

### SSH kapcsolat tesztelése

```bash
ssh -v root@YOUR_SERVER_IP
```

### Public key hozzáadása a szerverhez (ha még nincs)

```bash
ssh-copy-id root@YOUR_SERVER_IP
```

vagy manuálisan:
```bash
cat ~/.ssh/id_rsa.pub | ssh root@YOUR_SERVER_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

## További információk

- [GitHub Actions Secrets dokumentáció](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Hetzner Cloud dokumentáció](https://docs.hetzner.com/)
- [SSH best practices](https://www.ssh.com/academy/ssh/security)

