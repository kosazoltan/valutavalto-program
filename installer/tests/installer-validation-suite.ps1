#!/usr/bin/env pwsh
# =============================================================================
# Valutaváltó Pénztár Installer v1.5.0 — Teljes Validációs Teszt Suite
# =============================================================================
# Forrás: 5 tankönyv/referencia alapján:
#   1. NSIS Users Manual (nsis.sourceforge.io)
#   2. Tricentis "Installation Testing" methodology
#   3. SoftwareTestingHelp install/uninstall checklist
#   4. GeeksForGeeks "Installation Testing in Software Testing"
#   5. Advanced Installer "Application Packaging Testing Process Guide"
# =============================================================================
# Használat: powershell -ExecutionPolicy Bypass -File installer-validation-suite.ps1
# Futtatás: Rendszergazdaként (admin)!
# =============================================================================

param(
    [string]$InstallerExe = "",
    [switch]$SkipInstall,
    [switch]$SkipUninstall,
    [switch]$OnlyValidate
)

$ErrorActionPreference = "Continue"
$global:TestResults = @()
$global:PassCount = 0
$global:FailCount = 0
$global:WarnCount = 0
$global:StartTime = Get-Date

# --- Konfigurálás ---
$INSTDIR = "C:\Program Files\Valutavalto Penztar"
$DATA_DIR = "C:\ProgramData\BestChange"

# X8a fix: verzio dinamikusan a monorepo-gyoker package.json-bol (build-common.ps1
# helper, ugyanaz, amit a build-installer.ps1:24 hasznal). Hardcode-literal TILOS.
# $ErrorActionPreference = "Continue" van -> a dot-source + hivas hibajat try/catch-ben
# kell fail-loudda tenni, kulonben a suite verziotlanul fut tovabb rossz $VERSION-nel.
try {
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'build-common.ps1')
    $VERSION = Get-VersionFromPackageJson -ScriptRoot (Split-Path -Parent $PSScriptRoot)
} catch {
    Write-Host "HIBA: verzio nem olvashato a package.json-bol: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$PG_PORT = 54320
$BE_PORT = 8080
$SVC_PG = "BestChange-PostgreSQL"
$SVC_BE = "BestChange-Backend"
$PUBLISHER = "Exclusive Best Change Zrt."
$global:InstalledMode = $null

# X8b fix: az NSI SetRegView 64-gyel ir (Penztar-Setup.nsi:1171-1187, v2.3.1
# Codex P2 #220) -> a nativ 64-bit kulcs az elsodleges. WOW6432Node fallback
# a v2.3.1 ELOTTI (32-bit view-ba irt) installok validalasahoz. Ha a 64-bit PS
# nem elerheto, a registry-nezet redirektalodhat -> warn (de nem abort).
if (-not [Environment]::Is64BitProcess) {
    Write-Host "WARN: 32-bit PowerShell folyamat - a registry-nezet redirektalodhat, futtasd 64-bit PS-bol!" -ForegroundColor Yellow
}
function Resolve-RegPath([string[]]$Candidates) {
    foreach ($c in $Candidates) { if (Test-Path $c) { return $c } }
    return $Candidates[0]
}
$REG_APP = Resolve-RegPath @(
    'HKLM:\Software\BestChange\ValutavaltoPenztar',
    'HKLM:\Software\WOW6432Node\BestChange\ValutavaltoPenztar'
)
$REG_UNINST = Resolve-RegPath @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar'
)

# FULL install may use a WinNAT-safe fallback port (registry PgPort/HttpPort).
if (Test-Path $REG_APP) {
    $portReg = Get-ItemProperty $REG_APP -ErrorAction SilentlyContinue
    if ($null -ne $portReg) {
        if ($portReg.PgPort -match '^\d+$') { $PG_PORT = [int]$portReg.PgPort }
        if ($portReg.HttpPort -match '^\d+$') { $BE_PORT = [int]$portReg.HttpPort }
    }
}

function Get-InstalledMode {
    if (-not (Test-Path $REG_APP)) {
        return $global:InstalledMode
    }

    $appReg = Get-ItemProperty $REG_APP -ErrorAction SilentlyContinue
    if ($null -eq $appReg) {
        return $global:InstalledMode
    }

    $mode = $appReg.InstallMode
    if ([string]::IsNullOrWhiteSpace($mode)) {
        $mode = "FULL"
    }

    $global:InstalledMode = $mode.ToUpperInvariant()
    return $global:InstalledMode
}

function Test-IsFullInstallMode {
    return (Get-InstalledMode) -eq "FULL"
}

function Wait-ForPathState {
    param(
        [string]$Path,
        [bool]$ShouldExist,
        [int]$TimeoutSeconds = 15
    )

    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        if ((Test-Path $Path) -eq $ShouldExist) {
            return $true
        }
        Start-Sleep -Seconds 1
        $elapsed++
    }

    return ((Test-Path $Path) -eq $ShouldExist)
}

