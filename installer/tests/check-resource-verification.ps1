# Ellenorzi, hogy a Penztar-Setup.nsi minden kritikus Electron runtime-fajlra
# tartalmaz post-copy IfFileExists verifikaciot (audit TOP15 #3, 2026-07-04 incidens).
$ErrorActionPreference = 'Stop'
$nsi = Get-Content -Raw (Join-Path $PSScriptRoot '..\Penztar-Setup.nsi')

$required = @(
    'icudtl.dat', 'resources.pak', 'v8_context_snapshot.bin',
    'snapshot_blob.bin', 'chrome_100_percent.pak', 'chrome_200_percent.pak',
    'ffmpeg.dll', 'locales\en-US.pak', 'locales\hu.pak', 'resources\app.asar'
)

$failed = @()
foreach ($f in $required) {
    $pattern = [regex]::Escape("VerifyElectronFile `"$f`"")
    if ($nsi -notmatch $pattern) { $failed += $f }
}
if ($nsi -notmatch '!macro\s+VerifyElectronFile') {
    $failed += '<VerifyElectronFile makro definicio>'
}
if ($failed.Count -gt 0) {
    Write-Host "FAIL - hianyzo resource-verifikacio(k):" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host "OK - mind a $($required.Count) kritikus Electron-fajl verifikalva a .nsi-ben."
exit 0
