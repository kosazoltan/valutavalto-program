# start-local.ps1 — Teljes lokális fejlesztői környezet indítás
# Backend (Java :8080) + Frontend (Vite :3000) + Electron (penztar-client)
# Használat: powershell -ExecutionPolicy Bypass -File start-local.ps1

$ErrorActionPreference = "Continue"
$repoRoot = "D:\repo\valutavalto-program"

Write-Host "=== Valutavalto Local Startup ===" -ForegroundColor Cyan

# --- 0. Kill existing processes ---
Write-Host "`n[0/5] Korábbi folyamatok leállítása..." -ForegroundColor Yellow
Get-Process -Name "electron" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
# Kill java on 8080/8081
foreach ($port in 8080, 8081) {
    $pids = netstat -ano 2>$null | Select-String "LISTENING" | Select-String ":$port " | ForEach-Object {
        ($_ -split '\s+')[-1]
    } | Sort-Object -Unique
    foreach ($pid in $pids) {
        if ($pid -and $pid -ne "0") {
            Write-Host "  Killing PID $pid on port $port"
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }
    }
}
# Kill node on 3000
$pids3000 = netstat -ano 2>$null | Select-String "LISTENING" | Select-String ":3000 " | ForEach-Object {
    ($_ -split '\s+')[-1]
} | Sort-Object -Unique
foreach ($pid in $pids3000) {
    if ($pid -and $pid -ne "0") {
        Write-Host "  Killing PID $pid on port 3000"
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep 2

# --- 1. Check PostgreSQL ---
Write-Host "`n[1/5] PostgreSQL ellenőrzés..." -ForegroundColor Yellow
$pgOk = $false
try {
    $tcp = Test-NetConnection -ComputerName 127.0.0.1 -Port 54320 -WarningAction SilentlyContinue
    $pgOk = $tcp.TcpTestSucceeded
} catch {}
if ($pgOk) {
    Write-Host "  PostgreSQL :54320 OK" -ForegroundColor Green
} else {
    Write-Host "  PostgreSQL :54320 NEM ELÉRHETŐ!" -ForegroundColor Red
    Write-Host "  Indítsd: nssm start BestChange-PostgreSQL" -ForegroundColor Red
    exit 1
}

# --- 2. Start Backend ---
Write-Host "`n[2/5] Backend indítás :8080..." -ForegroundColor Yellow

# WARNING: These are insecure dev-only defaults. In any shared or staging environment,
# set the real values via environment variables BEFORE running this script.
$env:JWT_SECRET         = if ($env:JWT_SECRET)         { $env:JWT_SECRET }         else { "BestChangeLocalPenztarJWT2026SecretKey" }
$env:SPRING_DATASOURCE_URL      = if ($env:SPRING_DATASOURCE_URL)      { $env:SPRING_DATASOURCE_URL }      else { "jdbc:postgresql://localhost:54320/valuta" }
$env:SPRING_DATASOURCE_USERNAME = if ($env:SPRING_DATASOURCE_USERNAME) { $env:SPRING_DATASOURCE_USERNAME } else { "valuta_user" }
$env:SPRING_DATASOURCE_PASSWORD = if ($env:SPRING_DATASOURCE_PASSWORD) { $env:SPRING_DATASOURCE_PASSWORD } else { "BestChange2026Local" }
$env:ENCRYPTION_KEY     = if ($env:ENCRYPTION_KEY)     { $env:ENCRYPTION_KEY }     else { "LocalInstallKey2026BestChange" }
$env:ENCRYPTION_SALT    = if ($env:ENCRYPTION_SALT)    { $env:ENCRYPTION_SALT }    else { "a1b2c3d4e5f6a7b8" }

$javaExe = "C:\ProgramData\BestChange\jre\bin\java.exe"
$jarPath = "C:\ProgramData\BestChange\backend\valuta-backend.jar"
$configPath = "C:\ProgramData\BestChange\config\application-local.properties"

if (-not (Test-Path $jarPath)) {
    Write-Host "  Backend JAR nem található: $jarPath" -ForegroundColor Red
    exit 1
}

$backendArgs = @(
    "-jar", $jarPath,
    "--server.port=8080",
    "--spring.datasource.url=$env:SPRING_DATASOURCE_URL",
    "--spring.datasource.username=$env:SPRING_DATASOURCE_USERNAME",
    "--spring.datasource.password=$env:SPRING_DATASOURCE_PASSWORD",
    "--spring.datasource.driver-class-name=org.postgresql.Driver",
    "--spring.jpa.hibernate.ddl-auto=update",
    "--jwt.secret=$env:JWT_SECRET",
    "--jwt.expiration=86400000",
    "--cors.allowed-origins=app://localhost,http://localhost:3000",
    "--app.encryption.key=$env:ENCRYPTION_KEY",
    "--app.encryption.salt=$env:ENCRYPTION_SALT",
    "--management.endpoints.web.exposure.include=health,info",
    "--camera.enabled=false",
    "--penztar.bootstrap.company-code=EBC",
    "--penztar.bootstrap.worker-code=BORSI",
    "--penztar.bootstrap.role-code=CASHIER",
    "--spring.config.additional-location=file:$configPath"
)

$backendProc = Start-Process -FilePath $javaExe -ArgumentList $backendArgs -PassThru -WindowStyle Minimized
Write-Host "  Backend PID: $($backendProc.Id)" -ForegroundColor Green

# Wait for health
Write-Host "  Várakozás backend health-re..." -ForegroundColor Yellow
$maxWait = 90
$waited = 0
$healthy = $false
while ($waited -lt $maxWait) {
    Start-Sleep 3
    $waited += 3
    if ($backendProc.HasExited) {
        Write-Host "  Backend meghalt! Exit: $($backendProc.ExitCode)" -ForegroundColor Red
        break
    }
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8080/actuator/health" -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200) { $healthy = $true; break }
    } catch {}
    Write-Host "  ... $waited s" -NoNewline
}
Write-Host ""
if ($healthy) {
    Write-Host "  Backend :8080 UP ✅" -ForegroundColor Green
} else {
    Write-Host "  Backend :8080 nem indult el ⚠️" -ForegroundColor Red
}

# --- 3. Start Frontend ---
Write-Host "`n[3/5] Frontend indítás :3000..." -ForegroundColor Yellow
$frontendDir = Join-Path $repoRoot "frontend-react"
Start-Process -FilePath "node" -ArgumentList "node_modules/vite/bin/vite.js","--port","3000","--strictPort","--host","0.0.0.0" -WorkingDirectory $frontendDir -WindowStyle Minimized
Start-Sleep 3

$frontendOk = $false
try {
    $resp = Invoke-WebRequest -Uri "http://127.0.0.1:3000" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($resp.StatusCode -eq 200) { $frontendOk = $true }
} catch {}
if ($frontendOk) {
    Write-Host "  Frontend :3000 UP ✅" -ForegroundColor Green
} else {
    Write-Host "  Frontend :3000 nem válaszol ⚠️ (lehet IPv6-only)" -ForegroundColor Yellow
}

# --- 4. Build Electron ---
Write-Host "`n[4/5] Electron build..." -ForegroundColor Yellow
$electronDir = Join-Path $repoRoot "penztar-client"
Push-Location $electronDir
npm run build:electron 2>$null | Out-Null
Pop-Location
Write-Host "  Electron build kész ✅" -ForegroundColor Green

# --- 5. Start Electron ---
Write-Host "`n[5/5] Electron indítás..." -ForegroundColor Yellow

# CRITICAL: Remove ELECTRON_RUN_AS_NODE env var!
# If set, Electron runs as plain Node.js and require('electron') returns path string.
$env:ELECTRON_RUN_AS_NODE = $null
Remove-Item Env:\ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue

$electronExe = Join-Path $electronDir "node_modules\electron\dist\electron.exe"
Start-Process -FilePath $electronExe -ArgumentList $electronDir -WorkingDirectory $electronDir
Write-Host "  Electron indítva ✅" -ForegroundColor Green

Write-Host "`n=== KÉSZ ===" -ForegroundColor Cyan
Write-Host "Backend:  http://127.0.0.1:8080"
Write-Host "Frontend: http://127.0.0.1:3000"
Write-Host "Electron: Valuta Pénztár ablak"
Write-Host ""
Write-Host "Bejelentkezés: EBC/BORSI/1234 vagy EBC/KOSA/1234"
