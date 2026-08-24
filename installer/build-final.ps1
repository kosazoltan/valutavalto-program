param([string]$Version)
$ErrorActionPreference = "Stop"
# v2.1.6 (AI review #103): centralized version via build-common.ps1,
# add optional -Version override capability (consistency with other scripts).
. (Join-Path $PSScriptRoot 'build-common.ps1')
if (-not $Version) {
    $Version = Get-VersionFromPackageJson -ScriptRoot $PSScriptRoot
}
$BuildDate = Get-Date -Format "yyyyMMdd"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$InstallerDir = $PSScriptRoot
$BuildDir = Join-Path $InstallerDir "build"
$StageDir = Join-Path $BuildDir "stage"

# Preflight: x64 toolchain guard (2026-05-31) — ARM dev-gép védelem (lásd build-common.ps1).
# Fail-fast MIELŐTT az electron-builder a natív runtime-ot csomagolná.
Assert-X64NodeToolchain

Write-Host "=== Electron Build ===" -ForegroundColor Cyan
Set-Location (Join-Path $RepoRoot "penztar-client")

# X9 fix: a build-time .env-be TILOS VITE_API_URL-t irni (v2.5.7 minta,
# build-installer.ps1:285-305). A Vite inline-olna es localhost:8080-ra
# race-elne prod helyett. Az URL a .env.production-bol jon (build-installer
# 0/6 lepes generalja a .env.production.example alapjan).
# Fail-loud guard: ha a .env.production hianyzik, a Vite ures URL-lel epulne.
foreach ($envProd in @(
    (Join-Path $RepoRoot "penztar-client\.env.production"),
    (Join-Path $RepoRoot "frontend-react\.env.production")
)) {
    if (-not (Test-Path $envProd)) {
        throw "HIANYZO ENV: $envProd - futtasd elobb a build-installer.ps1-t (0/6 env injection lepes generalja), vagy allitsd elo kezzel a .env.production.example alapjan."
    }
}

# Set local installer env (build-time .env: csak BRANCH_CODE + COMPANY_ID,
# a VITE_API_URL-t a .env.production szolgaltatja)
$envContent = @"
VITE_BRANCH_CODE=EBC
VITE_COMPANY_ID=1
"@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) ".env.local-installer"), $envContent)
if (Test-Path ".env") { Copy-Item ".env" ".env.backup" -Force }
Copy-Item ".env.local-installer" ".env" -Force

# Build electron (vite)
Write-Host "build:electron..."
npm run build:electron
if ($LASTEXITCODE -ne 0) { throw "build:electron failed" }

# Build frontend (tsc + vite in frontend-react)
Write-Host "build:frontend..."
npm run build:frontend
if ($LASTEXITCODE -ne 0) { throw "build:frontend failed" }

# Copy frontend dist over penztar-client/dist using robocopy (lock-safe)
Write-Host "Copying frontend dist via robocopy..."
$src = Join-Path $RepoRoot "frontend-react\dist"
$dst = Join-Path (Get-Location) "dist"
& robocopy $src $dst /MIR /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -gt 7) { throw "robocopy failed ($LASTEXITCODE)" }

# Electron-builder: produce unpacked dir
Write-Host "electron-builder --win dir..."
npx electron-builder --win dir --config electron-builder.json
if ($LASTEXITCODE -ne 0) { throw "electron-builder failed" }

# Copy electron unpacked to stage
$unpackedDir = Get-Item "release\win-unpacked" -ErrorAction SilentlyContinue
if (-not $unpackedDir) {
    $unpackedDir = Get-ChildItem "release" -Directory | Where-Object { $_.Name -match "unpacked" } | Select-Object -First 1
}
if ($unpackedDir) {
    Copy-Item (Join-Path $unpackedDir.FullName "*") "$StageDir\electron\" -Recurse -Force
    # Rename accented EXE to ASCII-safe
    $exeFiles = Get-ChildItem "$StageDir\electron\*.exe" | Where-Object { $_.Name -match "P.nzt.r|Penztar|valuta" -and $_.Name -ne "Penztar.exe" }
    foreach ($exe in $exeFiles) {
        Move-Item $exe.FullName -Destination (Join-Path (Split-Path $exe.FullName) "Penztar.exe") -Force
        Write-Host "  Renamed: $($exe.Name) -> Penztar.exe" -ForegroundColor Yellow
    }
    Write-Host "Electron staged" -ForegroundColor Green
} else { throw "Electron unpacked dir not found" }

# Restore env
if (Test-Path ".env.backup") { Copy-Item ".env.backup" ".env" -Force; Remove-Item ".env.backup" }

# Config + scripts
Write-Host "=== Config + Scripts ===" -ForegroundColor Cyan
$backendConfig = @"
server.port=8080
spring.datasource.url=jdbc:postgresql://localhost:54320/valuta
spring.datasource.username=valuta_user
spring.datasource.password=__PG_PASSWORD__
spring.datasource.driver-class-name=org.postgresql.Driver
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=2
spring.jpa.hibernate.ddl-auto=none
spring.jpa.show-sql=false
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.baseline-on-migrate=true
spring.flyway.validate-on-migrate=true
spring.flyway.out-of-order=true
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
"@
[System.IO.File]::WriteAllText("$StageDir\config\application-local.properties", $backendConfig)
$penztarEnv = "VITE_API_URL=http://localhost:8080/api/v1`nVITE_BRANCH_CODE=EBC`nVITE_COMPANY_ID=1"
[System.IO.File]::WriteAllText("$StageDir\config\penztar.env", $penztarEnv)
Copy-Item "$InstallerDir\scripts\init-db.bat" "$StageDir\scripts\" -ErrorAction SilentlyContinue
Copy-Item "$InstallerDir\scripts\seed-data.sql" "$StageDir\scripts\" -Force
Copy-Item "$InstallerDir\scripts\start-services.bat" "$StageDir\scripts\" -ErrorAction SilentlyContinue
Copy-Item "$InstallerDir\scripts\stop-services.bat" "$StageDir\scripts\" -ErrorAction SilentlyContinue

# NSIS compile
Write-Host "=== NSIS Compile ===" -ForegroundColor Cyan
$nsisExe = "C:\Program Files (x86)\NSIS\makensis.exe"
$nsiScript = Join-Path $InstallerDir "Penztar-Setup.nsi"
& $nsisExe /DVERSION=$Version /DBUILD_DATE=$BuildDate /DSTAGE_DIR=$StageDir /DOUTPUT_DIR=$BuildDir $nsiScript
if ($LASTEXITCODE -ne 0) { throw "NSIS compile failed" }

$outputExe = Get-ChildItem "$BuildDir\Penztar-Setup-*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($outputExe) {
    $mb = [math]::Round($outputExe.Length / 1MB, 1)
    Write-Host "`nKESZ: $($outputExe.Name) ($mb MB)" -ForegroundColor Green
    Write-Host "Helye: $($outputExe.FullName)"
}