# Installer exe auto-detect
if (-not $InstallerExe) {
    $buildDir = Join-Path (Split-Path $PSScriptRoot) "build"
    $InstallerExe = Get-ChildItem "$buildDir\Penztar-Setup-*.exe" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    if (-not $InstallerExe) {
        Write-Host "HIBA: Nem talalhato installer exe a build/ mappaban!" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Installer: $InstallerExe" -ForegroundColor Cyan
Write-Host "Verzio: $VERSION" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# TEST FRAMEWORK
# =============================================================================
function Test-Assert {
    param(
        [string]$Category,
        [string]$TestName,
        [bool]$Condition,
        [string]$Detail = "",
        [string]$Severity = "FAIL" # FAIL | WARN
    )
    $result = [PSCustomObject]@{
        Category = $Category
        Test     = $TestName
        Result   = if ($Condition) { "PASS" } else { $Severity }
        Detail   = $Detail
    }
    $global:TestResults += $result

    if ($Condition) {
        $global:PassCount++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } elseif ($Severity -eq "WARN") {
        $global:WarnCount++
        Write-Host "  [WARN] $TestName — $Detail" -ForegroundColor Yellow
    } else {
        $global:FailCount++
        Write-Host "  [FAIL] $TestName — $Detail" -ForegroundColor Red
    }
}

# =============================================================================
# CATEGORY 1: PRE-INSTALL VALIDATION (Tricentis + GeeksForGeeks)
# "Verify system requirements before installation"
# =============================================================================
function Test-PreInstall {
    Write-Host "`n=== 1. PRE-INSTALL VALIDACIO ===" -ForegroundColor Cyan

    # 1.1 Installer exe létezik és mérete ésszerű
    $exeExists = Test-Path $InstallerExe
    Test-Assert "PreInstall" "Installer EXE letezik" $exeExists "Path: $InstallerExe"
    if ($exeExists) {
        $sizeMB = [math]::Round((Get-Item $InstallerExe).Length / 1MB, 1)
        Test-Assert "PreInstall" "Installer meret esszeru (>100MB)" ($sizeMB -gt 100) "Meret: $sizeMB MB"
    }

    # 1.2 EXE Properties (Windows metadata) — Forrás: NSIS Manual
    if ($exeExists) {
        $vi = (Get-Item $InstallerExe).VersionInfo
        $fileVersionOk = ($vi.FileVersion -eq $VERSION -or $vi.FileVersion -eq "$VERSION.0")
        Test-Assert "PreInstall" "FileVersion metadata kitoltve" $fileVersionOk "FileVersion: $($vi.FileVersion)"
        Test-Assert "PreInstall" "ProductName metadata" ($vi.ProductName -like "*Penztar*" -or $vi.ProductName -like "*P*nzt*r*") "ProductName: $($vi.ProductName)"
        Test-Assert "PreInstall" "CompanyName metadata" ($vi.CompanyName -like "*Best Change*" -or $vi.CompanyName -like "*Exclusive*") "CompanyName: $($vi.CompanyName)"
        Test-Assert "PreInstall" "FileDescription metadata" ($null -ne $vi.FileDescription -and $vi.FileDescription -ne "") "FileDescription: $($vi.FileDescription)"
    }

    # 1.3 Admin jog check
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    Test-Assert "PreInstall" "Teszt admin joggal fut" $isAdmin "Admin: $isAdmin; nem emelt shell eseten UAC prompt jelenhet meg" "WARN"

    # 1.4 x64 OS
    Test-Assert "PreInstall" "64-bites OS" ([Environment]::Is64BitOperatingSystem) ""

    # 1.5 Disk space (GeeksForGeeks: "verify sufficient disk space")
    $drive = (Split-Path $INSTDIR -Qualifier)
    $freeGB = [math]::Round((Get-PSDrive ($drive -replace ':','') -ErrorAction SilentlyContinue).Free / 1GB, 1)
    Test-Assert "PreInstall" "Eleg szabad hely (>2GB)" ($freeGB -gt 2) "Szabad: $freeGB GB"
}

# =============================================================================
# CATEGORY 2: SILENT INSTALL EXECUTION (Tricentis + SoftwareTestingHelp)
# =============================================================================
function Test-SilentInstall {
    Write-Host "`n=== 2. SILENT INSTALL ===" -ForegroundColor Cyan

    $installStart = Get-Date
    Write-Host "  Telepites indul: $InstallerExe /S ..." -ForegroundColor DarkCyan

    $proc = Start-Process -FilePath $InstallerExe -ArgumentList "/S" -Wait -PassThru
    $installSec = [math]::Round(((Get-Date) - $installStart).TotalSeconds, 0)

    Test-Assert "Install" "Exit code 0" ($proc.ExitCode -eq 0) "ExitCode: $($proc.ExitCode)"
    Test-Assert "Install" "Telepites ideje esszeru (<600s)" ($installSec -lt 600) "Ido: ${installSec}s"

    $mode = Get-InstalledMode
    Test-Assert "Install" "InstallMode rogzitve" (-not [string]::IsNullOrWhiteSpace($mode)) "InstallMode: $mode"

    if (Test-IsFullInstallMode) {
        # Várjunk a service-ekre
        Write-Host "  Varakozas a service-ekre (max 120s)..." -ForegroundColor DarkCyan
        $waited = 0
        while ($waited -lt 120) {
            Start-Sleep -Seconds 5
            $waited += 5
            try {
                $r = Invoke-WebRequest -Uri "http://localhost:$BE_PORT/actuator/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
                if ($r.StatusCode -eq 200) {
                    Write-Host "  Backend health OK (${waited}s)" -ForegroundColor Green
                    break
                }
            } catch { }
        }
        Test-Assert "Install" "Backend health 200 (max 120s)" ($waited -lt 120) "Waited: ${waited}s"
    } else {
        Test-Assert "Install" "Silent install alapertelmezett modja THIN" ($mode -eq "THIN") "InstallMode: $mode"
    }
}

# =============================================================================
# CATEGORY 3: FILE SYSTEM VALIDATION (NSIS Manual + Advanced Installer)
# "Verify all expected files are installed to correct directories"
# =============================================================================
function Test-FileSystem {
    Write-Host "`n=== 3. FAJLRENDSZER VALIDACIO ===" -ForegroundColor Cyan
    $isFullInstall = Test-IsFullInstallMode

    # 3.1 INSTDIR fájlok
    $instFiles = @(
        @{ Path = "$INSTDIR\Penztar.exe"; Desc = "Electron app" },
        @{ Path = "$INSTDIR\uninstall.exe"; Desc = "Uninstaller" },
        @{ Path = "$INSTDIR\diagnose-penztar-network.ps1"; Desc = "Diagnosztikai script" }
    )
    foreach ($f in $instFiles) {
        Test-Assert "Files" "$($f.Desc) letezik" (Test-Path $f.Path) $f.Path
    }

    # 3.2 DATA_DIR struktúra
    if ($isFullInstall) {
        $dataDirs = @(
            "$DATA_DIR\pgsql\bin\postgres.exe",
            "$DATA_DIR\pgsql\bin\psql.exe",
            "$DATA_DIR\pgsql\data\PG_VERSION",
            "$DATA_DIR\pgsql\data\postgresql.conf",
            "$DATA_DIR\pgsql\data\pg_hba.conf",
            "$DATA_DIR\jre\bin\java.exe",
            "$DATA_DIR\backend\valuta-backend.jar",
            "$DATA_DIR\tools\nssm.exe",
            "$DATA_DIR\config\application-local.properties",
            "$DATA_DIR\scripts\seed-data.sql"
        )
        foreach ($p in $dataDirs) {
            $name = Split-Path $p -Leaf
            Test-Assert "Files" "$name letezik" (Test-Path $p) $p
        }

        # 3.3 Log könyvtárak léteznek
        Test-Assert "Files" "PG log dir" (Test-Path "$DATA_DIR\pgsql\log") "$DATA_DIR\pgsql\log"
        Test-Assert "Files" "Backend log dir" (Test-Path "$DATA_DIR\backend\logs") "$DATA_DIR\backend\logs"
    } else {
        Test-Assert "Files" "THIN modban lokalis backend nem kotelezo" $true "InstallMode: $(Get-InstalledMode)"
    }

    # 3.4 Config tartalom ellenőrzés (Advanced Installer: "integrity check")
    if (Test-Path "$DATA_DIR\config\application-local.properties") {
        $cfg = Get-Content "$DATA_DIR\config\application-local.properties" -Raw
        Test-Assert "Config" "DB URL helyes" ($cfg -match "jdbc:postgresql://localhost:$PG_PORT/valuta") "Port: $PG_PORT"
        Test-Assert "Config" "DB user helyes" ($cfg -match "valuta_user") ""
        Test-Assert "Config" "JWT secret nem placeholder" ($cfg -notmatch "__GENERATED_AT_INSTALL_TIME__") ""
        Test-Assert "Config" "JWT secret nem ures" ($cfg -match "jwt\.secret=.{10,}") ""
        Test-Assert "Config" "Encryption key nem ures" ($cfg -match "app\.encryption\.key=.{10,}") ""
        Test-Assert "Config" "Encryption salt nem ures" ($cfg -match "app\.encryption\.salt=.{10,}") ""
        Test-Assert "Config" "DB jelszo nem ures" ($cfg -match "spring\.datasource\.password=.{10,}") ""
        Test-Assert "Config" "Swagger UI disabled" ($cfg -match "springdoc\.swagger-ui\.enabled=false") "Production: swagger disabled"
        Test-Assert "Config" "Server port $BE_PORT" ($cfg -match "server\.port=$BE_PORT") ""
    }

    # 3.5 pg_hba.conf biztonsági ellenőrzés
    if (Test-Path "$DATA_DIR\pgsql\data\pg_hba.conf") {
        $hba = Get-Content "$DATA_DIR\pgsql\data\pg_hba.conf" -Raw
        Test-Assert "Security" "valuta_user scram-sha-256" ($hba -match "valuta_user.*scram-sha-256") "pg_hba.conf should have scram-sha-256 for valuta_user"
        # X8c fix (v7.0 S6-04 hardening tukre, Penztar-Setup.nsi:782-817):
        # MINDEN user scram-sha-256, trust auth epphogy TILOS a kesz rendszeren.
        Test-Assert "Security" "postgres scram-sha-256" ($hba -match "postgres.*scram-sha-256") "pg_hba.conf: postgres user is scram-sha-256 (v7.0 S6-04)"
        # Nincs md5 (weak) auth — only in custom lines, not in default comments
        $hbaLines = ($hba -split "`n") | Where-Object { $_ -notmatch "^\s*#" -and $_ -match "\S" }
        $hasMd5 = $hbaLines | Where-Object { $_ -match "\bmd5\b" }
        Test-Assert "Security" "Nincs md5 auth" ($null -eq $hasMd5) "Csak scram-sha-256 megengedett (md5 es trust tilos)"
        $hasTrust = $hbaLines | Where-Object { $_ -match "\btrust\b" }
        Test-Assert "Security" "Nincs trust auth" ($null -eq $hasTrust) "v7.0: trust sor nem maradhat (NSI fail-closed tukor)"
    }

    # 3.6 Temp fájlok NEM maradtak (G2-06 + NSIS best practice)
    Test-Assert "Cleanup" "generate-secrets.ps1 torolve" (-not (Test-Path "$INSTDIR\generate-secrets.ps1")) "Temp PS1 nem maradhat"
    Test-Assert "Cleanup" "setup-user.sql torolve" (-not (Test-Path "$DATA_DIR\scripts\setup-user.sql")) "Jelszo nem maradhat fajlban"
    Test-Assert "Cleanup" "update-password.sql torolve" (-not (Test-Path "$DATA_DIR\scripts\update-password.sql")) ""
    Test-Assert "Cleanup" "verify-user.sql torolve" (-not (Test-Path "$DATA_DIR\scripts\verify-user.sql")) ""
}

# =============================================================================
# CATEGORY 4: REGISTRY VALIDATION (SoftwareTestingHelp + NSIS Manual)
# "Verify correct registry entries created"
# =============================================================================
function Test-Registry {
    Write-Host "`n=== 4. REGISTRY VALIDACIO ===" -ForegroundColor Cyan

    # 4.1 App registry
    Test-Assert "Registry" "App key letezik" (Test-Path $REG_APP) $REG_APP
    if (Test-Path $REG_APP) {
        $appReg = Get-ItemProperty $REG_APP -ErrorAction SilentlyContinue
        $global:InstalledMode = if ([string]::IsNullOrWhiteSpace($appReg.InstallMode)) { "FULL" } else { $appReg.InstallMode.ToUpperInvariant() }
        Test-Assert "Registry" "InstallDir helyes" ($appReg.InstallDir -eq $INSTDIR) "InstallDir: $($appReg.InstallDir)"
        Test-Assert "Registry" "DataDir helyes" ($appReg.DataDir -eq $DATA_DIR) "DataDir: $($appReg.DataDir)"
        Test-Assert "Registry" "Version helyes" ($appReg.Version -eq $VERSION) "Version: $($appReg.Version)"
        Test-Assert "Registry" "InstallMode helyes" ($global:InstalledMode -in @("THIN", "FULL")) "InstallMode: $($global:InstalledMode)"
    }

    # 4.2 Uninstall registry (Add/Remove Programs)
    Test-Assert "Registry" "Uninstall key letezik" (Test-Path $REG_UNINST) $REG_UNINST
    if (Test-Path $REG_UNINST) {
        $unReg = Get-ItemProperty $REG_UNINST -ErrorAction SilentlyContinue
        Test-Assert "Registry" "DisplayName tartalmazza verziot" ($unReg.DisplayName -like "*$VERSION*") "DisplayName: $($unReg.DisplayName)"
        Test-Assert "Registry" "Publisher helyes" ($unReg.Publisher -eq $PUBLISHER) "Publisher: $($unReg.Publisher)"
        Test-Assert "Registry" "DisplayIcon letezik" ($null -ne $unReg.DisplayIcon -and $unReg.DisplayIcon -ne "") "DisplayIcon: $($unReg.DisplayIcon)"
        Test-Assert "Registry" "UninstallString kitoltve" ($null -ne $unReg.UninstallString -and $unReg.UninstallString -ne "") ""
        Test-Assert "Registry" "QuietUninstallString kitoltve" ($null -ne $unReg.QuietUninstallString -and $unReg.QuietUninstallString -ne "") ""
        Test-Assert "Registry" "EstimatedSize > 0" ($unReg.EstimatedSize -gt 0) "EstimatedSize: $($unReg.EstimatedSize)"
        Test-Assert "Registry" "NoModify = 1" ($unReg.NoModify -eq 1) ""
        Test-Assert "Registry" "NoRepair = 1" ($unReg.NoRepair -eq 1) ""
        Test-Assert "Registry" "URLInfoAbout kitoltve" ($null -ne $unReg.URLInfoAbout) "URL: $($unReg.URLInfoAbout)"
        Test-Assert "Registry" "InstallDate kitoltve" ($null -ne $unReg.InstallDate -and $unReg.InstallDate -ne "") "InstallDate: $($unReg.InstallDate)"
    }
}

# =============================================================================
# CATEGORY 5: WINDOWS SERVICES VALIDATION (Advanced Installer + Tricentis)
# "Verify services installed, configured, and running correctly"
# =============================================================================
function Test-Services {
    Write-Host "`n=== 5. SZOLGALTATASOK VALIDACIO ===" -ForegroundColor Cyan
    if (-not (Test-IsFullInstallMode)) {
        Test-Assert "Services" "THIN modban nincs lokalis service" $true "InstallMode: $(Get-InstalledMode)"
        return
    }

    foreach ($svcName in @($SVC_PG, $SVC_BE)) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        Test-Assert "Services" "$svcName letezik" ($null -ne $svc) ""
        if ($svc) {
            Test-Assert "Services" "$svcName Running" ($svc.Status -eq "Running") "Status: $($svc.Status)"
            # StartType check
            $startType = (Get-CimInstance Win32_Service -Filter "Name='$svcName'" -ErrorAction SilentlyContinue).StartMode
            Test-Assert "Services" "$svcName Auto start" ($startType -eq "Auto") "StartType: $startType"
        }
    }

    # Service dependency: Backend → PostgreSQL
    $beDep = (Get-CimInstance Win32_Service -Filter "Name='$SVC_BE'" -ErrorAction SilentlyContinue)
    if ($beDep) {
        $deps = (Get-Service $SVC_BE -ErrorAction SilentlyContinue).ServicesDependedOn
        $hasPgDep = $deps | Where-Object { $_.Name -eq $SVC_PG }
        Test-Assert "Services" "Backend fugg PostgreSQL-tol" ($null -ne $hasPgDep) "DependsOn: $($deps.Name -join ',')"
    }

    $svcAccounts = @{
        $SVC_PG = "*NetworkService*"
        $SVC_BE = "LocalSystem"
    }
    foreach ($svcName in @($SVC_PG, $SVC_BE)) {
        $svcObj = Get-CimInstance Win32_Service -Filter "Name='$svcName'" -ErrorAction SilentlyContinue
        if ($svcObj) {
            $account = $svcObj.StartName
            $expected = $svcAccounts[$svcName]
            Test-Assert "Services" "$svcName megfelelo szolgaltatasfiok" ($account -like $expected) "Account: $account"
        }
    }
}

# =============================================================================
# CATEGORY 6: NETWORK / HEALTH VALIDATION (Tricentis + SoftwareTestingHelp)
# "Verify application functions correctly after installation"
# =============================================================================
function Test-Network {
    Write-Host "`n=== 6. HALOZAT ES HEALTH VALIDACIO ===" -ForegroundColor Cyan
    if (-not (Test-IsFullInstallMode)) {
        Test-Assert "Network" "THIN modban nincs lokalis backend port" $true "InstallMode: $(Get-InstalledMode)"
        return
    }

    # 6.1 PostgreSQL port
    $pgConn = $null
    try {
        $pgConn = New-Object System.Net.Sockets.TcpClient
        $pgConn.Connect("127.0.0.1", $PG_PORT)
        $pgOk = $pgConn.Connected
        $pgConn.Close()
    } catch { $pgOk = $false }
    Test-Assert "Network" "PostgreSQL port $PG_PORT elerheto" $pgOk ""

    # 6.2 Backend port
    $beConn = $null
    try {
        $beConn = New-Object System.Net.Sockets.TcpClient
        $beConn.Connect("127.0.0.1", $BE_PORT)
        $beOk = $beConn.Connected
        $beConn.Close()
    } catch { $beOk = $false }
    Test-Assert "Network" "Backend port $BE_PORT elerheto" $beOk ""

    # 6.3 Health endpoint
    try {
        $health = Invoke-WebRequest -Uri "http://localhost:$BE_PORT/actuator/health" -UseBasicParsing -TimeoutSec 10
        Test-Assert "Health" "Actuator health 200" ($health.StatusCode -eq 200) "Status: $($health.StatusCode)"
        # Invoke-WebRequest returns Content as byte array sometimes; force string
        $contentStr = if ($health.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($health.Content) } else { $health.Content.ToString() }
        $body = $contentStr | ConvertFrom-Json -ErrorAction SilentlyContinue
        Test-Assert "Health" "Health status UP" ($body.status -eq "UP") "Status: $($body.status) Raw: $($contentStr.Substring(0, [Math]::Min(100,$contentStr.Length)))"
    } catch {
        Test-Assert "Health" "Actuator health elerheto" $false "Error: $($_.Exception.Message)"
    }

    # 6.4 Swagger UI disabled (production security)
    try {
        $swagger = Invoke-WebRequest -Uri "http://localhost:$BE_PORT/swagger-ui.html" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        Test-Assert "Security" "Swagger UI nem elerheto (404/error)" ($swagger.StatusCode -ne 200) "Swagger NE legyen elerheto production-ben" "WARN"
    } catch {
        # 404 or connection error = good (swagger disabled)
        Test-Assert "Security" "Swagger UI nem elerheto" $true ""
    }

    # 6.5 DB connection — psql check
    $psqlExe = "$DATA_DIR\pgsql\bin\psql.exe"
    if (Test-Path $psqlExe) {
        $psqlResult = & $psqlExe -p $PG_PORT -U postgres -d valuta -t -A -c "SELECT count(*) FROM pg_roles WHERE rolname='valuta_user'" 2>&1
        $userExists = ($psqlResult -match "^1$" -or $psqlResult -eq "1")
        Test-Assert "Database" "valuta_user letezik" $userExists "psql output: $psqlResult"

        # DB exists
        $dbResult = & $psqlExe -p $PG_PORT -U postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='valuta'" 2>&1
        Test-Assert "Database" "valuta DB letezik" ($dbResult -match "1") "psql output: $dbResult"
    }
}

# =============================================================================
# CATEGORY 7: SHORTCUTS VALIDATION (SoftwareTestingHelp)
# "Verify shortcuts created in correct locations"
# =============================================================================
function Test-Shortcuts {
    Write-Host "`n=== 7. PARANCSIKONOK VALIDACIO ===" -ForegroundColor Cyan
    $isFullInstall = Test-IsFullInstallMode

    # Desktop shortcut
    $desktopLnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Valutavalto Penztar.lnk"
    Test-Assert "Shortcuts" "Asztali ikon letezik" (Wait-ForPathState -Path $desktopLnk -ShouldExist $true) $desktopLnk

    # Start Menu shortcuts
    $smDir = Join-Path ([Environment]::GetFolderPath("Programs")) "Valutavalto Penztar"
    Test-Assert "Shortcuts" "Start menu mappa letezik" (Wait-ForPathState -Path $smDir -ShouldExist $true) $smDir

    $expectedLinks = @(
        "Valutavalto Penztar.lnk",
        "Halozati diagnosztika.lnk",
        "Eltavolitas.lnk"
    )
    if ($isFullInstall) {
        $expectedLinks += @(
            "Szolgaltatasok inditasa.lnk",
            "Szolgaltatasok leallitasa.lnk"
        )
    }
    foreach ($lnk in $expectedLinks) {
        $lnkPath = Join-Path $smDir $lnk
        Test-Assert "Shortcuts" "Start menu: $lnk" (Wait-ForPathState -Path $lnkPath -ShouldExist $true) $lnkPath
    }

    # Shortcut target validation (Advanced Installer: "shortcuts point to correct executables")
    if (Test-Path $desktopLnk) {
        $shell = New-Object -ComObject WScript.Shell
        $sc = $shell.CreateShortcut($desktopLnk)
        Test-Assert "Shortcuts" "Desktop target = Penztar.exe" ($sc.TargetPath -like "*Penztar.exe*") "Target: $($sc.TargetPath)"
    }
}

# =============================================================================
# CATEGORY 8: SECURITY VALIDATION (NSIS Best Practices + Advanced Installer)
# =============================================================================
function Test-Security {
    Write-Host "`n=== 8. BIZTONSAGI VALIDACIO ===" -ForegroundColor Cyan
    $isFullInstall = Test-IsFullInstallMode

    # 8.1 Config fájl nem world-readable
    $cfgFile = "$DATA_DIR\config\application-local.properties"
    if ($isFullInstall -and (Test-Path $cfgFile)) {
        $acl = Get-Acl $cfgFile
        $everyoneAccess = $acl.Access | Where-Object { $_.IdentityReference -like "*Everyone*" -or $_.IdentityReference -like "*Users*" }
        # Ha van Users/Everyone olvasási jog, az WARN (NetworkService elég)
        Test-Assert "Security" "Config nem Everyone-readable" ($null -eq ($everyoneAccess | Where-Object { $_.FileSystemRights -match "FullControl|Write" })) "Nincs Everyone/Users irasi jog" "WARN"
    }

    # 8.2 NSSM exe nem world-writable
    $nssmPath = "$DATA_DIR\tools\nssm.exe"
    if ($isFullInstall -and (Test-Path $nssmPath)) {
        $nssmAcl = Get-Acl $nssmPath
        $nssmWrite = $nssmAcl.Access | Where-Object { $_.IdentityReference -like "*Users*" -and $_.FileSystemRights -match "Write|FullControl" }
        Test-Assert "Security" "NSSM nem Users-writable" ($null -eq $nssmWrite) ""
    }

    # 8.3 Jelszó sehol nem plaintext temp fájlban
    if ($isFullInstall) {
        $tempSqlFiles = Get-ChildItem "$DATA_DIR\scripts\*.sql" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "setup-user|update-password|verify-user" }
        Test-Assert "Security" "Nincs temp SQL jelszo-fajl" ($tempSqlFiles.Count -eq 0) "Talalt: $($tempSqlFiles.Name -join ',')"
    } else {
        Test-Assert "Security" "THIN modban nincs lokalis SQL temp fajl" $true "InstallMode: $(Get-InstalledMode)"
    }

    # 8.4 generate-secrets.ps1 nem maradt
    Test-Assert "Security" "Nincs temp secrets PS1" (-not (Test-Path "$INSTDIR\generate-secrets.ps1")) ""
}

