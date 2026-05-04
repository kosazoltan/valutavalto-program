# =============================================================================
# Valutavalto Penztar - Halozati diagnosztika szkript
# =============================================================================
# Hasznalat: jobb-klikk -> "Run with PowerShell" VAGY:
#   powershell -ExecutionPolicy Bypass -File diagnose-penztar-network.ps1
#
# A szkript egy diagnostic-report-<datum>.txt fajlt hoz letre az asztalon.
# Ezt a fajlt kell elkuldeni az adminisztratornak a hibajegyhez.
# =============================================================================

$reportPath = Join-Path $env:USERPROFILE "Desktop\penztar-diagnostic-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$out = New-Object System.Collections.ArrayList

function Add-Section($title) {
    [void]$out.Add("")
    [void]$out.Add("=" * 70)
    [void]$out.Add($title)
    [void]$out.Add("=" * 70)
}
function Add-Line($line) { [void]$out.Add($line) }

Add-Section "0. SZAMITOGEP ALAPADATOK"
Add-Line "Datum: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-Line "Felhasznalo: $env:USERNAME"
Add-Line "Computername: $env:COMPUTERNAME"
Add-Line "Windows: $((Get-CimInstance Win32_OperatingSystem).Caption) $((Get-CimInstance Win32_OperatingSystem).Version)"
Add-Line "OS Build: $([System.Environment]::OSVersion.Version)"
Add-Line "PowerShell: $($PSVersionTable.PSVersion)"

Add-Section "1. PROXY BEALLITAS (Internet Settings)"
$ie = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
Add-Line "ProxyEnable: $($ie.ProxyEnable)"
Add-Line "ProxyServer: $($ie.ProxyServer)"
Add-Line "ProxyOverride: $($ie.ProxyOverride)"
Add-Line "AutoConfigURL: $($ie.AutoConfigURL)"
$winhttpProxy = & netsh winhttp show proxy 2>&1 | Out-String
Add-Line ""
Add-Line "WinHTTP proxy:"
Add-Line $winhttpProxy

Add-Section "2. DNS RESOLUTION (excvaluta.com)"
try {
    $dns = Resolve-DnsName 'excvaluta.com' -ErrorAction Stop
    $dns | ForEach-Object { Add-Line "  $($_.Type) $($_.Name) -> $($_.IPAddress ?? $_.NameHost)" }
} catch {
    Add-Line "DNS HIBA: $($_.Exception.Message)"
}

Add-Section "3. TCP CONNECT TEST (excvaluta.com:443)"
try {
    $tnc = Test-NetConnection -ComputerName excvaluta.com -Port 443 -WarningAction SilentlyContinue
    Add-Line "TcpTestSucceeded: $($tnc.TcpTestSucceeded)"
    Add-Line "RemoteAddress: $($tnc.RemoteAddress)"
    Add-Line "PingSucceeded: $($tnc.PingSucceeded)"
} catch {
    Add-Line "Test-NetConnection HIBA: $($_.Exception.Message)"
}

Add-Section "4. HTTP HEALTH CHECK (https://excvaluta.com/api/v1/auth/bootstrap-status)"
try {
    $r = Invoke-WebRequest -Uri 'https://excvaluta.com/api/v1/auth/bootstrap-status' -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Add-Line "HTTP Status: $($r.StatusCode)"
    Add-Line "Content (max 500 char): $($r.Content.Substring(0, [Math]::Min(500, $r.Content.Length)))"
} catch [System.Net.WebException] {
    Add-Line "WebException: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Add-Line "  StatusCode: $($_.Exception.Response.StatusCode)"
    }
} catch {
    Add-Line "HIBA: $($_.Exception.Message)"
    Add-Line "  Tipusa: $($_.Exception.GetType().FullName)"
}

