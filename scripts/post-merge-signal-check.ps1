<#
.SYNOPSIS
    Post-merge AI review signal-check, 15-perces iterativ polling.

.DESCRIPTION
    A 2026-04-24 protokoll-violation utan (3 kumulalt mulasztas) kotelezo
    script. A Sourcery es Codex tipusu bot-ok reszletes review-t 5-25 perccel
    a commit utan is kuldhetnek (high-level suggestions, reviewers-guide,
    kesoi inline comments). A 90s wait NEM elegseges.

    Ez a script egy adott PR-re 15 percig figyel, 2 percenkent polling-gol,
    listaz minden Sourcery + Codex reviewot es inline commentet.

.PARAMETER PR
    PR szam (kotelezo)

.PARAMETER MaxMinutes
    Max polling ido percben (default: 15)

.PARAMETER Interval
    Polling interval masodpercben (default: 120)

.EXAMPLE
    pwsh scripts/post-merge-signal-check.ps1 -PR 187
    pwsh scripts/post-merge-signal-check.ps1 -PR 190 -MaxMinutes 20
#>

param(
    [Parameter(Mandatory = $true)]
    [int]$PR,
    [int]$MaxMinutes = 15,
    [int]$MinMinutes = 15,   # PR #193 Sourcery: NEM lepheto at. A Sourcery high-level feedback 10-15 perccel merge utan erkezik.
    [int]$Interval = 120
)

$ErrorActionPreference = 'Stop'

$repoSlug = (gh repo view --json nameWithOwner -q '.nameWithOwner').Trim()
if (-not $repoSlug) {
    throw 'gh repo view failed - gh auth + repo init needed'
}

Write-Host ""
Write-Host "=== Post-merge signal-check PR #$PR ($repoSlug) ===" -ForegroundColor Cyan
Write-Host "Polling: minden $Interval mp, max $MaxMinutes perc"
Write-Host ""

$deadline = (Get-Date).AddMinutes($MaxMinutes)
$iteration = 0
$lastReviewCount = 0
$lastCommentCount = 0
$stableIterations = 0
$STABILITY_THRESHOLD = 3  # 3 no-change iter (6 min), de csak MinMinutes UTAN hasznalhato

while ((Get-Date) -lt $deadline) {
    $iteration++
    $elapsed = [math]::Round(((Get-Date) - ($deadline.AddMinutes(-$MaxMinutes))).TotalMinutes, 1)

    # Paginated lekerdezes
    $reviews = gh api --paginate "repos/$repoSlug/pulls/$PR/reviews" --jq '.[] | select((.user.login | ascii_downcase | contains("sourcery")) or (.user.login | ascii_downcase | contains("codex"))) | {user:.user.login, state, body}' 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue -Depth 5
    $comments = gh api --paginate "repos/$repoSlug/pulls/$PR/comments" --jq '.[] | select((.user.login | ascii_downcase | contains("sourcery")) or (.user.login | ascii_downcase | contains("codex"))) | {user:.user.login, path, line, body}' 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue -Depth 5

    $reviewCount = if ($reviews) { (@($reviews)).Count } else { 0 }
    $commentCount = if ($comments) { (@($comments)).Count } else { 0 }

    $delta = "reviews=$reviewCount comments=$commentCount"
    if ($reviewCount -eq $lastReviewCount -and $commentCount -eq $lastCommentCount) {
        $stableIterations++
        Write-Host "[+$elapsed min] $delta (stable $stableIterations/$STABILITY_THRESHOLD)"
    } else {
        $stableIterations = 0
        Write-Host "[+$elapsed min] $delta (valtozott)" -ForegroundColor Yellow
    }

    $lastReviewCount = $reviewCount
    $lastCommentCount = $commentCount

    # PR #193 CRITICAL FIX: stability detection csak MinMinutes UTAN engedheto
    # (Sourcery high-level review 15 perccel merge utan is jon, early-exit = finding-miss)
    $elapsedNow = ((Get-Date) - ($deadline.AddMinutes(-$MaxMinutes))).TotalMinutes
    if ($stableIterations -ge $STABILITY_THRESHOLD -and $elapsedNow -ge $MinMinutes) {
        Write-Host ""
        Write-Host "=== Stable (>= $STABILITY_THRESHOLD iter no-change) es elapsed >= $MinMinutes min, kilepes ===" -ForegroundColor Green
        break
    }

    if ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds $Interval
    }
}

Write-Host ""
Write-Host "=== FINAL REPORT PR #$PR ===" -ForegroundColor Cyan
Write-Host "Reviews: $lastReviewCount"
if ($reviews) {
    foreach ($r in @($reviews)) {
        $bodyShort = if ($r.body.Length -gt 200) { $r.body.Substring(0, 200) + '...' } else { $r.body }
        Write-Host ""
        Write-Host "  [$($r.user) / $($r.state)]" -ForegroundColor Yellow
        Write-Host "  $bodyShort"
    }
}
Write-Host ""
Write-Host "Inline comments: $lastCommentCount"
if ($comments) {
    foreach ($c in @($comments)) {
        $bodyShort = if ($c.body.Length -gt 200) { $c.body.Substring(0, 200) + '...' } else { $c.body }
        Write-Host ""
        Write-Host "  [$($c.user)] $($c.path):$($c.line)" -ForegroundColor Yellow
        Write-Host "  $bodyShort"
    }
}

Write-Host ""
if ($lastReviewCount -eq 0 -and $lastCommentCount -eq 0) {
    Write-Host "[OK] Nincs AI review finding - PR tiszta." -ForegroundColor Green
    exit 0
} else {
    Write-Host "[ACTION] $lastReviewCount review + $lastCommentCount inline, manualis osszegzes szukseges." -ForegroundColor Yellow
    exit 1
}