#!/usr/bin/env pwsh
<#
.SYNOPSIS
  A 9 verzio-helyet DETERMINISZTIKUSAN a megadott verziora allitja.

.DESCRIPTION
  A release-workflow `commit-version-bump` jobja ezt hivja a `ci-version-bump-gate.ps1`
  HELYETT. Miert: a gate baseline-ja tartalmazza a legutobbi GitHub Release taget is,
  es ez a job a `publish-release` UTAN fut — ekkor a baseline mar az EPP KIADOTT tag.
  A gate ujrafuttatasa ezert a friss main-fat meg egy patch-csel tovabb bumpolna
  (pl. TARGET=2.28.87 -> 2.28.88), a TARGET_VERSION-ellenorzes elbukna, es a kiadott
  verzio SOHA nem kerulne be a main-be.

  Itt nincs baseline-szamitas: a preflight altal mar kiszamolt es KIADOTT verziot
  irjuk be, majd 9-utas konzisztencia-ellenorzest futtatunk.

.PARAMETER TargetVersion
  A kiadott verzio (X.Y.Z). Kotelezo.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetVersion,

    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
)

$ErrorActionPreference = 'Stop'

if ($TargetVersion -notmatch '^\d+\.\d+\.\d+$') {
    # NEM Write-Error: az $ErrorActionPreference='Stop' mellett terminating hibat dob,
    # amit a PowerShell sajat exit-kodra (1) fordit — a hivo igy nem tudja
    # megkulonboztetni a valodi kapu-elutasitast (2) egy varatlan osszeomlastol.
    Write-Host "::error::apply-release-version: ervenytelen verzio '$TargetVersion' (X.Y.Z formatum kell)." -ForegroundColor Red
    exit 2
}

. (Join-Path $RepoRoot 'installer/build-common.ps1')

$rootPkgPath      = Join-Path $RepoRoot 'package.json'
$feReactPath      = Join-Path $RepoRoot 'frontend-react/package.json'
$clientPkgPath    = Join-Path $RepoRoot 'penztar-client/package.json'
$kozpontiPkgPath  = Join-Path $RepoRoot 'kozponti-client/package.json'
$pomXmlPath       = Join-Path $RepoRoot 'backend/pom.xml'
$rootLockPath     = Join-Path $RepoRoot 'package-lock.json'
$feReactLockPath  = Join-Path $RepoRoot 'frontend-react/package-lock.json'
$clientLockPath   = Join-Path $RepoRoot 'penztar-client/package-lock.json'
$kozpontiLockPath = Join-Path $RepoRoot 'kozponti-client/package-lock.json'

Write-Host "=== Release verzio alkalmazasa: v$TargetVersion (9 hely) ===" -ForegroundColor Cyan

# Idempotens alkalmazas: a Set-PomXmlVersion szandekosan DOB, ha a csere nem
# valtoztatott semmit (ez a bump-utvonalon jogos vedelem). Itt viszont teljesen
# szabalyos, hogy egy fajl mar a cel-verzion all — ezert csak akkor irunk, ha
# tenylegesen elter. A shared helper viselkedeset NEM gyengitjuk.
function Set-VersionIfDifferent {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$NewVersion,
        [Parameter(Mandatory = $true)][scriptblock]$Getter,
        [Parameter(Mandatory = $true)][scriptblock]$Setter,
        [Parameter(Mandatory = $true)][string]$Label
    )
    $current = & $Getter $Path
    if ($current -eq $NewVersion) {
        Write-Host "  $Label : mar v$NewVersion (valtozatlan)" -ForegroundColor DarkGray
        return
    }
    & $Setter $Path $NewVersion
    Write-Host "  $Label : $current -> v$NewVersion" -ForegroundColor Green
}

