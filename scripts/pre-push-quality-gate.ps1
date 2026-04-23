<#
.SYNOPSIS
    Opus 4.7 GitHub quality mandate - pre-push lokalis kapu (lint + typecheck + test + build).

.DESCRIPTION
    Kotelezoen futtatando MINDEN git push elott. Ha barmelyik lepes bukik,
    exit=1 es tilos push-olni. A user-direktiva (2026-04-23) alapjan az agent
    csak zold bizonyitek utan mondhat "kesz" / "push-olhato" allapotot.

.PARAMETER SkipBackend
    Ha csak frontend valtozott, a backend build kihagyhato (gyors mod).

.PARAMETER SkipFrontend
    Ha csak backend valtozott, a frontend build kihagyhato.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/pre-push-quality-gate.ps1
    powershell -ExecutionPolicy Bypass -File scripts/pre-push-quality-gate.ps1 -SkipBackend
#>
param(
    [switch]$SkipBackend,
    [switch]$SkipFrontend
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$failed = @()

function Write-Step { param($Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-OK   { param($Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Err  { param($Msg) Write-Host "[ERR] $Msg" -ForegroundColor Red }

Write-Step "Opus 4.7 pre-push quality gate (2026-04-23+)"
Write-Host "Repo: $RepoRoot"

# 1. FRONTEND
if (-not $SkipFrontend) {
    Write-Step "1. Frontend (React) - typecheck"
    Push-Location (Join-Path $RepoRoot "frontend-react")
    try {
        & npx tsc --noEmit
        if ($LASTEXITCODE -eq 0) { Write-OK "tsc --noEmit: 0 error" }
        else { Write-Err "tsc --noEmit FAIL"; $failed += "frontend typecheck" }
    } finally { Pop-Location }

    Write-Step "1. Frontend (React) - lint (ha letezik)"
    Push-Location (Join-Path $RepoRoot "frontend-react")
    try {
        $hasLintConfig = (Test-Path ".eslintrc*") -or ((Get-Content package.json -Raw) -match '"lint"')
        if ($hasLintConfig) {
            & npm run lint --if-present
            if ($LASTEXITCODE -eq 0) { Write-OK "npm run lint: 0 error" }
            else { Write-Err "npm run lint FAIL"; $failed += "frontend lint" }
        } else { Write-Host "  (nincs lint config)" -ForegroundColor DarkGray }
    } finally { Pop-Location }
}

# 2. BACKEND
if (-not $SkipBackend) {
    Write-Step "2. Backend (Maven) - compile"
    Push-Location (Join-Path $RepoRoot "backend")
    try {
        & ./mvnw -q -DskipTests compile
        if ($LASTEXITCODE -eq 0) { Write-OK "mvn compile: 0 error" }
        else { Write-Err "mvn compile FAIL"; $failed += "backend compile" }
    } finally { Pop-Location }
}

# 3. SUMMARY
Write-Step "Eredmeny"
if ($failed.Count -eq 0) {
    Write-OK "Minden kapu ZOLD. Push engedelyezett."
    Write-Host ""
    Write-Host "Kovetkezo lepes push utan:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File scripts/github-signal-check.ps1 <PR_NUM>" -ForegroundColor Yellow
    exit 0
} else {
    Write-Err "BLOKKOLO kapu failed: $($failed -join ', ')"
    Write-Err "TILOS push-olni. Javits, futtasd ujra, es csak zold allapotban merj push-olni."
    exit 1
}