Add-Section "5. TLS/SSL CERT CHECK"
try {
    $req = [System.Net.HttpWebRequest]::Create('https://excvaluta.com/api/v1/auth/bootstrap-status')
    $req.Timeout = 10000
    $resp = $req.GetResponse()
    $cert = $req.ServicePoint.Certificate
    if ($cert) {
        Add-Line "Cert Subject: $($cert.Subject)"
        Add-Line "Cert Issuer: $($cert.Issuer)"
        Add-Line "Cert ExpiryDate: $($cert.GetExpirationDateString())"
        Add-Line "Cert Serial: $($cert.GetSerialNumberString())"
    }
    $resp.Close()
} catch {
    Add-Line "TLS HIBA: $($_.Exception.Message)"
    if ($_.Exception.InnerException) {
        Add-Line "  InnerException: $($_.Exception.InnerException.Message)"
    }
}

Add-Section "6. TRACEROUTE (excvaluta.com)"
try {
    $tracert = & tracert -h 15 -w 1500 excvaluta.com 2>&1 | Out-String
    Add-Line $tracert
} catch {
    Add-Line "tracert HIBA: $($_.Exception.Message)"
}

Add-Section "7. WINDOWS FIREWALL RULES (Penztar)"
$rules = Get-NetFirewallRule -DisplayName "*Penztar*" -ErrorAction SilentlyContinue
if ($rules) {
    $rules | ForEach-Object { Add-Line "  $($_.DisplayName) - Direction=$($_.Direction) Action=$($_.Action) Enabled=$($_.Enabled)" }
} else {
    Add-Line "  Nincs Penztar firewall szabaly (nem feltetlen baj)"
}

Add-Section "8. TELEPITES ELLENORZES (C:\Program Files\Valutavalto Penztar)"
$instDir = 'C:\Program Files\Valutavalto Penztar'
if (Test-Path $instDir) {
    Add-Line "InstallDir letezik: $instDir"
    $envFile = "$instDir\.env"
    if (Test-Path $envFile) {
        Add-Line "Install dir .env tartalom:"
        Get-Content $envFile | ForEach-Object { Add-Line "  $_" }
    }
    $prodUrls = "$instDir\resources\production-urls.json"
    if (Test-Path $prodUrls) {
        $cfg = Get-Content $prodUrls -Raw | ConvertFrom-Json
        Add-Line "production-urls.json api_url: $($cfg.api_url)"
    } else {
        Add-Line "HIBA: production-urls.json HIANYZIK"
    }
} else {
    Add-Line "Telepites NEM TALALHATO ($instDir)"
}

Add-Section "9. USERDATA (%APPDATA%\valuta-penztar)"
$ud = "$env:APPDATA\valuta-penztar"
if (Test-Path $ud) {
    Add-Line "UserData letezik: $ud"
    $udEnv = "$ud\.env"
    if (Test-Path $udEnv) {
        Add-Line "UserData .env tartalom:"
        Get-Content $udEnv | ForEach-Object { Add-Line "  $_" }
    } else { Add-Line "UserData .env NEM letezik (= SetupWizard nem futott)" }
    $sc = "$ud\setup-config.json"
    if (Test-Path $sc) {
        Add-Line "setup-config.json tartalom:"
        Get-Content $sc | ForEach-Object { Add-Line "  $_" }
    } else { Add-Line "setup-config.json NEM letezik" }
    $db = "$ud\penztar.db"
    if (Test-Path $db) {
        Add-Line "penztar.db letezik: $((Get-Item $db).Length / 1KB) KB"
    } else {
        Add-Line "penztar.db NEM letezik (=> a SQLite server_url config nincs)"
    }
} else {
    Add-Line "UserData NEM letezik ($ud) — Penztar.exe meg sosem futott vagy az eltavolito torolte."
}

Add-Section "10. PENZTAR LOG (utolso 50 sor)"
$logFile = Get-ChildItem "$ud\logs" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($logFile) {
    Add-Line "Log: $($logFile.FullName)"
    Get-Content $logFile.FullName -Tail 50 -ErrorAction SilentlyContinue | ForEach-Object { Add-Line "  $_" }
} else {
    Add-Line "Nincs log fajl (Penztar.exe meg sosem futott vagy nem all rendelkezesre)"
}

# Mentes
$out -join "`n" | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "DIAGNOSZTIKAI JELENTES KESZ:" -ForegroundColor Green
Write-Host $reportPath -ForegroundColor Yellow
Write-Host ""
Write-Host "Kuld el ezt a fajlt az adminisztratornak (Kosa Zoltan)." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Nyomj ENTER-t a kilepeshez"
