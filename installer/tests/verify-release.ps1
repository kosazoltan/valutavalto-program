# Valutavalto release-verifikáció a LETÖLTÖTT assetekre.
#
# MIÉRT: a zöld CI nem bizonyíték — a flotta a letöltött fájlokat kapja, tehát azokat
# kell mérni. A script pontosan azt ellenőrzi, amit a KLIENSEK ellenőriznek majd.
#
# Használat:
#   powershell -File verify-release.ps1 -Path C:\...\valutavalto-v2.28.80
#   powershell -File verify-release.ps1                       # a script mappájában keres
#   powershell -File verify-release.ps1 -Version 2.28.80 -ExpectedRollout 100
#
# A verziót a -Version paraméterből, vagy a mappában talált `Penztar-Setup-<ver>-*.exe`
# fájlnévből állapítja meg (NEM a mappa nevéből).
#
# Exit: 0 = minden zöld, 1 = szabálysértés, 2 = nem futtatható (nincs asset-mappa).

param(
    [string]$Path = '',
    [string]$Version = '',
    [int]$ExpectedRollout = 25
)

$ErrorActionPreference = 'Stop'
$failed = 0

function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if ($Ok) { Write-Host "[PASS] $Name" }
    else {
        Write-Host "[FAIL] $Name"
        if ($Detail) { Write-Host "       $Detail" }
        $script:failed++
    }
}

# --- Asset-könyvtár ---
# A repóból futtatva a $PSScriptRoot az installer/tests, ahol nincsenek assetek,
# ezért a -Path megadható (review: P2).
$dir = $Path
if (-not $dir) { $dir = $PSScriptRoot }
if (-not $dir) { $dir = (Get-Location).Path }
if (-not (Test-Path $dir)) {
    Write-Host "[FAIL] Az asset-konyvtar nem letezik: $dir"
    exit 2
}
$dir = (Resolve-Path $dir).Path

# --- Verzió ---
if (-not $Version) {
    $found = Get-ChildItem $dir -Filter 'Penztar-Setup-*.exe' -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($found -and $found.Name -match 'Penztar-Setup-(\d+\.\d+\.\d+)-') { $Version = $Matches[1] }
}
if (-not $Version) {
    Write-Host "[FAIL] A verzio nem allapithato meg ($dir). Adja meg: -Version X.Y.Z"
    exit 2
}

Write-Host "=== Valutavalto v$Version release-verifikacio ==="
Write-Host "Konyvtar:       $dir"
Write-Host "Elvart rollout: $ExpectedRollout%"
Write-Host ''

$penztarSetup = Get-ChildItem $dir -Filter "Penztar-Setup-$Version-*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
$penztarUninst = Get-ChildItem $dir -Filter "Penztar-Eltavolito-$Version-*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
$kozpontiName = "Kozponti-Munkaallomas-Setup-$Version.exe"

# --- 0. KÖTELEZŐ assetek jelenléte ---
# Review (P1): ha egy telepitő kimarad a release-bol, a script korabban csendben
# atengedte volna (a foreach egyszeruen nem futott le ra). Az assetek meglete ezert
# ONALLO, kotelezo ellenorzes.
Write-Host '--- 0. Kotelezo assetek jelenlete ---'
Check "Penztar-Setup-$Version-*.exe jelen van" ($null -ne $penztarSetup) 'a penztaros suite-telepito KOTELEZO'
Check "Penztar-Eltavolito-$Version-*.exe jelen van" ($null -ne $penztarUninst) 'az eltavolito KOTELEZO (a telepito hivatkozik ra)'
Check "$kozpontiName jelen van" (Test-Path (Join-Path $dir $kozpontiName)) 'a kozponti munkaallomas telepitoje KOTELEZO'
Check 'windows-signed-release-sha256.txt jelen van' (Test-Path (Join-Path $dir 'windows-signed-release-sha256.txt'))
Check 'update-manifest.json jelen van (penztar feed)' (Test-Path (Join-Path $dir 'update-manifest.json'))
Check 'munkaallomas.yml jelen van (kozponti feed)' (Test-Path (Join-Path $dir 'munkaallomas.yml'))
Check "valuta-backend-$Version.jar jelen van" (Test-Path (Join-Path $dir "valuta-backend-$Version.jar"))
Write-Host ''

