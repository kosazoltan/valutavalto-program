#Requires -Version 5.1
<#
.SYNOPSIS
  Vite/Electron dist/ bundle meret-ellenorzes -- nagy chunk-ok kiszurese.

Replaces: AI "is the bundle too big?" kerdesek + kezi du / du-sh futtas.

Ellenorzi:
  - dist/ mappaban levo fajlok merete (JS/CSS/WASM)
  - 500KB+ JS chunk-ok = WARN
  - 1MB+ JS chunk-ok = ERROR
  - Osszes bundle meret (> 20MB = WARN)
  - .map fajlok jelenlete production dist/-ben (tilos)

.EXAMPLE
  .\scripts\dev-tools\bundle-size-check.ps1
  .\scripts\dev-tools\bundle-size-check.ps1 -Module frontend-react

Exit: 0 = OK, 1 = nagy bundle
#>
param(
    [string]$Module = ""
)

$Root    = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Failed  = $false

# Find dist dirs
$distDirs = @()
if ($Module) {
    $candidate = Join-Path $Root $Module "dist"
    if (Test-Path $candidate) { $distDirs += $candidate }
} else {
    foreach ($mod in @("frontend-react", "penztar-client", "kozponti-client", "arfolyam-keszito-client")) {
        $d = Join-Path $Root $mod "dist"
        if (Test-Path $d) { $distDirs += $d }
    }
}

if (-not $distDirs) {
    Write-Host "bundle-size-check: Nincs dist/ mappa -- futtasd a build-et elobb" -ForegroundColor Yellow
    exit 0
}

$WARN_CHUNK  = 500KB
$ERROR_CHUNK = 1MB
$WARN_TOTAL  = 20MB

foreach ($dir in $distDirs) {
    $rel      = (Resolve-Path -Relative $dir).TrimStart('.\/')
    $allFiles = Get-ChildItem -Recurse -File $dir
    $jsFiles  = $allFiles | Where-Object { $_.Extension -in @(".js", ".mjs", ".cjs") }
    $cssFiles = $allFiles | Where-Object { $_.Extension -eq ".css" }
    $mapFiles = $allFiles | Where-Object { $_.Extension -eq ".map" }

    $totalJs  = ($jsFiles  | Measure-Object Length -Sum).Sum
    $totalCss = ($cssFiles | Measure-Object Length -Sum).Sum
    $totalAll = ($allFiles | Measure-Object Length -Sum).Sum

    Write-Host "bundle-size-check: $rel" -ForegroundColor Cyan
    Write-Host ("  JS total:  {0:N0} KB" -f ($totalJs  / 1KB))
    Write-Host ("  CSS total: {0:N0} KB" -f ($totalCss / 1KB))
    Write-Host ("  All:       {0:N0} KB" -f ($totalAll / 1KB))

    # Source maps in production
    if ($mapFiles) {
        Write-Host "  [ERROR] .map fajlok a dist/-ben -- ne szallisd ki production-be!" -ForegroundColor Red
        $mapFiles | Select-Object -First 5 | ForEach-Object {
            Write-Host "    $($_.Name)" -ForegroundColor Red
        }
        $Failed = $true
    }

    # Large chunks
    $largeChunks = $jsFiles | Where-Object { $_.Length -ge $WARN_CHUNK } |
                   Sort-Object Length -Descending
    foreach ($f in $largeChunks) {
        $kb   = [math]::Round($f.Length / 1KB)
        $name = $f.Name
        if ($f.Length -ge $ERROR_CHUNK) {
            Write-Host ("  [ERROR] {0} = {1} KB (>1MB)" -f $name, $kb) -ForegroundColor Red
            $Failed = $true
        } else {
            Write-Host ("  [WARN]  {0} = {1} KB (>500KB)" -f $name, $kb) -ForegroundColor Yellow
        }
    }

    # Total size
    if ($totalAll -ge $WARN_TOTAL) {
        Write-Host ("  [WARN] Osszes bundle: {0:N0} KB (>20MB)" -f ($totalAll / 1KB)) -ForegroundColor Yellow
    }

    Write-Host ""
}

if ($Failed) {
    exit 1
} else {
    Write-Host "bundle-size-check: OK" -ForegroundColor Green
    exit 0
}
