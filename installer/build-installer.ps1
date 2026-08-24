#!/usr/bin/env pwsh
# =============================================================================
# Valutaváltó Pénztár — Egyfájlos Windows Telepítő Build Script
# =============================================================================
# Használat: powershell -ExecutionPolicy Bypass -File build-installer.ps1
# Előfeltételek: JDK 21, Maven (mvnw), Node.js 20+, NSIS 3.x
# =============================================================================

param(
    [string]$Version,
    [switch]$SkipBackendBuild,
    [switch]$SkipFrontendBuild,
    [switch]$SkipDownloads,
    [switch]$SkipNsis,
    [switch]$AllowMissingProductionSecrets
)

# Build date for filename and metadata (YYYYMMDD format)
$BuildDate = Get-Date -Format "yyyyMMdd"

# v2.1.6 (AI review #102+103): centralized version resolution via build-common.ps1
. (Join-Path $PSScriptRoot 'build-common.ps1')
if (-not $Version) {
    $Version = Get-VersionFromPackageJson -ScriptRoot $PSScriptRoot
}

Write-Host "Initial version (pre-gate): v$Version ($BuildDate)" -ForegroundColor Cyan

# v2.3.4 (Zoltan decision 2026-04-27): Version bump enforcement gate
# DEFAULT: AUTO-PATCH every build (X.Y.Z -> X.Y.Z+1)
# Use -NoAutoPatch flag on the guard script to require manual bump
$RepoRoot = Split-Path -Parent $PSScriptRoot
$InstallerDir = $PSScriptRoot
$BuildDirEarly = Join-Path $InstallerDir "build"

Write-Host "`n=== Version Bump Gate (AUTO-PATCH default) ===" -ForegroundColor Cyan
# Run guard via pwsh (PowerShell 7+) to avoid WinPS 5.1 caching/precedence bugs.
# The guard mutates package.json in-place when auto-patching.
$gateScript = Join-Path $PSScriptRoot 'scripts\check-version-bump.ps1'
$gateOutput = @()
try {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        # Prefer pwsh (PS7) for better compatibility and no caching issues
        $gateOutput = & pwsh -NoLogo -NoProfile -File $gateScript `
            -RepoRoot $RepoRoot `
            -BuildDir $BuildDirEarly `
            -CurrentVersion $Version 2>&1
    } else {
        # Fallback to powershell.exe (WinPS 5.1) if pwsh unavailable
        Write-Host "WARN: pwsh not found, using powershell.exe (may have caching issues)" -ForegroundColor Yellow
        $gateOutput = & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $gateScript `
            -RepoRoot $RepoRoot `
            -BuildDir $BuildDirEarly `
            -CurrentVersion $Version 2>&1
    }
} catch {
    throw "VERSION BUMP GATE ERROR: $_"
}

$gateExit = $LASTEXITCODE
$gateOutput | ForEach-Object { Write-Host $_ }
if ($gateExit -ne 0) {
    throw "VERSION BUMP GATE FAILED (exit $gateExit). See output above."
}

# Parse gate output for the resolved version
$versionLine = $gateOutput | Where-Object { $_ -match '^(BUMPED_VERSION|KEPT_VERSION)=(\d+\.\d+\.\d+)$' } | Select-Object -Last 1
if ($versionLine -match '^(BUMPED_VERSION|KEPT_VERSION)=(\d+\.\d+\.\d+)$') {
    $resolvedVersion = $Matches[2]
    $kind = $Matches[1]
    if ($Version -ne $resolvedVersion) {
        Write-Host "Version updated by gate: $Version -> $resolvedVersion ($kind)" -ForegroundColor Magenta
        $Version = $resolvedVersion
    } else {
        Write-Host "Version confirmed: $Version ($kind)" -ForegroundColor Green
    }
} else {
    # Eszter F2 finding 4 (MEDIUM): never fail-open. If we cannot trust the gate output,
    # abort the build to avoid producing a stale-version installer.
    throw "VERSION BUMP GATE: Could not parse a valid BUMPED_VERSION|KEPT_VERSION=X.Y.Z line from gate output. Aborting build."
}

