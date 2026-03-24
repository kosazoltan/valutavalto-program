@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

echo ============================================
echo   Valutavalto Backend - Neon DB Start
echo ============================================

set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "APP_PORT=8080"

echo [1/3] Java ellenorzes
java -version
if errorlevel 1 (
  echo HIBA: Java nem elerheto.
  exit /b 1
)

echo.
echo [2/3] Neon DB kornyezet beallitasa
REM --- .env fajlbol olvassa a connection adatokat ---
for /f "tokens=1,* delims==" %%A in ('type "%ROOT_DIR%.env" ^| findstr /B "DATABASE_"') do (
  set "%%A=%%B"
)

REM --- Spring Flyway enabled: Neon is Flyway-managed ---
set "SPRING_FLYWAY_ENABLED=true"
set "SPRING_FLYWAY_BASELINE_ON_MIGRATE=false"
set "SPRING_DATASOURCE_URL="
set "SPRING_DATASOURCE_USERNAME="
set "SPRING_DATASOURCE_PASSWORD="
set "SPRING_PROFILES_ACTIVE=development"
set "SERVER_PORT=%APP_PORT%"

echo.
echo [3/3] Backend inditas
echo API: http://localhost:%APP_PORT%/api/v1
echo Swagger: http://localhost:%APP_PORT%/swagger-ui.html
echo DB: Neon (ep-polished-morning)
echo Flyway: enabled
echo.

cd /d "%BACKEND_DIR%"
call mvnw.cmd spring-boot:run -DskipTests
