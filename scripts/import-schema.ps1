# =============================================================================
# PostgreSQL Schema Import Script
# Render PostgreSQL adatbázis inicializálás
# =============================================================================

# Environment változók betöltés
$envFile = Join-Path $PSScriptRoot ".." ".env"
if (-not (Test-Path $envFile)) {
    Write-Error ".env fájl nem található! Futtasd a szkriptet a projekt gyökérkönyvtárából."
    exit 1
}

# .env fájl parse (primitív módszer)
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.+)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$key" -Value $value
    }
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Valutaváltó - PostgreSQL Import" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# PostgreSQL kapcsolat ellenőrzés
Write-Host "[1/5] PostgreSQL kliens ellenőrzés..." -ForegroundColor Yellow
$psqlVersion = & psql --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "psql parancs nem található! Telepítsd a PostgreSQL 16 klienst:"
    Write-Host "  choco install postgresql16" -ForegroundColor Cyan
    exit 1
}
Write-Host "✓ PostgreSQL kliens telepítve: $psqlVersion" -ForegroundColor Green
Write-Host ""

# Render kapcsolat teszt
Write-Host "[2/5] Render PostgreSQL kapcsolat teszt..." -ForegroundColor Yellow
$env:PGPASSWORD = $env:RENDER_DB_PASSWORD
$testQuery = "SELECT version();"
$result = & psql -h $env:RENDER_DB_HOST -p $env:RENDER_DB_PORT -U $env:RENDER_DB_USER -d $env:RENDER_DB_NAME -c $testQuery 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "Render PostgreSQL kapcsolat sikertelen!"
    Write-Host "Host: $env:RENDER_DB_HOST" -ForegroundColor Red
    Write-Host "Port: $env:RENDER_DB_PORT" -ForegroundColor Red
    Write-Host "User: $env:RENDER_DB_USER" -ForegroundColor Red
    Write-Host "Database: $env:RENDER_DB_NAME" -ForegroundColor Red
    Write-Host ""
    Write-Host "Hiba: $result" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Render PostgreSQL elérhető!" -ForegroundColor Green
Write-Host ""

# Extension-ök engedélyezése
Write-Host "[3/5] PostgreSQL extension-ök engedélyezése..." -ForegroundColor Yellow
$extensions = @("pg_uuidv7", "pgcrypto")
foreach ($ext in $extensions) {
    Write-Host "  - $ext engedélyezése..." -ForegroundColor Gray
    & psql -h $env:RENDER_DB_HOST -p $env:RENDER_DB_PORT -U $env:RENDER_DB_USER -d $env:RENDER_DB_NAME -c "CREATE EXTENSION IF NOT EXISTS $ext;" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✓ $ext engedélyezve" -ForegroundColor Green
    } else {
        Write-Warning "    ⚠ $ext engedélyezés sikertelen (lehet hogy már létezik)"
    }
}
Write-Host ""

# Prohibited táblák import
Write-Host "[4/5] Prohibited táblák (AML/terror lista) import..." -ForegroundColor Yellow
$prohibitedSql = Join-Path $PSScriptRoot ".." "database" "migrations" "001_prohibited_tables.sql"
if (-not (Test-Path $prohibitedSql)) {
    Write-Error "001_prohibited_tables.sql nem található!"
    exit 1
}
& psql -h $env:RENDER_DB_HOST -p $env:RENDER_DB_PORT -U $env:RENDER_DB_USER -d $env:RENDER_DB_NAME -f $prohibitedSql
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Prohibited táblák sikeresen létrehozva!" -ForegroundColor Green
} else {
    Write-Error "Prohibited táblák import sikertelen!"
    exit 1
}
Write-Host ""

# Teljes schema import (valuta_data.sql)
Write-Host "[5/5] Teljes schema import (valuta_data.sql)..." -ForegroundColor Yellow
$mainSql = Join-Path $PSScriptRoot ".." "backend_deployment" "pgsql" "valuta_data.sql"
if (-not (Test-Path $mainSql)) {
    Write-Error "valuta_data.sql nem található!"
    exit 1
}

Write-Host "  FIGYELEM: Ez a művelet 7451 sor SQL-t fog futtatni (~2-3 perc)." -ForegroundColor Yellow
$confirm = Read-Host "  Folytatod? (I/N)"
if ($confirm -ne "I") {
    Write-Host "Import megszakítva." -ForegroundColor Red
    exit 0
}

& psql -h $env:RENDER_DB_HOST -p $env:RENDER_DB_PORT -U $env:RENDER_DB_USER -d $env:RENDER_DB_NAME -f $mainSql
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Teljes schema sikeresen importálva!" -ForegroundColor Green
} else {
    Write-Error "Schema import sikertelen! Ellenőrizd a valuta_data.sql fájlt."
    exit 1
}
Write-Host ""

# Összesítő
Write-Host "================================" -ForegroundColor Cyan
Write-Host "IMPORT SIKERES! 🎉" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Következő lépések:" -ForegroundColor Yellow
Write-Host "1. Ellenőrizd a táblákat: psql RENDER_DB_URL_EXTERNAL -c '\dt'" -ForegroundColor White
Write-Host "2. Indítsd a Spring Boot backend-et: cd backend && mvnw spring-boot:run" -ForegroundColor White
Write-Host "3. Tesztel API-t: http://localhost:8080/api/health" -ForegroundColor White
Write-Host ""
