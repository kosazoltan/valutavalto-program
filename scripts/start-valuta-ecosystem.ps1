<#
.SYNOPSIS
  Valuta ERP komplex okoszisztema inditas - PRODUCTION-FIRST (2026-04-21+).

.DESCRIPTION
  KOTELEZO ERVENYU launcher. A fejlesztes KOZVETLENUL a produktumhoz illeszkedik
  (Hetzner HA: lasd config/production-urls.json). NINCS divergens lokalis backend.

  Komponensek (production-first):
  1. Hetzner produktum elerhetoseg ellenorzes (config/production-urls.json)
  2. Frontend-react (Vite, port 3000, proxy -> config/production-urls.json)
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

# SSOT: production URL-ek a config/production-urls.json-bol
. (Join-Path $PSScriptRoot '_production-urls.ps1')

# 1) Hetzner produktum health check
Write-Step "1/3 - Hetzner produktum ($($PRODUCTION_URLS.base_url)) health check"
try {
    $r = Invoke-WebRequest -Uri $PRODUCTION_URLS.health_url -TimeoutSec 10 -UseBasicParsing
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
Write-Step "2/3 - Frontend-react (Vite, --host 0.0.0.0, VITE_PROXY_TARGET=$($PRODUCTION_URLS.base_url))"
$env:VITE_PROXY_TARGET = $PRODUCTION_URLS.base_url
$feAlready = $false
try {
    $code = (Invoke-WebRequest -Uri "http://localhost:3000/" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
    if ($code -eq 200) { $feAlready = $true }
} catch {}

if ($feAlready) {
    Write-OK "Frontend mar fut 3000-on"
} else {
    # Windows PowerShell kavar: Start-Process -FilePath "npm" a "C:\Program Files\nodejs\npm"
    # Unix shell scriptet talalja elobb -> "%1: nem Win32 alkalmazas" hiba.
    # Fix: child powershell.exe indit, az megkeresi az npm.cmd-et es lefuttatja.
    # AI REVIEW FIX (PR #100 Sourcery bug_risk): -WorkingDirectory helyettesiti a
    # Set-Location '$feDir' interpolaciot -> apostrophe-s path nem torik el.
    $feDir = Join-Path $RepoRoot "frontend-react"
    $env:VITE_PROXY_TARGET = $PRODUCTION_URLS.base_url
    Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoProfile", "-NoLogo", "-ExecutionPolicy", "Bypass",
        "-Command", "npm run dev -- --host 0.0.0.0"
    ) -WorkingDirectory $feDir -WindowStyle Hidden `
        -RedirectStandardOutput "$env:TEMP\valuta-frontend.log" `
        -RedirectStandardError "$env:TEMP\valuta-frontend-err.log"
    Write-Step "Vite inditva - var..."
    $start = Get-Date
    while ($true) {
        Start-Sleep -Seconds 2
        try { if ((Invoke-WebRequest -Uri "http://127.0.0.1:3000/" -TimeoutSec 2 -UseBasicParsing).StatusCode -eq 200) { Write-OK "Frontend READY"; break } } catch {}
        if (((Get-Date) - $start).TotalSeconds -gt 45) { Write-Err "Vite nem indult el 45 masodpercen belul - ld. $env:TEMP\valuta-frontend.log (stdout) es ..-err.log (stderr)"; exit 1 }
    }
}

# 3) Electron penztar-client - IDEMPOTENT (singleton, uzletmenet-kritikus)
if (-not $SkipElectron) {
    Write-Step "3/3 - Electron penztar-client (npm run dev:main)"
    # UZLETMENET-KRITIKUS: a penztar-client csak 1 peldanyban futhat.
    # Ha mar fut electron process, NE inditsunk ujat - a main.ts
    # app.requestSingleInstanceLock() is vedi, de itt hamarabb elkapjuk.
    $existingElectron = Get-Process -Name 'electron' -ErrorAction SilentlyContinue
    if ($existingElectron) {
        Write-OK "Electron mar fut ($($existingElectron.Count) process), skip (singleton)."
        $mainElectron = $existingElectron | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -First 1
        if ($mainElectron) {
            Write-Host "  Meglevo ablak PID $($mainElectron.Id)" -ForegroundColor DarkGray
        }
    } else {
        # AI REVIEW FIX (PR #100 Sourcery bug_risk): -WorkingDirectory quote-mentes.
        $elDir = Join-Path $RepoRoot "penztar-client"
        Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-NoProfile", "-NoLogo", "-ExecutionPolicy", "Bypass",
            "-Command", "npm run dev:main"
        ) -WorkingDirectory $elDir -WindowStyle Hidden `
            -RedirectStandardOutput "$env:TEMPaluta-electron.log" `
            -RedirectStandardError "$env:TEMPaluta-electron-err.log"
        Write-OK "Electron inditva"
    }
} else {
    Write-Step "Electron SKIP"
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  VALUTA OKOSZISZTEMA (production-first) UP" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Backend:      $($PRODUCTION_URLS.base_url)  (Hetzner HA primary)"
Write-Host "  Frontend:     http://localhost:3000  (Vite proxy -> $($PRODUCTION_URLS.domain))"
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