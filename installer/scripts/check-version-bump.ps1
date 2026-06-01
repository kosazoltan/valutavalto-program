#!/usr/bin/env pwsh
# =============================================================================
# check-version-bump.ps1 - Version bump enforcement gate (FULL 6-way sync)
# =============================================================================
# Strategy: dot-sources `build-common.ps1` (CLAUDE.md established pattern,
# PR #103 + #104) and uses the official `npm version patch` CLI command
# (industry standard: https://docs.npmjs.com/cli/v10/commands/npm-version)
# plus Maven pom.xml manipulation.
#
# IMPORTANT: This repo has 6 version locations that MUST be kept in sync
# (kanonikus forras: scripts/check-version-sync.mjs; CLAUDE.md release process,
# PR #177):
#   1. package.json (monorepo root)
#   2. frontend-react/package.json
#   3. penztar-client/package.json
#   4. arfolyam-keszito-client/package.json
#   5. kozponti-client/package.json
#   6. backend/pom.xml (top-level <version>)
#
# Behavior (DEFAULT mode = AUTO-PATCH):
#   - If current version <= latest existing build/*.exe: bump all 6 locations
#   - If current version > latest existing: keep as-is (no bump)
#
# Optional flags:
#   -NoAutoPatch : strict mode, error out instead of bumping
#   -DryRun      : preview only, no file modification
#
# Output (last line, machine-readable):
#   - "BUMPED_VERSION=X.Y.Z" when version was bumped
#   - "KEPT_VERSION=X.Y.Z"   when no bump was needed
#
# Exit codes:
#   0 = OK (PASS or successful auto-patch)
#   1 = BLOCK (bump needed AND -NoAutoPatch set)
#   2 = ERROR (npm command failed, files missing, version drift, etc.)
# =============================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [Parameter(Mandatory = $true)]
    [string]$BuildDir,

    [Parameter(Mandatory = $true)]
    [string]$CurrentVersion,

    [switch]$NoAutoPatch,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Dot-source build-common.ps1 (CLAUDE.md pattern, v2.1.6+)
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'build-common.ps1')

Write-Host ""
Write-Host "=== Version Bump Gate (6-way: package.json x5 + pom.xml) ===" -ForegroundColor Cyan
Write-Host "Current version: $CurrentVersion" -ForegroundColor Yellow
Write-Host "Build dir: $BuildDir" -ForegroundColor DarkGray
$modeLabel = if ($NoAutoPatch) { "STRICT (no auto-patch)" } else { "AUTO-PATCH (default)" }
Write-Host "Mode: $modeLabel" -ForegroundColor DarkGray
if ($DryRun) { Write-Host "DryRun: TRUE (no file modification)" -ForegroundColor DarkGray }

# Verify npm is available
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm not found in PATH. Required for version-bump gate."
    exit 2
}

# Validate ALL 6 version locations are in sync BEFORE deciding on bump.
# Eszter F2 finding 3 (HIGH): no-bump early-exit must not skip this check.
# CLAUDE.md release process: 6-way sync required.
$projectVersions = Get-AllProjectVersions -RepoRoot $RepoRoot

Write-Host "Version locations (6-way check):" -ForegroundColor DarkGray
Write-Host "  package.json (root):                 $($projectVersions.Root)" -ForegroundColor DarkGray
Write-Host "  frontend-react/package.json:         $($projectVersions.FrontendReact)" -ForegroundColor DarkGray
Write-Host "  penztar-client/package.json:         $($projectVersions.PenztarClient)" -ForegroundColor DarkGray
Write-Host "  arfolyam-keszito-client/package.json: $($projectVersions.ArfolyamKeszitoClient)" -ForegroundColor DarkGray
Write-Host "  kozponti-client/package.json:        $($projectVersions.KozpontiClient)" -ForegroundColor DarkGray
Write-Host "  backend/pom.xml:                     $($projectVersions.BackendPom)" -ForegroundColor DarkGray

if (-not $projectVersions.IsConsistent) {
    Write-Host ""
    Write-Host ("ERROR: Version drift detected. " +
                "All 6 locations must be in sync (CLAUDE.md release process, PR #177).") -ForegroundColor Red
    Write-Host ("Found: " + ($projectVersions.UniqueVersions -join ', ')) -ForegroundColor Red
    Write-Host ""
    Write-Host "Fix: align all 6 files manually to a single version, then re-run the gate." -ForegroundColor Red
    exit 2
}