# =============================================================================
# CATEGORY 9: SILENT UNINSTALL + CLEANUP VALIDATION
# (SoftwareTestingHelp + Tricentis: "clean uninstall leaves no artifacts")
# =============================================================================
function Test-SilentUninstall {
    Write-Host "`n=== 9. SILENT UNINSTALL ===" -ForegroundColor Cyan

    $uninstExe = "$INSTDIR\uninstall.exe"
    if (-not (Test-Path $uninstExe)) {
        Test-Assert "Uninstall" "Uninstaller letezik" $false "$uninstExe"
        return
    }

    Write-Host "  Eltavolitas indul: $uninstExe /S ..." -ForegroundColor DarkCyan
    $proc = Start-Process -FilePath $uninstExe -ArgumentList "/S" -Wait -PassThru
    # NSIS uninstaller may return non-zero or the exe self-deletes
    Start-Sleep -Seconds 10

    Test-Assert "Uninstall" "Uninstaller lefutott" $true "ExitCode: $($proc.ExitCode)"
}

function Test-PostUninstall {
    Write-Host "`n=== 10. POST-UNINSTALL VALIDACIO ===" -ForegroundColor Cyan
    $wasFullInstall = Test-IsFullInstallMode

    # 10.1 Services eltuntek
    if ($wasFullInstall) {
        foreach ($svcName in @($SVC_PG, $SVC_BE)) {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            Test-Assert "PostUninst" "$svcName eltavolitve" ($null -eq $svc) "Status: $($svc.Status)"
        }
    } else {
        Test-Assert "PostUninst" "THIN modban nincs service eltavolitando" $true "InstallMode: THIN"
    }

    # 10.2 Portok szabadok
    if ($wasFullInstall) {
        $pgListen = netstat -an | Select-String ":$PG_PORT " | Select-String "LISTENING"
        Test-Assert "PostUninst" "Port $PG_PORT szabad" ($null -eq $pgListen) ""
        $beListen = netstat -an | Select-String ":$BE_PORT " | Select-String "LISTENING"
        Test-Assert "PostUninst" "Port $BE_PORT szabad" ($null -eq $beListen) ""
    }

    # 10.3 Registry torolve
    Test-Assert "PostUninst" "App registry torolve" (-not (Test-Path $REG_APP)) ""
    Test-Assert "PostUninst" "Uninstall registry torolve" (-not (Test-Path $REG_UNINST)) ""

    # 10.4 INSTDIR torolve (vagy csak uninstall.exe maradt — NSIS self-delete)
    $instdirExists = Test-Path $INSTDIR
    if ($instdirExists) {
        $remaining = Get-ChildItem $INSTDIR -Recurse -ErrorAction SilentlyContinue
        Test-Assert "PostUninst" "INSTDIR ures vagy torolve" ($remaining.Count -le 1) "Maradt: $($remaining.Name -join ',')" "WARN"
    } else {
        Test-Assert "PostUninst" "INSTDIR torolve" $true ""
    }

    # 10.5 Shortcuts torolve
    $desktopLnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Valutavalto Penztar.lnk"
    Test-Assert "PostUninst" "Asztali ikon torolve" (Wait-ForPathState -Path $desktopLnk -ShouldExist $false) ""
    $smDir = Join-Path ([Environment]::GetFolderPath("Programs")) "Valutavalto Penztar"
    Test-Assert "PostUninst" "Start menu mappa torolve" (Wait-ForPathState -Path $smDir -ShouldExist $false) ""

    # 10.6 DATA_DIR: silent uninstall megtartja az adatokat (design decision)
    if ($wasFullInstall) {
        Test-Assert "PostUninst" "DATA_DIR adatok megmaradtak (silent=keep)" (Test-Path "$DATA_DIR\pgsql\data\PG_VERSION") "Silent uninstall NEM torol adatot" "WARN"
    } else {
        $thinDataDirMissingOrEmpty = (-not (Test-Path "$DATA_DIR")) -or (@(Get-ChildItem "$DATA_DIR" -Force -ErrorAction SilentlyContinue).Count -eq 0)
        Test-Assert "PostUninst" "THIN modban nincs lokalis DATA_DIR" $thinDataDirMissingOrEmpty "InstallMode: THIN"
    }

    # 10.7 DATA_DIR: binarisok torolve (jre, tools, scripts)
    if ($wasFullInstall) {
        Test-Assert "PostUninst" "JRE binaris torolve" (-not (Test-Path "$DATA_DIR\jre\bin\java.exe")) ""
        Test-Assert "PostUninst" "NSSM torolve" (-not (Test-Path "$DATA_DIR\tools\nssm.exe")) ""
        Test-Assert "PostUninst" "Backend JAR torolve" (-not (Test-Path "$DATA_DIR\backend\valuta-backend.jar")) ""
    }
}

