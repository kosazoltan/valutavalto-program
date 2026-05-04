# =============================================================================
# Valutavalto Penztar - Halozati diagnosztika szkript
# =============================================================================
# Hasznalat: dupla-klikk a Penztar-Diagnosztika.exe-re VAGY:
#   powershell -ExecutionPolicy Bypass -File diagnose-penztar-network.ps1
#
# A szkript egy penztar-diagnostic-<datum>.txt fajlt hoz letre az asztalon.
# Ezt a fajlt kell elkuldeni az adminisztratornak a hibajegyhez.
# =============================================================================

$ErrorActionPreference = 'Continue'  # Egy hiba NE allitsa le a teljes diagnosztikat

# Asztal eleresenek meghatarozasa (OneDrive Desktop redirect tamogatas)
$desktops = @(
    [Environment]::GetFolderPath('Desktop'),
    "$env:USERPROFILE\OneDrive\Desktop",
    "$env:USERPROFILE\Desktop"
) | Where-Object { Test-Path $_ } | Select-Object -Unique
$desktopPath = $desktops | Select-Object -First 1
if (-not $desktopPath) { $desktopPath = "$env:USERPROFILE\Desktop"; New-Item -ItemType Directory -Force $desktopPath | Out-Null }

$reportPath = Join-Path $desktopPath "penztar-diagnostic-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$out = New-Object System.Collections.ArrayList

function Add-Section($title) {
    [void]$out.Add("")
    [void]$out.Add("=" * 70)
    [void]$out.Add($title)
    [void]$out.Add("=" * 70)
    # Inkrementalis mentes — minden szakasz utan ki-irjuk, hogy ne vesszen el adat
    $out -join "`n" | Out-File -FilePath $reportPath -Encoding UTF8 -Force
}
function Add-Line($line) {
    [void]$out.Add($line)
    $out -join "`n" | Out-File -FilePath $reportPath -Encoding UTF8 -Force
}
function Try-Section($title, $block) {
    Add-Section $title
    try { & $block } catch { Add-Line "HIBA a szakaszban: $($_.Exception.Message)" }
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Green
Write-Host "  VALUTAVALTO PENZTAR - HALOZATI DIAGNOSZTIKA" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Folyamatban... 30-60 masodperc" -ForegroundColor Yellow
Write-Host "  Jelentes: $reportPath" -ForegroundColor Cyan
Write-Host ""

Try-Section "0. SZAMITOGEP ALAPADATOK" {
    Add-Line "Datum: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Line "Felhasznalo: $env:USERNAME"
    Add-Line "Computername: $env:COMPUTERNAME"
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        Add-Line "Windows: $($os.Caption) $($os.Version)"
    } catch { Add-Line "Win32_OperatingSystem nem elerheto: $($_.Exception.Message)" }
    Add-Line "OS Build: $([System.Environment]::OSVersion.Version)"
    Add-Line "PowerShell: $($PSVersionTable.PSVersion)"
}

Try-Section "1. PROXY BEALLITAS" {
    $ie = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
    Add-Line "ProxyEnable: $($ie.ProxyEnable)"
    Add-Line "ProxyServer: $($ie.ProxyServer)"
    Add-Line "ProxyOverride: $($ie.ProxyOverride)"
    Add-Line "AutoConfigURL: $($ie.AutoConfigURL)"
    try {
        $winhttp = & netsh winhttp show proxy 2>&1 | Out-String
        Add-Line ""
        Add-Line "WinHTTP proxy:"
        Add-Line $winhttp
    } catch { Add-Line "netsh winhttp nem futtathato: $($_.Exception.Message)" }
}

Try-Section "2. DNS RESOLUTION (excvaluta.com)" {
    try {
        $dns = Resolve-DnsName 'excvaluta.com' -ErrorAction Stop
        foreach ($entry in $dns) {
            $val = if ($entry.IPAddress) { $entry.IPAddress } else { $entry.NameHost }
            Add-Line "  $($entry.Type) $($entry.Name) -> $val"
        }
    } catch { Add-Line "DNS HIBA: $($_.Exception.Message)" }
}

Try-Section "3. TCP CONNECT TEST (excvaluta.com:443)" {
    try {
        # Custom 5s timeout TCP test (Test-NetConnection lassu lehet)
        $tcp = New-Object System.Net.Sockets.TcpClient
        $task = $tcp.ConnectAsync('excvaluta.com', 443)
        $ok = $task.Wait(5000)
        if ($ok -and $tcp.Connected) {
            Add-Line "TCP/443 OK"
            Add-Line "RemoteEndPoint: $($tcp.Client.RemoteEndPoint)"
        } else {
            Add-Line "TCP/443 NEM SIKERULT (timeout vagy connection refused)"
        }
        $tcp.Close()
    } catch { Add-Line "TCP HIBA: $($_.Exception.Message)" }
}