# Use the consistent version as authoritative
$rootCurrentVersion = $projectVersions.Root
if ($CurrentVersion -ne $rootCurrentVersion) {
    Write-Host "WARN: -CurrentVersion ($CurrentVersion) differs from package.json ($rootCurrentVersion); using package.json value." -ForegroundColor Yellow
    $CurrentVersion = $rootCurrentVersion
}

# Use build-common.ps1 helper to scan existing builds
$maxExisting = Get-LatestExistingBuildVersion -BuildDir $BuildDir

if ($maxExisting) {
    Write-Host "Latest existing: v$($maxExisting.Version) ($($maxExisting.Variant), $($maxExisting.Date))" -ForegroundColor Yellow
} else {
    Write-Host "No existing builds found - virgin install OK" -ForegroundColor Green
}

# Decide: bump needed?
# Use [version]::Parse + CompareTo (avoids WinPS 5.1 -le operator caching bug)
$bumpNeeded = $false
if ($maxExisting) {
    $cur = [version]::Parse($CurrentVersion)
    $max = [version]::Parse($maxExisting.Version)
    if ($cur.CompareTo($max) -le 0) {
        $bumpNeeded = $true
    }
}

if (-not $bumpNeeded) {
    Write-Host "Version OK: $CurrentVersion is greater than latest build (no bump needed)" -ForegroundColor Green
    Write-Output "KEPT_VERSION=$CurrentVersion"
    exit 0
}

# Bump needed
if ($NoAutoPatch) {
    $maxV = $maxExisting.Version
    $msg = 'VERSION BUMP REQUIRED!' + [Environment]::NewLine + [Environment]::NewLine
    $msg += "Current version ($CurrentVersion) is not greater than latest build ($maxV)." + [Environment]::NewLine
    $msg += 'Manual bump required (NoAutoPatch mode active).' + [Environment]::NewLine + [Environment]::NewLine
    $msg += 'Run (6-way sync needed):' + [Environment]::NewLine
    $msg += "  cd $RepoRoot && npm version patch --no-git-tag-version" + [Environment]::NewLine
    $msg += "  cd $RepoRoot\frontend-react && npm version patch --no-git-tag-version" + [Environment]::NewLine
    $msg += "  cd $RepoRoot\penztar-client && npm version patch --no-git-tag-version" + [Environment]::NewLine
    $msg += "  cd $RepoRoot\arfolyam-keszito-client && npm version patch --no-git-tag-version" + [Environment]::NewLine
    $msg += "  cd $RepoRoot\kozponti-client && npm version patch --no-git-tag-version" + [Environment]::NewLine
    $msg += "  # backend/pom.xml: update top-level <version> tag manually"
    Write-Error $msg
    exit 1
}

# AUTO-PATCH path
# If existing > current, sync up to existing first (so bump produces existing+1)
$baseVersion = $CurrentVersion
if ($maxExisting -and ([version]::Parse($CurrentVersion).CompareTo([version]::Parse($maxExisting.Version)) -lt 0)) {
    $baseVersion = $maxExisting.Version
    Write-Host "Sync: package.json $CurrentVersion -> $baseVersion (matching latest build before patch)" -ForegroundColor DarkGray
}

# Compute target version
$b = [version]::Parse($baseVersion)
$patchPart = if ($b.Build -ge 0) { $b.Build } else { 0 }
$targetVersion = "{0}.{1}.{2}" -f $b.Major, $b.Minor, ($patchPart + 1)

if ($DryRun) {
    Write-Host "DryRun: would update 6 locations $baseVersion -> $targetVersion" -ForegroundColor Yellow
    Write-Output "BUMPED_VERSION=$targetVersion"
    exit 0
}

# Pre-bump sync if needed (uses build-common.ps1 helpers)
$rootPkgPath     = Join-Path $RepoRoot 'package.json'
$feReactPath     = Join-Path $RepoRoot 'frontend-react\package.json'
$clientPkgPath   = Join-Path $RepoRoot 'penztar-client\package.json'
$arfolyamPkgPath = Join-Path $RepoRoot 'arfolyam-keszito-client\package.json'
$kozpontiPkgPath = Join-Path $RepoRoot 'kozponti-client\package.json'
$pomXmlPath      = Join-Path $RepoRoot 'backend\pom.xml'

