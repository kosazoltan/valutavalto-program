$ErrorActionPreference = "Stop"
$Version = "1.6.0"
$BuildDate = Get-Date -Format "yyyyMMdd"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$InstallerDir = $PSScriptRoot
$BuildDir = Join-Path $InstallerDir "build"
$StageDir = Join-Path $BuildDir "stage"

Write-Host "=== Electron Build ===" -ForegroundColor Cyan
Set-Location (Join-Path $RepoRoot "penztar-client")

# Set local installer env
$envContent = "VITE_API_URL=http://localhost:8080/api/v1`nVITE_BRANCH_CODE=EBC`nVITE_COMPANY_ID=1"
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
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.flyway.enabled=false
cors.allowed-origins=app://localhost
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
