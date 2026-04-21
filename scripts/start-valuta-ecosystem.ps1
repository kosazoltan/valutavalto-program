<#
.SYNOPSIS
  Valuta ERP komplex okoszisztema elindit - egyben (backend + frontend + Electron).

.DESCRIPTION
  KOTELEZO ERVENYU launcher: a Valuta program megnyitasa mindig az osszes
  komponenst parhuzamosan indit, TILOS kulon megnyitni.

  Komponensek:
  1. Lokalis Postgres ellenorzes (5432)
  2. Backend (Spring Boot, port 8080)
  3. Frontend-react admin (Vite, port 3000)
  4. Penztar-client Electron (renderer: 3000)

.PARAMETER SkipElectron
  Ne inditsa az Electron klienst (csak webes dashboard).

.PARAMETER SkipBackend
  Ne inditsa a backend-et (ha mar fut).

.EXAMPLE
  powershell -File scripts/start-valuta-ecosystem.ps1
#>
param(
    [switch]$SkipElectron,
    [switch]$SkipBackend,
    [int]$HealthCheckTimeoutSec = 90
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$LogDir = "$env:TEMP\valuta-logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Step { param($Msg) Write-Host "[START-ECOSYSTEM] $Msg" -ForegroundColor Cyan }
function Write-OK   { param($Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Err  { param($Msg) Write-Host "[ERR] $Msg" -ForegroundColor Red }
function Write-Warn { param($Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }

# 1) Env betoltes
Write-Step "1/5 - Env fajl betoltese (.env)"
$envFile = Join-Path $RepoRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Err "Nincs .env fajl a repo rootban! Masold at a konfigot (.env.example alapjan)."
    exit 1
}
foreach ($line in Get-Content $envFile) {
    if ($line -match "^\s*([^#=][^=]*)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        if ($value.StartsWith('"') -and $value.EndsWith('"')) { $value = $value.Substring(1, $value.Length - 2) }
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
}
# Kikapcsolom a Neon-t, hasznaljuk a lokalis Postgres-t
[Environment]::SetEnvironmentVariable('DATABASE_URL', '', 'Process')
[Environment]::SetEnvironmentVariable('DATABASE_USERNAME', '', 'Process')
[Environment]::SetEnvironmentVariable('DATABASE_PASSWORD', '', 'Process')
Write-OK "Env betoltve - lokalis Postgres mode (.env-bol LOCAL_DB_*)"

# 2) Lokalis Postgres ellenorzes
Write-Step "2/5 - Lokalis Postgres (5432) ellenorzes"
try {
    $pg = Test-NetConnection -ComputerName '127.0.0.1' -Port 5432 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($pg) { Write-OK "Postgres 5432 nyitva" }
    else {
        Write-Warn "Postgres 5432-n NEM valaszol - indits docker compose up -d postgres (vagy lokalis psql service)"
        $continueAnyway = Read-Host "Folytassam? (y/N)"
        if ($continueAnyway -ne 'y') { exit 1 }
    }
} catch { Write-Warn "Port teszt nem volt sikeres, folytatas..." }

# 3) Backend
if (-not $SkipBackend) {
    Write-Step "3/5 - Backend (Spring Boot) inditasa - 8080"
    $backendLog = Join-Path $LogDir "backend.log"
    $backendDir = Join-Path $RepoRoot "backend"

    # Meglevo backend ellenorzes
    $already = $false
    try {
        $code = (Invoke-WebRequest -Uri "http://localhost:8080/api/v1/auth/bootstrap-status" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
        if ($code -eq 200) { $already = $true }
    } catch {}

    if ($already) {
        Write-OK "Backend mar fut 8080-on - skip"
    } else {
        Start-Process -FilePath "$backendDir\mvnw.cmd" `
            -ArgumentList "spring-boot:run" `
            -WorkingDirectory $backendDir `
            -RedirectStandardOutput $backendLog `
            -RedirectStandardError "$backendLog.err" `
            -WindowStyle Hidden
        Write-Step "Backend indul... log: $backendLog"

        # Wait for health
        $start = Get-Date
        while ($true) {
            Start-Sleep -Seconds 3
            try {
                $code = (Invoke-WebRequest -Uri "http://localhost:8080/api/v1/auth/bootstrap-status" -TimeoutSec 2 -UseBasicParsing).StatusCode
                if ($code -eq 200) { Write-OK "Backend READY (HTTP $code)"; break }
            } catch {}
            $elapsed = ((Get-Date) - $start).TotalSeconds
            if ($elapsed -gt $HealthCheckTimeoutSec) {
                Write-Err "Backend nem indul el $HealthCheckTimeoutSec mp alatt - log: $backendLog"
                exit 1
            }
            Write-Host "  ... varok backend-re ($([int]$elapsed)s)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Step "3/5 - Backend SKIP"
}

# 4) Frontend-react
Write-Step "4/5 - Frontend-react (Vite) - 3000"
$frontendLog = Join-Path $LogDir "frontend.log"
$frontendDir = Join-Path $RepoRoot "frontend-react"

$feAlready = $false
try {
    $code = (Invoke-WebRequest -Uri "http://localhost:3000/" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
    if ($code -eq 200) { $feAlready = $true }
} catch {}

if ($feAlready) {
    Write-OK "Frontend mar fut 3000-on - skip"
} else {
    Start-Process -FilePath "npm" `
        -ArgumentList "run", "dev" `
        -WorkingDirectory $frontendDir `
        -RedirectStandardOutput $frontendLog `
        -RedirectStandardError "$frontendLog.err" `
        -WindowStyle Hidden
    Write-Step "Frontend indul... log: $frontendLog"

    $start = Get-Date
    while ($true) {
        Start-Sleep -Seconds 2
        try {
            $code = (Invoke-WebRequest -Uri "http://localhost:3000/" -TimeoutSec 2 -UseBasicParsing).StatusCode
            if ($code -eq 200) { Write-OK "Frontend READY (HTTP $code)"; break }
        } catch {}
        $elapsed = ((Get-Date) - $start).TotalSeconds
        if ($elapsed -gt 30) { Write-Err "Frontend nem indul - log: $frontendLog"; exit 1 }
    }
}

# 5) Penztar-client Electron
if (-not $SkipElectron) {
    Write-Step "5/5 - Penztar-client Electron (main)"
    $electronLog = Join-Path $LogDir "penztar-electron.log"
    $electronDir = Join-Path $RepoRoot "penztar-client"

    Start-Process -FilePath "npm" `
        -ArgumentList "run", "dev:main" `
        -WorkingDirectory $electronDir `
        -RedirectStandardOutput $electronLog `
        -RedirectStandardError "$electronLog.err" `
        -WindowStyle Hidden
    Write-OK "Electron inditva - log: $electronLog"
    Write-Host "  (A GUI ablakot kb. 15-30 mp mulva lathatod)" -ForegroundColor DarkGray
} else {
    Write-Step "5/5 - Electron SKIP"
}

# Osszegzo
Write-Host ""
Write-Host "===========================================================" -ForegroundColor Green
Write-Host "  VALUTA OKOSZISZTEMA ELINDULT" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Frontend (webes admin):  http://localhost:3000"
Write-Host "  Backend API:              http://localhost:8080"
Write-Host "  OpenAPI Swagger:          http://localhost:8080/swagger-ui.html"
Write-Host ""
Write-Host "  Belepes: EBC / ADMIN / Admin1234!"
Write-Host ""
Write-Host "  Log-ok:"
Write-Host "    - Backend:  $LogDir\backend.log"
Write-Host "    - Frontend: $LogDir\frontend.log"
Write-Host "    - Electron: $LogDir\penztar-electron.log"
Write-Host ""
Write-Host "  Leallitas: powershell -File scripts\stop-valuta-ecosystem.ps1"
Write-Host "===========================================================" -ForegroundColor Green