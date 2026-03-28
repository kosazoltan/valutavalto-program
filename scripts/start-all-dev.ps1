# ============================================
# Valutavalto ERP — Unified Dev Launcher
# Backend + Frontend + Electron egyben
# ============================================
param(
    [switch]$ElectronOnly,
    [switch]$NoElectron,
    [int]$BackendPort = 8080,
    [int]$FrontendPort = 5173
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path "$ROOT\backend\pom.xml")) {
    $ROOT = Split-Path -Parent $PSScriptRoot
}
if (-not (Test-Path "$ROOT\backend\pom.xml")) {
    $ROOT = $PSScriptRoot | Split-Path
}

$BACKEND   = Join-Path $ROOT 'backend'
$FRONTEND  = Join-Path $ROOT 'frontend-react'
$ELECTRON  = Join-Path $ROOT 'penztar-client'

$JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot'
$env:JAVA_HOME = $JAVA_HOME
$env:PATH = "$JAVA_HOME\bin;$env:PATH"

Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Valutavalto ERP — Dev Launcher' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

# --- 1) Docker PostgreSQL ---
Write-Host '[1/5] Docker PostgreSQL inditasa...' -ForegroundColor Yellow
$dockerUp = docker compose -f "$ROOT\docker-compose.yml" up -d postgres 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  WARN: Docker postgres nem indult ($dockerUp)" -ForegroundColor Red
    Write-Host '  Ellenorizd, hogy a Docker Desktop fut-e.' -ForegroundColor Red
} else {
    Write-Host '  OK — postgres container fut' -ForegroundColor Green
}

# --- 2) DB user sync ---
Write-Host '[2/5] DB user/jelszo szinkronizalas...' -ForegroundColor Yellow
Start-Sleep -Seconds 3
docker exec valuta-postgres psql -U valuta_user -d postgres -c "ALTER USER valuta_user WITH PASSWORD 'valuta_pass';" 2>$null | Out-Null
Write-Host '  OK' -ForegroundColor Green

# --- 3) Backend (Maven Spring Boot) ---
Write-Host '[3/5] Backend inditas (port $BackendPort)...' -ForegroundColor Yellow
$env:DATABASE_URL = "jdbc:postgresql://127.0.0.1:5432/valuta"
$env:DATABASE_USERNAME = 'valuta_user'
$env:DATABASE_PASSWORD = 'valuta_pass'
$env:SPRING_PROFILES_ACTIVE = 'development'
$env:SERVER_PORT = "$BackendPort"

$backendJob = Start-Process -FilePath 'cmd.exe' `
    -ArgumentList "/c cd /d `"$BACKEND`" && mvnw.cmd spring-boot:run -DskipTests" `
    -PassThru -WindowStyle Minimized
Write-Host "  Backend PID: $($backendJob.Id) — http://localhost:$BackendPort/api/v1" -ForegroundColor Green
Write-Host "  Swagger: http://localhost:$BackendPort/swagger-ui.html" -ForegroundColor Green

# --- 4) Frontend React (Vite) ---
Write-Host "[4/5] Frontend React inditas (port $FrontendPort)..." -ForegroundColor Yellow
$frontendJob = Start-Process -FilePath 'cmd.exe' `
    -ArgumentList "/c cd /d `"$FRONTEND`" && npx vite --port $FrontendPort --host" `
    -PassThru -WindowStyle Minimized
Write-Host "  Frontend PID: $($frontendJob.Id) — http://localhost:$FrontendPort" -ForegroundColor Green

if (-not $NoElectron) {
    # --- 5) Electron ---
    Write-Host '[5/5] Electron penztar-client inditas...' -ForegroundColor Yellow
    Write-Host '  Varakozas backend + frontend keszultsegere (15s)...' -ForegroundColor DarkGray
    Start-Sleep -Seconds 15
    $electronJob = Start-Process -FilePath 'cmd.exe' `
        -ArgumentList "/c cd /d `"$ELECTRON`" && npm run dev" `
        -PassThru -WindowStyle Minimized
    Write-Host "  Electron PID: $($electronJob.Id)" -ForegroundColor Green
} else {
    Write-Host '[5/5] Electron KIHAGYVA (-NoElectron flag)' -ForegroundColor DarkGray
}

Write-Host '' 
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Minden komponens elindult!' -ForegroundColor Green
Write-Host "  Backend:  http://localhost:$BackendPort/api/v1" -ForegroundColor White
Write-Host "  Frontend: http://localhost:$FrontendPort" -ForegroundColor White
Write-Host '  Electron: Penztar ablak' -ForegroundColor White
Write-Host '' 
Write-Host '  Leallitas: Ctrl+C vagy ablakokat bezarni' -ForegroundColor DarkGray
Write-Host '============================================' -ForegroundColor Cyan

# Varakozas — ha bezarjak, mindent leallitunk
Write-Host ''
Write-Host 'Nyomj ENTER-t a leallitashoz...' -ForegroundColor Yellow
Read-Host

Write-Host 'Leallitas...' -ForegroundColor Yellow
if ($backendJob -and -not $backendJob.HasExited)  { Stop-Process -Id $backendJob.Id -Force -ErrorAction SilentlyContinue }
if ($frontendJob -and -not $frontendJob.HasExited) { Stop-Process -Id $frontendJob.Id -Force -ErrorAction SilentlyContinue }
if ($electronJob -and -not $electronJob.HasExited) { Stop-Process -Id $electronJob.Id -Force -ErrorAction SilentlyContinue }
docker compose -f "$ROOT\docker-compose.yml" down 2>$null
Write-Host 'Kesz.' -ForegroundColor Green
