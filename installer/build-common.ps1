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

function Assert-X64NodeToolchain {
    <#
    .SYNOPSIS
      x64 toolchain guard (2026-05-31) — ARM dev-gep vedelem.
    .DESCRIPTION
      A fejlesztogep ARM is lehet, de a TERMEK x64 Windows-on fut a kollegaknal. Az
      electron-builder.json arch:["x64"]-re van rogzitve (Electron-runtime + packaging),
      DE a nativ node-modulok rebuild-je (better-sqlite3, node-gyp/electron-rebuild) es a
      Prisma/engine letoltes a PATH-ban levo Node `process.arch`-ja szerint resolve-ol.
      ARM Node-dal ARM nativ runtime szivaroghatna a csomagba -> a kollegak x64 gepen nem
      indulna el. HARD-FAIL, ha nem x64 Node van a PATH-ban (NULLADIK PRIORITAS).
    .EXAMPLE
      Assert-X64NodeToolchain
    #>
    $nodeArch = (& node -p "process.arch").Trim()
    if ($nodeArch -ne "x64") {
        throw "BUILD ABORT (x64 guard): a csomagolashoz x64 Node kell, de a PATH-ban '$nodeArch' Node van. Tegyel x64 Node-ot a PATH elejere (ARM nativ runtime-szennyezes veszelye), majd inditsd ujra a buildet."
    }
    Write-Host "Preflight: x64 Node toolchain OK (process.arch=$nodeArch)" -ForegroundColor Green
}

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

function Get-PomXmlVersion {
    <#
    .SYNOPSIS
      Reads the project (artifact) version from a Maven pom.xml.
    .DESCRIPTION
      Returns the FIRST top-level <version> tag found, which Maven convention
      places right after artifactId. Avoids parent <version> and dependency
      <version> tags by stopping at the first match below the root.
    .PARAMETER Path
      Path to pom.xml.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "pom.xml not found: $Path"
    }

    [xml]$xml = Get-Content $Path -Raw
    # Top-level <version> is a direct child of <project>
    $projectNs = $xml.project.NamespaceURI
    $verNode = $xml.project.ChildNodes | Where-Object { $_.LocalName -eq 'version' } | Select-Object -First 1
    if (-not $verNode) {
        throw "No top-level <version> found in $Path (Maven release pom expected)"
    }
    return [string]$verNode.InnerText
}

function Set-PomXmlVersion {
    <#
    .SYNOPSIS
      Updates the project (artifact) version in a Maven pom.xml.
    .DESCRIPTION
      Replaces ONLY the top-level <version> tag (direct child of <project>),
      preserving all dependency / plugin / parent versions. Uses regex anchored
      to the artifactId tag to be robust against XML namespace variations.
    .PARAMETER Path
      Path to pom.xml.
    .PARAMETER NewVersion
      Target version string (e.g. "2.3.5").
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$NewVersion
    )

    if (-not (Test-Path $Path)) {
        throw "pom.xml not found: $Path"
    }

    $content = Get-Content $Path -Raw
    # Match the version tag that immediately follows the artifactId (top-level project version)
    # Regex: capture <artifactId>...</artifactId>\s*<version>... and replace just the version value.
    $pattern = '(?ms)(<artifactId>[^<]+</artifactId>\s*<version>)(\d+\.\d+\.\d+(?:-[A-Za-z0-9]+)?)(</version>)'
    $regex = [regex]::new($pattern)
    if (-not $regex.IsMatch($content)) {
        throw "Could not locate top-level <artifactId>...</artifactId><version>X.Y.Z</version> in $Path"
    }
    $newContent = $regex.Replace($content, "`${1}$NewVersion`${3}", 1)
    if ($newContent -eq $content) {
        throw "pom.xml version replace produced no change in $Path"
    }
    Set-Content -Path $Path -Value $newContent -NoNewline
}

function Get-AllProjectVersions {
    <#
    .SYNOPSIS
      Reads all 5 version locations across the monorepo.
    .DESCRIPTION
      Single source of truth for what "the version" means in this repo:
        1. package.json (root)
        2. frontend-react/package.json
        3. penztar-client/package.json
        4. kozponti-client/package.json
        5. backend/pom.xml (top-level <version>)
      All 5 must always be in sync. Kanonikus forras: scripts/check-version-sync.mjs.
      Documented in CLAUDE.md and PR #177.
      (2026-08-11: az arfolyam-keszito-client torolve — 6 helybol 5 maradt.)
    .PARAMETER RepoRoot
      Repository root directory.
    .OUTPUTS
      PSCustomObject with Root, FrontendReact, PenztarClient, KozpontiClient,
      BackendPom properties and IsConsistent boolean.
    #>
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $rootPkg = Join-Path $RepoRoot 'package.json'
    $feReactPkg = Join-Path $RepoRoot 'frontend-react\package.json'
    $clientPkg = Join-Path $RepoRoot 'penztar-client\package.json'
    $kozpontiPkg = Join-Path $RepoRoot 'kozponti-client\package.json'
    $pomXml = Join-Path $RepoRoot 'backend\pom.xml'

    $rootVer       = (Get-Content $rootPkg -Raw     | ConvertFrom-Json).version
    $feReactVer    = (Get-Content $feReactPkg -Raw  | ConvertFrom-Json).version
    $clientVer     = (Get-Content $clientPkg -Raw   | ConvertFrom-Json).version
    $kozpontiVer   = (Get-Content $kozpontiPkg -Raw | ConvertFrom-Json).version
    $backendPomVer = Get-PomXmlVersion -Path $pomXml

    $versions = @($rootVer, $feReactVer, $clientVer, $kozpontiVer, $backendPomVer)
    $unique = $versions | Sort-Object -Unique
    $isConsistent = ($unique.Count -eq 1)

    return [PSCustomObject]@{
        Root                  = $rootVer
        FrontendReact         = $feReactVer
        PenztarClient         = $clientVer
        KozpontiClient        = $kozpontiVer
        BackendPom            = $backendPomVer
        IsConsistent          = $isConsistent
        UniqueVersions        = $unique
    }
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
