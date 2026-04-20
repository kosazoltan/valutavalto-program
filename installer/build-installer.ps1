#!/usr/bin/env pwsh
# =============================================================================
# Valutaváltó Pénztár — Egyfájlos Windows Telepítő Build Script
# =============================================================================
# Használat: powershell -ExecutionPolicy Bypass -File build-installer.ps1
# Előfeltételek: JDK 21, Maven (mvnw), Node.js 20+, NSIS 3.x
# =============================================================================

param(
    [string]$Version = "2.1.5",
    [switch]$SkipBackendBuild,
    [switch]$SkipFrontendBuild,
    [switch]$SkipDownloads,
    [switch]$SkipNsis
)

# Build date for filename and metadata (YYYYMMDD format)
$BuildDate = Get-Date -Format "yyyyMMdd"
Write-Host "Build: v$Version ($BuildDate)" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$InstallerDir = $PSScriptRoot
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

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

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
        $jar = Get-ChildItem "target\valuta-backend-*.jar" -Exclude "*-sources.jar","*-javadoc.jar" | Select-Object -First 1
        if (-not $jar) { throw "Backend JAR not found" }
        Copy-Item $jar.FullName "$StageDir\backend\valuta-backend.jar"
        Write-Host "Backend JAR: $($jar.Name) -> staged" -ForegroundColor Green
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
        --strip-debug --compress zip-6 --no-header-files --no-man-pages

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
        # Set local API URL for build
        $envContent = @'
VITE_API_URL=http://localhost:8080/api/v1
VITE_BRANCH_CODE=EBC
VITE_COMPANY_ID=1
'@
        # BS-A fix: No BOM (Set-Content -Encoding UTF8 writes BOM on PS 5.1)
        [System.IO.File]::WriteAllText((Join-Path (Get-Location) ".env.local-installer"), $envContent)

        # Backup original .env, replace with local installer config
        if (Test-Path ".env") { Copy-Item ".env" ".env.backup" -Force }
        Copy-Item ".env.local-installer" ".env" -Force

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
        } else {
            throw "Electron unpacked directory not found in release/"
        }

        # Restore original .env
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
        Invoke-WebRequest -Uri $PG_URL -OutFile $pgZip -UseBasicParsing
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

    # NSSM
    # NSSM — skip download if already staged
    if (Test-Path "$StageDir\tools\nssm.exe") {
        Write-Host "NSSM already staged, skipping download" -ForegroundColor Yellow
    } else {
        $nssmZip = Join-Path $dlDir "nssm.zip"
        if (-not (Test-Path $nssmZip)) {
            Write-Host "Downloading NSSM $NSSM_VERSION..."
            Invoke-WebRequest -Uri $NSSM_URL -OutFile $nssmZip -UseBasicParsing
        } else { Write-Host "NSSM ZIP cached" -ForegroundColor Yellow }

        Write-Host "Extracting NSSM..."
        Expand-Archive -Path $nssmZip -DestinationPath "$dlDir\nssm-extract" -Force
        $nssmExe = Get-ChildItem "$dlDir\nssm-extract" -Recurse -Filter "nssm.exe" | Where-Object { $_.Directory.Name -eq "win64" } | Select-Object -First 1
        Copy-Item $nssmExe.FullName "$StageDir\tools\nssm.exe"
        Assert-FileHash "$StageDir\tools\nssm.exe" $NSSM_SHA256 "NSSM $NSSM_VERSION"
        Write-Host "NSSM staged" -ForegroundColor Green
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