Try-Section "4. HTTP HEALTH CHECK (https://excvaluta.com/api/v1/auth/bootstrap-status)" {
    try {
        $r = Invoke-WebRequest -Uri 'https://excvaluta.com/api/v1/auth/bootstrap-status' -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        Add-Line "HTTP Status: $($r.StatusCode)"
        $contentSnippet = $r.Content.Substring(0, [Math]::Min(500, $r.Content.Length))
        Add-Line "Content (max 500 char): $contentSnippet"
    } catch [System.Net.WebException] {
        Add-Line "WebException: $($_.Exception.Message)"
    } catch {
        Add-Line "HIBA: $($_.Exception.Message)"
        Add-Line "  Tipus: $($_.Exception.GetType().FullName)"
    }
}

Try-Section "5. TELEPITES ELLENORZES (C:\Program Files\Valutavalto Penztar)" {
    $instDir = 'C:\Program Files\Valutavalto Penztar'
    if (Test-Path $instDir) {
        Add-Line "InstallDir letezik: $instDir"
        $envFile = "$instDir\.env"
        if (Test-Path $envFile) {
            Add-Line "Install dir .env tartalom:"
            Get-Content $envFile -ErrorAction SilentlyContinue | ForEach-Object { Add-Line "  $_" }
        } else { Add-Line "Install dir .env NEM letezik" }
        $prodUrls = "$instDir\resources\production-urls.json"
        if (Test-Path $prodUrls) {
            try {
                $cfg = Get-Content $prodUrls -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                Add-Line "production-urls.json api_url: $($cfg.api_url)"
            } catch { Add-Line "production-urls.json olvasasi hiba: $($_.Exception.Message)" }
        } else { Add-Line "HIBA: production-urls.json HIANYZIK" }
    } else { Add-Line "Telepites NEM TALALHATO ($instDir)" }
}

Try-Section "6. USERDATA (%APPDATA%\valuta-penztar)" {
    $ud = "$env:APPDATA\valuta-penztar"
    if (Test-Path $ud) {
        Add-Line "UserData letezik: $ud"
        $udEnv = "$ud\.env"
        if (Test-Path $udEnv) {
            Add-Line "UserData .env tartalom:"
            Get-Content $udEnv -ErrorAction SilentlyContinue | ForEach-Object { Add-Line "  $_" }
        } else { Add-Line "UserData .env NEM letezik (= SetupWizard nem futott)" }
        $sc = "$ud\setup-config.json"
        if (Test-Path $sc) {
            Add-Line "setup-config.json tartalom:"
            Get-Content $sc -ErrorAction SilentlyContinue | ForEach-Object { Add-Line "  $_" }
        } else { Add-Line "setup-config.json NEM letezik" }
        $db = "$ud\penztar.db"
        if (Test-Path $db) {
            Add-Line "penztar.db letezik: $((Get-Item $db).Length / 1KB) KB"
        } else { Add-Line "penztar.db NEM letezik" }
    } else { Add-Line "UserData NEM letezik ($ud) - Penztar.exe meg sosem futott" }
}

Try-Section "7. PENZTAR LOG (utolso 50 sor)" {
    $ud = "$env:APPDATA\valuta-penztar"
    $logFile = Get-ChildItem "$ud\logs" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($logFile) {
        Add-Line "Log: $($logFile.FullName)"
        Get-Content $logFile.FullName -Tail 50 -ErrorAction SilentlyContinue | ForEach-Object { Add-Line "  $_" }
    } else { Add-Line "Nincs log fajl" }
}

# Vegso mentes (mar minden szakasz utan mentve, de biztos ami biztos)
$out -join "`n" | Out-File -FilePath $reportPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Green
Write-Host "  KESZ! Diagnosztikai jelentes letrehozva:" -ForegroundColor Green
Write-Host "  $reportPath" -ForegroundColor Yellow
Write-Host "===========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  KOVETKEZO LEPES:" -ForegroundColor Cyan
Write-Host "  Kuldd el ezt a fajlt az adminisztratornak (Kosa Zoltan)." -ForegroundColor Cyan
Write-Host ""
$null = Read-Host "Nyomj ENTER-t a kilepeshez"
