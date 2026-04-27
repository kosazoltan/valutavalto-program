#!/usr/bin/env pwsh
# =============================================================================
# Valutavalto Penztar - kozos build helper-ek (v2.1.6+)
# =============================================================================
# AI REVIEW FIX (PR #103 Sourcery P2 + P3):
# - centralized version resolution from monorepo root package.json
# - robust JSON validation (malformed / missing version -> explicit error)
#
# Dot-source ezt a scriptet minden installer/build-*.ps1 scriptbol:
#   . (Join-Path $PSScriptRoot 'build-common.ps1')
# =============================================================================

function Get-VersionFromPackageJson {
    <#
    .SYNOPSIS
      Version auto-load a monorepo root package.json-bol.
    .PARAMETER ScriptRoot
      A hivo script $PSScriptRoot-ja (pl. installer/).
    .OUTPUTS
      Version string (pl. "2.1.6").
    .EXAMPLE
      $Version = Get-VersionFromPackageJson -ScriptRoot $PSScriptRoot
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot
    )

    $pkgPath = Join-Path (Split-Path -Parent $ScriptRoot) "package.json"

    if (-not (Test-Path $pkgPath)) {
        throw "package.json nem talalhato: $pkgPath - add meg a -Version parametert"
    }

    # Validacio: a JSON ervenyes-e?
    try {
        $pkgJson = Get-Content $pkgPath -Raw | ConvertFrom-Json
    } catch {
        throw "package.json ervenytelen JSON: $pkgPath - javitsd a fajlt vagy add meg -Version parametert. Eredeti hiba: $($_.Exception.Message)"
    }

    # Validacio: van-e nem-ures 'version' mezo?
    if (-not $pkgJson.PSObject.Properties.Match('version') -or [string]::IsNullOrWhiteSpace($pkgJson.version)) {
        throw "package.json nem tartalmaz ervenyes 'version' mezot: $pkgPath - add meg -Version parametert vagy egeszitsd ki a fajlt"
    }

    $version = [string]$pkgJson.version
    Write-Host "Version auto-loaded from package.json: $version" -ForegroundColor DarkGray
    return $version
}

function Invoke-NpmVersionPatch {
    <#
    .SYNOPSIS
      Bumps patch version using `npm version patch --no-git-tag-version` (industry standard).
    .DESCRIPTION
      Idempotently bumps the patch version in package.json via the official npm CLI.
      No git side effects (--no-git-tag-version). Caller must change CWD before calling.
      Reference: https://docs.npmjs.com/cli/v10/commands/npm-version
    .PARAMETER Cwd
      Directory containing the package.json to bump (must be set explicitly).
    .OUTPUTS
      New version string (pl. "2.3.3").
    .EXAMPLE
      $newVer = Invoke-NpmVersionPatch -Cwd "D:\repo\valutavalto-program"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Cwd
    )

    if (-not (Test-Path (Join-Path $Cwd "package.json"))) {
        throw "package.json not found in $Cwd"
    }

    Push-Location $Cwd
    try {
        $output = & npm version patch --no-git-tag-version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "npm version patch failed in $Cwd : $output"
        }
        # Re-read package.json to get authoritative version (npm output parsing
        # is fragile because warnings may interleave with the version line).
        # Eszter F2 finding 5 (HIGH): https://docs.npmjs.com/cli/v10/commands/npm-version
        $pkg = Get-Content (Join-Path $Cwd 'package.json') -Raw | ConvertFrom-Json
        return [string]$pkg.version
    } finally {
        Pop-Location
    }
}

function Set-PackageJsonVersion {
    <#
    .SYNOPSIS
      Sets package.json version field directly (used for sync-before-bump).
    .PARAMETER Path
      Path to package.json file.
    .PARAMETER NewVersion
      Target version string (e.g. "2.3.5").
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$NewVersion
    )

    if (-not (Test-Path $Path)) {
        throw "package.json not found: $Path"
    }

    $pkg = Get-Content $Path -Raw | ConvertFrom-Json
    $pkg.version = $NewVersion
    $pkg | ConvertTo-Json -Depth 100 | Set-Content -Path $Path -NoNewline
    Add-Content -Path $Path -Value ""  # npm convention: trailing newline
}

function Get-LatestExistingBuildVersion {
    <#
    .SYNOPSIS
      Scans build/*.exe filenames and returns the highest version found, or $null.
    .PARAMETER BuildDir
      Path to the build output directory.
    .OUTPUTS
      PSCustomObject @{Name; Variant; Version; VersionObj; Date} or $null if no existing builds.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$BuildDir
    )

    if (-not (Test-Path $BuildDir)) {
        return $null
    }

    # Anchored regex (Eszter F2 finding 6 LOW): only match exactly the expected filename schema.
    $exePattern = '^Penztar-(Setup|Thin|Eltavolito)-(\d+\.\d+\.\d+)-(\d{8})\.exe$'
    $existing = @()

    Get-ChildItem "$BuildDir\*.exe" -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -match $exePattern) {
            $existing += [PSCustomObject]@{
                Name       = $_.Name
                Variant    = $Matches[1]
                Version    = $Matches[2]
                Date       = $Matches[3]
                VersionObj = [version]$Matches[2]
            }
        }
    }

    if ($existing.Count -eq 0) { return $null }
    return $existing | Sort-Object -Property { $_.VersionObj } -Descending | Select-Object -First 1
}