if ($baseVersion -ne $CurrentVersion) {
    Set-PackageJsonVersion -Path $rootPkgPath     -NewVersion $baseVersion
    Set-PackageJsonVersion -Path $feReactPath     -NewVersion $baseVersion
    Set-PackageJsonVersion -Path $clientPkgPath   -NewVersion $baseVersion
    Set-PackageJsonVersion -Path $arfolyamPkgPath -NewVersion $baseVersion
    Set-PackageJsonVersion -Path $kozpontiPkgPath -NewVersion $baseVersion
    Set-PomXmlVersion      -Path $pomXmlPath      -NewVersion $baseVersion
    Write-Host "Pre-bump sync: $CurrentVersion -> $baseVersion (6-way)" -ForegroundColor DarkGray
}

# Run npm version patch in 5 directories (uses build-common.ps1 helper)
Write-Host "Running: npm version patch --no-git-tag-version (root)" -ForegroundColor DarkGray
$newRootVersion = Invoke-NpmVersionPatch -Cwd $RepoRoot
Write-Host "  Root: v$newRootVersion" -ForegroundColor Green

$feReactDir = Join-Path $RepoRoot 'frontend-react'
Write-Host "Running: npm version patch --no-git-tag-version (frontend-react)" -ForegroundColor DarkGray
$newFeReactVersion = Invoke-NpmVersionPatch -Cwd $feReactDir
Write-Host "  Frontend-react: v$newFeReactVersion" -ForegroundColor Green

$clientDir = Join-Path $RepoRoot 'penztar-client'
Write-Host "Running: npm version patch --no-git-tag-version (penztar-client)" -ForegroundColor DarkGray
$newClientVersion = Invoke-NpmVersionPatch -Cwd $clientDir
Write-Host "  Client: v$newClientVersion" -ForegroundColor Green

$arfolyamDir = Join-Path $RepoRoot 'arfolyam-keszito-client'
Write-Host "Running: npm version patch --no-git-tag-version (arfolyam-keszito-client)" -ForegroundColor DarkGray
$newArfolyamVersion = Invoke-NpmVersionPatch -Cwd $arfolyamDir
Write-Host "  Arfolyam-keszito-client: v$newArfolyamVersion" -ForegroundColor Green

$kozpontiDir = Join-Path $RepoRoot 'kozponti-client'
Write-Host "Running: npm version patch --no-git-tag-version (kozponti-client)" -ForegroundColor DarkGray
$newKozpontiVersion = Invoke-NpmVersionPatch -Cwd $kozpontiDir
Write-Host "  Kozponti-client: v$newKozpontiVersion" -ForegroundColor Green

# Update backend/pom.xml manually (no Maven CLI needed; regex-based update)
Write-Host "Updating: backend/pom.xml top-level <version>" -ForegroundColor DarkGray
Set-PomXmlVersion -Path $pomXmlPath -NewVersion $newRootVersion
$newPomVersion = Get-PomXmlVersion -Path $pomXmlPath
Write-Host "  Backend pom.xml: $newPomVersion" -ForegroundColor Green

# Sanity check: ALL 6 locations must agree
$postVersions = Get-AllProjectVersions -RepoRoot $RepoRoot
if (-not $postVersions.IsConsistent) {
    Write-Host "ERROR: Version drift after bump:" -ForegroundColor Red
    Write-Host "  Root:                    $($postVersions.Root)" -ForegroundColor Red
    Write-Host "  Frontend-react:          $($postVersions.FrontendReact)" -ForegroundColor Red
    Write-Host "  Penztar-client:          $($postVersions.PenztarClient)" -ForegroundColor Red
    Write-Host "  Arfolyam-keszito-client: $($postVersions.ArfolyamKeszitoClient)" -ForegroundColor Red
    Write-Host "  Kozponti-client:         $($postVersions.KozpontiClient)" -ForegroundColor Red
    Write-Host "  Backend pom:             $($postVersions.BackendPom)" -ForegroundColor Red
    exit 2
}

Write-Host "Auto-patch complete: $CurrentVersion -> $newRootVersion (6-way sync OK)" -ForegroundColor Green
Write-Output "BUMPED_VERSION=$newRootVersion"
exit 0
