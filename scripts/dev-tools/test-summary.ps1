#Requires -Version 5.1
<#
.SYNOPSIS
  Run backend (Maven) + frontend-react + penztar-client tests; terse summary.

.PARAMETER BackendOnly
  Skip frontend Vitest runs.

.PARAMETER FrontendOnly
  Skip backend Maven run.

.EXAMPLE
  .\scripts\dev-tools\test-summary.ps1
  .\scripts\dev-tools\test-summary.ps1 -FrontendOnly
  .\scripts\dev-tools\test-summary.ps1 -BackendOnly

Exit: 0 = all pass, 1 = any fail
#>
param(
    [switch]$BackendOnly,
    [switch]$FrontendOnly
)

$Root    = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Results = [System.Collections.Generic.List[PSCustomObject]]::new()
$Failed  = $false

function Add-Result($name, $ok, $detail) {
    $script:Results.Add([PSCustomObject]@{ Name = $name; OK = $ok; Detail = $detail })
    if (-not $ok) { $script:Failed = $true }
}

# ── helpers ──────────────────────────────────────────────────────────────────

function Parse-Vitest([string[]]$output) {
    $fileMatch  = $output | Select-String 'Test Files\s+(\d+)' | Select-Object -Last 1
    $testMatch  = $output | Select-String '^\s+Tests\s+(\d+)' | Select-Object -Last 1
    $failMatch  = $output | Select-String 'failed'
    $files = if ($fileMatch)  { $fileMatch.Matches[0].Groups[1].Value }  else { '?' }
    $tests = if ($testMatch)  { $testMatch.Matches[0].Groups[1].Value }  else { '?' }
    $hasFail = $null -ne $failMatch
    [PSCustomObject]@{ Files = $files; Tests = $tests; HasFail = $hasFail }
}

function Parse-Maven([string[]]$output) {
    # Last "Tests run: N, Failures: N, Errors: N, Skipped: N" line
    $summary = $output | Select-String 'Tests run:' | Select-Object -Last 1
    $build   = $output | Select-String 'BUILD (SUCCESS|FAILURE)' | Select-Object -Last 1
    [PSCustomObject]@{ Summary = $summary?.Line?.Trim(); Build = $build?.Line?.Trim() }
}

function Show-FirstErrors([string[]]$output, [int]$count = 8) {
    $output | Where-Object { $_ -match 'FAIL|error|Error' } |
        Select-Object -First $count |
        ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
}

# ── Backend ───────────────────────────────────────────────────────────────────

if (-not $FrontendOnly) {
    $backendDir = Join-Path $Root 'backend'
    Write-Host 'backend (Maven)...' -NoNewline
    $sw  = [System.Diagnostics.Stopwatch]::StartNew()
    $raw = & cmd /d /c "cd /d `"$backendDir`" && .\mvnw.cmd test -q 2>&1"
    $ok  = $LASTEXITCODE -eq 0
    $sw.Stop(); $sec = [math]::Round($sw.Elapsed.TotalSeconds, 0)
    $parsed = Parse-Maven $raw
    if ($ok) {
        $detail = $parsed.Summary ?? 'PASS'
        Write-Host " ✅  [$($sec)s]" -ForegroundColor Green
    } else {
        $detail = $parsed.Summary ?? $parsed.Build ?? 'FAIL'
        Write-Host " ❌  [$($sec)s]" -ForegroundColor Red
        Show-FirstErrors $raw
    }
    Add-Result 'backend' $ok $detail
}

# ── Frontend / Vitest ─────────────────────────────────────────────────────────

$frontendProjects = @(
    [PSCustomObject]@{ Name = 'frontend-react'; Dir = 'frontend-react' },
    [PSCustomObject]@{ Name = 'penztar-client';  Dir = 'penztar-client'  }
)

if (-not $BackendOnly) {
    foreach ($p in $frontendProjects) {
        $dir = Join-Path $Root $p.Dir
        Write-Host "$($p.Name) (vitest)..." -NoNewline
        $sw  = [System.Diagnostics.Stopwatch]::StartNew()
        $raw = & cmd /d /c "cd /d `"$dir`" && npm test 2>&1"
        $ok  = $LASTEXITCODE -eq 0
        $sw.Stop(); $sec = [math]::Round($sw.Elapsed.TotalSeconds, 0)
        $v = Parse-Vitest $raw
        if ($ok) {
            Write-Host " ✅  $($v.Tests) tests  [$($sec)s]" -ForegroundColor Green
            Add-Result $p.Name $true "$($v.Tests) tests passed"
        } else {
            Write-Host " ❌  [$($sec)s]" -ForegroundColor Red
            Show-FirstErrors $raw
            Add-Result $p.Name $false "FAILED (files=$($v.Files), tests=$($v.Tests))"
        }
    }
}

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "── Summary ──────────────────────────────────────────" -ForegroundColor Cyan
foreach ($r in $Results) {
    $icon  = if ($r.OK) { '✅' } else { '❌' }
    $color = if ($r.OK) { 'Green' } else { 'Red' }
    Write-Host ("  {0}  {1,-22}  {2}" -f $icon, $r.Name, $r.Detail) -ForegroundColor $color
}

Write-Host ""
if ($Failed) {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "All tests PASSED" -ForegroundColor Green
exit 0
