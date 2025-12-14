# Hetzner VPS SSH Kulcs Beállítás

## SSH Kulcs Információk

### Public Key helye
```
%USERPROFILE%\.ssh\id_rsa.pub
```

### Private Key helye (NEVER SHARE!)
```
%USERPROFILE%\.ssh\id_rsa
```

## SSH Public Key (másold be a Hetzner-be)

A kulcs a vágólapon van. Ha nincs ott, másold ki az alábbi fájlból:
- Fájl: `%USERPROFILE%\.ssh\id_rsa.pub`

## Hetzner VPS SSH Kulcs Hozzáadása

1. **Hetzner Cloud Konzol**
   - Menj a [Hetzner Cloud Console](https://console.hetzner.cloud/) oldalra
   - Jelentkezz be

2. **VPS Kiválasztása**
   - Válaszd ki a VPS szervert

3. **SSH Keys Hozzáadása**
   - Kattints a **Settings** fülre
   - Válaszd az **SSH Keys** opciót
   - Kattints az **Add SSH Key** gombra
   - **Name**: Add meg egy nevet (pl: "My Laptop")
   - **Public Key**: Illesszd be a vágólapon lévő SSH public key-t
   - Kattints a **Add SSH Key** gombra

4. **Kapcsolódás**
   ```bash
   ssh root@YOUR_SERVER_IP
   ```
   Vagy ha másik user-t használsz:
   ```bash
   ssh username@YOUR_SERVER_IP
   ```

## SSH Config Beállítás (Opcionális)

Könnyebb kapcsolódás érdekében létrehozhatsz egy SSH config fájlt:

**Fájl helye**: `%USERPROFILE%\.ssh\config`

**Tartalom**:
```
Host hetzner-vps
    HostName YOUR_SERVER_IP
    User root
    IdentityFile ~/.ssh/id_rsa
    Port 22
```

**Használat**:
```bash
ssh hetzner-vps
```

## Git Secrets

Git Secrets egy AWS által fejlesztett eszköz, ami megakadályozza, hogy érzékeny adatokat (pl. API kulcsok, jelszavak) commitolj a git repository-ba.

### Windows Telepítés

1. **Git Credential Manager** (ajánlott)
   - Már beépítve van a Git-ben
   - Használja a Windows Credential Manager-t

2. **WSL (Windows Subsystem for Linux)** használata
   ```bash
   # WSL-ben
   sudo apt-get install git-secrets
   ```

3. **Manuális telepítés**
   - Kövesd a [Git Secrets GitHub oldal](https://github.com/awslabs/git-secrets) útmutatóját

### Git Secrets Használat

#### Windows PowerShell Script (Ajánlott)

A projekt tartalmaz egy PowerShell scriptet, ami ellenőrzi az érzékeny adatokat:

```powershell
# Manuális ellenőrzés
.\scripts\git-secrets-check.ps1

# Pre-commit hookként használat
# A .git/hooks/pre-commit már tartalmazza a logikát
```

#### Git Secrets Patterns

A projekt tartalmaz egy `.git-secrets-patterns` fájlt, ami tartalmazza az észlelendő mintákat:

- Jelszavak és kulcsok (password, secret, api_key, etc.)
- JWT és tokenek (jwt_secret, token, auth_token)
- Adatbázis hitelesítési adatok
- AWS és cloud kulcsok
- OAuth és social media kulcsok
- Email és messaging kulcsok
- Payment kulcsok (Stripe, PayPal)
- SSH kulcsok és tanúsítványok
- Hetzner specifikus kulcsok
- Application specifikus minták

#### Linux/Mac Git Secrets (Ha telepítve van)

```bash
# Repository inicializálása
git secrets --install

# Minták hozzáadása (pl. API kulcs formátumok)
git secrets --register-aws

# Egyedi minták hozzáadása
while IFS= read -r pattern; do
    [[ "$pattern" =~ ^#.*$ ]] && continue
    [[ -z "$pattern" ]] && continue
    git secrets --add "$pattern"
done < .git-secrets-patterns

# Ellenőrzés commit előtt
git secrets --scan
```

## Biztonsági Tippek

1. **Private Key védelem**
   - SOHA ne oszd meg a private key-t (`id_rsa`)
   - Csak a public key-t (`id_rsa.pub`) add hozzá a szerverhez

2. **Jelszó használata SSH kulcson**
   - Opcionálisan hozzáadhatsz jelszót a private key-hez:
   ```bash
   ssh-keygen -p -f ~/.ssh/id_rsa
   ```

3. **Key Rotation**
   - Rendszeresen (pl. évente) generálj új kulcsokat
   - Távolítsd el a régi kulcsokat mindenhol

4. **SSH Agent**
   - Windows-ban használd a built-in SSH Agent-et
   - Automatikusan kezeli a kulcsokat

## További Segítség

- [Hetzner SSH Keys Dokumentáció](https://docs.hetzner.com/cloud/servers/remote-access/ssh-keys/)
- [Git Secrets GitHub](https://github.com/awslabs/git-secrets)
- [SSH Best Practices](https://www.ssh.com/academy/ssh/security)

