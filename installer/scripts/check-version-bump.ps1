#!/usr/bin/env pwsh
# =============================================================================
# check-version-bump.ps1 - Version bump enforcement gate (FULL 9-way sync)
# =============================================================================
# Strategy: dot-sources `build-common.ps1` (CLAUDE.md established pattern,
# PR #103 + #104) and uses the official `npm version patch` CLI command
# (industry standard: https://docs.npmjs.com/cli/v10/commands/npm-version)
# plus Maven pom.xml manipulation.
#
# IMPORTANT: This repo has 9 version locations that MUST be kept in sync
# (kanonikus forras: scripts/check-version-sync.mjs; CLAUDE.md release process,
# PR #177):
#   1. package.json (monorepo root)
#   2. frontend-react/package.json
#   3. penztar-client/package.json
#   4. kozponti-client/package.json
#   5. backend/pom.xml (top-level <version>)
#   6. package-lock.json (root: version + packages."".version)
#   7. frontend-react/package-lock.json (version + packages."".version)
#   8. penztar-client/package-lock.json (version + packages."".version)
#   9. kozponti-client/package-lock.json (version + packages."".version)
#
# (2026-08-11: az arfolyam-keszito-client torolve — 11 helybol 9 maradt.)
#
# Behavior (DEFAULT mode = AUTO-PATCH):
#   - If current version <= latest existing build/*.exe: bump all 9 locations
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
Write-Host "=== Version Bump Gate (9-way: package.json x4 + pom.xml + package-lock.json x4) ===" -ForegroundColor Cyan
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

function Format-VersionField {
    param([AllowNull()][string]$Version)
    if ([string]::IsNullOrWhiteSpace($Version)) { return '<missing>' }
    return $Version
}

function Get-PackageLockVersionRow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $path = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $path)) {
        throw "package-lock.json not found: $path"
    }

    $content = Get-Content $path -Raw
    if ((Get-Command Test-Json -ErrorAction SilentlyContinue) -and -not (Test-Json $content)) {
        throw "Invalid package-lock.json: $path"
    }

    $topLevelMatch = [regex]::Match($content, '"version"\s*:\s*"([^"]+)"')
    $packageRootMatch = [regex]::Match($content, '(?s)"packages"\s*:\s*\{\s*""\s*:\s*\{.*?"version"\s*:\s*"([^"]+)"')
    $topLevelVersion = if ($topLevelMatch.Success) { $topLevelMatch.Groups[1].Value } else { $null }
    $packageRootVersion = if ($packageRootMatch.Success) { $packageRootMatch.Groups[1].Value } else { $null }

    return [PSCustomObject]@{
        Label              = $Label
        RelativePath       = $RelativePath
        Path               = $path
        TopLevelVersion    = [string]$topLevelVersion
        PackageRootVersion = [string]$packageRootVersion
    }
}

function Get-AllPackageLockVersions {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    return @(
        Get-PackageLockVersionRow -RepoRoot $RepoRoot -Label 'package-lock.json (root)' -RelativePath 'package-lock.json'
        Get-PackageLockVersionRow -RepoRoot $RepoRoot -Label 'frontend-react/package-lock.json' -RelativePath 'frontend-react\package-lock.json'
        Get-PackageLockVersionRow -RepoRoot $RepoRoot -Label 'penztar-client/package-lock.json' -RelativePath 'penztar-client\package-lock.json'
        Get-PackageLockVersionRow -RepoRoot $RepoRoot -Label 'kozponti-client/package-lock.json' -RelativePath 'kozponti-client\package-lock.json'
    )
}

function Get-AllVersionValues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$ProjectVersions,

        [Parameter(Mandatory = $true)]
        [object[]]$LockfileVersions
    )

    $values = @(
        $ProjectVersions.Root,
        $ProjectVersions.FrontendReact,
        $ProjectVersions.PenztarClient,
        $ProjectVersions.KozpontiClient,
        $ProjectVersions.BackendPom
    )

    foreach ($lock in $LockfileVersions) {
        $values += $lock.TopLevelVersion
        $values += $lock.PackageRootVersion
    }

    return $values
}