# Defense-in-depth: re-read package.json and verify it matches the gate's resolved version.
$packageJsonVersion = Get-VersionFromPackageJson -ScriptRoot $PSScriptRoot
if ($packageJsonVersion -ne $Version) {
    throw "VERSION BUMP GATE: package.json version ($packageJsonVersion) does not match gate-resolved version ($Version). Aborting build to avoid drift."
}
Write-Host "Build: v$Version ($BuildDate)" -ForegroundColor Cyan

# Preflight: x64 toolchain guard (2026-05-31) — ARM dev-gép védelem (lásd build-common.ps1).
# Fail-fast MIELŐTT a backend-build vagy a natív kliens-csomagolás elindulna.
Assert-X64NodeToolchain

$ErrorActionPreference = "Stop"
# $RepoRoot, $InstallerDir already set during the version gate above
$BuildDir = Join-Path $InstallerDir "build"
$StageDir = Join-Path $BuildDir "stage"

# Verziók
$PG_VERSION = "17.5-1"
$PG_URL = "https://get.enterprisedb.com/postgresql/postgresql-${PG_VERSION}-windows-x64-binaries.zip"
$NSSM_VERSION = "2.24"
$NSSM_URL = "https://nssm.cc/release/nssm-${NSSM_VERSION}.zip"
$NSIS_EXE = "C:\Program Files (x86)\NSIS\makensis.exe"

# S6-02/03 fix: SHA-256 checksums for supply chain integrity
$PG_SHA256 = "795196DF1B2855FD0C7FB52629C6CC16ACAA85819912E732BD4C46863E77EB30"
$NSSM_SHA256 = "F689EE9AF94B00E9E3F0BB072B34CAAF207F32DCB4F5782FC9CA351DF9A06C97"  # nssm.exe win64
$VCREDIST_SHA256 = "CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B"

function Assert-FileHash($Path, $Expected, $Label) {
    $actual = (Get-FileHash $Path -Algorithm SHA256).Hash
    if ($actual -ne $Expected) {
        throw "CHECKSUM MISMATCH for $Label!`nExpected: $Expected`nActual:   $actual`nFile:     $Path"
    }
    Write-Host "  $Label checksum OK" -ForegroundColor Green
}

# Robusztus letoltes: a kulso forrasok (pl. nssm.cc, EnterpriseDB PG-mirror) idoszakosan
# 503/timeout-ot VAGY IP-rate-limit miatt 403/429-et adnak (a CI-runner IP-jet a CDN
# atmenetileg blokkolja, ha tobb build rovid idon belul ugyanarrol a pool-rol tolt).
# Hardening (2026-06-16, v2.28.8 build-incidens — EDB 403 a runner IP-re):
#  - bongeszo User-Agent (no-UA keresekre nemely CDN 403-at ad),
#  - tobb probalkozas (8) hosszabb, JITTER-elt backoff-fal -> egy tobbperces rate-limit
#    ablakot is kiulunk, nem bukik a teljes alairt build egy atmeneti CDN-blokkon.
function Invoke-DownloadWithRetry($Uri, $OutFile, $Label, $MaxAttempts = 8) {
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -TimeoutSec 180 -UserAgent $ua
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 0) { return }
            throw "Ures fajl: $OutFile"
        } catch {
            # Exponencialis backoff 45s-ig + 0-7s jitter (a parhuzamos CI-job-ok ne szinkronban ujrazzanak).
            $wait = [math]::Min(45, [math]::Pow(2, $attempt)) + (Get-Random -Minimum 0 -Maximum 8)
            Write-Host "  [$Label] letoltes sikertelen ($attempt/$MaxAttempts): $($_.Exception.Message). Ujraprobalkozas ${wait}s mulva..." -ForegroundColor Yellow
            if (Test-Path $OutFile) { Remove-Item $OutFile -Force -ErrorAction SilentlyContinue }
            if ($attempt -eq $MaxAttempts) { throw "[$Label] letoltes $MaxAttempts probalkozas utan is sikertelen: $Uri" }
            Start-Sleep -Seconds $wait
        }
    }
}

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

# Env injection: .env.production-t generaljuk a .env.production.example-bol.
# A frontend-react/.env.production es penztar-client/.env.production GIT-IGNORE-OLTAK
# (Google OAuth Web client ID + Desktop client_secret miatt). A repo-gyokeri .env-bol
# (gitignore-olt, csak a fejleszto gepen) olvassuk a tenyleges ertekeket es helyettesitjuk
# a placeholder-eket.

