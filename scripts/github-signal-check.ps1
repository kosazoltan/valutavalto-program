<#
.SYNOPSIS
    Opus 4.7 GitHub jelzes lekerdezesi protokoll (user-direktiva 2026-04-23+).

.DESCRIPTION
    MINDEN push utan + minden merge/deploy elott KOTELEZOEN futtatando.
    Lekerdezi:
      1. PR alapadatok + head SHA
      2. Required checks allapot
      3. Minden check-run + annotation
      4. Codex review + inline comments
      5. Sourcery review + inline comments
      6. Dependabot high/critical alert
      7. CodeQL high/critical alert (PR-hez kotve)
      8. Secret scanning + push protection allapot

    Email-bol AI review bemasolgatas MEGSZUNTETVE.

.PARAMETER PrNumber
    A PR szama (pl. 156).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/github-signal-check.ps1 156
#>
param(
    [Parameter(Mandatory=$true)][int]$PrNumber
)

$OWNER = "kosazoltan"
$REPO = "valutavalto-program"
$PR = $PrNumber.ToString()

function Write-Section { param($Msg) Write-Host "`n========== $Msg ==========" -ForegroundColor Cyan }
function Write-Warn    { param($Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }

Write-Host "Opus 4.7 GitHub signal check - PR #$PR" -ForegroundColor Magenta
Write-Host "Forras: OPUS_GITHUB_QUALITY_MANDATE.md" -ForegroundColor DarkGray

# 1. PR alapadatok
Write-Section "1. PR alapadatok + head SHA"
$prInfo = & gh pr view $PR --repo "$OWNER/$REPO" --json number,title,headRefOid,reviewDecision,mergeStateStatus,isDraft,state 2>&1 | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { Write-Warn "gh pr view FAIL"; exit 2 }
Write-Host ("  PR: " + $prInfo.title)
Write-Host ("  State: " + $prInfo.state + " | Draft: " + $prInfo.isDraft)
Write-Host ("  Review decision: " + $prInfo.reviewDecision)
Write-Host ("  Merge state: " + $prInfo.mergeStateStatus)
Write-Host ("  Head SHA: " + $prInfo.headRefOid)

$HEAD_SHA = $prInfo.headRefOid
$blockers = @()

if ($prInfo.reviewDecision -eq "CHANGES_REQUESTED") {
    $blockers += "reviewDecision=CHANGES_REQUESTED"
}

# 2. Required checks
Write-Section "2. Required checks (gh pr checks --required)"
$checks = & gh pr checks $PR --repo "$OWNER/$REPO" --required --json name,workflow,state,bucket,description,link 2>&1 | ConvertFrom-Json
if ($checks) {
    foreach ($c in $checks) {
        $color = if ($c.bucket -eq "pass") { "Green" } elseif ($c.bucket -eq "fail" -or $c.bucket -eq "cancel") { "Red" } else { "Yellow" }
        Write-Host ("  [" + $c.bucket.ToUpper() + "] " + $c.name + " (" + $c.workflow + ")") -ForegroundColor $color
        if ($c.bucket -eq "fail" -or $c.bucket -eq "cancel") {
            $blockers += "required check FAIL: $($c.name)"
        }
    }
} else { Write-Host "  (nincs required check adat)" -ForegroundColor DarkGray }

# 3. Minden check-run
Write-Section "3. Osszes check-run (commits/{head_sha}/check-runs)"
$runs = & gh api "/repos/$OWNER/$REPO/commits/$HEAD_SHA/check-runs?per_page=100" --jq '.check_runs[] | {name,status,conclusion,app:.app.name,title:.output.title,annotations_count:.output.annotations_count}' 2>&1
if ($runs) {
    $runs -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
        $r = $_ | ConvertFrom-Json
        $color = if ($r.conclusion -eq "success") { "Green" } elseif ($r.conclusion -eq "failure") { "Red" } else { "Yellow" }
        Write-Host ("  [" + $r.conclusion + "] " + $r.name + " (" + $r.app + ")") -ForegroundColor $color
        if ($r.annotations_count -and $r.annotations_count -gt 0) {
            Write-Host ("    annotations: " + $r.annotations_count) -ForegroundColor Yellow
        }
        if ($r.conclusion -eq "failure") {
            $blockers += "check-run failed: $($r.name)"
        }
    }
}

# 4. Codex review
Write-Section "4. Codex review (pulls/{pr}/reviews + comments)"
$codexReviews = & gh api "/repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" --jq '.[] | select((.user.login | ascii_downcase | contains("codex"))) | {reviewer:.user.login,state,submitted_at}' 2>&1
if ($codexReviews) {
    $codexReviews -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
        $r = $_ | ConvertFrom-Json
        Write-Host ("  [" + $r.state + "] " + $r.reviewer + " @ " + $r.submitted_at) -ForegroundColor Magenta
        if ($r.state -eq "CHANGES_REQUESTED") { $blockers += "Codex CHANGES_REQUESTED" }
    }
} else { Write-Host "  (nincs Codex review)" -ForegroundColor DarkGray }

