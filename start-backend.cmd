@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

echo ============================================
echo   Valutavalto Backend - Deterministic Start
echo ============================================

set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"

set "DB_CONTAINER=valuta-postgres"
set "DB_NAME=valuta"
set "DB_USER=valuta_user"
set "DB_PASS=valuta_pass"
set "APP_PORT=8080"

echo [1/5] Java ellenorzes
java -version
if errorlevel 1 (
  echo HIBA: Java nem elerheto.
  exit /b 1
)

echo.
echo [2/5] Lokalis PostgreSQL kontener inditasa
docker compose -f "%ROOT_DIR%docker-compose.yml" up -d postgres
if errorlevel 1 (
  echo HIBA: Docker postgres inditas sikertelen.
  exit /b 1
)

echo.
echo [3/5] Lokalis DB user/jelszo szinkronizalas
docker exec %DB_CONTAINER% psql -U %DB_USER% -d postgres -c "ALTER USER %DB_USER% WITH PASSWORD '%DB_PASS%';" >nul
if errorlevel 1 (
  echo HIBA: Nem sikerult a DB user jelszavat beallitani a kontenerben.
  exit /b 1
)

docker exec %DB_CONTAINER% psql -U %DB_USER% -d %DB_NAME% -c "ALTER TABLE IF EXISTS branch ADD COLUMN IF NOT EXISTS denomination_rule_id UUID; ALTER TABLE IF EXISTS rate_workgroup ADD COLUMN IF NOT EXISTS limit1_boundary NUMERIC(15,2); ALTER TABLE IF EXISTS rate_workgroup ADD COLUMN IF NOT EXISTS limit2_boundary NUMERIC(15,2); ALTER TABLE IF EXISTS rate_workgroup ADD COLUMN IF NOT EXISTS limit3_boundary NUMERIC(15,2); UPDATE rate_workgroup SET limit1_boundary = COALESCE(limit1_boundary, 50000), limit2_boundary = COALESCE(limit2_boundary, 300000), limit3_boundary = COALESCE(limit3_boundary, 1000000);" >nul
if errorlevel 1 (
  echo HIBA: Nem sikerult a lokalis schema kompatibilitasi javitas.
  exit /b 1
)

echo.
echo [4/5] Tiszta folyamat-kornyezet beallitasa
set "DATABASE_URL=jdbc:postgresql://127.0.0.1:5432/%DB_NAME%"
set "DATABASE_USERNAME=%DB_USER%"
set "DATABASE_PASSWORD=%DB_PASS%"
set "SPRING_DATASOURCE_URL="
set "SPRING_DATASOURCE_USERNAME="
set "SPRING_DATASOURCE_PASSWORD="
set "SPRING_FLYWAY_ENABLED=false"
set "SPRING_PROFILES_ACTIVE=development"
set "SERVER_PORT=%APP_PORT%"

echo.
echo [5/5] Backend inditas
echo API: http://localhost:%APP_PORT%/api/v1
echo Swagger: http://localhost:%APP_PORT%/swagger-ui.html
echo DB: %DATABASE_URL%
echo Flyway: disabled (lokalis determinisztikus start)
echo.

cd /d "%BACKEND_DIR%"
call mvnw.cmd spring-boot:run -DskipTests
