#!/usr/bin/env pwsh
# =============================================================================
# Valutavalto v2.5.51 Multi-Installer Acceptance Test Suite
# =============================================================================
# 3 telepítő párhuzamos validációja friss Windows VM-en (vagy clean rendszeren):
#   1. Penztar-Setup-2.5.51 (pénztáros + értéktáros közös)
#   2. Kozponti-Iranyitokozpont-Setup-2.5.51 (központi munkaállomás)
#   3. Arfolyamkeszito-Setup-2.5.51 (RFM főértéktárosi)
#
# Használat:
#   powershell -ExecutionPolicy Bypass -File installer-validation-suite-v2.5.51.ps1 -Component all
#   powershell -ExecutionPolicy Bypass -File installer-validation-suite-v2.5.51.ps1 -Component penztar
#   powershell -ExecutionPolicy Bypass -File installer-validation-suite-v2.5.51.ps1 -Component kozponti
#   powershell -ExecutionPolicy Bypass -File installer-validation-suite-v2.5.51.ps1 -Component rfm
#
# Futtatás KÖTELEZŐ admin (rendszergazda) joggal!
# =============================================================================

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('all','penztar','kozponti','rfm')]
    [string]$Component = 'all',

    [Parameter()]
    [string]$InstallerDir = "$env:USERPROFILE\Downloads",

    [Parameter()]
    [switch]$SkipUninstall,

    [Parameter()]
    [switch]$NoLaunch
)

$ErrorActionPreference = 'Continue'
$script:Results = @()
$script:PassCount = 0
$script:FailCount = 0
$script:WarnCount = 0
$script:StartTime = Get-Date
$VERSION = '2.5.51'

# Komponens-specifikus konfiguráció
$Installers = @{
    penztar = @{
        Name        = 'Pénztáros/Értéktáros kliens'
        ExePattern  = "Penztar-Setup-$VERSION-*.exe"
        InstallDir  = 'C:\Program Files\Valutavalto Penztar'
        AppExe      = 'Valutavalto Penztar.exe'
        AppId       = 'com.bestchange.penztar'
        Uninst32Bit = $true
        RegKey      = 'HKLM:\Software\WOW6432Node\BestChange\ValutavaltoPenztar'
        AppMode     = 'penztar / ertektar'
        Route       = '/cashier vagy /treasury'
    }
    kozponti = @{
        Name        = 'Központi munkaállomás'
        ExePattern  = "Kozponti-Iranyitokozpont-Setup-$VERSION.exe"
        InstallDir  = 'C:\Program Files\Valutavalto Kozponti Iranyitokozpont'
        AppExe      = 'Valutavalto Kozponti Iranyitokozpont.exe'
        AppId       = 'com.bestchange.kozponti'
        Uninst32Bit = $false
        RegKey      = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
        AppMode     = 'full'
        Route       = '/central-workstation'
    }
    rfm = @{
        Name        = 'RFM (Árfolyamkészítő)'
        ExePattern  = "Arfolyamkeszito-Setup-$VERSION.exe"
        InstallDir  = 'C:\Program Files\Valutavalto Arfolyamkeszito'
        AppExe      = 'Valutavalto Arfolyamkeszito.exe'
        AppId       = 'com.bestchange.arfolyamkeszito'
        Uninst32Bit = $false
        RegKey      = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
        AppMode     = 'rate-maker'
        Route       = '/rates/creation'
    }
}

# --- Helper függvények ---
function Write-Header($text) {
    Write-Host ""
    Write-Host ('=' * 78) -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ('=' * 78) -ForegroundColor Cyan
}

function Add-Result($component, $test, $status, $detail = '') {
    $script:Results += [PSCustomObject]@{
        Component = $component
        Test      = $test
        Status    = $status
        Detail    = $detail
        Timestamp = (Get-Date).ToString('HH:mm:ss')
    }
    $color = switch ($status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'WARN' { 'Yellow' }
        default { 'Gray' }
    }
    $symbol = switch ($status) {
        'PASS' { '[OK]   ' }
        'FAIL' { '[FAIL] ' }
        'WARN' { '[WARN] ' }
        default { '[INFO] ' }
    }
    Write-Host "$symbol$component | $test" -ForegroundColor $color
    if ($detail) {
        Write-Host "       $detail" -ForegroundColor Gray
    }
    switch ($status) {
        'PASS' { $script:PassCount++ }
        'FAIL' { $script:FailCount++ }
        'WARN' { $script:WarnCount++ }
    }
}