$codexComments = & gh api "/repos/$OWNER/$REPO/pulls/$PR/comments?per_page=100" --jq '.[] | select((.user.login | ascii_downcase | contains("codex"))) | {user:.user.login,path,line,body}' 2>&1
if ($codexComments) {
    Write-Host "  INLINE COMMENTEK:" -ForegroundColor Magenta
    $codexComments -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
        $c = $_ | ConvertFrom-Json
        $snippet = if ($c.body.Length -gt 120) { $c.body.Substring(0, 120) + "..." } else { $c.body }
        Write-Host ("    " + $c.path + ":" + $c.line + " - " + $snippet) -ForegroundColor DarkMagenta
        if ($c.body -match 'P1|P0|bug_risk|Badge') { $blockers += "Codex P0/P1/bug_risk comment: $($c.path):$($c.line)" }
    }
}

# 5. Sourcery review
Write-Section "5. Sourcery review"
$sourceryReviews = & gh api "/repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" --jq '.[] | select((.user.login | ascii_downcase | contains("sourcery"))) | {reviewer:.user.login,state,submitted_at}' 2>&1
if ($sourceryReviews) {
    $sourceryReviews -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
        $r = $_ | ConvertFrom-Json
        Write-Host ("  [" + $r.state + "] " + $r.reviewer + " @ " + $r.submitted_at) -ForegroundColor Cyan
        if ($r.state -eq "CHANGES_REQUESTED") { $blockers += "Sourcery CHANGES_REQUESTED" }
    }
} else { Write-Host "  (nincs Sourcery review)" -ForegroundColor DarkGray }

$sourceryComments = & gh api "/repos/$OWNER/$REPO/pulls/$PR/comments?per_page=100" --jq '.[] | select((.user.login | ascii_downcase | contains("sourcery"))) | {user:.user.login,path,line,body}' 2>&1
if ($sourceryComments) {
    Write-Host "  INLINE COMMENTEK:" -ForegroundColor Cyan
    $sourceryComments -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
        $c = $_ | ConvertFrom-Json
        $snippet = if ($c.body.Length -gt 120) { $c.body.Substring(0, 120) + "..." } else { $c.body }
        Write-Host ("    " + $c.path + ":" + $c.line + " - " + $snippet) -ForegroundColor DarkCyan
        if ($c.body -match 'bug_risk|security|complexity') { $blockers += "Sourcery blocking comment: $($c.path):$($c.line)" }
    }
}

# 6. Dependabot
Write-Section "6. Dependabot high/critical open"
$dependabot = & gh api "/repos/$OWNER/$REPO/dependabot/alerts?state=open&severity=high,critical&per_page=100" --jq '.[] | {number,severity:.security_vulnerability.severity,package:.dependency.package.name,fixed_version:.security_vulnerability.first_patched_version.identifier}' 2>&1
if ($dependabot) {
    $dependabot -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
        $d = $_ | ConvertFrom-Json
        Write-Host ("  [" + $d.severity + "] #" + $d.number + " " + $d.package + " -> " + $d.fixed_version) -ForegroundColor Red
        $blockers += "Dependabot $($d.severity): $($d.package)"
    }
} else { Write-Host "  (nincs open high/critical Dependabot alert)" -ForegroundColor Green }

# 7. CodeQL (PR)
Write-Section "7. CodeQL/code scanning (PR #$PR)"
$codeql = & gh api "/repos/$OWNER/$REPO/code-scanning/alerts?state=open&severity=critical,high&pr=$PR&per_page=100" --jq '.[] | {number,tool:.tool.name,rule_id:.rule.id,severity:.rule.security_severity_level,path:.most_recent_instance.location.path,line:.most_recent_instance.location.start_line}' 2>&1
if ($codeql -and $codeql -notmatch "Not Found") {
    $codeql -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
        $c = $_ | ConvertFrom-Json
        Write-Host ("  [" + $c.severity + "] " + $c.tool + " " + $c.rule_id + " " + $c.path + ":" + $c.line) -ForegroundColor Red
        $blockers += "CodeQL $($c.severity): $($c.rule_id)"
    }
} else { Write-Host "  (nincs high/critical code scanning alert a PR-en)" -ForegroundColor Green }

# 8. Secret scanning
Write-Section "8. Secret scanning + push protection"
$secAnalysis = & gh api "/repos/$OWNER/$REPO" --jq '{secret_scanning:.security_and_analysis.secret_scanning.status,push_protection:.security_and_analysis.secret_scanning_push_protection.status}' 2>&1
Write-Host ("  " + $secAnalysis)

# Final decision
Write-Section "DONTES"
if ($blockers.Count -eq 0) {
    Write-Host "Minden jelzes ZOLD. Merge-ready." -ForegroundColor Green
    exit 0
} else {
    Write-Host "BLOKKOLO jelzesek:" -ForegroundColor Red
    $blockers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host "`nTILOS merge/deploy. Javitsd a jelzeseket, majd futtasd ujra." -ForegroundColor Red
    exit 1
}