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

if ($fail -gt 0) { Write-Host "`n$fail teszt FAIL" -ForegroundColor Red; exit 1 }
Write-Host "`nMinden teszt PASS" -ForegroundColor Green; exit 0