Write-Step "0/6 - Env injection (.env.production a .env-bol)"
$rootEnv = Join-Path $RepoRoot ".env"
if (-not (Test-Path $rootEnv)) {
    if ($AllowMissingProductionSecrets) {
        Write-Host "WARNING: $rootEnv nem letezik - Google OAuth env nelkul a build folytatodik explicit override miatt." -ForegroundColor Yellow
    } else {
        throw "PRODUCTION SECRET GATE: $rootEnv nem letezik. Google OAuth production installer nem keszulhet hianyzo .env nelkul. Fejlesztoi buildhez add meg: -AllowMissingProductionSecrets"
    }
} else {
    $envLines = Get-Content $rootEnv
    $googleWebClientId = ''
    $googleDesktopClientId = ''
    $googleDesktopClientSecret = ''
    foreach ($line in $envLines) {
        if ($line -match '^GOOGLE_CLIENT_ID=(.*)$') { $googleWebClientId = $Matches[1].Trim() }
        elseif ($line -match '^GOOGLE_DESKTOP_CLIENT_ID=(.*)$') { $googleDesktopClientId = $Matches[1].Trim() }
        elseif ($line -match '^GOOGLE_DESKTOP_CLIENT_SECRET=(.*)$') { $googleDesktopClientSecret = $Matches[1].Trim() }
    }
    $missingSecretNames = @()
    if (-not $googleWebClientId) { $missingSecretNames += 'GOOGLE_CLIENT_ID' }
    if (-not $googleDesktopClientId) { $missingSecretNames += 'GOOGLE_DESKTOP_CLIENT_ID' }
    if (-not $googleDesktopClientSecret) { $missingSecretNames += 'GOOGLE_DESKTOP_CLIENT_SECRET' }
    if ($missingSecretNames.Count -gt 0) {
        if ($AllowMissingProductionSecrets) {
            Write-Host ("  WARN: hianyzo Google OAuth env-ek explicit override mellett: " + ($missingSecretNames -join ', ')) -ForegroundColor Yellow
        } else {
            throw ("PRODUCTION SECRET GATE: hianyzo Google OAuth env-ek: " + ($missingSecretNames -join ', ') + ". Production installer Google login nelkul nem adhato ki. Fejlesztoi buildhez add meg: -AllowMissingProductionSecrets")
        }
    }
    $envFiles = @(
        @{ Example = (Join-Path $RepoRoot 'frontend-react\.env.production.example'); Target = (Join-Path $RepoRoot 'frontend-react\.env.production') },
        @{ Example = (Join-Path $RepoRoot 'penztar-client\.env.production.example'); Target = (Join-Path $RepoRoot 'penztar-client\.env.production') }
    )
    foreach ($pair in $envFiles) {
        $exPath = $pair.Example
        $targetPath = $pair.Target
        if (-not (Test-Path $exPath)) {
            throw "ENV TEMPLATE NOT FOUND: $exPath"
        }
        $content = Get-Content -Raw $exPath
        $content = $content.Replace('<<__GOOGLE_WEB_CLIENT_ID__>>', $googleWebClientId)
        $content = $content.Replace('<<__GOOGLE_DESKTOP_CLIENT_ID__>>', $googleDesktopClientId)
        $content = $content.Replace('<<__GOOGLE_DESKTOP_CLIENT_SECRET__>>', $googleDesktopClientSecret)
        [System.IO.File]::WriteAllText($targetPath, $content)
        Write-Host ("  Generated: " + $targetPath) -ForegroundColor Green
    }
}

# ─── Előkészítés ────────────────────────────────────────────────────────────
Write-Step "Előkészítés"
New-Item -ItemType Directory -Force $BuildDir | Out-Null
New-Item -ItemType Directory -Force $StageDir | Out-Null
New-Item -ItemType Directory -Force "$StageDir\pgsql" | Out-Null
New-Item -ItemType Directory -Force "$StageDir\jre" | Out-Null
New-Item -ItemType Directory -Force "$StageDir\backend" | Out-Null
New-Item -ItemType Directory -Force "$StageDir\tools" | Out-Null
New-Item -ItemType Directory -Force "$StageDir\config" | Out-Null
New-Item -ItemType Directory -Force "$StageDir\scripts" | Out-Null
New-Item -ItemType Directory -Force "$StageDir\electron" | Out-Null
Write-Host "Build dir: $BuildDir"
Write-Host "Stage dir: $StageDir"

