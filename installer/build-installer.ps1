#!/usr/bin/env pwsh
# =============================================================================
# Valutaváltó Pénztár — Egyfájlos Windows Telepítő Build Script
# =============================================================================
# Használat: powershell -ExecutionPolicy Bypass -File build-installer.ps1
# Előfeltételek: JDK 21, Maven (mvnw), Node.js 20+, NSIS 3.x
# =============================================================================

param(
    [string]$Version = "1.1.0",
    [switch]$SkipBackendBuild,
    [switch]$SkipFrontendBuild,
    [switch]$SkipDownloads,
    [switch]$SkipNsis
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$InstallerDir = $PSScriptRoot
$BuildDir = Join-Path $InstallerDir "build"
$StageDir = Join-Path $BuildDir "stage"

# Verziók
$PG_VERSION = "16.8-1"
$PG_URL = "https://get.enterprisedb.com/postgresql/postgresql-${PG_VERSION}-windows-x64-binaries.zip"
$NSSM_VERSION = "2.24"
$NSSM_URL = "https://nssm.cc/release/nssm-${NSSM_VERSION}.zip"
$NSIS_EXE = "C:\Program Files (x86)\NSIS\makensis.exe"

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
    Write-Step "1/6 — Backend Build (Maven)"
    $backendDir = Join-Path $RepoRoot "backend"
    Push-Location $backendDir
    try {
        & .\mvnw.cmd package -DskipTests -q
        if ($LASTEXITCODE -ne 0) { throw "Maven build failed" }
        $jar = Get-ChildItem "target\valuta-backend-*.jar" -Exclude "*-sources.jar","*-javadoc.jar" | Select-Object -First 1
        if (-not $jar) { throw "Backend JAR not found" }
        Copy-Item $jar.FullName "$StageDir\backend\valuta-backend.jar"
        Write-Host "Backend JAR: $($jar.Name) → staged" -ForegroundColor Green
    } finally { Pop-Location }
} else { Write-Host "Backend build SKIPPED" -ForegroundColor Yellow }

# ─── 2. JRE Custom Runtime (jlink) ────────────────────────────────────────
Write-Step "2/6 — JRE Custom Runtime (jlink)"
$javaHome = (Get-Command java).Source | Split-Path | Split-Path
$jlinkExe = Join-Path $javaHome "bin\jlink.exe"
$jreOut = "$StageDir\jre"

