#Requires -Version 7.0
<#
.SYNOPSIS
  Komplex pre-push ellenőrzés — AI review hívások kiváltása helyi statikus analízissel.

Replaces: Codex/Copilot/Sourcery AI review körök NAGY részét. Lefuttatja azokat
az ellenőrzéseket amelyek nem igényelnek futó szervert vagy teljes build-et.

.PARAMETER Fast
  Kihagyja a lassabb ellenőrzéseket (dead-code-scan, complexity-scan).

.PARAMETER ChangedOnly
  Csak a git diff-ben szereplő fájlokra futtatja az analízist.

.EXAMPLE
  .\scripts\dev-tools\pre-push-gate.ps1
  .\scripts\dev-tools\pre-push-gate.ps1 -Fast
  .\scripts\dev-tools\pre-push-gate.ps1 -ChangedOnly

Exit: 0 = all pass, 1 = any fail
#>
param(
    [switch]$Fast,
    [switch]$ChangedOnly
)

$Root    = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Scripts = Join-Path $Root 'scripts\dev-tools'
$Failed  = $false
$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-Result($name, $ok, $detail, $elapsed) {
    $script:Results.Add([PSCustomObject]@{ Name=$name; OK=$ok; Detail=$detail; Sec=$elapsed })
    if (-not $ok) { $script:Failed = $true }
}

function Run-Check($name, $cmd, [int[]]$AllowedExitCodes = @(0)) {
    Write-Host "  $name..." -NoNewline
    $sw  = [System.Diagnostics.Stopwatch]::StartNew()
    $out = & cmd /d /c "$cmd 2>&1"
    $ok  = $AllowedExitCodes -contains $LASTEXITCODE
    $sw.Stop()
    $sec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    if ($ok) {
        Write-Host " OK [$($sec)s]" -ForegroundColor Green
    } else {
        Write-Host " FAIL [$($sec)s]" -ForegroundColor Red
        $out | Select-Object -Last 8 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkRed }
    }
    Add-Result $name $ok ($out | Select-Object -Last 1) $sec
}

Write-Host ""
Write-Host "pre-push-gate — helyi AI-review helyettesítő" -ForegroundColor Cyan
Write-Host "Root: $Root"
Write-Host ""

# ── 1. Flyway migráció validáció ──────────────────────────────────────────────
Run-Check "flyway-validate" "python `"$Scripts\flyway-validate.py`""

# ── 2. Endpoint biztonsági audit ──────────────────────────────────────────────
Run-Check "endpoint-audit (missing-only)" "python `"$Scripts\endpoint-audit.py`" --missing-only"

# ── 3. Multi-tenant audit (JPQL + findAll) ────────────────────────────────────
Run-Check "multi-tenant-audit" "python `"$Scripts\multi-tenant-audit.py`""

# ── 4. TypeScript typecheck (párhuzamos) ─────────────────────────────────────
Run-Check "typecheck-all" "pwsh -NoProfile -ExecutionPolicy Bypass -File `"$Scripts\typecheck-all.ps1`""

# ── 5. TODO/FIXME összesítő (nem blokoló — csak tájékoztató) ─────────────────
Write-Host "  todo-harvest (summary)..." -NoNewline
$sw  = [System.Diagnostics.Stopwatch]::StartNew()
$todos = & pwsh -NoProfile -ExecutionPolicy Bypass -File "$Scripts\todo-harvest.ps1" -Summary 2>&1
$sw.Stop()
$sec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
$todoCount = if (($todos -join "`n") -match 'todo-harvest: (\d+) hit') { $Matches[1] } else { "?" }
Write-Host " $todoCount item(s) [$($sec)s]" -ForegroundColor Yellow
# TODO harvest nem blokkolja a push-t — csak tájékoztat

# ── 6. Titkos adat gyors scan ─────────────────────────────────────────────────
Write-Host "  secrets-scan..." -NoNewline
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$secretHits = & rg --no-heading --line-number --color=never `
    --glob "!**/node_modules/**" --glob "!**/target/**" --glob "!**/dist/**" `
    --glob "!**/.git/**" --glob "!**/security-reports/**" --glob "!**/*.test.*" `
    -e '(?i)(password|secret|api[_-]?key|token|private[_-]?key)\s*[:=]\s*["\x27][^"x27]{6,}["\x27]' `
    "$Root\backend\src\main" "$Root\frontend-react\src" "$Root\penztar-client\electron" 2>$null |
    Where-Object { $_ -notmatch 'PARAM_[A-Z0-9_]+\s*=\s*"[A-Z0-9_]{6,}"' }
$sw.Stop(); $sec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
if ($secretHits) {
    Write-Host " FAIL [$($sec)s]" -ForegroundColor Red
    $secretHits | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    Add-Result "secrets-scan" $false "hardcoded secret candidates found" $sec
} else {
    Write-Host " OK [$($sec)s]" -ForegroundColor Green
    Add-Result "secrets-scan" $true "" $sec
}

# ── 7. Secrets deep scan (30+ minta) ─────────────────────────────────────────
Run-Check "secrets-deep-scan" "python `"$Scripts\secrets-deep-scan.py`""

# ── 8. Electron security (3 kliens) ──────────────────────────────────────────
Run-Check "electron-security" "python `"$Scripts\electron-security-scan.py`"" @(0, 2)

# ── 9. Flyway SQL tartalom audit ──────────────────────────────────────────────
Run-Check "flyway-content-audit" "python `"$Scripts\flyway-content-audit.py`" --last 5 --fail-severity MEDIUM"

# ── 10. Repo-memória frissesség (aktív memória write-gate) ────────────────────
# A .agent/memory bundle nem lehet elavult: a következő session onnan olvas be
# terület-tudást, elavult bundle = hamis tudás. AGENTS.md 2.1.
Run-Check "memory-stale-check" "node `"$Root\scripts\repo-memory.mjs`" stale-check"

# ── 11. (Opcionális, lassabb) ─────────────────────────────────────────────────
if (-not $Fast) {
    Run-Check "complexity-scan"    "python `"$Scripts\complexity-scan.py`""
    Run-Check "layer-violations"   "python `"$Scripts\layer-violation-scan.py`""
    Run-Check "transaction-audit"  "python `"$Scripts\transaction-audit.py`""
    Run-Check "n-plus-one-scan"    "python `"$Scripts\n-plus-one-scan.py`""
    Run-Check "ts-antipatterns"    "python `"$Scripts\ts-antipattern-scan.py`""
}

# ── Összesítő ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Összesítő ────────────────────────────────────────" -ForegroundColor Cyan
foreach ($r in $Results) {
    $icon  = if ($r.OK) { '✅' } else { '❌' }
    $color = if ($r.OK) { 'Green' } else { 'Red' }
    Write-Host ("  {0}  {1,-35} [{2}s]" -f $icon, $r.Name, $r.Sec) -ForegroundColor $color
}

$totalSec = ($Results | Measure-Object Sec -Sum).Sum
Write-Host ""
Write-Host ("Összesen: {0}s" -f [math]::Round($totalSec, 1)) -ForegroundColor Gray

if ($Failed) {
    Write-Host ""
    Write-Host "PRE-PUSH GATE SIKERTELEN — javítsd a hibákat push előtt" -ForegroundColor Red
    Write-Host "Tipp: -Fast flaggel kihagyod a complexity-scan-t a gyorsabb iterációhoz" -ForegroundColor DarkGray
    exit 1
}

Write-Host ""
Write-Host "PRE-PUSH GATE ÁTMENT — push mehet" -ForegroundColor Green
exit 0