# ─── 1. Backend Build ──────────────────────────────────────────────────────
if (-not $SkipBackendBuild) {
    Write-Step "1/6 - Backend Build (Maven)"
    $backendDir = Join-Path $RepoRoot "backend"
    Push-Location $backendDir
    try {
        & .\mvnw.cmd package -DskipTests -q
        if ($LASTEXITCODE -ne 0) { throw "Maven build failed" }
        # A pontos, aktualis verzioju JAR-t stageljuk — a target/ sok regi build-artifactot
        # tartalmaz (2.26.x ... 2.27.x). A korabbi "Select-Object -First 1" Sort nelkul az
        # alfabetikusan elso (legregebbi, pl. 2.26.17) JAR-t valasztotta -> minden telepito
        # elavult backendet bundle-olt. Determinisztikus, fail-loud illesztes a $Version-re.
        $jarPath = Join-Path "target" "valuta-backend-$Version.jar"
        if (-not (Test-Path $jarPath)) {
            throw "Backend JAR not found for version ${Version}: $jarPath (Maven nem termelte le a friss artifactot?)"
        }
        Copy-Item $jarPath "$StageDir\backend\valuta-backend.jar"
        Write-Host "Backend JAR: valuta-backend-$Version.jar -> staged" -ForegroundColor Green
    } finally { Pop-Location }
} else { Write-Host "Backend build SKIPPED" -ForegroundColor Yellow }

# ─── 2. JRE Custom Runtime (jlink) ────────────────────────────────────────
Write-Step "2/6 - JRE Custom Runtime (jlink)"
$javaHome = (Get-Command java).Source | Split-Path | Split-Path
$jlinkExe = Join-Path $javaHome "bin\jlink.exe"
$jreOut = "$StageDir\jre"