function Test-VersionGateConsistency {
    param(
        [Parameter(Mandatory = $true)]
        [object]$ProjectVersions,

        [Parameter(Mandatory = $true)]
        [object[]]$LockfileVersions
    )

    $values = Get-AllVersionValues -ProjectVersions $ProjectVersions -LockfileVersions $LockfileVersions
    $missing = @($values | Where-Object { [string]::IsNullOrWhiteSpace($_) })
    $unique = @($values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)

    return [PSCustomObject]@{
        IsConsistent   = ($ProjectVersions.IsConsistent -and $missing.Count -eq 0 -and $unique.Count -eq 1)
        MissingCount   = $missing.Count
        UniqueVersions = $unique
    }
}

function Write-VersionLocations {
    param(
        [Parameter(Mandatory = $true)]
        [object]$ProjectVersions,

        [Parameter(Mandatory = $true)]
        [object[]]$LockfileVersions,

        [Parameter(Mandatory = $true)]
        [ConsoleColor]$Color
    )

    Write-Host "  package.json (root):                  $($ProjectVersions.Root)" -ForegroundColor $Color
    Write-Host "  frontend-react/package.json:          $($ProjectVersions.FrontendReact)" -ForegroundColor $Color
    Write-Host "  penztar-client/package.json:          $($ProjectVersions.PenztarClient)" -ForegroundColor $Color
    Write-Host "  kozponti-client/package.json:         $($ProjectVersions.KozpontiClient)" -ForegroundColor $Color
    Write-Host "  backend/pom.xml:                      $($ProjectVersions.BackendPom)" -ForegroundColor $Color
    foreach ($lock in $LockfileVersions) {
        Write-Host ("  {0}: version={1}, packages.`"`".version={2}" -f $lock.Label, (Format-VersionField $lock.TopLevelVersion), (Format-VersionField $lock.PackageRootVersion)) -ForegroundColor $Color
    }
}

function Set-PackageLockJsonVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$NewVersion
    )

    if (-not (Test-Path $Path)) {
        throw "package-lock.json not found: $Path"
    }

    $content = Get-Content $Path -Raw
    if ((Get-Command Test-Json -ErrorAction SilentlyContinue) -and -not (Test-Json $content)) {
        throw "Invalid package-lock.json: $Path"
    }

    $topPattern = '("version"\s*:\s*")([^"]*)(")'
    if (-not [regex]::IsMatch($content, $topPattern)) {
        throw "package-lock.json missing top-level version field: $Path"
    }
    $topRegex = [regex]::new($topPattern)
    $content = $topRegex.Replace($content, { param($m) $m.Groups[1].Value + $NewVersion + $m.Groups[3].Value }, 1)

    $rootPackagePattern = '(?s)("packages"\s*:\s*\{\s*""\s*:\s*\{.*?"version"\s*:\s*")([^"]*)(")'
    if (-not [regex]::IsMatch($content, $rootPackagePattern)) {
        throw ("package-lock.json missing packages.`"`".version field: {0}" -f $Path)
    }
    $rootPackageRegex = [regex]::new($rootPackagePattern)
    $content = $rootPackageRegex.Replace($content, { param($m) $m.Groups[1].Value + $NewVersion + $m.Groups[3].Value }, 1)

    Set-Content -Path $Path -Value $content -NoNewline
}

# Validate ALL 9 version locations are in sync BEFORE deciding on bump.
# Eszter F2 finding 3 (HIGH): no-bump early-exit must not skip this check.
# CLAUDE.md release process: 9-way sync required.
$projectVersions = Get-AllProjectVersions -RepoRoot $RepoRoot
$lockfileVersions = Get-AllPackageLockVersions -RepoRoot $RepoRoot
$gateConsistency = Test-VersionGateConsistency -ProjectVersions $projectVersions -LockfileVersions $lockfileVersions

Write-Host "Version locations (9-way check):" -ForegroundColor DarkGray
Write-VersionLocations -ProjectVersions $projectVersions -LockfileVersions $lockfileVersions -Color DarkGray

if (-not $gateConsistency.IsConsistent) {
    Write-Host ""
    Write-Host ("ERROR: Version drift detected. " +
                "All 9 locations must be in sync (CLAUDE.md release process, PR #177).") -ForegroundColor Red
    $foundVersions = @($gateConsistency.UniqueVersions)
    if ($gateConsistency.MissingCount -gt 0) { $foundVersions += '<missing>' }
    Write-Host ("Found: " + ($foundVersions -join ', ')) -ForegroundColor Red
    Write-Host ""
    Write-Host "Fix: align all 9 version locations manually to a single version, then re-run the gate." -ForegroundColor Red
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
    $msg += 'Run (9-way sync needed; npm also updates the matching package-lock.json files):' + [Environment]::NewLine
    $msg += "  cd $RepoRoot && npm version patch --no-git-tag-version" + [Environment]::NewLine
    $msg += "  cd $RepoRoot\frontend-react && npm version patch --no-git-tag-version" + [Environment]::NewLine
    $msg += "  cd $RepoRoot\penztar-client && npm version patch --no-git-tag-version" + [Environment]::NewLine
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
    Write-Host "DryRun: would update 9 locations $baseVersion -> $targetVersion" -ForegroundColor Yellow
    Write-Output "BUMPED_VERSION=$targetVersion"
    exit 0
}

# Pre-bump sync if needed (uses build-common.ps1 helpers)
$rootPkgPath     = Join-Path $RepoRoot 'package.json'
$feReactPath     = Join-Path $RepoRoot 'frontend-react\package.json'
$clientPkgPath   = Join-Path $RepoRoot 'penztar-client\package.json'
$kozpontiPkgPath = Join-Path $RepoRoot 'kozponti-client\package.json'
$pomXmlPath      = Join-Path $RepoRoot 'backend\pom.xml'
$rootLockPath     = Join-Path $RepoRoot 'package-lock.json'
$feReactLockPath  = Join-Path $RepoRoot 'frontend-react\package-lock.json'
$clientLockPath   = Join-Path $RepoRoot 'penztar-client\package-lock.json'
$kozpontiLockPath = Join-Path $RepoRoot 'kozponti-client\package-lock.json'

if ($baseVersion -ne $CurrentVersion) {
    Set-PackageJsonVersion -Path $rootPkgPath     -NewVersion $baseVersion
    Set-PackageJsonVersion -Path $feReactPath     -NewVersion $baseVersion
    Set-PackageJsonVersion -Path $clientPkgPath   -NewVersion $baseVersion
    Set-PackageJsonVersion -Path $kozpontiPkgPath -NewVersion $baseVersion
    Set-PomXmlVersion      -Path $pomXmlPath      -NewVersion $baseVersion
    Set-PackageLockJsonVersion -Path $rootLockPath     -NewVersion $baseVersion
    Set-PackageLockJsonVersion -Path $feReactLockPath  -NewVersion $baseVersion
    Set-PackageLockJsonVersion -Path $clientLockPath   -NewVersion $baseVersion
    Set-PackageLockJsonVersion -Path $kozpontiLockPath -NewVersion $baseVersion
    Write-Host "Pre-bump sync: $CurrentVersion -> $baseVersion (9-way)" -ForegroundColor DarkGray
}

# Run npm version patch in 4 directories (uses build-common.ps1 helper)
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

$kozpontiDir = Join-Path $RepoRoot 'kozponti-client'
Write-Host "Running: npm version patch --no-git-tag-version (kozponti-client)" -ForegroundColor DarkGray
$newKozpontiVersion = Invoke-NpmVersionPatch -Cwd $kozpontiDir
Write-Host "  Kozponti-client: v$newKozpontiVersion" -ForegroundColor Green

# Update backend/pom.xml manually (no Maven CLI needed; regex-based update)
Write-Host "Updating: backend/pom.xml top-level <version>" -ForegroundColor DarkGray
Set-PomXmlVersion -Path $pomXmlPath -NewVersion $newRootVersion
$newPomVersion = Get-PomXmlVersion -Path $pomXmlPath
Write-Host "  Backend pom.xml: $newPomVersion" -ForegroundColor Green

# Sanity check: ALL 9 locations must agree
$postVersions = Get-AllProjectVersions -RepoRoot $RepoRoot
$postLockfileVersions = Get-AllPackageLockVersions -RepoRoot $RepoRoot
$postGateConsistency = Test-VersionGateConsistency -ProjectVersions $postVersions -LockfileVersions $postLockfileVersions
if (-not $postGateConsistency.IsConsistent) {
    Write-Host "ERROR: Version drift after bump:" -ForegroundColor Red
    Write-VersionLocations -ProjectVersions $postVersions -LockfileVersions $postLockfileVersions -Color Red
    exit 2
}

Write-Host "Auto-patch complete: $CurrentVersion -> $newRootVersion (9-way sync OK)" -ForegroundColor Green
Write-Output "BUMPED_VERSION=$newRootVersion"
exit 0
