<#
.SYNOPSIS
  Valuta ERP komplex okoszisztema leallitasa - egyben (backend + frontend + Electron).

.DESCRIPTION
  A start-valuta-ecosystem.ps1 parja. Minden egyutt indult, minden egyutt all le.
#>
param(
    [switch]$Force
)

$ErrorActionPreference = 'SilentlyContinue'

function Write-Step { param($Msg) Write-Host "[STOP-ECOSYSTEM] $Msg" -ForegroundColor Cyan }
function Write-OK   { param($Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }

Write-Step "1/4 - Electron penztar-client leallitas"
Get-Process electron, valutavalto-penztar -ErrorAction SilentlyContinue | ForEach-Object {
    Write-OK "Kill: $($_.ProcessName) PID=$($_.Id)"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Step "2/4 - Frontend-react (Vite) leallitas - port 3000"
$vite = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
if ($vite) {
    $pids = $vite.OwningProcess | Select-Object -Unique
    foreach ($pid in $pids) {
        try { Stop-Process -Id $pid -Force; Write-OK "Kill: Vite PID=$pid" } catch {}
    }
}

Write-Step "3/4 - Backend (Spring Boot) leallitas - port 8080"
$be = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if ($be) {
    $pids = $be.OwningProcess | Select-Object -Unique
    foreach ($pid in $pids) {
        try { Stop-Process -Id $pid -Force; Write-OK "Kill: Backend PID=$pid" } catch {}
    }
}

Write-Step "4/4 - Arvak: npm, java processek"
if ($Force) {
    Get-Process node, java -ErrorAction SilentlyContinue | ForEach-Object {
        Write-OK "Force kill: $($_.ProcessName) PID=$($_.Id)"
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "  (--Force kapcsoloval az osszes node/java process megszakitodik)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "  VALUTA OKOSZISZTEMA LEALLITVA" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green