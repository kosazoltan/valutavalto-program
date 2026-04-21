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
