#!/usr/bin/env pwsh
# =============================================================================
# check-version-bump.ps1 - Version bump enforcement gate
# =============================================================================
# Strategy: dot-sources `build-common.ps1` (CLAUDE.md established pattern,
# PR #103 + #104) and uses the official `npm version patch` CLI command
# (industry standard: https://docs.npmjs.com/cli/v10/commands/npm-version).
#
# Behavior (DEFAULT mode = AUTO-PATCH):
#   - If current package.json version <= latest existing build/*.exe version:
#     run `npm version patch --no-git-tag-version` in BOTH:
#       a) repo root
#       b) penztar-client/
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
#   2 = ERROR (npm command failed, files missing, etc.)
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
Write-Host "=== Version Bump Gate (npm version patch) ===" -ForegroundColor Cyan
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

# Validate root + client package.json consistency BEFORE deciding on bump.
# Eszter F2 finding 3 (HIGH): no-bump early-exit must not skip this check.
$rootPkgPath = Join-Path $RepoRoot "package.json"
$clientPkgPath = Join-Path $RepoRoot "penztar-client\package.json"
if (-not (Test-Path $rootPkgPath))   { Write-Error "Root package.json not found: $rootPkgPath"; exit 2 }
if (-not (Test-Path $clientPkgPath)) { Write-Error "Client package.json not found: $clientPkgPath"; exit 2 }

$rootCurrentVersion = (Get-Content $rootPkgPath -Raw | ConvertFrom-Json).version
$clientCurrentVersion = (Get-Content $clientPkgPath -Raw | ConvertFrom-Json).version
if ($rootCurrentVersion -ne $clientCurrentVersion) {
    Write-Host ("ERROR: Pre-gate version mismatch: root package.json=$rootCurrentVersion, penztar-client/package.json=$clientCurrentVersion.") -ForegroundColor Red
    Write-Host "Both must be in sync before the gate runs." -ForegroundColor Red
    Write-Host "Fix: align both package.json files manually, or run 'npm version <X.Y.Z> --no-git-tag-version' in each directory." -ForegroundColor Red
    exit 2
}
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
    $msg += 'Run:' + [Environment]::NewLine
    $msg += "  cd $RepoRoot && npm version patch --no-git-tag-version" + [Environment]::NewLine
    $msg += "  cd $RepoRoot\penztar-client && npm version patch --no-git-tag-version"
    Write-Error $msg
    exit 1
}

# AUTO-PATCH path
# Paths already validated above (Eszter F2 finding 3).
# If existing > current, sync up to existing first (so npm version patch produces existing+1)
$baseVersion = $CurrentVersion
if ($maxExisting -and ([version]::Parse($CurrentVersion).CompareTo([version]::Parse($maxExisting.Version)) -lt 0)) {
    $baseVersion = $maxExisting.Version
    Write-Host "Sync: package.json $CurrentVersion -> $baseVersion (matching latest build before patch)" -ForegroundColor DarkGray
}

if ($DryRun) {
    $b = [version]::Parse($baseVersion)
    $patchPart = if ($b.Build -ge 0) { $b.Build } else { 0 }
    $predicted = "{0}.{1}.{2}" -f $b.Major, $b.Minor, ($patchPart + 1)
    Write-Host "DryRun: would bump $baseVersion -> $predicted via 'npm version patch --no-git-tag-version' in 2 dirs" -ForegroundColor Yellow
    Write-Output "BUMPED_VERSION=$predicted"
    exit 0
}

# Pre-bump sync if needed (uses build-common.ps1 helper)
if ($baseVersion -ne $CurrentVersion) {
    Set-PackageJsonVersion -Path $rootPkgPath   -NewVersion $baseVersion
    Set-PackageJsonVersion -Path $clientPkgPath -NewVersion $baseVersion
    Write-Host "Pre-bump sync: $CurrentVersion -> $baseVersion" -ForegroundColor DarkGray
}

# Run npm version patch in both directories (uses build-common.ps1 helper)
Write-Host "Running: npm version patch --no-git-tag-version (in $RepoRoot)" -ForegroundColor DarkGray
$newRootVersion = Invoke-NpmVersionPatch -Cwd $RepoRoot
Write-Host "  Root: v$newRootVersion" -ForegroundColor Green

$clientDir = Join-Path $RepoRoot "penztar-client"
Write-Host "Running: npm version patch --no-git-tag-version (in $clientDir)" -ForegroundColor DarkGray
$newClientVersion = Invoke-NpmVersionPatch -Cwd $clientDir
Write-Host "  Client: v$newClientVersion" -ForegroundColor Green

# Sanity check: both files agree
if ($newRootVersion -ne $newClientVersion) {
    Write-Error "Version mismatch after bump: root=$newRootVersion, client=$newClientVersion"
    exit 2
}

Write-Host "Auto-patch complete: $CurrentVersion -> $newRootVersion" -ForegroundColor Green
Write-Output "BUMPED_VERSION=$newRootVersion"
exit 0
