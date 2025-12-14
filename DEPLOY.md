# Deploy Útmutató

## Adatbázis Deploy

### Lokális adatbázis deploy (törlés + újraimportálás)

```powershell
.\scripts\deploy-database.ps1
```

Vagy paraméterekkel:

```powershell
.\scripts\deploy-database.ps1 `
    -Host "localhost" `
    -Port 5432 `
    -Database "valuta" `
    -Username "valuta_user" `
    -Password "valuta_pass" `
    -SchemaFile "database/schema/valuta_schema.sql" `
    -Force
```

**Fontos:** Ez a script **törli és újra létrehozza** az adatbázist! Minden adat elvész!

### Neon adatbázis deploy

```powershell
# Load .env variables first
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

# Deploy to Neon
.\scripts\deploy-database.ps1 `
    -Host "ep-hidden-bread-ag06kat1-pooler.c-2.eu-central-1.aws.neon.tech" `
    -Port 5432 `
    -Database "neondb" `
    -Username "neondb_owner" `
    -Password "npg_vUByfDYK39QH" `
    -SchemaFile "database/schema/valuta_schema.sql" `
    -Force
```

## VPS Deploy

### Teljes deploy (adatbázis + backend)

```powershell
.\scripts\deploy-to-vps.ps1 `
    -VpsHost "YOUR_VPS_IP" `
    -All
```

### Csak adatbázis deploy

```powershell
.\scripts\deploy-to-vps.ps1 `
    -VpsHost "YOUR_VPS_IP" `
    -DeployDatabase
```

### Csak backend deploy

```powershell
.\scripts\deploy-to-vps.ps1 `
    -VpsHost "YOUR_VPS_IP" `
    -DeployBackend
```

## GitHub Actions Automatikus Deploy

### Szükséges GitHub Secrets

1. **HETZNER_SSH_PRIVATE_KEY** - SSH private key
2. **HETZNER_SERVER_IP** - VPS IP cím
3. **HETZNER_SSH_USER** - SSH felhasználó (általában: root)
4. **DB_USERNAME** - Adatbázis felhasználó
5. **DB_PASSWORD** - Adatbázis jelszó
6. **DB_NAME** - Adatbázis név (pl: valuta)

### Automatikus deploy

Amikor push történik a `main` vagy `master` branch-re, a GitHub Actions automatikusan:

1. **Deploy-olja az adatbázis sémát:**
   - Törli a meglévő adatbázist
   - Létrehozza újra
   - Importálja a sémát

2. **Deploy-olja a backend-et:**
   - Pull-olja a legújabb kódot
   - Build-eli a projektet
   - Újraindítja a Docker Compose szolgáltatásokat

## Manuális Deploy Lépések

### 1. Séma exportálása (ha még nincs)

```powershell
.\scripts\export-database-schema-only.ps1
```

### 2. Git commit és push

```powershell
git add .
git commit -m "Deploy: database schema and backend updates"
git push origin main
```

### 3. GitHub Actions automatikus deploy

A GitHub Actions automatikusan lefut a push után.

### 4. Vagy manuális VPS deploy

```powershell
.\scripts\deploy-to-vps.ps1 -VpsHost "YOUR_VPS_IP" -All
```

## Deploy Script Működése

### deploy-database.ps1

1. Ellenőrzi, hogy létezik-e a séma fájl
2. Törli a meglévő adatbázist
3. Létrehozza az új adatbázist
4. Importálja a sémát
5. Ellenőrzi a táblák számát

### deploy-to-vps.ps1

1. Teszteli az SSH kapcsolatot
2. Ha `-DeployDatabase`: másolja és importálja a sémát
3. Ha `-DeployBackend`: pull-ol, build-el és újraindítja

## Hibaelhárítás

### "Schema file not found"

```powershell
# Export schema first
.\scripts\export-database-schema-only.ps1
```

### "SSH connection failed"

- Ellenőrizd az SSH kulcsot
- Ellenőrizd, hogy a VPS IP elérhető-e
- Ellenőrizd a Hetzner Firewall beállításokat

### "Database deploy failed"

- Ellenőrizd az adatbázis hitelesítési adatokat
- Ellenőrizd, hogy a PostgreSQL fut-e a VPS-en
- Nézd meg a hibaüzeneteket

### "Maven build failed"

- Ellenőrizd, hogy Maven telepítve van-e a VPS-en
- Ellenőrizd a Java verziót (Java 21 szükséges)
- Nézd meg a build logokat

## Biztonsági Megjegyzések

⚠️ **FONTOS:**
- A database deploy script **törli az összes adatot** az adatbázisból!
- Csak development/staging környezetben használd így
- Production-ben használj migrációkat vagy backup-ot deploy előtt
- SOHA ne commitold a `.env` fájlt (tartalmazza a jelszavakat)

## Útmutató GitHub Actions Secrets beállításához

Lásd: `github-actions-secrets-guide.md`

