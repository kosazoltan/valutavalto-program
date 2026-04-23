<#
.SYNOPSIS
    Opus 4.7 GitHub quality mandate - pre-push lokalis kapu (lint + typecheck + test + build).

.DESCRIPTION
    Kotelezoen futtatando MINDEN git push elott. Ha barmelyik lepes bukik,
    exit=1 es tilos push-olni.

    Codex PR #156 P1 review fix: mvn test + mvn package (nem csak compile).
    Sourcery PR #156 fix: Test-Path check a directory-kre (robusztusabb).

.PARAMETER SkipBackend
    Ha csak frontend valtozott, a backend build kihagyhato (gyors mod).

.PARAMETER SkipFrontend
    Ha csak backend valtozott, a frontend build kihagyhato.

.PARAMETER SkipTests
    GYORS mod: csak compile/typecheck/lint, NEM tests/package. Csak hot-fix hoz.
    TILOS ezt hasznalni sima push-hoz.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/pre-push-quality-gate.ps1
    powershell -ExecutionPolicy Bypass -File scripts/pre-push-quality-gate.ps1 -SkipBackend
#>
param(
    [switch]$SkipBackend,
    [switch]$SkipFrontend,
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$failed = @()
$warnings = @()

function Write-Step { param($Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-OK   { param($Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Err  { param($Msg) Write-Host "[ERR] $Msg" -ForegroundColor Red }
function Write-Warn { param($Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }

Write-Step "Opus 4.7 pre-push quality gate (2026-04-23+)"
Write-Host "Repo: $RepoRoot"
if ($SkipTests) { Write-Warn "SkipTests=true - HOTFIX mod, tilos sima push-hoz" }

# 1. FRONTEND
$feDir = Join-Path $RepoRoot "frontend-react"
if ($SkipFrontend) {
    Write-Host "  (frontend skip)" -ForegroundColor DarkGray
} elseif (-not (Test-Path $feDir)) {
    Write-Warn "frontend-react konyvtar nincs - skipping"
    $warnings += "frontend-react dir missing"
} else {
    Write-Step "1a. Frontend (React) - typecheck"
    Push-Location $feDir
    try {
        & npx tsc --noEmit
        if ($LASTEXITCODE -eq 0) { Write-OK "tsc --noEmit: 0 error" }
        else { Write-Err "tsc --noEmit FAIL"; $failed += "frontend typecheck" }
    } finally { Pop-Location }

    Write-Step "1b. Frontend (React) - lint"
    Push-Location $feDir
    try {
        $hasLintConfig = (Test-Path ".eslintrc*") -or ((Test-Path "package.json") -and ((Get-Content package.json -Raw) -match '"lint"'))
        if ($hasLintConfig) {
            & npm run lint --if-present
            if ($LASTEXITCODE -eq 0) { Write-OK "npm run lint: 0 error" }
            else { Write-Err "npm run lint FAIL"; $failed += "frontend lint" }
        } else { Write-Host "  (nincs lint config)" -ForegroundColor DarkGray }
    } finally { Pop-Location }

    if (-not $SkipTests) {
        Write-Step "1c. Frontend (React) - vitest (gyors: csak changed)"
        Push-Location $feDir
        try {
            $hasTest = (Test-Path "package.json") -and ((Get-Content package.json -Raw) -match '"test"')
            if ($hasTest) {
                & npm test -- --run --reporter=dot 2>&1 | Select-Object -Last 100
                if ($LASTEXITCODE -eq 0) { Write-OK "vitest: 0 failure" }
                else { Write-Warn "vitest FAIL (optional)"; $warnings += "frontend vitest" }
            } else { Write-Host "  (nincs test config)" -ForegroundColor DarkGray }
        } finally { Pop-Location }
    }
}

# 2. BACKEND
$beDir = Join-Path $RepoRoot "backend"
if ($SkipBackend) {
    Write-Host "  (backend skip)" -ForegroundColor DarkGray
} elseif (-not (Test-Path $beDir)) {
    Write-Warn "backend konyvtar nincs - skipping"
    $warnings += "backend dir missing"
} elseif (-not (Test-Path (Join-Path $beDir "mvnw"))) {
    Write-Warn "backend/mvnw nincs - skipping"
    $warnings += "mvnw missing"
} else {
    if ($SkipTests) {
        Write-Step "2a. Backend (Maven) - compile (SkipTests mode)"
        Push-Location $beDir
        try {
            & ./mvnw -q -DskipTests compile
            if ($LASTEXITCODE -eq 0) { Write-OK "mvn compile: 0 error" }
            else { Write-Err "mvn compile FAIL"; $failed += "backend compile" }
        } finally { Pop-Location }
    } else {
        Write-Step "2a. Backend (Maven) - TEST (default)"
        Push-Location $beDir
        try {
            & ./mvnw -q test
            if ($LASTEXITCODE -eq 0) { Write-OK "mvn test: 0 failure" }
            else { Write-Err "mvn test FAIL"; $failed += "backend test" }
        } finally { Pop-Location }

        Write-Step "2b. Backend (Maven) - PACKAGE (reprodukalhato build)"
        Push-Location $beDir
        try {
            & ./mvnw -q -DskipTests package
            if ($LASTEXITCODE -eq 0) { Write-OK "mvn package: OK" }
            else { Write-Err "mvn package FAIL"; $failed += "backend package" }
        } finally { Pop-Location }
    }
}

# 3. LOCKFILE INTEGRITY (V2 #17)
Write-Step "3. Lockfile integrity (V2 #17)"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'lockfile-integrity-check.ps1') -Strict
if ($LASTEXITCODE -ne 0) { $failed += "lockfile integrity" }

# 4. ACTIONS HARDENING (V2 #18)
Write-Step "4. GitHub Actions hardening (V2 #18)"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'actions-hardening-check.ps1') -Strict
if ($LASTEXITCODE -ne 0) { $failed += "actions hardening" }

# 3. SUMMARY
Write-Step "Eredmeny"
if ($warnings.Count -gt 0) {
    Write-Host "Figyelmeztetesek:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
if ($failed.Count -eq 0) {
    Write-OK "Minden kapu ZOLD. Push engedelyezett."
    Write-Host ""
    Write-Host "Kovetkezo lepes push utan:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File scripts/github-signal-check.ps1 <PR_NUM>" -ForegroundColor Yellow
    exit 0
} else {
    Write-Err "BLOKKOLO kapu failed: $($failed -join ', ')"
    Write-Err "TILOS push-olni. Javits, futtasd ujra, es csak zold allapotban push-olj."
    exit 1
}