if (Test-Path "$jreOut\bin\java.exe") {
    Write-Host "JRE already staged, skipping jlink" -ForegroundColor Yellow
} else {
    # jlink requires output dir to not exist (Remove-Item * leaves an empty jre/ folder)
    Remove-Item $jreOut -Recurse -Force -ErrorAction SilentlyContinue

    $modules = @(
        "java.base",
        "java.sql",
        "java.naming",
        "java.management",
        "java.instrument",
        "java.desktop",
        "java.security.jgss",
        "java.security.sasl",
        "java.net.http",
        "java.xml",
        "java.compiler",
        "java.datatransfer",
        "java.logging",
        "java.prefs",
        "java.scripting",
        "java.transaction.xa",
        "jdk.crypto.ec",
        "jdk.unsupported",
        "jdk.zipfs"
    ) -join ","

    & $jlinkExe --module-path "$javaHome\jmods" `
        --add-modules $modules `
        --output $jreOut `
        --strip-debug --compress 2 --no-header-files --no-man-pages

    if ($LASTEXITCODE -ne 0) { throw "jlink failed" }
    $jreSize = (Get-ChildItem $jreOut -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "JRE custom: $([math]::Round($jreSize, 1)) MB" -ForegroundColor Green
}

# ─── 3. Frontend + Electron Build ─────────────────────────────────────────
if (-not $SkipFrontendBuild) {
    Write-Step "3/6 - Frontend + Electron Build"
    $clientDir = Join-Path $RepoRoot "penztar-client"
    Push-Location $clientDir
    try {
        # v2.5.7 KRITIKUS FIX (gyokerok analysis 2026-05-04 utan):
        # KORABBI BUG: itt felulirtuk a `.env`-et `VITE_API_URL=http://localhost:8080/api/v1`-re,
        # amit a Vite a build-time inline-olt a bundle-ba (.env precedence felulbirja a .env.production-t).
        # A renderer `client.ts:41` az `import.meta.env.VITE_API_URL`-t hasznalja default-nak, es az
        # SQLite `server_url`-rel csak ASYNC override-olta — race condition: friss gepen az elso
        # API hivas (`fetchWorkers` a LoginPage-en) azonnal indul, axios meg `localhost:8080`-ra megy
        # mire a Promise resolve-ol -> Network Error.
        #
        # FIX: a `.env`-be CSAK a `VITE_BRANCH_CODE` + `VITE_COMPANY_ID` kerul (LoginPage default-jaihoz),
        # de a `VITE_API_URL`-t NEM bantjuk — igy a `.env.production`-bol jovo `https://excvaluta.com/api/v1`
        # ervenyes. A Vite a build-time ezt inline-olja a renderer-bundle-ba, igy az axios induloban
        # mar a HELYES URL-en mukodik, nem kell az async SQLite override-ra varni.
        $envContent = @'
VITE_BRANCH_CODE=EBC
VITE_COMPANY_ID=1
'@
        # BS-A fix: No BOM (Set-Content -Encoding UTF8 writes BOM on PS 5.1)
        [System.IO.File]::WriteAllText((Join-Path (Get-Location) ".env.local-installer"), $envContent)
        if (Test-Path ".env") { Copy-Item ".env" ".env.backup" -Force }
        Copy-Item ".env.local-installer" ".env" -Force
        Write-Host "  v2.5.7 fix: .env CSAK VITE_BRANCH_CODE+COMPANY_ID-t tartalmaz (NEM VITE_API_URL!)" -ForegroundColor Cyan

        # Install deps if needed
        if (-not (Test-Path "node_modules")) {
            Write-Host "Installing npm dependencies..."
            npm install --ignore-scripts --no-audit --no-fund --loglevel=error
        }

        # Build: step-by-step to avoid dist lock issues on Windows
        Write-Host "Building electron main process..."
        npm run build:electron
        if ($LASTEXITCODE -ne 0) { throw "build:electron failed" }

        Write-Host "Building frontend..."
        npm run build:frontend
        if ($LASTEXITCODE -ne 0) { throw "build:frontend failed" }

        # Replace dist with frontend build using robocopy (Windows lock-safe)
        Write-Host "Copying frontend dist (robocopy /MIR)..."
        $distDir = Join-Path (Get-Location) "dist"
        $frontendDist = Join-Path (Split-Path (Get-Location)) "frontend-react\dist"
        if (-not (Test-Path $frontendDist)) { throw "frontend-react/dist not found after build" }
        # robocopy /MIR mirrors source to dest, exit codes 0-7 are success
        & robocopy $frontendDist $distDir /MIR /NFL /NDL /NJH /NJS /NP
        if ($LASTEXITCODE -gt 7) { throw "robocopy failed with exit code $LASTEXITCODE" }
        $LASTEXITCODE = 0  # Reset for downstream checks
        Write-Host "Frontend dist copied via robocopy" -ForegroundColor Green

        # Electron-builder: produce unpacked directory (not installer — we pack ourselves)
        Write-Host "Packaging Electron (dir target)..."
        npx electron-builder --win dir --config electron-builder.json
        if ($LASTEXITCODE -ne 0) { throw "electron-builder failed" }

        # Copy unpacked electron to stage
        $unpackedDir = Get-Item "release\win-unpacked" -ErrorAction SilentlyContinue
        if (-not $unpackedDir) {
            $unpackedDir = Get-ChildItem "release" -Directory | Where-Object { $_.Name -match "unpacked" } | Select-Object -First 1
        }
        if ($unpackedDir) {
            $electronStage = Join-Path $StageDir "electron"
            Copy-Item (Join-Path $unpackedDir.FullName "*") $electronStage -Recurse -Force

            # Rename non-ASCII product EXE to ASCII-safe Penztar.exe (NSIS / Windows paths)
            $exeFiles = Get-ChildItem (Join-Path $electronStage "*.exe") | Where-Object { $_.Name -ne "Penztar.exe" }
            foreach ($exe in $exeFiles) {
                $newName = "Penztar.exe"
                Write-Host "  EXE rename: $($exe.Name) -> $newName" -ForegroundColor Yellow
                $targetPath = Join-Path (Split-Path $exe.FullName) $newName
                Move-Item $exe.FullName -Destination $targetPath -Force
            }

            Write-Host "Electron app staged" -ForegroundColor Green

            # v2.5.8 FIX: app-update.yml - electron-updater hibanaploja "ENOENT app-update.yml"
            # Az electron-builder a `nsis` target-tel automatikusan generalja a publish config-bol,
            # de mi custom Penztar-Setup.nsi-t hasznalunk, igy a fajl HIANYZIK az unpacked dir-bol.
            # Ennek hianya csak az auto-update funkciot bukja, a fo program tovabb fut, de a Sentry-ben
            # error log generalodik, ami zavaro. Itt manualisan letrehozzuk az electron-builder.json
            # `publish` config alapjan.
            # FONTOS: a `channel: penztar` egyezzen az electron-builder.json publish.channel-jével,
            # hogy az electron-updater a release-ben a `penztar.yml` manifestet keresse (NEM latest.yml).
            # A munkaallomas kliens a `munkaallomas` channel-t hasznalja — igy egy repo-release-ben
            # nincs latest.yml utkozes a ket telepito kozott.
            $appUpdateYml = @"
provider: github
owner: kosazoltan
repo: valutavalto-program
channel: penztar
updaterCacheDirName: valuta-penztar-updater
"@
            $appUpdateTarget = Join-Path $electronStage "resources\app-update.yml"
            [System.IO.File]::WriteAllText($appUpdateTarget, $appUpdateYml, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  app-update.yml generated -> $appUpdateTarget" -ForegroundColor Green
        } else {
            throw "Electron unpacked directory not found in release/"
        }

        # Restore original .env (a 3/6 elejen .env.backup-ba mentett verzio)
        if (Test-Path ".env.backup") {
            Copy-Item ".env.backup" ".env" -Force
            Remove-Item ".env.backup"
        }
    } catch {
        throw
    } finally { Pop-Location }
} else { Write-Host "Frontend/Electron build SKIPPED" -ForegroundColor Yellow }

