<#
.SYNOPSIS
  Valuta ERP komplex okoszisztema inditas - PRODUCTION-FIRST (2026-04-21+).

.DESCRIPTION
  KOTELEZO ERVENYU launcher. A fejlesztes KOZVETLENUL a produktumhoz illeszkedik
  (Hetzner HA: https://excvaluta.com). NINCS divergens lokalis backend.

  Komponensek (production-first):
  1. Hetzner produktum elerhetoseg ellenorzes (https://excvaluta.com)
  2. Frontend-react (Vite, port 3000, proxy -> excvaluta.com)
  3. Penztar-client Electron (a renderer: http://127.0.0.1:3000 proxy-n keresztul)

.PARAMETER WithLocalBackend
  CSAK MVN TESZT-HEZ: lokalis backend indit 8080-on (NEM ajanlott integracioshoz).

.EXAMPLE
  powershell -File scripts/start-valuta-ecosystem.ps1
#>
param(
    [switch]$WithLocalBackend,
    [switch]$SkipElectron
)

$ErrorActionPreference = 'Stop'

function Write-Step { param($Msg) Write-Host "[START] $Msg" -ForegroundColor Cyan }
function Write-OK   { param($Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Err  { param($Msg) Write-Host "[ERR] $Msg" -ForegroundColor Red }

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

# 1) Hetzner produktum health check
Write-Step "1/3 - Hetzner produktum (https://excvaluta.com) health check"
try {
    $r = Invoke-WebRequest -Uri "https://excvaluta.com/api/v1/auth/bootstrap-status" -TimeoutSec 10 -UseBasicParsing
    if ($r.StatusCode -eq 200) {
        Write-OK "Produktum elerheto (HTTP $($r.StatusCode))"
    } else {
        Write-Err "Produktum nem 200 valaszol: $($r.StatusCode)"
        exit 1
    }
} catch {
    Write-Err "Produktum NEM elerheto: $_"
    Write-Err "HA failover szukseges. Ld. deploy/hetzner/ha/failover-to-standby.sh"
    exit 1
}

# Opcionalisan: lokalis backend debug-hoz
if ($WithLocalBackend) {
    Write-Step "OPT - Lokalis backend (mvn spring-boot:run) - CSAK TESZT-HEZ"
    Write-Host "  (kulonallo shell-ben kepzelt: 'cd backend && ./mvnw spring-boot:run')" -ForegroundColor DarkGray
    Write-Host "  Jelen launcher NEM inditja - hasznald a konkurrens terminalban" -ForegroundColor DarkGray
}

# 2) Frontend-react (Vite) - proxy production-re
Write-Step "2/3 - Frontend-react (Vite, --host 0.0.0.0, VITE_PROXY_TARGET=https://excvaluta.com)"
$env:VITE_PROXY_TARGET = 'https://excvaluta.com'
$feAlready = $false
try {
    $code = (Invoke-WebRequest -Uri "http://localhost:3000/" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
    if ($code -eq 200) { $feAlready = $true }
} catch {}

if ($feAlready) {
    Write-OK "Frontend mar fut 3000-on"
} else {
    Push-Location (Join-Path $RepoRoot "frontend-react")
    Start-Process -FilePath "npm" -ArgumentList "run","dev","--","--host","0.0.0.0" -WindowStyle Hidden `
        -RedirectStandardOutput "$env:TEMP\valuta-frontend.log" -RedirectStandardError "$env:TEMP\valuta-frontend-err.log"
    Pop-Location
    Write-Step "Vite inditva - var..."
    $start = Get-Date
    while ($true) {
        Start-Sleep -Seconds 2
        try { if ((Invoke-WebRequest -Uri "http://127.0.0.1:3000/" -TimeoutSec 2 -UseBasicParsing).StatusCode -eq 200) { Write-OK "Frontend READY"; break } } catch {}
        if (((Get-Date) - $start).TotalSeconds -gt 45) { Write-Err "Vite not up in 45s"; exit 1 }
    }
}

# 3) Electron penztar-client
if (-not $SkipElectron) {
    Write-Step "3/3 - Electron penztar-client (npm run dev:main)"
    Push-Location (Join-Path $RepoRoot "penztar-client")
    Start-Process -FilePath "npm" -ArgumentList "run","dev:main" -WindowStyle Hidden `
        -RedirectStandardOutput "$env:TEMP\valuta-electron.log" -RedirectStandardError "$env:TEMP\valuta-electron-err.log"
    Pop-Location
    Write-OK "Electron inditva"
} else {
    Write-Step "Electron SKIP"
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  VALUTA OKOSZISZTEMA (production-first) UP" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Backend:      https://excvaluta.com  (Hetzner HA primary)"
Write-Host "  Frontend:     http://localhost:3000  (Vite proxy -> excvaluta.com)"
Write-Host "  Electron:     GUI window (Pentztar-Rendszer)"
Write-Host ""
Write-Host "  Belepes: EBC / ADMIN / Admin1234!"
Write-Host ""
Write-Host "  Logok:"
Write-Host "    - Frontend:  $env:TEMP\valuta-frontend.log"
Write-Host "    - Electron:  $env:TEMP\valuta-electron.log"
Write-Host ""
Write-Host "  Leallitas: powershell -File scripts\stop-valuta-ecosystem.ps1"
Write-Host "============================================="