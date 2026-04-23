# Lockfile integrity checker - AGENTS.md #17
# Forras: MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md

param([switch]$Strict)

$ErrorActionPreference = 'Continue'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$blockers = @()

function Write-Step { param($Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }

Write-Step "Lockfile integrity check"

# Node.js/npm
$pkgJson = Join-Path $RepoRoot "frontend-react/package.json"
$pkgLock = Join-Path $RepoRoot "frontend-react/package-lock.json"
if (Test-Path $pkgJson) {
    if (-not (Test-Path $pkgLock)) { $blockers += "frontend-react: package.json VAN de package-lock.json NINCS" }
    else { Write-Host "[OK] frontend-react: package-lock.json VAN" -ForegroundColor Green }
}

$penztarPkg = Join-Path $RepoRoot "penztar-client/package.json"
$penztarLock = Join-Path $RepoRoot "penztar-client/package-lock.json"
if (Test-Path $penztarPkg) {
    if (-not (Test-Path $penztarLock)) { $blockers += "penztar-client: package-lock.json NINCS" }
    else { Write-Host "[OK] penztar-client: package-lock.json VAN" -ForegroundColor Green }
}

# Maven (pom.xml nem hasznal lockfile-t, de a .mvn/wrapper valtozas kockazatos)
$pom = Join-Path $RepoRoot "backend/pom.xml"
if (Test-Path $pom) { Write-Host "[INFO] backend/pom.xml (Maven dependency management, nincs lockfile-kovetelmeny)" -ForegroundColor DarkGray }

# Python (ha van)
$pyproject = Join-Path $RepoRoot "pyproject.toml"
$poetryLock = Join-Path $RepoRoot "poetry.lock"
$pipLock = Join-Path $RepoRoot "requirements.txt"
if (Test-Path $pyproject) {
    if (-not (Test-Path $poetryLock) -and -not (Test-Path $pipLock)) { $blockers += "pyproject.toml VAN de poetry.lock/requirements.txt NINCS" }
}

# Recommendation: kotelezo parancsok
Write-Step "Recommended commands"
Write-Host "  npm:   npm ci  (NEM npm install, lockfile felulirja!)" -ForegroundColor Yellow
Write-Host "  pnpm:  pnpm install --frozen-lockfile" -ForegroundColor Yellow
Write-Host "  pip:   pip install --require-hashes -r requirements.txt" -ForegroundColor Yellow

if ($blockers.Count -eq 0) {
    Write-Host "`n[PASS] Lockfile integrity OK" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[BLOCK] Blokkolo jelzesek:" -ForegroundColor Red
    $blockers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    if ($Strict) { exit 1 } else { exit 0 }
}
