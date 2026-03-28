@echo off
chcp 65001 >nul 2>&1
REM =============================================================================
REM Valutavalto Penztar - Adatbazis inicializalas
REM =============================================================================
REM Hasznalat: init-db.bat <pg_dir> <pg_port> <pg_password>
REM =============================================================================

set PG_DIR=%1
set PG_PORT=%2
set PG_PASSWORD=%3

if "%PG_DIR%"=="" (
    echo HIBA: Hianyzik a PostgreSQL konyvtar parameter
    exit /b 1
)
if "%PG_PORT%"=="" set PG_PORT=54320
if "%PG_PASSWORD%"=="" (
    echo HIBA: Hianyzik a PostgreSQL jelszo parameter - PG_PASSWORD kotelezo
    exit /b 1
)

echo [1/5] Adatbazis cluster inicializalasa...
"%PG_DIR%\bin\initdb.exe" -D "%PG_DIR%\data" -U postgres -E UTF8 --locale=C --auth=trust
if errorlevel 1 (
    echo HIBA: initdb sikertelen
    exit /b 1
)

REM PG config: port beallitas
echo port = %PG_PORT% >> "%PG_DIR%\data\postgresql.conf"
echo listen_addresses = 'localhost' >> "%PG_DIR%\data\postgresql.conf"

echo [2/5] PostgreSQL inditas...
"%PG_DIR%\bin\pg_ctl.exe" start -D "%PG_DIR%\data" -l "%PG_DIR%\log\postgresql.log" -w -t 30
if errorlevel 1 (
    echo HIBA: PostgreSQL inditas sikertelen
    exit /b 1
)

echo [3/5] Adatbazis letrehozasa: valuta
"%PG_DIR%\bin\createdb.exe" -p %PG_PORT% -U postgres valuta
if errorlevel 1 (
    echo FIGYELMEZETES: Adatbazis mar letezhet
)

echo [4/5] Felhasznalo letrehozasa: valuta_user
"%PG_DIR%\bin\psql.exe" -p %PG_PORT% -U postgres -c "DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='valuta_user') THEN CREATE USER valuta_user WITH PASSWORD '%PG_PASSWORD%'; END IF; END $$;"
if errorlevel 1 (
    echo HIBA: Felhasznalo letrehozas sikertelen
    "%PG_DIR%\bin\pg_ctl.exe" stop -D "%PG_DIR%\data" -m fast -w -t 30
    exit /b 1
)
"%PG_DIR%\bin\psql.exe" -p %PG_PORT% -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE valuta TO valuta_user;"
"%PG_DIR%\bin\psql.exe" -p %PG_PORT% -U postgres -d valuta -c "GRANT ALL ON SCHEMA public TO valuta_user;"
"%PG_DIR%\bin\psql.exe" -p %PG_PORT% -U postgres -d valuta -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO valuta_user;"

echo [5/5] PostgreSQL leallitas...
"%PG_DIR%\bin\pg_ctl.exe" stop -D "%PG_DIR%\data" -m fast -w -t 30

echo Adatbazis inicializalas KESZ.
exit /b 0
