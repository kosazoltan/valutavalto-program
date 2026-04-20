#!/usr/bin/env pwsh
# =============================================================================
# Valutavalto Penztar -- Thin Client Telepito Build Script (r3)
# =============================================================================
# Thin client = CSAK Electron frontend, NEM tartalmaz:
#   - PostgreSQL (a szerver Hetzner VPS-en fut)
#   - Java JRE / Spring Boot backend
#   - NSSM service manager
# Becsult meret: ~80-90 MB (vs. ~431 MB a fat installernel)
# r6: Locale pruning -- csak hu.pak es en-US.pak marad
#
# Hasznalat: powershell -ExecutionPolicy Bypass -File build-installer-thin.ps1
# Elofeltetelek: Node.js 20+, NSIS 3.x, .env.production beallitva
# =============================================================================

param(
    [string]$Version = "2.1.3",
    [switch]$SkipFrontendBuild,
    [switch]$SkipNsis,
    [string]$ApiUrl = "https://excvaluta.com/api/v1"
)

$BuildDate = Get-Date -Format "yyyyMMdd"
Write-Host "Thin client build: v$Version ($BuildDate)" -ForegroundColor Cyan
Write-Host "API URL: $ApiUrl" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$InstallerDir = $PSScriptRoot
$BuildDir = Join-Path $InstallerDir "build"
$ThinStageDir = Join-Path $BuildDir "thin-stage"
$NSIS_EXE = "C:\Program Files (x86)\NSIS\makensis.exe"

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

# Prepare stage
Write-Step "Elokerito"
New-Item -ItemType Directory -Force $ThinStageDir | Out-Null
Write-Host "Thin stage dir: $ThinStageDir"

# --- 1. Frontend + Electron Build ---
if (-not $SkipFrontendBuild) {
    Write-Step "1/2 - Frontend + Electron Build (thin client)"
    $clientDir = Join-Path $RepoRoot "penztar-client"
    Push-Location $clientDir
    try {
        if ($ApiUrl -ne "https://excvaluta.com/api/v1") {
            $envContent = "VITE_API_URL=$ApiUrl`nVITE_BRANCH_CODE=EBC`nVITE_COMPANY_ID=1`n"
            [System.IO.File]::WriteAllText((Join-Path (Get-Location) ".env.production"), $envContent)
            Write-Host "  .env.production frissitve: $ApiUrl" -ForegroundColor Yellow
        } else {
            Write-Host "  .env.production: $ApiUrl (Hetzner production)" -ForegroundColor Green
        }

        if (-not (Test-Path "node_modules")) {
            Write-Host "npm ci..."
            npm ci --silent
            if ($LASTEXITCODE -ne 0) { throw "npm ci failed" }
        }

        Write-Host "build:electron..."
        npm run build:electron
        if ($LASTEXITCODE -ne 0) { throw "build:electron failed" }

        Write-Host "build:frontend..."
        npm run build:frontend
        if ($LASTEXITCODE -ne 0) { throw "build:frontend failed" }

        $frontendDist = Join-Path $RepoRoot "frontend-react\dist"
        $electronDist = Join-Path (Get-Location) "dist"
        if (Test-Path $frontendDist) {
            & robocopy $frontendDist $electronDist /MIR /NFL /NDL /NJH /NJS /NP
            if ($LASTEXITCODE -gt 7) { throw "robocopy failed: $LASTEXITCODE" }
            $LASTEXITCODE = 0
            Write-Host "  frontend dist -> electron dist OK" -ForegroundColor Green
        }

        Write-Host "electron-builder (dir target, npmRebuild=false)..."
        npx electron-builder --win dir --config electron-builder-thin.json
        if ($LASTEXITCODE -ne 0) { throw "electron-builder failed" }

        $unpackedDir = Get-Item "release-thin\win-unpacked" -ErrorAction SilentlyContinue
        if (-not $unpackedDir) {
            $unpackedDir = Get-ChildItem "release-thin" -Directory | Where-Object { $_.Name -match "unpacked" } | Select-Object -First 1
        }
        if (-not $unpackedDir) { throw "Electron unpacked dir not found" }

        $electronStage = Join-Path $ThinStageDir "app"
        New-Item -ItemType Directory -Force $electronStage | Out-Null
        Copy-Item (Join-Path $unpackedDir.FullName "*") $electronStage -Recurse -Force

        $exes = Get-ChildItem (Join-Path $electronStage "*.exe") | Where-Object { $_.Name -ne "Penztar.exe" }
        foreach ($exe in $exes) {
            $target = Join-Path (Split-Path $exe.FullName) "Penztar.exe"
            Write-Host "  Rename: $($exe.Name) -> Penztar.exe" -ForegroundColor Yellow
            Move-Item $exe.FullName -Destination $target -Force
        }

        # r6: Lokalizacios fajlok csoekkentese -- csak hu es en-US kell
        $localesDir = Join-Path $electronStage "locales"
        if (Test-Path $localesDir) {
            $kept = @('hu.pak', 'en-US.pak')
            $removed = 0
            Get-ChildItem $localesDir -Filter '*.pak' | Where-Object { $_.Name -notin $kept } | ForEach-Object {
                Remove-Item $_.FullName -Force
                $removed++
            }
            Write-Host "  Locales: $removed felesleges .pak torolve, megtartva: $($kept -join ', ')" -ForegroundColor Yellow
        }

        $stageSize = (Get-ChildItem $electronStage -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "  Electron app staged (r6 utan): $([math]::Round($stageSize, 1)) MB" -ForegroundColor Green
    } finally { Pop-Location }
} else {
    Write-Host "Frontend/Electron build SKIPPED" -ForegroundColor Yellow
}

# --- 2. NSIS Compile ---
if (-not $SkipNsis) {
    Write-Step "2/2 - NSIS Compile (thin)"
    $nsiScript = Join-Path $InstallerDir "Penztar-Setup-Thin.nsi"
    if (-not (Test-Path $nsiScript)) { throw "NSIS thin script not found: $nsiScript" }

    & $NSIS_EXE /DVERSION=$Version /DBUILD_DATE=$BuildDate /DTHIN_STAGE_DIR=$ThinStageDir /DOUTPUT_DIR=$BuildDir $nsiScript
    if ($LASTEXITCODE -ne 0) { throw "NSIS compile failed" }

    $outputExe = Get-ChildItem "$BuildDir\Penztar-Thin-*.exe" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($outputExe) {
        $exeSizeMb = [math]::Round($outputExe.Length / 1MB, 1)
        Write-Host "`nKESZ: $($outputExe.Name) - $exeSizeMb MB" -ForegroundColor Green
        Write-Host "   Helye: $($outputExe.FullName)"
    }
} else {
    Write-Host "NSIS compile SKIPPED" -ForegroundColor Yellow
}

Write-Host "`n=== THIN CLIENT BUILD COMPLETE ===" -ForegroundColor Green
