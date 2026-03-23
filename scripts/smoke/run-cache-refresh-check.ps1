#Requires -Version 5.1
<#
.SYNOPSIS
  Pénztár Electron SQLite cache ellenőrzés (SyncEngine ~30s ciklus után).

.DESCRIPTION
  Futtasd a pénztár kliens elindítása és sikeres bejelentkezés UTÁN
  (hogy legyen JWT és fusson a SyncEngine).

  Alap: vár $WaitSeconds, majd beolvassa ~/.valuta/local.db-ból a
  cached_workers / cached_cash_desks max(cached_at) értékeket.

  Futtatás (repo gyökérből vagy innen):
    cd penztar-client
    ..\scripts\smoke\run-cache-refresh-check.ps1

.PARAMETER WaitSeconds
  Ennyit vár a első mintavétel előtt (alap: 32, > SyncEngine 30s).
#>
param(
  [int]$WaitSeconds = 32,
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$electronDir = Join-Path $WorkspaceRoot 'penztar-client'
$reader = Join-Path $WorkspaceRoot 'scripts\smoke\tmp-read-electron-cache.js'

if (-not (Test-Path -LiteralPath $reader)) {
  throw "Hiányzik: $reader"
}
if (-not (Test-Path -LiteralPath $electronDir)) {
  throw "Hiányzik: $electronDir"
}

Write-Host "[CACHE-SMOKE] Várakozás ${WaitSeconds}s (SyncEngine intervallum ~30s)..."
Start-Sleep -Seconds $WaitSeconds

Push-Location $electronDir
try {
  node $reader
  if ($LASTEXITCODE -ne 0) {
    throw "node exit $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}

Write-Host "[CACHE-SMOKE] Kész. Ha workerTs / cashDeskTs null: még nem töltött cache, vagy nincs bejelentkezés."