# --- 1. Kód-aláírás ---
Write-Host '--- 1. Kod-alairas ---'
$signedNames = @()
if ($penztarSetup) { $signedNames += $penztarSetup.Name }
if ($penztarUninst) { $signedNames += $penztarUninst.Name }
if (Test-Path (Join-Path $dir $kozpontiName)) { $signedNames += $kozpontiName }
foreach ($name in $signedNames) {
    $path = Join-Path $dir $name
    $sig = Get-AuthenticodeSignature -LiteralPath $path
    Check "$name : Authenticode Valid" ($sig.Status -eq 'Valid') "Status=$($sig.Status)"
    $subject = [string]$sig.SignerCertificate.Subject
    Check "$name : subject = EXCLUSIVE BEST Change Zrt." ($subject -like '*EXCLUSIVE BEST Change*') $subject
}
Write-Host ''

# --- 2. SHA-256 manifest ---
Write-Host '--- 2. SHA-256 manifest ---'
$manifestPath = Join-Path $dir 'windows-signed-release-sha256.txt'
if (Test-Path $manifestPath) {
    $hashLines = @(Get-Content $manifestPath | Where-Object { $_ -match '^[0-9a-f]{64}\s' })
    Check 'a manifest tartalmaz hash-sorokat (nem csak fejlecet)' ($hashLines.Count -gt 0) "sorok: $($hashLines.Count)"
    foreach ($line in $hashLines) {
        $parts = $line -split '\s+', 2
        $expected = $parts[0]
        $file = $parts[1].Trim()
        $path = Join-Path $dir $file
        if (-not (Test-Path $path)) { Check "$file : jelen van" $false 'a manifest hivatkozik ra, de nincs a release-ben'; continue }
        $actual = (Get-FileHash $path -Algorithm SHA256).Hash.ToLower()
        Check "$file : SHA-256 egyezik a manifesttel" ($actual -eq $expected) "manifest=$expected actual=$actual"
    }
} else {
    # Review: a hianyzo fajl utan NEM hivunk Get-Content-et ($ErrorActionPreference=Stop
    # mellett az megszakitotta volna a scriptet a tobbi ellenorzes elott).
    Write-Host '       (kihagyva — nincs manifest)'
}
Write-Host ''

# --- 3. update-manifest.json (PÉNZTÁR suite-updater feed) ---
Write-Host '--- 3. update-manifest.json (penztar suite-updater) ---'
$umPath = Join-Path $dir 'update-manifest.json'
if (Test-Path $umPath) {
    $um = Get-Content $umPath -Raw | ConvertFrom-Json
    Check 'schemaVersion = 1 (a kliens ezt varja)' ($um.schemaVersion -eq 1) "kapott: $($um.schemaVersion)"
    Check "version = $Version" ($um.version -eq $Version) "kapott: $($um.version)"
    # A kliens hianyzo rolloutPercent eseten 100-at hasznal.
    $actualRollout = if ($null -ne $um.rolloutPercent) { [int]$um.rolloutPercent } else { 100 }
    Check "rolloutPercent = $ExpectedRollout (staged rollout)" ($actualRollout -eq $ExpectedRollout) "kapott: $actualRollout"
    Check 'mandatory = false (nincs kenyszeritett frissites)' ($um.mandatory -eq $false)
    if ($penztarSetup) {
        Check 'penztar.file a helyes telepito' ($um.penztar.file -eq $penztarSetup.Name) "kapott: $($um.penztar.file)"
    }
    Check 'penztar.file illeszkedik a kliens szigoru mintajara' `
        ($um.penztar.file -match '^Penztar-Setup-[0-9A-Za-z._-]+\.exe$') $um.penztar.file
    Check 'penztar.file nem tartalmaz utvonalat (path-traversal vedelem)' `
        (($um.penztar.file -notmatch '[\\/]') -and ($um.penztar.file -notmatch '\.\.')) $um.penztar.file
    Check 'penztar.url HTTPS' ($um.penztar.url -like 'https://*') $um.penztar.url
    Check "penztar.url a v$Version release-re mutat" ($um.penztar.url -like "*/releases/download/v$Version/*") $um.penztar.url
    Check 'penztar.silentArgs tartalmazza a /S-t' ($um.penztar.silentArgs -contains '/S')
    Check 'penztar.silentArgs csak engedelyezett zaszlokat tartalmaz' `
        (@($um.penztar.silentArgs | Where-Object { $_ -notin @('/S', '/NCRC') }).Count -eq 0) `
        ($um.penztar.silentArgs -join ' ')
    if ($penztarSetup) {
        $realHash = (Get-FileHash $penztarSetup.FullName -Algorithm SHA256).Hash.ToLower()
        Check 'penztar.sha256 EGYEZIK a letoltott telepito tenyleges hash-evel' ($um.penztar.sha256 -eq $realHash) "manifest=$($um.penztar.sha256) actual=$realHash"
        # A kliensben a sizeBytes OPCIONALIS, ezert csak akkor allitunk rola, ha van.
        if ($null -ne $um.penztar.sizeBytes) {
            Check 'penztar.sizeBytes egyezik a tenyleges merettel' ($um.penztar.sizeBytes -eq $penztarSetup.Length) "manifest=$($um.penztar.sizeBytes) actual=$($penztarSetup.Length)"
        } else {
            Write-Host '[INFO] penztar.sizeBytes nincs megadva (a kliensben opcionalis)'
        }
    }
} else {
    Write-Host '       (kihagyva — nincs update-manifest.json)'
}
Write-Host ''