$pkgGetter  = { param($p) (Get-Content $p -Raw | ConvertFrom-Json).version }
$pkgSetter  = { param($p, $v) Set-PackageJsonVersion -Path $p -NewVersion $v }
# A package-lock.json-ban van "packages": { "": {...} } — az ures property-nev miatt
# a ConvertFrom-Json elszall (-AsHashTable nelkul). A repo sajat gate-je is REGEX-szel
# olvassa (check-version-bump.ps1 Get-PackageLockVersionRow); ugyanazt a mintat kovetjuk.
$lockGetter = {
    param($p)
    $c = Get-Content $p -Raw
    $m = [regex]::Match($c, '"version"\s*:\s*"([^"]+)"')
    if ($m.Success) { $m.Groups[1].Value } else { $null }
}
$lockSetter = { param($p, $v) Set-PackageLockJsonVersion -Path $p -NewVersion $v }
$pomGetter  = { param($p) Get-PomXmlVersion -Path $p }
$pomSetter  = { param($p, $v) Set-PomXmlVersion -Path $p -NewVersion $v }

Set-VersionIfDifferent -Path $rootPkgPath     -NewVersion $TargetVersion -Getter $pkgGetter  -Setter $pkgSetter  -Label 'package.json (root)'
Set-VersionIfDifferent -Path $feReactPath     -NewVersion $TargetVersion -Getter $pkgGetter  -Setter $pkgSetter  -Label 'frontend-react/package.json'
Set-VersionIfDifferent -Path $clientPkgPath   -NewVersion $TargetVersion -Getter $pkgGetter  -Setter $pkgSetter  -Label 'penztar-client/package.json'
Set-VersionIfDifferent -Path $kozpontiPkgPath -NewVersion $TargetVersion -Getter $pkgGetter  -Setter $pkgSetter  -Label 'kozponti-client/package.json'
Set-VersionIfDifferent -Path $pomXmlPath      -NewVersion $TargetVersion -Getter $pomGetter  -Setter $pomSetter  -Label 'backend/pom.xml'
Set-VersionIfDifferent -Path $rootLockPath     -NewVersion $TargetVersion -Getter $lockGetter -Setter $lockSetter -Label 'package-lock.json (root)'
Set-VersionIfDifferent -Path $feReactLockPath  -NewVersion $TargetVersion -Getter $lockGetter -Setter $lockSetter -Label 'frontend-react/package-lock.json'
Set-VersionIfDifferent -Path $clientLockPath   -NewVersion $TargetVersion -Getter $lockGetter -Setter $lockSetter -Label 'penztar-client/package-lock.json'
Set-VersionIfDifferent -Path $kozpontiLockPath -NewVersion $TargetVersion -Getter $lockGetter -Setter $lockSetter -Label 'kozponti-client/package-lock.json'

# 9-utas konzisztencia-ellenorzes.
# A lockfile-olvaso es a konzisztencia-helperek a check-version-bump.ps1-ben elnek,
# nem a build-common.ps1-ben. NEM duplikaljuk oket: a gate scriptet -DryRun modban
# hivjuk, ami baseline-t szamol es kiirja a 9 hely allapotat, de NEM ir fajlt.
# Ha barmelyik hely eltér, a gate exit 2-vel jelez (version drift).
$gateScript = Join-Path $RepoRoot 'installer/scripts/check-version-bump.ps1'
$buildDir   = Join-Path $RepoRoot 'installer/build'

$actual = (Get-Content $rootPkgPath -Raw | ConvertFrom-Json).version
if ($actual -ne $TargetVersion) {
    Write-Host "::error::package.json ($actual) != cel verzio ($TargetVersion)" -ForegroundColor Red
    exit 2
}

Write-Host ""
Write-Host "=== 9-utas konzisztencia-ellenorzes (DryRun gate) ===" -ForegroundColor Cyan
$gateOut = & pwsh -NoLogo -NoProfile -File $gateScript `
    -RepoRoot $RepoRoot -BuildDir $buildDir -CurrentVersion $TargetVersion -DryRun 2>&1
$gateExit = $LASTEXITCODE
$gateOut | ForEach-Object { Write-Host "  $_" }

# exit 2 = verzio-drift a 9 hely kozott -> ez BLOKKOLO.
if ($gateExit -eq 2) {
    Write-Host "::error::Verzio-drift: a 9 hely nem egyezik." -ForegroundColor Red
    exit 2
}

Write-Host ""
Write-Host "OK: mind a 9 hely v$TargetVersion" -ForegroundColor Green
exit 0
