# Hostinger VPS IP Cím Megkeresése

## 1. Hostinger Control Panel (hPanel)

1. Menj a [Hostinger hPanel](https://hpanel.hostinger.com/) oldalra
2. Jelentkezz be a fiókodba
3. Válaszd ki a projektet vagy szervert

## 2. VPS Információk Megtekintése

### VPS Szolgáltatás esetén:

1. Kattints a **"VPS"** vagy **"Servers"** menüpontra
2. Válaszd ki a VPS szervert a listából
3. Az **"Overview"** vagy **"Details"** fülön találod az IP címet

### Hosting Szolgáltatás esetén:

1. Menj a **"Domains"** menüpontra
2. Válaszd ki a domain-t (excbesttest.com)
3. Kattints a **"Manage"** gombra
4. Az **"Advanced"** → **"IP Address"** részben láthatod az IP címet

## 3. SSH Hozzáférés

Hostinger VPS esetén:

```bash
ssh root@YOUR_VPS_IP
```

vagy ha van dedikált user:

```bash
ssh username@YOUR_VPS_IP
```

## 4. IP Cím Ellenőrzése SSH-n keresztül

Ha SSH-vel be vagy jelentkezve, ellenőrizheted:

```bash
# IP cím listázása
hostname -I

# Vagy részletes információk
ip addr show

# Vagy csak az első IPv4 cím
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
```

## 5. GitHub Secrets Konfigurálása

A GitHub Secrets-ben add meg a következőket:

### Secret nevek:

1. **VPS_SSH_PRIVATE_KEY**
   - Az SSH private key teljes tartalma
   - Fájl: `~/.ssh/id_rsa`

2. **VPS_SERVER_IP**
   - A VPS IPv4 címe
   - Pl: `123.45.67.89`

3. **VPS_SSH_USER**
   - SSH felhasználó (általában `root`)

4. **DB_USERNAME**
   - Adatbázis felhasználó név

5. **DB_PASSWORD**
   - Adatbázis jelszó

6. **DB_NAME**
   - Adatbázis neve (pl: `valuta`)

## 6. GitHub Secrets Hozzáadása

1. Menj a GitHub repository-ba
2. **Settings** → **Secrets and variables** → **Actions**
3. Kattints a **"New repository secret"** gombra
4. Add meg a fent felsorolt secret-eket egyenként

## 7. Deployment Elindítása

A GitHub Actions workflow automatikusan lefut, ha:
- Push történik a `main` vagy `master` branch-re
- Vagy manuálisan elindítod: **Actions** → **Deploy to VPS** → **Run workflow**

## Troubleshooting

### SSH kapcsolat sikertelen

```bash
# Teszteld az SSH kapcsolatot
ssh -v root@YOUR_VPS_IP

# Ellenőrizd, hogy a public key hozzá van-e adva
ssh-copy-id root@YOUR_VPS_IP
```

### IP cím nem található

Ha nem találod az IP címet a hPanel-ben:
1. Kattints a **"Support"** vagy **"Help"** gombra
2. Kérj segítséget a Hostinger support-tól
3. Vagy ellenőrizd az email-ben, ahol a VPS adatait küldték

## További Információk

- [Hostinger hPanel](https://hpanel.hostinger.com/)
- [Hostinger VPS Dokumentáció](https://support.hostinger.com/en/articles/2617659-connecting-to-your-vps-via-ssh)

