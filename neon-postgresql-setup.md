# Neon PostgreSQL Beállítás

## Neon PostgreSQL bevezetés

Neon egy serverless PostgreSQL platform, ami hasonló a Render-hez, de jobb teljesítményt és automatikus scaling-et biztosít.

## Szolgáltatás regisztrálás

1. **Neon Account létrehozás**
   - Menj a [Neon Console](https://console.neon.tech/) oldalra
   - Regisztrálj egy ingyenes fiókot

2. **Projekt létrehozás**
   - Kattints a **New Project** gombra
   - Add meg a projekt nevét (pl: `valutavalto`)
   - Válaszd ki a régiót (pl: `Europe (Frankfurt)` vagy `Europe (Paris)`)
   - Kattints a **Create Project** gombra

3. **Adatbázis kapcsolat információk**
   - A projekt létrehozása után megkapod a connection string-et
   - Kattints a **Connection Details** vagy **Connection String** gombra

## Connection String formátum

Neon connection string két formátumban érhető el:

### 1. PostgreSQL URI formátum
```
postgresql://username:password@ep-xxxxx-xxxxx.us-east-2.aws.neon.tech/valuta?sslmode=require
```

### 2. JDBC formátum (Java/Spring Boot)
```
jdbc:postgresql://ep-xxxxx-xxxxx.us-east-2.aws.neon.tech:5432/valuta?sslmode=require&user=username&password=password
```

## Beállítás a projektben

### 1. Environment változók (.env fájl)

**Fájl:** `.env` (a projekt gyökerében)

```env
# Neon PostgreSQL Connection
NEON_DATABASE_URL=postgresql://username:password@ep-xxxxx-xxxxx.region.aws.neon.tech/valuta?sslmode=require

# Vagy JDBC formátumban
DATABASE_URL=jdbc:postgresql://ep-xxxxx-xxxxx.region.aws.neon.tech:5432/valuta?sslmode=require&user=username&password=password

# Vagy külön változókkal
DB_HOST=ep-xxxxx-xxxxx.region.aws.neon.tech
DB_PORT=5432
DB_NAME=valuta
DB_USERNAME=your_neon_username
DB_PASSWORD=your_neon_password
```

### 2. application.yml (Backend)

**Fájl:** `backend/src/main/resources/application.yml`

```yaml
spring:
  datasource:
    # Neon PostgreSQL connection
    url: ${DATABASE_URL:jdbc:postgresql://ep-xxxxx-xxxxx.region.aws.neon.tech:5432/valuta?sslmode=require}
    username: ${DB_USERNAME:your_neon_username}
    password: ${DB_PASSWORD:your_neon_password}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 2
      connection-timeout: 20000
      # Neon requires SSL
      data-source-properties:
        ssl: true
        sslmode: require
```

### 3. GitHub Actions Secrets

Ha CI/CD-t használsz, add hozzá a GitHub Secrets-hez:

**Secrets:**
- `DATABASE_URL`: `jdbc:postgresql://ep-xxxxx-xxxxx.region.aws.neon.tech:5432/valuta?sslmode=require`
- `DB_USERNAME`: `your_neon_username`
- `DB_PASSWORD`: `your_neon_password`

## Adatbázis séma importálása Neon-ba

### 1. psql-lel (ha van PostgreSQL kliens)

```powershell
# Neon connection string (URI formátum)
$NEON_URL = "postgresql://username:password@ep-xxxxx-xxxxx.region.aws.neon.tech/valuta?sslmode=require"

# Séma importálása
psql $NEON_URL -f database/schema/valuta_schema.sql

# Vagy ha van schema export script:
.\scripts\export-database-schema-only.ps1 -Host "ep-xxxxx-xxxxx.region.aws.neon.tech" -Database "valuta" -Username "your_neon_username" -Password "your_neon_password"
```

### 2. Neon SQL Editor használata

1. Menj a Neon Console-ba
2. Válaszd ki a projektet
3. Kattints a **SQL Editor** fülre
4. Másold be a sémát a `database/schema/valuta_schema.sql` fájlból
5. Futtasd a lekérdezéseket

### 3. Script használata

```powershell
# Exportálás lokális adatbázisból
.\scripts\export-database-schema-only.ps1

# Importálás Neon-ba
.\scripts\import-database.ps1 `
    -Host "ep-xxxxx-xxxxx.region.aws.neon.tech" `
    -Port 5432 `
    -Database "valuta" `
    -Username "your_neon_username" `
    -Password "your_neon_password" `
    -InputFile "database/schema/valuta_schema.sql"
```

## Neon specifikus beállítások

### SSL kapcsolat

Neon **kötelezően SSL-t** igényel. Biztosítsd, hogy:

1. **JDBC URL-ben** legyen: `?sslmode=require`
2. **HikariCP konfigurációban** legyen: `sslmode=require`

### Connection pooling

Neon serverless, ezért ajánlott:
- **Maximum pool size**: 10-20 (Neon limitje)
- **Idle timeout**: 30 másodperc
- **Connection timeout**: 20 másodperc

### Branching (Development/Production)

Neon támogatja a **branching** funkciót:
- Létrehozhatsz külön branch-eket development és production környezetekhez
- Minden branch-nek saját connection string-e van

**Használat:**
- **Main branch**: Production
- **Development branch**: Fejlesztéshez

## Connection string példa Neon-ból

A Neon Console-ban a **Connection Details** menüpontban találod:

```
postgresql://valuta_user:your_password@ep-cool-darkness-123456.us-east-2.aws.neon.tech/valuta?sslmode=require
```

**JDBC formátumra konvertálva:**
```
jdbc:postgresql://ep-cool-darkness-123456.us-east-2.aws.neon.tech:5432/valuta?sslmode=require&user=valuta_user&password=your_password
```

## Hibaelhárítás

### "SSL connection required"

**Probléma:** Neon SSL-t igényel.

**Megoldás:**
- Add hozzá az URL-hez: `?sslmode=require`
- Vagy a HikariCP konfigban: `sslmode=require`

### "Connection timeout"

**Probléma:** A szerver nem elérhető vagy rossz az endpoint.

**Megoldás:**
- Ellenőrizd a connection string-et a Neon Console-ban
- Bizonyosodj meg, hogy az endpoint helyes
- Próbáld meg újragenerálni a jelszót

### "Too many connections"

**Probléma:** Túl sok connection van nyitva.

**Megoldás:**
- Csökkentsd a connection pool méretét
- Növeld az idle timeout-ot
- Használj connection pooling-ot (HikariCP)

## Hasznos linkek

- [Neon Console](https://console.neon.tech/)
- [Neon Dokumentáció](https://neon.tech/docs)
- [Neon Connection String Guide](https://neon.tech/docs/connect/connect-from-any-app)
- [Neon Branching](https://neon.tech/docs/guides/branching)

## Migráció Render/egyéb PostgreSQL-ről Neon-ra

Ha már van adatbázisod máshol:

```powershell
# 1. Exportálás régi adatbázisból
.\scripts\export-database.ps1 -Host "old-host" -Database "valuta" -OutputFile "database/export/migration.sql"

# 2. Importálás Neon-ba
.\scripts\import-database.ps1 `
    -Host "ep-xxxxx-xxxxx.region.aws.neon.tech" `
    -Database "valuta" `
    -Username "neon_username" `
    -Password "neon_password" `
    -InputFile "database/export/migration.sql"
```

## Monitoring és Analytics

Neon ingyenes monitoring-t biztosít:
- Query performance
- Connection statistics
- Database size
- Active connections

Hozzáférés a Neon Console-ban: **Metrics** fül.