# =============================================================================
# CATEGORY 11: UPGRADE VALIDATION (Tricentis: "upgrade preserves settings")
# Reinstall after uninstall to test upgrade path
# =============================================================================
function Test-Reinstall {
    Write-Host "`n=== 11. UJRATELEPITES (UPGRADE PATH) ===" -ForegroundColor Cyan

    Write-Host "  Ujratelepites indul..." -ForegroundColor DarkCyan
    $proc = Start-Process -FilePath $InstallerExe -ArgumentList "/S" -Wait -PassThru
    Test-Assert "Reinstall" "Ujratelepites exit code 0" ($proc.ExitCode -eq 0) "ExitCode: $($proc.ExitCode)"

    $mode = Get-InstalledMode
    if ($mode -eq "FULL") {
        # Várjunk a health-re
        Write-Host "  Varakozas backend-re (max 120s)..." -ForegroundColor DarkCyan
        $waited = 0
        $healthOk = $false
        while ($waited -lt 120) {
            Start-Sleep -Seconds 5
            $waited += 5
            try {
                $r = Invoke-WebRequest -Uri "http://localhost:$BE_PORT/actuator/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
                if ($r.StatusCode -eq 200) { $healthOk = $true; break }
            } catch { }
        }
        Test-Assert "Reinstall" "Backend health OK ujratelepites utan" $healthOk "Waited: ${waited}s"

        # DB megmaradt az adatokkal
        $psqlExe = "$DATA_DIR\pgsql\bin\psql.exe"
        if (Test-Path $psqlExe) {
            $dbCheck = & $psqlExe -p $PG_PORT -U postgres -d valuta -t -A -c "SELECT 1" 2>&1
            Test-Assert "Reinstall" "DB kapcsolat mukodik" ($dbCheck -match "1") ""
        }
    } else {
        Test-Assert "Reinstall" "Silent ujratelepites THIN modban marad" ($mode -eq "THIN") "InstallMode: $mode"
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
Write-Host "=============================================" -ForegroundColor White
Write-Host " VALUTAVALTO PENZTAR INSTALLER TESZT SUITE" -ForegroundColor White
Write-Host " Verzio: $VERSION | $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White

# Run all test categories
Test-PreInstall

if (-not $SkipInstall -and -not $OnlyValidate) {
    Test-SilentInstall
}

Test-FileSystem
Test-Registry
Test-Services
Test-Network
Test-Shortcuts
Test-Security

if (-not $SkipUninstall -and -not $OnlyValidate) {
    Test-SilentUninstall
    Start-Sleep -Seconds 5
    Test-PostUninstall

    # Reinstall for upgrade path test
    Test-Reinstall

    # Re-validate after reinstall
    Write-Host "`n=== 12. UJRAVALIDACIO UJRATELEPITES UTAN ===" -ForegroundColor Cyan
    Test-FileSystem
    Test-Registry
    Test-Services
    Test-Network
    Test-Shortcuts
    Test-Security
}

# =============================================================================
# SUMMARY
# =============================================================================
$elapsed = [math]::Round(((Get-Date) - $global:StartTime).TotalSeconds, 0)

Write-Host "`n=============================================" -ForegroundColor White
Write-Host " OSSZESITES" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White
Write-Host "  PASS: $($global:PassCount)" -ForegroundColor Green
Write-Host "  FAIL: $($global:FailCount)" -ForegroundColor $(if ($global:FailCount -gt 0) { "Red" } else { "Green" })
Write-Host "  WARN: $($global:WarnCount)" -ForegroundColor $(if ($global:WarnCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  TOTAL: $($global:TestResults.Count) | IDO: ${elapsed}s" -ForegroundColor White

if ($global:FailCount -gt 0) {
    Write-Host "`n  FAILED TESZTEK:" -ForegroundColor Red
    $global:TestResults | Where-Object { $_.Result -eq "FAIL" } | ForEach-Object {
        Write-Host "    [$($_.Category)] $($_.Test) — $($_.Detail)" -ForegroundColor Red
    }
}
if ($global:WarnCount -gt 0) {
    Write-Host "`n  WARNINGS:" -ForegroundColor Yellow
    $global:TestResults | Where-Object { $_.Result -eq "WARN" } | ForEach-Object {
        Write-Host "    [$($_.Category)] $($_.Test) — $($_.Detail)" -ForegroundColor Yellow
    }
}

$verdict = if ($global:FailCount -eq 0) { "PASS" } elseif ($global:FailCount -le 3) { "CONDITIONAL PASS" } else { "FAIL" }
Write-Host "`n  VERDIKT: $verdict" -ForegroundColor $(if ($verdict -eq "PASS") { "Green" } elseif ($verdict -eq "FAIL") { "Red" } else { "Yellow" })
Write-Host "=============================================" -ForegroundColor White

# Export results
$reportPath = Join-Path (Split-Path $PSScriptRoot) "build\test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$global:TestResults | ConvertTo-Json -Depth 3 | Set-Content $reportPath -Encoding UTF8
Write-Host "  Report: $reportPath" -ForegroundColor DarkGray

exit $global:FailCount