if (Test-Path "$jreOut\bin\java.exe") {
    Write-Host "JRE already staged, skipping jlink" -ForegroundColor Yellow
} else {
    # Clean target
    Remove-Item "$jreOut\*" -Recurse -Force -ErrorAction SilentlyContinue

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
    Write-Step "3/6 — Frontend + Electron Build"
    $clientDir = Join-Path $RepoRoot "penztar-client"
    Push-Location $clientDir
    try {
        # Set local API URL for build
        $envContent = @"
VITE_API_URL=http://localhost:8080/api/v1
VITE_BRANCH_CODE=EBC
VITE_COMPANY_ID=1
"@
        $envContent | Set-Content ".env.local-installer" -Encoding UTF8

        # Backup original .env, replace with local installer config
        if (Test-Path ".env") { Copy-Item ".env" ".env.backup" -Force }
        Copy-Item ".env.local-installer" ".env" -Force

        # Install deps if needed
        if (-not (Test-Path "node_modules")) {
            Write-Host "Installing npm dependencies..."
            npm ci --silent
        }

        # Build: typescript + vite + electron
        Write-Host "Building frontend + electron..."
        npm run build
        if ($LASTEXITCODE -ne 0) { throw "npm run build failed" }

        # Electron-builder: produce unpacked directory (not installer — we pack ourselves)
        Write-Host "Packaging Electron (dir target)..."
        npx electron-builder --win dir --config electron-builder.json
        if ($LASTEXITCODE -ne 0) { throw "electron-builder failed" }

        # Copy unpacked electron to stage
        $unpackedDir = Get-ChildItem "release\win-unpacked" -ErrorAction SilentlyContinue
        if (-not $unpackedDir) {
            $unpackedDir = Get-ChildItem "release" -Directory | Where-Object { $_.Name -match "unpacked" } | Select-Object -First 1
        }
        if ($unpackedDir) {
            Copy-Item "$($unpackedDir.FullName)\*" "$StageDir\electron\" -Recurse -Force

            # FONTOS: Átnevezés ékezetes EXE → ASCII-safe "Penztar.exe"
            # Az electron-builder productName-ből generál ékezetes EXE nevet,
            # ami NSIS-ben és egyes Windows konfigurációkban problémás.
            $exeFiles = Get-ChildItem "$StageDir\electron\*.exe" | Where-Object { $_.Name -match "Pénztár|Penztar|valuta" -and $_.Name -ne "Penztar.exe" }
            foreach ($exe in $exeFiles) {
                $newName = "Penztar.exe"
                Write-Host "  EXE átnevezés: $($exe.Name) → $newName" -ForegroundColor Yellow
                Rename-Item $exe.FullName -NewName $newName -Force
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
    } finally { Pop-Location }
} else { Write-Host "Frontend/Electron build SKIPPED" -ForegroundColor Yellow }

# ─── 4. Download Dependencies ─────────────────────────────────────────────
if (-not $SkipDownloads) {
    Write-Step "4/6 — Letöltés: PostgreSQL + NSSM"

    $dlDir = Join-Path $BuildDir "downloads"
    New-Item -ItemType Directory -Force $dlDir | Out-Null

    # PostgreSQL binaries
    $pgZip = Join-Path $dlDir "postgresql-binaries.zip"
    if (-not (Test-Path $pgZip)) {
        Write-Host "Downloading PostgreSQL $PG_VERSION binaries..."
        Invoke-WebRequest -Uri $PG_URL -OutFile $pgZip -UseBasicParsing
    } else { Write-Host "PostgreSQL ZIP cached" -ForegroundColor Yellow }

    Write-Host "Extracting PostgreSQL..."
    Expand-Archive -Path $pgZip -DestinationPath "$dlDir\pg-extract" -Force
    $pgExtracted = Get-ChildItem "$dlDir\pg-extract\pgsql" -ErrorAction SilentlyContinue
    if (-not $pgExtracted) {
        $pgExtracted = Get-ChildItem "$dlDir\pg-extract" -Directory | Select-Object -First 1
    }
    Copy-Item "$($pgExtracted.FullName)\*" "$StageDir\pgsql\" -Recurse -Force
    Write-Host "PostgreSQL staged" -ForegroundColor Green

    # NSSM
    $nssmZip = Join-Path $dlDir "nssm.zip"
    if (-not (Test-Path $nssmZip)) {
        Write-Host "Downloading NSSM $NSSM_VERSION..."
        Invoke-WebRequest -Uri $NSSM_URL -OutFile $nssmZip -UseBasicParsing
    } else { Write-Host "NSSM ZIP cached" -ForegroundColor Yellow }

    Write-Host "Extracting NSSM..."
    Expand-Archive -Path $nssmZip -DestinationPath "$dlDir\nssm-extract" -Force
    $nssmExe = Get-ChildItem "$dlDir\nssm-extract" -Recurse -Filter "nssm.exe" | Where-Object { $_.Directory.Name -eq "win64" } | Select-Object -First 1
    Copy-Item $nssmExe.FullName "$StageDir\tools\nssm.exe"
    Write-Host "NSSM staged" -ForegroundColor Green
} else { Write-Host "Downloads SKIPPED" -ForegroundColor Yellow }

# ─── 5. Config + Scripts ──────────────────────────────────────────────────
Write-Step "5/6 — Config és Scripts"

# application-local.properties template (PG_PASSWORD placeholder replaced by NSIS at install time)
$backendConfig = @"
# Auto-generated by Penztar installer
server.port=8080
spring.datasource.url=jdbc:postgresql://localhost:54320/valuta
spring.datasource.username=valuta_user
spring.datasource.password=__PG_PASSWORD__
spring.datasource.driver-class-name=org.postgresql.Driver
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=2
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.flyway.enabled=false
# Flyway disabled: JPA ddl-auto=update manages schema, seed via init-db
cors.allowed-origins=app://localhost,http://localhost:3000
logging.level.root=INFO
springdoc.api-docs.enabled=true
springdoc.swagger-ui.enabled=true
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
"@
$backendConfig | Set-Content "$StageDir\config\application-local.properties" -Encoding UTF8

# Penztar .env template
$penztarEnv = @"
VITE_API_URL=http://localhost:8080/api/v1
VITE_BRANCH_CODE=EBC
VITE_COMPANY_ID=1
"@
$penztarEnv | Set-Content "$StageDir\config\penztar.env" -Encoding UTF8

# Init DB + seed + service scripts
Copy-Item "$InstallerDir\scripts\init-db.bat" "$StageDir\scripts\" -ErrorAction SilentlyContinue
$seedSql = Join-Path $InstallerDir "scripts\seed-data.sql"
if (Test-Path $seedSql) {
    Copy-Item $seedSql "$StageDir\scripts\" -Force
    Write-Host "seed-data.sql staged" -ForegroundColor Green
} else {
    throw "MISSING: seed-data.sql not found at $seedSql — installer would lack seed data!"
}
Copy-Item "$InstallerDir\scripts\start-services.bat" "$StageDir\scripts\" -ErrorAction SilentlyContinue
Copy-Item "$InstallerDir\scripts\stop-services.bat" "$StageDir\scripts\" -ErrorAction SilentlyContinue

Write-Host "Config + scripts staged" -ForegroundColor Green

# ─── 6. NSIS Compile ──────────────────────────────────────────────────────
if (-not $SkipNsis) {
    Write-Step "6/6 — NSIS Compile"
    $nsiScript = Join-Path $InstallerDir "Penztar-Setup.nsi"
    if (-not (Test-Path $nsiScript)) { throw "NSIS script not found: $nsiScript" }

    & $NSIS_EXE /DVERSION=$Version /DSTAGE_DIR=$StageDir /DOUTPUT_DIR=$BuildDir $nsiScript
    if ($LASTEXITCODE -ne 0) { throw "NSIS compile failed" }

    $outputExe = Get-ChildItem "$BuildDir\Penztar-Setup-*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($outputExe) {
        $exeSize = $outputExe.Length / 1MB
        Write-Host "`n✅ KÉSZ: $($outputExe.Name) ($([math]::Round($exeSize, 1)) MB)" -ForegroundColor Green
        Write-Host "   Helye: $($outputExe.FullName)"
    }
} else { Write-Host "NSIS compile SKIPPED" -ForegroundColor Yellow }

Write-Host "`n=== BUILD COMPLETE ===" -ForegroundColor Green