function Test-AdminPrivilege {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- Admin check ---
if (-not (Test-AdminPrivilege)) {
    Write-Host "HIBA: Ez a script admin (rendszergazda) joggal futtatható!" -ForegroundColor Red
    Write-Host "Indítsd újra a PowerShell-t 'Run as Administrator' móddal." -ForegroundColor Yellow
    exit 1
}

# --- Komponens-validáció egy installerre ---
function Test-Component($key, $config) {
    Write-Header "VALIDÁCIÓ: $($config.Name) ($key)"

    # 1. Installer fájl megtalálása
    $exeFile = Get-ChildItem -Path $InstallerDir -Filter $config.ExePattern -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $exeFile) {
        Add-Result $key 'Installer fájl megtalálása' 'FAIL' "Nem található: $InstallerDir\$($config.ExePattern)"
        return
    }
    Add-Result $key 'Installer fájl megtalálása' 'PASS' "$($exeFile.Name) ($([math]::Round($exeFile.Length / 1MB, 1)) MB)"

    # 2. SHA-256 számítás (lehet validálni manuálisan)
    $hash = (Get-FileHash -Path $exeFile.FullName -Algorithm SHA256).Hash
    Add-Result $key 'SHA-256 számítás' 'PASS' "$($hash.Substring(0,16))..."

    # 3. Digital signature ellenőrzés (várt: nincs signed, dev build)
    $sig = Get-AuthenticodeSignature -FilePath $exeFile.FullName
    if ($sig.Status -eq 'Valid') {
        Add-Result $key 'Digital signature' 'PASS' "Signer: $($sig.SignerCertificate.Subject)"
    } else {
        Add-Result $key 'Digital signature' 'WARN' "Status: $($sig.Status) (dev build, várt)"
    }

    # 4. Telepítés (silent, /S flag NSIS-hez)
    Write-Host "   Telepítés indul... (~2-3 perc)" -ForegroundColor Yellow
    $installStart = Get-Date
    $proc = Start-Process -FilePath $exeFile.FullName -ArgumentList '/S' -Wait -PassThru -ErrorAction SilentlyContinue
    if ($proc.ExitCode -eq 0) {
        $duration = ((Get-Date) - $installStart).TotalSeconds
        Add-Result $key 'Telepítés (silent /S)' 'PASS' "Idő: ${duration} sec, exit: 0"
    } else {
        Add-Result $key 'Telepítés (silent /S)' 'FAIL' "Exit code: $($proc.ExitCode)"
        return
    }

    # 5. Install könyvtár létrejött
    if (Test-Path $config.InstallDir) {
        $files = (Get-ChildItem $config.InstallDir -Recurse -ErrorAction SilentlyContinue).Count
        Add-Result $key 'Install könyvtár létrejötte' 'PASS' "$($config.InstallDir) ($files fájl)"
    } else {
        Add-Result $key 'Install könyvtár létrejötte' 'FAIL' "Nincs: $($config.InstallDir)"
    }

    # 6. App futtatható (.exe)
    $appExePath = Join-Path $config.InstallDir $config.AppExe
    if (Test-Path $appExePath) {
        $version = (Get-Item $appExePath).VersionInfo.ProductVersion
        Add-Result $key 'App .exe létezik' 'PASS' "$appExePath (v$version)"
    } else {
        Add-Result $key 'App .exe létezik' 'FAIL' "Hiányzik: $appExePath"
    }

    # 7. Start Menu shortcut
    $shortcutPattern = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\*\$($config.AppExe -replace '\.exe',' *.lnk')"
    $shortcuts = Get-ChildItem $shortcutPattern -ErrorAction SilentlyContinue
    if ($shortcuts) {
        Add-Result $key 'Start Menu shortcut' 'PASS' "$($shortcuts[0].FullName)"
    } else {
        Add-Result $key 'Start Menu shortcut' 'WARN' 'Nem található Start Menu shortcut'
    }

    # 8. Registry uninstall entry
    $regPath = $config.RegKey
    if (Test-Path $regPath) {
        Add-Result $key 'Registry entry' 'PASS' $regPath
    } else {
        Add-Result $key 'Registry entry' 'WARN' "Nem található: $regPath"
    }

    # 9. Production URL config
    $urlConfig = Join-Path $config.InstallDir 'resources\production-urls.json'
    if (Test-Path $urlConfig) {
        $content = Get-Content $urlConfig -Raw | ConvertFrom-Json
        if ($content.api_url -eq 'https://excvaluta.com/api/v1') {
            Add-Result $key 'production-urls.json' 'PASS' $content.api_url
        } else {
            Add-Result $key 'production-urls.json' 'FAIL' "Rossz URL: $($content.api_url)"
        }
    } else {
        Add-Result $key 'production-urls.json' 'WARN' "Nem található: $urlConfig"
    }

    # 10. Launch test (NO Login, csak indítható-e + főablak megjelenik)
    if (-not $NoLaunch -and (Test-Path $appExePath)) {
        Write-Host "   Launch teszt... (5 sec)" -ForegroundColor Yellow
        $launchStart = Get-Date
        $launchProc = Start-Process -FilePath $appExePath -PassThru -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        if (-not $launchProc.HasExited) {
            Add-Result $key 'Launch teszt' 'PASS' "PID $($launchProc.Id) fut 5 másodperce"
            Stop-Process -Id $launchProc.Id -Force -ErrorAction SilentlyContinue
        } else {
            Add-Result $key 'Launch teszt' 'FAIL' "Process azonnal kilépett (exit: $($launchProc.ExitCode))"
        }
    }

    # 11. Eltávolítás (opcionális)
    if (-not $SkipUninstall) {
        Write-Host "   Eltávolítás..." -ForegroundColor Yellow
        # Penztar-Eltavolito közös ha van
        $uninstaller = Get-ChildItem -Path $InstallerDir -Filter "Penztar-Eltavolito-*.exe" |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($uninstaller -and $key -eq 'penztar') {
            $u = Start-Process -FilePath $uninstaller.FullName -ArgumentList '/S' -Wait -PassThru
            if ($u.ExitCode -eq 0) {
                Add-Result $key 'Eltávolítás (közös NSIS uninstaller)' 'PASS' "Exit: 0"
            } else {
                Add-Result $key 'Eltávolítás' 'WARN' "Exit: $($u.ExitCode)"
            }
        } else {
            # NSIS app uninstaller a saját install könyvtárában
            $appUninst = Join-Path $config.InstallDir 'Uninstall*.exe'
            $uExe = Get-ChildItem $appUninst -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($uExe) {
                $u = Start-Process -FilePath $uExe.FullName -ArgumentList '/S' -Wait -PassThru
                if ($u.ExitCode -eq 0) {
                    Add-Result $key 'Eltávolítás (app uninstaller)' 'PASS' "Exit: 0"
                } else {
                    Add-Result $key 'Eltávolítás' 'WARN' "Exit: $($u.ExitCode)"
                }
            } else {
                Add-Result $key 'Eltávolítás' 'WARN' "Nem található uninstaller"
            }
        }

        # Cleanup verifikáció
        Start-Sleep -Seconds 2
        if (Test-Path $config.InstallDir) {
            Add-Result $key 'Install könyvtár törlése' 'WARN' "Még mindig létezik: $($config.InstallDir)"
        } else {
            Add-Result $key 'Install könyvtár törlése' 'PASS' "Cleanup OK"
        }
    }
}

