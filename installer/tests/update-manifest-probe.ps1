# update-manifest.json generalo logika OFFLINE probaja.
#
# MIERT: a workflow-lepes csak eles release-nel futna le, es a hash-kinyeres
# regex-e konnyen csendben ures marad (a SHA-256 manifest maga is ebbe a csapdaba
# esett: `-Include` `\*` nelkul ures listat adott). Ez a script ugyanazt a logikat
# futtatja szintetikus release-flat konyvtaron, es ELLENORZI a kimenetet.

$ErrorActionPreference = 'Stop'
$failed = 0

function Assert-Check {
    param([string]$Name, [bool]$Ok)
    if ($Ok) {
        Write-Host "[PASS] $Name"
    } else {
        Write-Host "[FAIL] $Name"
        $script:failed++
    }
}

$flatDir = Join-Path $env:TEMP ("release-flat-probe-" + (Get-Random))
New-Item -ItemType Directory -Force -Path $flatDir | Out-Null

# Szintetikus release-assetek a valos nevkonvencioval.
$penztarName = 'Penztar-Setup-2.28.79-20260812.exe'
Set-Content -Path (Join-Path $flatDir $penztarName) -Value 'penztar suite installer payload' -NoNewline
Set-Content -Path (Join-Path $flatDir 'Penztar-Eltavolito-2.28.79-20260812.exe') -Value 'uninstaller' -NoNewline
Set-Content -Path (Join-Path $flatDir 'Kozponti-Munkaallomas-Setup-2.28.79.exe') -Value 'kozponti' -NoNewline
Set-Content -Path (Join-Path $flatDir 'valuta-backend.jar') -Value 'jar' -NoNewline

# 1. SHA-256 manifest ugyanugy, ahogy a workflow generalja.
$manifest = Join-Path $flatDir 'windows-signed-release-sha256.txt'
'# Valutavalto v2.28.79 signed release SHA-256' | Out-File $manifest
'# Build date: 20260812' | Out-File $manifest -Append
'' | Out-File $manifest -Append
Get-ChildItem $flatDir -File | Where-Object { $_.Extension -in '.exe', '.jar' } | Sort-Object Name | ForEach-Object {
    $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    ($h + '  ' + $_.Name) | Out-File $manifest -Append
}

# 2. A VIZSGALT logika (szo szerint a workflow publish-release jobjabol).
$penztarExe = Get-ChildItem $flatDir -File | Where-Object { $_.Name -like 'Penztar-Setup-*.exe' } | Sort-Object Name | Select-Object -Last 1
Assert-Check 'megtalalta a Penztar-Setup exe-t' ($null -ne $penztarExe)

$manifestLines = Get-Content $manifest
$hashLine = $manifestLines | Where-Object { $_ -match "\s$([regex]::Escape($penztarExe.Name))$" } | Select-Object -First 1
Assert-Check 'talalt hash-sort a manifestben (nem ures lista)' ($null -ne $hashLine)

$penztarHash = ($hashLine -split '\s+')[0]
Assert-Check 'a kinyert hash 64 hexa karakter' ($penztarHash -match '^[0-9a-f]{64}$')

$rolloutInt = 25
$tag = 'v2.28.79'
$url = 'https://github.com/kosazoltan/valutavalto-program/releases/download/' + $tag + '/' + $penztarExe.Name

$updateManifest = [ordered]@{}
$updateManifest['schemaVersion'] = 1
$updateManifest['version'] = '2.28.79'
$updateManifest['releasedAt'] = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$updateManifest['rolloutPercent'] = $rolloutInt
$updateManifest['mandatory'] = $false
$updateManifest['notes'] = 'Probe futas.'

$penztarBlock = [ordered]@{}
$penztarBlock['file'] = $penztarExe.Name
$penztarBlock['url'] = $url
$penztarBlock['sha256'] = $penztarHash
$penztarBlock['sizeBytes'] = $penztarExe.Length
$penztarBlock['silentArgs'] = @('/S')
$updateManifest['penztar'] = $penztarBlock

$updateManifestPath = Join-Path $flatDir 'update-manifest.json'
$updateManifest | ConvertTo-Json -Depth 5 | Out-File $updateManifestPath -Encoding utf8

# 3. ELLENORZES: a kliens `parseManifest` szerzodese + hash-igazsag.
$parsed = Get-Content $updateManifestPath -Raw | ConvertFrom-Json
$actual = (Get-FileHash $penztarExe.FullName -Algorithm SHA256).Hash.ToLower()

Assert-Check 'schemaVersion = 1' ($parsed.schemaVersion -eq 1)
Assert-Check 'version semver formatum' ($parsed.version -match '^\d+\.\d+\.\d+$')
Assert-Check 'a manifest hash EGYEZIK a fajl tenyleges hash-evel' ($parsed.penztar.sha256 -eq $actual)
Assert-Check 'hash 64 hexa karakter (kliens-elvaras)' ($parsed.penztar.sha256 -match '^[0-9a-f]{64}$')
Assert-Check 'url HTTPS (kliens elutasit mast)' ($parsed.penztar.url -like 'https://*')
Assert-Check 'url a helyes fajlra mutat' ($parsed.penztar.url.EndsWith($penztarExe.Name))
Assert-Check 'fajlnev .exe' ($parsed.penztar.file -like '*.exe')
Assert-Check 'sizeBytes = tenyleges meret' ($parsed.penztar.sizeBytes -eq $penztarExe.Length)
Assert-Check 'silentArgs tartalmazza a /S-t' ($parsed.penztar.silentArgs -contains '/S')
Assert-Check 'rolloutPercent atmegy (25, nem valik 100-ra)' ($parsed.rolloutPercent -eq 25)
Assert-Check 'NEM a kozponti telepitot valasztotta' ($parsed.penztar.file -notlike 'Kozponti*')
Assert-Check 'NEM az uninstallert valasztotta' ($parsed.penztar.file -notlike '*Eltavolito*')

Write-Host ''
Write-Host '=== generalt update-manifest.json ==='
Get-Content $updateManifestPath

Remove-Item -Recurse -Force $flatDir -ErrorAction SilentlyContinue

Write-Host ''
if ($failed -gt 0) {
    Write-Host ("PROBE RESULT: FAIL - " + $failed + " ellenorzes bukott.")
    exit 1
}
Write-Host 'PROBE RESULT: PASS - minden ellenorzes zold.'
exit 0