# ─── 4. Download Dependencies ─────────────────────────────────────────────
if (-not $SkipDownloads) {
    Write-Step "4/6 - Letoltes: PostgreSQL + NSSM"

    $dlDir = Join-Path $BuildDir "downloads"
    New-Item -ItemType Directory -Force $dlDir | Out-Null

    # PostgreSQL binaries
    $pgZip = Join-Path $dlDir "postgresql-binaries.zip"
    if (-not (Test-Path $pgZip)) {
        Write-Host "Downloading PostgreSQL $PG_VERSION binaries..."
        Invoke-DownloadWithRetry $PG_URL $pgZip "PostgreSQL $PG_VERSION"
    } else { Write-Host "PostgreSQL ZIP cached" -ForegroundColor Yellow }

    Assert-FileHash $pgZip $PG_SHA256 "PostgreSQL $PG_VERSION"
    Write-Host "Extracting PostgreSQL..."
    Expand-Archive -Path $pgZip -DestinationPath "$dlDir\pg-extract" -Force
    $pgExtracted = Get-Item "$dlDir\pg-extract\pgsql" -ErrorAction SilentlyContinue
    if (-not $pgExtracted) {
        $pgExtracted = Get-ChildItem "$dlDir\pg-extract" -Directory | Select-Object -First 1
    }
    Copy-Item (Join-Path $pgExtracted.FullName "*") "$StageDir\pgsql\" -Recurse -Force

    # v2.1.5: pgAdmin 4 + doc + include + symbols + StackBuilder eltavolitasa a stage-bol
    # Ok: pgAdmin 4 deep nested paths meghaladjak a Windows MAX_PATH = 260 limitet,
    # NSIS fordito nem tudja megnyitni. Ezek nem kellenek a Penztar szerver runtime-hoz.
    foreach ($dir in @("pgAdmin 4", "doc", "include", "symbols", "StackBuilder")) {
        $pruneTarget = Join-Path "$StageDir\pgsql" $dir
        if (Test-Path $pruneTarget) {
            Remove-Item $pruneTarget -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Pruned: pgsql\$dir" -ForegroundColor DarkGray
        }
    }

    $pgStagedSize = [math]::Round((Get-ChildItem "$StageDir\pgsql" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "PostgreSQL staged - $pgStagedSize MB (pgAdmin/doc pruned)" -ForegroundColor Green

    # NSSM — beszerzési sorrend: 1) mar staged → skip; 2) VENDORED repo-binaris (determinisztikus,
    # nssm.cc-fuggetlen — a nssm.cc tartosan 503-azza a CI-IP-ket); 3) fallback: letoltes (retry).
    # Mindharom utat ugyanaz a SHA256-ellenorzes vedi (NSSM_SHA256 = hivatalos win64 nssm.exe).
    if (Test-Path "$StageDir\tools\nssm.exe") {
        Write-Host "NSSM already staged, skipping" -ForegroundColor Yellow
    } else {
        New-Item -ItemType Directory -Force -Path "$StageDir\tools" | Out-Null
        $vendoredNssm = Join-Path $RepoRoot "installer\vendor\nssm-2.24-win64.exe"
        if (Test-Path $vendoredNssm) {
            Copy-Item $vendoredNssm "$StageDir\tools\nssm.exe" -Force
            Assert-FileHash "$StageDir\tools\nssm.exe" $NSSM_SHA256 "NSSM $NSSM_VERSION (vendored)"
            Write-Host "NSSM staged a vendored repo-binarisbol (nssm.cc-fuggetlen)" -ForegroundColor Green
        } else {
            $nssmZip = Join-Path $dlDir "nssm.zip"
            if (-not (Test-Path $nssmZip)) {
                Write-Host "Downloading NSSM $NSSM_VERSION (nincs vendored copy)..."
                Invoke-DownloadWithRetry $NSSM_URL $nssmZip "NSSM $NSSM_VERSION"
            } else { Write-Host "NSSM ZIP cached" -ForegroundColor Yellow }

            Write-Host "Extracting NSSM..."
            Expand-Archive -Path $nssmZip -DestinationPath "$dlDir\nssm-extract" -Force
            $nssmExe = Get-ChildItem "$dlDir\nssm-extract" -Recurse -Filter "nssm.exe" | Where-Object { $_.Directory.Name -eq "win64" } | Select-Object -First 1
            Copy-Item $nssmExe.FullName "$StageDir\tools\nssm.exe" -Force
            Assert-FileHash "$StageDir\tools\nssm.exe" $NSSM_SHA256 "NSSM $NSSM_VERSION"
            Write-Host "NSSM staged (letoltve)" -ForegroundColor Green
        }
    }
    # VC++ 2015-2022 Redistributable x64 — PG16 EDB binárisok előfeltétele
    $vcRedist = "$StageDir\tools\vc_redist.x64.exe"
    if (Test-Path $vcRedist) {
        Write-Host "VC++ Redistributable already staged, skipping download" -ForegroundColor Yellow
    } else {
        $vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        Write-Host "Downloading VC++ 2015-2022 Redistributable x64..."
        Invoke-WebRequest -Uri $vcUrl -OutFile $vcRedist -UseBasicParsing
        Assert-FileHash $vcRedist $VCREDIST_SHA256 "VC++ Redistributable"
        $vcMb = [math]::Round((Get-Item $vcRedist).Length / 1MB, 1)
        Write-Host "VC++ Redistributable staged - $vcMb MB" -ForegroundColor Green
    }
} else { Write-Host "Downloads SKIPPED" -ForegroundColor Yellow }

# ─── 5. Config + Scripts ──────────────────────────────────────────────────
Write-Step "5/6 - Config es Scripts"

# application-local.properties template (PG_PASSWORD placeholder replaced by NSIS at install time)
$backendConfig = @'
# Auto-generated by Penztar installer
server.port=8080
spring.datasource.url=jdbc:postgresql://localhost:54320/valuta
spring.datasource.username=valuta_user
spring.datasource.password=__PG_PASSWORD__
spring.datasource.driver-class-name=org.postgresql.Driver
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=2
spring.jpa.hibernate.ddl-auto=none
spring.jpa.show-sql=false
# Flyway kezeli a schemat: V0_1 ... V144 migraciok automatikusan lefutnak eloszor
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.baseline-on-migrate=true
spring.flyway.validate-on-migrate=true
spring.flyway.out-of-order=true
# CORS: Electron renderer (app://localhost), web dev (3000/5173), local backend (8080)
cors.allowed-origins=http://localhost:3000,http://localhost:5173,http://localhost:8080,app://localhost,file://
logging.level.root=INFO
springdoc.api-docs.enabled=false
springdoc.swagger-ui.enabled=false
camera.enabled=false
jwt.secret=__GENERATED_AT_INSTALL_TIME__
jwt.expiration=86400000
google.client.id=none
google.client.secret=none
app.encryption.key=__GENERATED_AT_INSTALL_TIME__
app.encryption.salt=__GENERATED_AT_INSTALL_TIME__
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=never
management.health.mail.enabled=false
penztar.bootstrap.company-code=EBC
penztar.bootstrap.worker-code=BORSI
penztar.bootstrap.role-code=CASHIER
# FK-091: local profil — HQ vészkijárat (application-production.properties nem töltődik)
evening.closing.artifact-success-enabled=true
'@
# BS-A fix: No BOM for config template
[System.IO.File]::WriteAllText("$StageDir\config\application-local.properties", $backendConfig)

# Penztar .env template
$penztarEnv = @'
VITE_API_URL=http://localhost:8080/api/v1
VITE_BRANCH_CODE=EBC
VITE_COMPANY_ID=1
'@
[System.IO.File]::WriteAllText("$StageDir\config\penztar.env", $penztarEnv)

# Init DB + seed + service scripts
Copy-Item "$InstallerDir\scripts\init-db.bat" (Join-Path $StageDir "scripts") -ErrorAction SilentlyContinue
$seedSql = Join-Path $InstallerDir "scripts\seed-data.sql"
if (Test-Path $seedSql) {
    Copy-Item $seedSql (Join-Path $StageDir "scripts") -Force
    Write-Host "seed-data.sql staged" -ForegroundColor Green
} else {
    throw "MISSING: seed-data.sql not found at $seedSql - installer would lack seed data!"
}
Copy-Item "$InstallerDir\scripts\start-services.bat" (Join-Path $StageDir "scripts") -ErrorAction SilentlyContinue
Copy-Item "$InstallerDir\scripts\stop-services.bat" (Join-Path $StageDir "scripts") -ErrorAction SilentlyContinue

# v2.5.9: Diagnosztikai szkript (THIN + FULL modban is telepul az INSTDIR-be, parancsikon a Start menun)
$diagSrc = Join-Path $RepoRoot "scripts\diagnose-penztar-network.ps1"
if (Test-Path $diagSrc) {
    Copy-Item $diagSrc (Join-Path $StageDir "scripts") -Force
    Write-Host "diagnose-penztar-network.ps1 staged" -ForegroundColor Green
} else {
    Write-Host "WARN: diagnose-penztar-network.ps1 nem talalhato ($diagSrc) - a 'Halozati diagnosztika' parancsikon nem fog mukodni" -ForegroundColor Yellow
}

Write-Host "Config + scripts staged" -ForegroundColor Green

# ─── 6. NSIS Compile ──────────────────────────────────────────────────────
if (-not $SkipNsis) {
    Write-Step "6/6 - NSIS Compile"
    $nsiScript = Join-Path $InstallerDir "Penztar-Setup.nsi"
    if (-not (Test-Path $nsiScript)) { throw "NSIS script not found: $nsiScript" }

    & $NSIS_EXE /DVERSION=$Version /DBUILD_DATE=$BuildDate /DSTAGE_DIR=$StageDir /DOUTPUT_DIR=$BuildDir $nsiScript
    if ($LASTEXITCODE -ne 0) { throw "NSIS compile failed" }

    $outputExe = Get-ChildItem "$BuildDir\Penztar-Setup-*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($outputExe) {
        $exeSize = $outputExe.Length / 1MB
        $exeSizeMb = [math]::Round($exeSize, 1)
        Write-Host "`nKESZ: $($outputExe.Name) - $exeSizeMb MB" -ForegroundColor Green
        Write-Host "   Helye: $($outputExe.FullName)"
        Write-Host "   Verzio: $Version ($BuildDate)" -ForegroundColor Green
        Write-Host "   Jobb klikk: Tulajdonsagok / Reszletek / FileVersion, ProductVersion" -ForegroundColor DarkGray
    }
} else { Write-Host "NSIS compile SKIPPED" -ForegroundColor Yellow }

Write-Host "`n=== BUILD COMPLETE ===" -ForegroundColor Green
