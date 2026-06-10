#Requires -Version 5.1
<#
.SYNOPSIS
  Git diff alapjan melyik tesztek/modulok erintettek -- helyi hasvizsgalat.

Replaces: AI "what does this change affect?" kerdesek + blast-radius kezi futes.

Kiirja:
  - Valtoztatott fajlok listaja
  - Erintett backend modulok (controller/service/repo/entity)
  - Erintett frontend oldalak/komponensek
  - Ajanlott tesztfuttatas parancsok

.PARAMETER Base
  Alap branch/commit (default: main)

.PARAMETER Head
  Cel branch/commit (default: HEAD)

.EXAMPLE
  .\scripts\dev-tools\git-diff-impact.ps1
  .\scripts\dev-tools\git-diff-impact.ps1 -Base HEAD~5
  .\scripts\dev-tools\git-diff-impact.ps1 -Base main -Head feature/my-branch

Exit: 0 = OK
#>
param(
    [string]$Base = "main",
    [string]$Head = "HEAD"
)

$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')

# Changed files
$Changed = @(git -C $Root diff --name-only "${Base}...${Head}" 2>$null)
if (-not $Changed) {
    $Changed = @(git -C $Root diff --name-only HEAD 2>$null)
}

if (-not $Changed) {
    Write-Host "git-diff-impact: no changes detected vs $Base" -ForegroundColor Yellow
    exit 0
}

Write-Host "git-diff-impact: $($Changed.Count) changed file(s) vs $Base" -ForegroundColor Cyan
Write-Host ""

# Categorize
$BackendFiles    = $Changed | Where-Object { $_ -match '^backend/' }
$FrontendFiles   = $Changed | Where-Object { $_ -match '^frontend-react/' }
$PenzFiles       = $Changed | Where-Object { $_ -match '^penztar-client/' }
$KozpontiFiles   = $Changed | Where-Object { $_ -match '^kozponti-client/' }
$ArfolyamFiles   = $Changed | Where-Object { $_ -match '^arfolyam-keszito-client/' }
$FlywayFiles     = $Changed | Where-Object { $_ -match 'db/migration' }
$VaultFiles      = $Changed | Where-Object { $_ -match '^vault/' }
$ScriptFiles     = $Changed | Where-Object { $_ -match '^scripts/' }
$CIFiles         = $Changed | Where-Object { $_ -match '^\.github/' }

function Show-Module($label, $files) {
    if (-not $files -or $files.Count -eq 0) { return }
    Write-Host "  [$label] ($($files.Count))" -ForegroundColor Yellow
    $files | Select-Object -First 15 | ForEach-Object { Write-Host "    $_" }
    if ($files.Count -gt 15) { Write-Host "    ... ($($files.Count - 15) more)" }
    Write-Host ""
}

# Show modules
Show-Module "backend"        $BackendFiles
Show-Module "frontend-react" $FrontendFiles
Show-Module "penztar-client" $PenzFiles
Show-Module "kozponti"       $KozpontiFiles
Show-Module "arfolyam"       $ArfolyamFiles
Show-Module "flyway"         $FlywayFiles
Show-Module "vault/docs"     $VaultFiles
Show-Module "scripts"        $ScriptFiles
Show-Module "CI/CD"          $CIFiles

# Recommended test commands
Write-Host "Ajanlott tesztek:" -ForegroundColor Cyan
$testCmds = @()

if ($BackendFiles) {
    # Extract service/controller names for targeted tests
    $Targets = $BackendFiles | ForEach-Object {
        if ($_ -match '([A-Z]\w+)(Service|Controller|Repository)\.java') {
            $Matches[1] + $Matches[2] + "Test"
        }
    } | Where-Object { $_ }
    if ($Targets) {
        $testPattern = ($Targets | Select-Object -First 3) -join "|"
        $testCmds += "  cd backend && .\mvnw.cmd test -pl . -Dtest=`"$testPattern`" -q"
    } else {
        $testCmds += "  cd backend && .\mvnw.cmd test -q"
    }
}
if ($FlywayFiles) {
    $testCmds += "  python scripts/dev-tools/flyway-validate.py"
    $testCmds += "  python scripts/dev-tools/migration-next-version.py"
}
if ($FrontendFiles) {
    $testCmds += "  cd frontend-react && npm test -- --reporter=verbose"
}
if ($PenzFiles) {
    $testCmds += "  cd penztar-client && npm test -- --reporter=verbose"
}
if ($BackendFiles -or $FrontendFiles -or $PenzFiles) {
    $testCmds += "  .\scripts\dev-tools\typecheck-all.ps1"
}

if ($testCmds) {
    $testCmds | ForEach-Object { Write-Host $_ -ForegroundColor White }
} else {
    Write-Host "  (nem-kod fajlok, teszt nem szukseges)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Pre-push gate (teljes ellenorzeshez):" -ForegroundColor Cyan
Write-Host "  .\scripts\dev-tools\pre-push-gate.ps1 -Fast" -ForegroundColor White

exit 0
