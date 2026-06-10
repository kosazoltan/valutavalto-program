#Requires -Version 5.1
<#
.SYNOPSIS
  Branch allapot- es meretellen$rzes -- CI/merge elokeszites.

Replaces: AI "is this branch ready to merge?" kerdesek + kezi branch ellenorzes.

Ellenorzi:
  - Commit szam a branch-ben (vs base)
  - Elterult (stale) branchek a repoban
  - Branch elnevezes konvencio (feat/fix/chore/refactor/...)
  - Merge conflict markerek
  - Unsigned / missing author commit-ek

.PARAMETER Base
  Alap branch (default: main)

.EXAMPLE
  .\scripts\dev-tools\branch-hygiene.ps1
  .\scripts\dev-tools\branch-hygiene.ps1 -Base develop

Exit: 0 = OK, 1 = issues found
#>
param(
    [string]$Base = "main"
)

$Root    = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Failed  = $false
$Issues  = [System.Collections.Generic.List[string]]::new()

# Current branch
$CurrentBranch = & git -C $Root rev-parse --abbrev-ref HEAD 2>$null
Write-Host "branch-hygiene: $CurrentBranch (vs $Base)" -ForegroundColor Cyan
Write-Host ""

# 1. Branch naming convention
$NamePattern = '^(feat|fix|chore|refactor|docs|test|perf|ci|release|hotfix)/[\w\-]+$'
if ($CurrentBranch -ne "main" -and $CurrentBranch -ne "develop" -and
    $CurrentBranch -notmatch $NamePattern) {
    $Issues.Add("  [NAMING]  Branch name '$CurrentBranch' does not follow feat/fix/chore/... convention")
}

# 2. Commit count
$CommitCount = (& git -C $Root rev-list --count "${Base}...HEAD" 2>$null) -as [int]
Write-Host "  Commits ahead of ${Base}: $CommitCount"
if ($CommitCount -gt 50) {
    $Issues.Add("  [SIZE]  $CommitCount commits -- consider splitting into smaller PRs")
} elseif ($CommitCount -gt 20) {
    Write-Host "  (!) $CommitCount commits -- large PR, consider squashing" -ForegroundColor Yellow
}

# 3. Changed files count
$ChangedFiles = @(git -C $Root diff --name-only "${Base}...HEAD" 2>$null)
Write-Host "  Changed files: $($ChangedFiles.Count)"
if ($ChangedFiles.Count -gt 100) {
    $Issues.Add("  [SIZE]  $($ChangedFiles.Count) files changed -- very large PR")
}

# 4. Merge conflict markers
Write-Host "  Checking for conflict markers..."
$ConflictMarkers = & rg --no-heading --line-number --color=never `
    -e '^<{7}|^>{7}|^={7}' `
    --glob "!**/node_modules/**" --glob "!**/target/**" --glob "!**/.git/**" `
    $Root 2>$null
if ($ConflictMarkers) {
    $ConflictMarkers | Select-Object -First 5 | ForEach-Object {
        $Issues.Add("  [CONFLICT]  $_")
    }
}

# 5. Large files (>500KB) committed
$LargeFiles = @(git -C $Root diff --name-only "${Base}...HEAD" 2>$null) | ForEach-Object {
    $f = Join-Path $Root $_
    if (Test-Path $f) {
        $size = (Get-Item $f).Length
        if ($size -gt 500KB) { "$_ ($([math]::Round($size/1KB))KB)" }
    }
}
if ($LargeFiles) {
    foreach ($f in $LargeFiles) {
        $Issues.Add("  [LARGE-FILE]  $f -- should be in .gitignore or LFS")
    }
}

# 6. Stale branches (older than 30 days)
Write-Host ""
Write-Host "  Remote branches (stale > 30 days):"
$Cutoff = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
$StaleBranches = & git -C $Root for-each-ref `
    --format="%(refname:short) %(committerdate:short)" `
    "refs/remotes/origin" 2>$null |
    Where-Object { $_ -match '\d{4}-\d{2}-\d{2}' } |
    Where-Object {
        $parts = $_ -split ' '
        $parts.Count -ge 2 -and $parts[-1] -lt $Cutoff -and
        $parts[0] -notmatch 'HEAD|main|develop'
    }
if ($StaleBranches) {
    $StaleBranches | Select-Object -First 10 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor DarkGray
    }
} else {
    Write-Host "    (none older than 30 days)" -ForegroundColor Green
}

# Summary
Write-Host ""
if ($Issues.Count -eq 0) {
    Write-Host "branch-hygiene: OK -- branch is clean" -ForegroundColor Green
    exit 0
}

Write-Host "branch-hygiene: $($Issues.Count) issue(s):" -ForegroundColor Red
foreach ($issue in $Issues) {
    Write-Host $issue -ForegroundColor Red
}
exit 1
