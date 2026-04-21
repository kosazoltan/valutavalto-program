#!/usr/bin/env pwsh
# =============================================================================
# Valutavalto Penztar - Standalone Eltavolito (Cleanup) Build Script
# =============================================================================
# Egy onallo `Penztar-Eltavolito-<version>-<date>.exe` fordit le, amivel
# a kollegak gepen levo regi / torott telepitest TELJESEN el lehet tavolitani
# (szolgaltatasok leallitasa, PostgreSQL stop, file/registry/firewall cleanup)
# MIELOTT futtatjak a Penztar-Setup-<version>.exe-t.
#
# Hasznalat:
#   powershell -ExecutionPolicy Bypass -File installer\build-cleanup.ps1
#
# Elofeltetel: NSIS 3.x (C:\Program Files (x86)\NSIS\makensis.exe)
# Output:     installer\build\Penztar-Eltavolito-<version>-<date>.exe
# =============================================================================

param(
    [string]$Version
)

# v2.1.6 (AI review #102 P2): single source of truth - package.json root
if (-not $Version) {
    $pkgPath = Join-Path (Split-Path -Parent $PSScriptRoot) "package.json"
    if (Test-Path $pkgPath) {
        $Version = (Get-Content $pkgPath -Raw | ConvertFrom-Json).version
        Write-Host "Version auto-loaded from package.json: $Version" -ForegroundColor DarkGray
    } else { throw "package.json nem talalhato: $pkgPath - add meg -Version parametert" }
}

$ErrorActionPreference = "Stop"
$BuildDate    = Get-Date -Format "yyyyMMdd"
$InstallerDir = $PSScriptRoot
$BuildDir     = Join-Path $InstallerDir "build"
$NsiScript    = Join-Path $InstallerDir "Penztar-Cleanup.nsi"
$NsisExe      = "C:\Program Files (x86)\NSIS\makensis.exe"

Write-Host "=== Penztar-Eltavolito build v$Version ($BuildDate) ===" -ForegroundColor Cyan

if (-not (Test-Path $NsisExe)) {
    throw "NSIS nem talalhato: $NsisExe`nTelepitsd: https://nsis.sourceforge.io/Download"
}
if (-not (Test-Path $NsiScript)) {
    throw "NSIS script hianyzik: $NsiScript"
}

New-Item -ItemType Directory -Force $BuildDir | Out-Null

Push-Location $InstallerDir
try {
    & $NsisExe /DVERSION=$Version /DBUILD_DATE=$BuildDate $NsiScript
    if ($LASTEXITCODE -ne 0) { throw "NSIS compile failed (exit $LASTEXITCODE)" }
} finally {
    Pop-Location
}

$outputExe = Get-ChildItem "$BuildDir\Penztar-Eltavolito-*.exe" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($outputExe) {
    $mb = [math]::Round($outputExe.Length / 1MB, 2)
    Write-Host ""
    Write-Host "KESZ: $($outputExe.Name) - $mb MB" -ForegroundColor Green
    Write-Host "   Helye:  $($outputExe.FullName)"
    Write-Host "   Verzio: $Version ($BuildDate)" -ForegroundColor DarkGray
} else {
    throw "NSIS exit=0, de a kimeneti EXE nem jott letre: $BuildDir\Penztar-Eltavolito-*.exe"
}
