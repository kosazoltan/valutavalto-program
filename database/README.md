# Adatbázis Sémák és Migrációk

Ez a könyvtár tartalmazza az adatbázis sémákat és exportált adatbázis fájlokat.

## Könyvtárstruktúra

```
database/
├── schema/          # Csak séma (struktúra, adatok nélkül) - Git-be commitolható
├── export/          # Teljes exportok (adat + séma) - .gitignore-ban
└── migrations/      # Flyway migrációk (ha van)
```

## Export/Import Scriptek

### Séma exportálása (csak struktúra, újrahasznosítható)

```powershell
.\scripts\export-database-schema-only.ps1
```

Ez létrehozza a `database/schema/valuta_schema.sql` fájlt, ami:
- ✅ Csak a séma struktúrát tartalmazza
- ✅ Újrahasznosítható
- ✅ Git-be commitolható
- ❌ Nem tartalmaz érzékeny adatokat

### Teljes exportálás (séma + adatok)

```powershell
.\scripts\export-database.ps1
```

Vagy paraméterekkel:

```powershell
.\scripts\export-database.ps1 `
    -Host "your-vps-ip" `
    -Port 5432 `
    -Database "valuta" `
    -Username "valuta_user" `
    -Password "valuta_pass" `
    -OutputFile "database/export/backup.sql"
```

### Importálás

```powershell
.\scripts\import-database.ps1 -InputFile "database/schema/valuta_schema.sql"
```

Vagy teljes import újraépítéssel:

```powershell
.\scripts\import-database.ps1 `
    -InputFile "database/schema/valuta_schema.sql" `
    -DropDatabase `
    -CreateDatabase
```

## VPS-re telepítés

### 1. SCP-vel fájl másolása a VPS-re

```powershell
# Windows PowerShell
scp database/schema/valuta_schema.sql root@YOUR_VPS_IP:/tmp/
```

### 2. SSH-n keresztül importálás

```bash
ssh root@YOUR_VPS_IP

# PostgreSQL elindítása (ha Docker Compose-ban van)
cd /path/to/project
docker-compose exec db psql -U valuta_user -d valuta -f /tmp/valuta_schema.sql
```

Vagy közvetlenül:

```bash
# Ha PostgreSQL közvetlenül telepítve van
psql -h localhost -U valuta_user -d valuta -f /tmp/valuta_schema.sql
```

## GitHub Actions használat

A GitHub Actions workflow automatikusan használhatja a sémát:

```yaml
- name: Import database schema
  run: |
    ssh ${{ secrets.HETZNER_SSH_USER }}@${{ secrets.HETZNER_SERVER_IP }} << 'EOF'
      cd /var/www/valutavalto
      docker-compose exec -T db psql -U valuta_user -d valuta < /path/to/schema.sql
    EOF
```

## Biztonság

⚠️ **FONTOS:**
- A `schema/` könyvtár fájljai Git-be commitolhatók (csak struktúra)
- A `export/` könyvtár fájljai **SOHA** ne kerüljenek Git-be (értékes adatokat tartalmazhatnak)
- A `export/` könyvtár a `.gitignore`-ban van

## URL/Connection String

### Lokális fejlesztés

```
jdbc:postgresql://localhost:5432/valuta
```

### Docker Compose

```
jdbc:postgresql://db:5432/valuta
```

### VPS (távoli kapcsolat)

```
jdbc:postgresql://YOUR_VPS_IP:5432/valuta
```

### Environment változókban

```yaml
# application.yml vagy .env
DATABASE_URL: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:valuta}
DB_USERNAME: ${DB_USER:valuta_user}
DB_PASSWORD: ${DB_PASS:valuta_pass}
```

## Hasznos parancsok

### Adatbázis létrehozása

```sql
CREATE DATABASE valuta;
```

### Kapcsolódás psql-lel

```bash
psql -h localhost -U valuta_user -d valuta
```

### Táblák listázása

```sql
\dt
```

### Séma exportálása pg_dump-pal

```bash
pg_dump -h localhost -U valuta_user -d valuta --schema-only > schema.sql
```

