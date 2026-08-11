#Requires -Version 7.0
<#
.SYNOPSIS
  TypeScript typecheck on all 4 TS projects, parallel, terse summary.

.PARAMETER Sequential
  Run sequentially instead of in parallel.

.EXAMPLE
  .\scripts\dev-tools\typecheck-all.ps1
  .\scripts\dev-tools\typecheck-all.ps1 -Sequential

Exit: 0 = all pass, 1 = any fail
#>
param([switch]$Sequential)

$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')

$Projects = @(
    [PSCustomObject]@{ Name = 'frontend-react';         Dir = 'frontend-react'          },
    [PSCustomObject]@{ Name = 'penztar-client';          Dir = 'penztar-client'           },
    [PSCustomObject]@{ Name = 'kozponti-client';         Dir = 'kozponti-client'          }
)

Write-Host "typecheck-all — $($Projects.Count) projects" -ForegroundColor Cyan

function Run-Typecheck([string]$Name, [string]$FullDir) {
    if (-not (Test-Path $FullDir)) {
        return [PSCustomObject]@{ Name = $Name; OK = $false; Errors = 0; Sec = 0; Note = 'dir not found' }
    }
    $sw  = [System.Diagnostics.Stopwatch]::StartNew()
    $raw = & cmd /d /c "cd /d `"$FullDir`" && npm run typecheck 2>&1"
    $ok  = $LASTEXITCODE -eq 0
    $sw.Stop()
    $errCount = ($raw | Where-Object { $_ -match 'error TS\d+' }).Count
    [PSCustomObject]@{
        Name   = $Name
        OK     = $ok
        Errors = $errCount
        Sec    = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        Note   = ''
    }
}

$fullDirs = $Projects | ForEach-Object { [string](Join-Path $Root $_.Dir) }

if ($Sequential) {
    $Results = for ($i = 0; $i -lt $Projects.Count; $i++) {
        Run-Typecheck $Projects[$i].Name $fullDirs[$i]
    }
} else {
    # PS7+ ForEach-Object -Parallel; $using: brings outer vars into thread
    $Results = 0..($Projects.Count - 1) | ForEach-Object -Parallel {
        $idx  = $_
        $name = ($using:Projects)[$idx].Name
        $dir  = ($using:fullDirs)[$idx]

        if (-not (Test-Path $dir)) {
            return [PSCustomObject]@{ Name = $name; OK = $false; Errors = 0; Sec = 0; Note = 'dir not found' }
        }
        $sw  = [System.Diagnostics.Stopwatch]::StartNew()
        $raw = & cmd /d /c "cd /d `"$dir`" && npm run typecheck 2>&1"
        $ok  = $LASTEXITCODE -eq 0
        $sw.Stop()
        $errCount = ($raw | Where-Object { $_ -match 'error TS\d+' }).Count
        [PSCustomObject]@{
            Name   = $name
            OK     = $ok
            Errors = $errCount
            Sec    = [math]::Round($sw.Elapsed.TotalSeconds, 1)
            Note   = ''
        }
    } -ThrottleLimit 4
}

Write-Host ""
$anyFailed = $false
foreach ($r in $Results | Sort-Object Name) {
    if ($r.Note) {
        Write-Host ("  {0,-32} ⚠️  {1}" -f $r.Name, $r.Note) -ForegroundColor Yellow
        $anyFailed = $true
    } elseif ($r.OK) {
        Write-Host ("  {0,-32} ✅ PASS  [{1}s]" -f $r.Name, $r.Sec) -ForegroundColor Green
    } else {
        Write-Host ("  {0,-32} ❌ FAIL  [{1}s]  $($r.Errors) error(s)" -f $r.Name, $r.Sec) -ForegroundColor Red
        $anyFailed = $true
    }
}

Write-Host ""
if ($anyFailed) {
    Write-Host "TYPECHECK FAILED — run: cd <project> && npm run typecheck" -ForegroundColor Red
    exit 1
}
Write-Host "All typechecks PASSED" -ForegroundColor Green
exit 0