# --- 4. munkaallomas.yml (KÖZPONTI electron-updater feed) ---
Write-Host '--- 4. munkaallomas.yml (kozponti electron-updater) ---'
$ymlPath = Join-Path $dir 'munkaallomas.yml'
if (Test-Path $ymlPath) {
    $ymlText = Get-Content $ymlPath -Raw
    $verMatch = [regex]::Match($ymlText, '(?m)^\s*version:\s*(.+?)\s*$')
    Check "a yml verzioja $Version" ($verMatch.Success -and $verMatch.Groups[1].Value.Trim() -eq $Version) $verMatch.Groups[1].Value
    $pathMatch = [regex]::Match($ymlText, '(?m)^\s*path:\s*(.+?)\s*$')
    $shaMatch = [regex]::Match($ymlText, '(?m)^\s*sha512:\s*(.+?)\s*$')
    Check 'a yml tartalmaz path + sha512 mezot' ($pathMatch.Success -and $shaMatch.Success)
    if ($pathMatch.Success -and $shaMatch.Success) {
        $exeName = $pathMatch.Groups[1].Value.Trim("'", '"')
        $exePath = Join-Path $dir $exeName
        Check "a yml-ben hivatkozott exe jelen van ($exeName)" (Test-Path $exePath)
        if (Test-Path $exePath) {
            $sha512 = [System.Security.Cryptography.SHA512]::Create()
            $stream = [System.IO.File]::OpenRead($exePath)
            try { $actual = [Convert]::ToBase64String($sha512.ComputeHash($stream)) }
            finally { $stream.Dispose(); $sha512.Dispose() }
            Check 'munkaallomas.yml sha512 EGYEZIK az alairt exe hash-evel' ($actual -eq $shaMatch.Groups[1].Value) "yml=$($shaMatch.Groups[1].Value) actual=$actual"
        }
    }
    Check '.blockmap jelen van (delta-letoltes)' (Test-Path (Join-Path $dir "$kozpontiName.blockmap"))
} else {
    Write-Host '       (kihagyva — nincs munkaallomas.yml)'
}
Write-Host ''

# --- 5. TILOS assetek ---
Write-Host '--- 5. Tilos assetek (duplikalt-telepites vedelem) ---'
foreach ($forbidden in @('penztar.yml', 'latest.yml')) {
    Check "$forbidden NINCS a release-ben" (-not (Test-Path (Join-Path $dir $forbidden))) 'a regi penztar-flotta duplikalt telepitest kapna (terv 3.2)'
}
Write-Host ''

# --- 6. Backend ---
Write-Host '--- 6. Backend ---'
$jar = Join-Path $dir "valuta-backend-$Version.jar"
if (Test-Path $jar) {
    Check 'a JAR erdemi meretu (>50 MB)' ((Get-Item $jar).Length -gt 50MB) "$([math]::Round((Get-Item $jar).Length/1MB,1)) MB"
} else {
    Write-Host '       (kihagyva — nincs backend JAR)'
}

Write-Host ''
Write-Host '=============================================='
if ($failed -gt 0) {
    Write-Host "VERIFIKACIO: FAIL - $failed ellenorzes bukott."
    exit 1
}
Write-Host 'VERIFIKACIO: PASS - minden ellenorzes zold.'
exit 0
