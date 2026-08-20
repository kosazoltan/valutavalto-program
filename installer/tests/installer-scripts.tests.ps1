#!/usr/bin/env pwsh
# =============================================================================
# Statikus + dry-run regresszios tesztek az installer-scriptekre (X8/X9 fixek).
# PS 5.1-kompatibilis, nincs Pester fuggoseg. Futtatas:
#   powershell -NoProfile -ExecutionPolicy Bypass -File installer\tests\installer-scripts.tests.ps1
# Exit 0 = minden PASS; Exit 1 = van FAIL.
# =============================================================================
$ErrorActionPreference = 'Stop'
$fail = 0
function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) { Write-Host "[PASS] $name" -ForegroundColor Green }
    else { Write-Host "[FAIL] $name  $detail" -ForegroundColor Red; $script:fail++ }
}
$testsDir     = $PSScriptRoot
$installerDir = Split-Path -Parent $testsDir
$repoRoot     = Split-Path -Parent $installerDir

# --- T-A: mindharom script parse-olhato (AST, 0 error) ---
foreach ($f in @('build-final.ps1', 'build-common.ps1', 'tests\installer-validation-suite.ps1')) {
    $p = Join-Path $installerDir $f
    $errs = $null
    [System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$null, [ref]$errs) | Out-Null
    Check "parse: $f" ($errs.Count -eq 0) ($errs | Select-Object -First 1 | Out-String)
}

# --- T-B: Get-VersionFromPackageJson dry-run == root package.json version ---
. (Join-Path $installerDir 'build-common.ps1')
$expected = (Get-Content (Join-Path $repoRoot 'package.json') -Raw | ConvertFrom-Json).version
$actual   = Get-VersionFromPackageJson -ScriptRoot $installerDir
Check 'version helper dinamikus' ($actual -eq $expected -and $actual -match '^\d+\.\d+\.\d+$') "expected=$expected actual=$actual"

# --- T-C (X8a): a suite-ban NINCS hardcode-olt verzio-literal ---
$suite = Get-Content (Join-Path $testsDir 'installer-validation-suite.ps1') -Raw
Check 'suite: nincs hardcoded $VERSION' ($suite -notmatch '\$VERSION\s*=\s*["'']\d+\.\d+\.\d+["'']')

# --- T-D (X8b): nativ 64-bit registry path jelen van; WOW6432Node csak fallbackkent ---
Check 'suite: nativ reg path' ($suite -match [regex]::Escape('HKLM:\Software\BestChange\ValutavaltoPenztar'))

# --- T-E (X8c): postgres scram-check + no-trust assert jelen ---
Check 'suite: postgres scram' ($suite -match 'postgres.*scram-sha-256')
Check 'suite: no-trust assert' ($suite -match 'Nincs trust auth')

# --- T-F (X9): build-final .env-blokkja nem ir VITE_API_URL-t ---
$bf = Get-Content (Join-Path $installerDir 'build-final.ps1') -Raw
# A $envContent (build-time .env) assignment nem tartalmazhat VITE_API_URL-t;
# a penztar.env ($penztarEnv, runtime install-config) legitim modon tartalmazza.
$envContentMatch = [regex]::Match($bf, '(?ms)\$envContent\s*=.*?(?=\r?\n\s*\[System\.IO\.File\])')
Check 'build-final: van $envContent blokk' $envContentMatch.Success
Check 'build-final: .env-ben nincs VITE_API_URL' ($envContentMatch.Success -and $envContentMatch.Value -notmatch 'VITE_API_URL')

# --- T-G (X9 guard): .env.production guard jelen van ---
Check 'build-final: .env.production guard' ($bf -match '\.env\.production')

# --- T-H: WinNAT excludedportrange picker (FULL local install abort fix) ---
$pickerPath = Join-Path $installerDir 'scripts\pick-local-ports.ps1'
Check 'pick-local-ports.ps1 letezik' (Test-Path $pickerPath)
$pickerErrs = $null
[System.Management.Automation.Language.Parser]::ParseFile($pickerPath, [ref]$null, [ref]$pickerErrs) | Out-Null
Check 'pick-local-ports.ps1 parse' ($pickerErrs.Count -eq 0) ($pickerErrs | Select-Object -First 1 | Out-String)

. $pickerPath -DefineOnly
$sampleNetsh = @"
Protocol tcp Port Exclusion Ranges

Start Port    End Port
----------    --------
      5357        5357
     50000       50059     *
     54313       54412
     54566       54665
"@
$parsed = Get-TcpExcludedPortRangesFromText -Text $sampleNetsh
Check 'excluded range parser count' ($parsed.Count -eq 4) ("count=$($parsed.Count)")
Check '54320 excluded in sample' (Test-PortInExcludedRange -Port 54320 -Ranges $parsed)
Check '55432 not excluded in sample' (-not (Test-PortInExcludedRange -Port 55432 -Ranges $parsed))
Check '8080 not excluded in sample' (-not (Test-PortInExcludedRange -Port 8080 -Ranges $parsed))

$bindOk = { param($p) @(55432, 8080, 18080) -contains $p }
$pickedPg = Select-LocalListenPort -Preferred 54320 -Fallbacks @(55432, 55532) -ExcludedRanges $parsed -BindProbe $bindOk
Check 'picker skips excluded 54320' ($pickedPg -eq 55432) ("picked=$pickedPg")
$pickedHttp = Select-LocalListenPort -Preferred 8080 -Fallbacks @(18080) -ExcludedRanges $parsed -BindProbe $bindOk
Check 'picker keeps free 8080' ($pickedHttp -eq 8080) ("picked=$pickedHttp")
$none = Select-LocalListenPort -Preferred 54320 -Fallbacks @(54321) -ExcludedRanges $parsed -BindProbe { param($p) $false }
Check 'picker null if nothing bindable' ($null -eq $none)

$liveLine = powershell.exe -NoProfile -ExecutionPolicy Bypass -File $pickerPath | Select-Object -Last 1
Check 'live picker format PG,HTTP' ($liveLine -match '^\d+,\d+$') "out=$liveLine"
if ($liveLine -match '^(\d+),(\d+)$') {
    $livePg = [int]$Matches[1]
    $liveRanges = Get-TcpExcludedPortRanges
    if (Test-PortInExcludedRange -Port 54320 -Ranges $liveRanges) {
        Check 'live picker avoids excluded 54320' ($livePg -ne 54320) "picked=$livePg"
    } else {
        Check 'live picker 54320 allowed here' ($true)
    }
}

$nsi = Get-Content (Join-Path $installerDir 'Penztar-Setup.nsi') -Raw
Check 'NSI: pick-local-ports.ps1' ($nsi -match 'pick-local-ports\.ps1')
Check 'NSI: $PG_PORT var' ($nsi -match '(?m)^Var PG_PORT')
Check 'NSI: postgresql.conf uses \$PG_PORT' ($nsi -match 'port = \$PG_PORT')
Check 'NSI: no hardcoded port = 54320 write' ($nsi -notmatch 'FileWrite \$0 "port = 54320')
Check 'NSI: jdbc url uses \$PG_PORT' ($nsi -match 'jdbc:postgresql://localhost:\$PG_PORT/valuta')
Check 'NSI: listen_addresses 127.0.0.1' ($nsi -match "listen_addresses = '127\.0\.0\.1'")

if ($fail -gt 0) { Write-Host "`n$fail teszt FAIL" -ForegroundColor Red; exit 1 }
Write-Host "`nMinden teszt PASS" -ForegroundColor Green; exit 0