# --- Pre-flight ---
Write-Header "Valutavalto v$VERSION Multi-Installer Acceptance Test"
Write-Host "  Komponens: $Component"
Write-Host "  Installer könyvtár: $InstallerDir"
Write-Host "  Skip uninstall: $SkipUninstall"
Write-Host "  No launch test: $NoLaunch"
Write-Host "  OS: $((Get-CimInstance Win32_OperatingSystem).Caption) $((Get-CimInstance Win32_OperatingSystem).Version)"
Write-Host "  Admin: $(Test-AdminPrivilege)"
Write-Host "  Start: $($script:StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

# --- Komponensek futtatása ---
$componentsToTest = if ($Component -eq 'all') { @('penztar','kozponti','rfm') } else { @($Component) }

foreach ($key in $componentsToTest) {
    Test-Component -key $key -config $Installers[$key]
}

# --- Összegzés ---
Write-Header "VÉGSŐ ÖSSZEGZÉS"
$duration = ((Get-Date) - $script:StartTime).TotalSeconds
Write-Host "  Idő: $([math]::Round($duration,1)) sec"
Write-Host "  PASS: $script:PassCount" -ForegroundColor Green
Write-Host "  FAIL: $script:FailCount" -ForegroundColor Red
Write-Host "  WARN: $script:WarnCount" -ForegroundColor Yellow
Write-Host ""

# CSV riport
$reportFile = "installer-validation-v$VERSION-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$reportPath = Join-Path $PSScriptRoot $reportFile
$script:Results | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
Write-Host "  CSV riport: $reportPath" -ForegroundColor Cyan

if ($script:FailCount -gt 0) {
    Write-Host ""
    Write-Host "  ✗ Validáció SIKERTELEN — $script:FailCount FAIL találat" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "  ✓ Validáció SIKERES — minden PASS" -ForegroundColor Green
    exit 0
}
