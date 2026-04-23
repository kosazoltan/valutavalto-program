<#
.SYNOPSIS
    Opus 4.7 GitHub jelzes lekerdezesi protokoll (user-direktiva 2026-04-23+).

.DESCRIPTION
    MINDEN push utan + minden merge/deploy elott KOTELEZOEN futtatando.
    Email-bol AI review bemasolgatas MEGSZUNTETVE.

    Lekerdezi: PR info, required checks, osszes check-run + annotacio,
    Codex review + inline comments, Sourcery review + inline comments,
    Dependabot high/critical, CodeQL PR-hez kotott high/critical,
    secret scanning + push protection.

.PARAMETER PrNumber
    A PR szama (pl. 156).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/github-signal-check.ps1 156
#>
param(
    [Parameter(Mandatory=$true)][int]$PrNumber
)

$OWNER = "kosazoltan"
$REPO  = "valutavalto-program"
$PR    = $PrNumber.ToString()
$ErrorActionPreference = 'Continue'

function Write-Section { param($Msg) Write-Host "`n========== $Msg ==========" -ForegroundColor Cyan }

function Invoke-GhApi {
    param([string]$Path, [string]$JqFilter = '.')
    $args = @('api', $Path, '--jq', $JqFilter)
    $raw = & gh @args 2>&1
    if ($LASTEXITCODE -ne 0) { return @() }
    # --jq elotag: sor-elvalasztott JSON objektumok (nem array wrapper)
    $lines = $raw | Where-Object { $_ -is [string] -and $_.Trim().Length -gt 0 -and $_.Trim() -ne '[]' }
    $result = @()
    foreach ($line in $lines) {
        try {
            $obj = $line | ConvertFrom-Json -ErrorAction Stop
            $result += $obj
        } catch {
            # Ha a jq complex output-ot produkalt, kihagyjuk
        }
    }
    return ,$result
}

Write-Host "Opus 4.7 GitHub signal check - PR #$PR" -ForegroundColor Magenta
Write-Host "Source: OPUS_GITHUB_QUALITY_MANDATE.md (user-direktiva 2026-04-23)" -ForegroundColor DarkGray

$blockers = @()
$warnings = @()

# 1. PR alapadatok
Write-Section "1. PR alapadatok + head SHA"
$prInfoRaw = & gh pr view $PR --repo "$OWNER/$REPO" --json number,title,headRefOid,reviewDecision,mergeStateStatus,isDraft,state 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host "[ERR] gh pr view FAIL" -ForegroundColor Red; exit 2 }
$prInfo = $prInfoRaw | ConvertFrom-Json
Write-Host "  PR: $($prInfo.title)"
Write-Host "  State: $($prInfo.state) | Draft: $($prInfo.isDraft)"
Write-Host "  Review decision: $($prInfo.reviewDecision)"
Write-Host "  Merge state: $($prInfo.mergeStateStatus)"
Write-Host "  Head SHA: $($prInfo.headRefOid)"
$HEAD_SHA = $prInfo.headRefOid
if ($prInfo.reviewDecision -eq "CHANGES_REQUESTED") { $blockers += "reviewDecision=CHANGES_REQUESTED" }

# 2. Required checks
Write-Section "2. Required checks"
$checksRaw = & gh pr checks $PR --repo "$OWNER/$REPO" --required --json name,workflow,state,bucket 2>&1
if ($LASTEXITCODE -eq 0 -and $checksRaw) {
    $checks = $checksRaw | ConvertFrom-Json
    if ($checks -and $checks.Count -gt 0) {
        foreach ($c in $checks) {
            $color = if ($c.bucket -eq "pass") { "Green" } elseif ($c.bucket -eq "fail" -or $c.bucket -eq "cancel") { "Red" } else { "Yellow" }
            Write-Host "  [$($c.bucket.ToUpper())] $($c.name) ($($c.workflow))" -ForegroundColor $color
            if ($c.bucket -eq "fail" -or $c.bucket -eq "cancel") { $blockers += "required check FAIL: $($c.name)" }
            if ($c.bucket -eq "pending") { $blockers += "required check PENDING: $($c.name)" }  # Codex P1 #2
        }
    } else { Write-Host "  (nincs required check beallitva)" -ForegroundColor DarkGray }
} else { Write-Host "  (gh pr checks nem adott adatot)" -ForegroundColor DarkGray }

# 3. Osszes check-run
Write-Section "3. Osszes check-run (commits/{sha}/check-runs)"
$runs = Invoke-GhApi -Path "/repos/$OWNER/$REPO/commits/$HEAD_SHA/check-runs?per_page=100" -JqFilter '.check_runs[] | {name,status,conclusion,app:(.app.name // "unknown"),title:(.output.title // ""),annotations_count:(.output.annotations_count // 0)}'
if ($runs.Count -gt 0) {
    foreach ($r in $runs) {
        $concl = if ($r.conclusion) { $r.conclusion } else { $r.status }
        $color = if ($concl -eq "success") { "Green" } elseif ($concl -eq "failure") { "Red" } else { "Yellow" }
        Write-Host "  [$concl] $($r.name) ($($r.app))" -ForegroundColor $color
        if ($r.annotations_count -gt 0) { Write-Host "    annotations: $($r.annotations_count)" -ForegroundColor Yellow }
        if ($concl -eq "failure") { $blockers += "check-run failed: $($r.name)" }
    }
} else { Write-Host "  (nincs check-run)" -ForegroundColor DarkGray }

# 4. Codex review
Write-Section "4. Codex review"
$codexReviews = Invoke-GhApi -Path "/repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" -JqFilter '.[] | select(.user.login | ascii_downcase | contains("codex")) | {reviewer:.user.login,state,submitted_at}'
if ($codexReviews.Count -gt 0) {
    foreach ($r in $codexReviews) {
        Write-Host "  [$($r.state)] $($r.reviewer) @ $($r.submitted_at)" -ForegroundColor Magenta
        if ($r.state -eq "CHANGES_REQUESTED") { $blockers += "Codex CHANGES_REQUESTED" }
    }
} else { Write-Host "  (nincs Codex review)" -ForegroundColor DarkGray }

$codexComments = Invoke-GhApi -Path "/repos/$OWNER/$REPO/pulls/$PR/comments?per_page=100" -JqFilter '.[] | select(.user.login | ascii_downcase | contains("codex")) | {user:.user.login,path,line:(.line // 0),body:(.body[:200])}'
if ($codexComments.Count -gt 0) {
    Write-Host "  INLINE COMMENTEK:" -ForegroundColor Magenta
    foreach ($c in $codexComments) {
        $snippet = if ($c.body.Length -gt 120) { $c.body.Substring(0, 120) + "..." } else { $c.body }
        Write-Host "    $($c.path):$($c.line) - $snippet" -ForegroundColor DarkMagenta
        if ($c.body -match 'P[01]|bug_risk|Badge') { $blockers += "Codex P0/P1/bug_risk: $($c.path):$($c.line)" }
    }
}

# 5. Sourcery review
Write-Section "5. Sourcery review"
$sourceryReviews = Invoke-GhApi -Path "/repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" -JqFilter '.[] | select(.user.login | ascii_downcase | contains("sourcery")) | {reviewer:.user.login,state,submitted_at}'
if ($sourceryReviews.Count -gt 0) {
    foreach ($r in $sourceryReviews) {
        Write-Host "  [$($r.state)] $($r.reviewer) @ $($r.submitted_at)" -ForegroundColor Cyan
        if ($r.state -eq "CHANGES_REQUESTED") { $blockers += "Sourcery CHANGES_REQUESTED" }
    }
} else { Write-Host "  (nincs Sourcery review)" -ForegroundColor DarkGray }

$sourceryComments = Invoke-GhApi -Path "/repos/$OWNER/$REPO/pulls/$PR/comments?per_page=100" -JqFilter '.[] | select(.user.login | ascii_downcase | contains("sourcery")) | {user:.user.login,path,line:(.line // 0),body:(.body[:200])}'
if ($sourceryComments.Count -gt 0) {
    Write-Host "  INLINE COMMENTEK:" -ForegroundColor Cyan
    foreach ($c in $sourceryComments) {
        $snippet = if ($c.body.Length -gt 120) { $c.body.Substring(0, 120) + "..." } else { $c.body }
        Write-Host "    $($c.path):$($c.line) - $snippet" -ForegroundColor DarkCyan
        if ($c.body -match 'bug_risk|security|complexity') { $blockers += "Sourcery blocking: $($c.path):$($c.line)" }
    }
}

# 6. Dependabot
Write-Section "6. Dependabot high/critical open"
$dependabot = Invoke-GhApi -Path "/repos/$OWNER/$REPO/dependabot/alerts?state=open&severity=high,critical&per_page=100" -JqFilter '.[] | {number,severity:.security_vulnerability.severity,package:.dependency.package.name,fixed_version:(.security_vulnerability.first_patched_version.identifier // "null")}'
if ($dependabot.Count -gt 0) {
    foreach ($d in $dependabot) {
        Write-Host "  [$($d.severity)] #$($d.number) $($d.package) -> $($d.fixed_version)" -ForegroundColor Red
        $blockers += "Dependabot $($d.severity): $($d.package)"
    }
} else { Write-Host "  (nincs open high/critical Dependabot alert)" -ForegroundColor Green }

# 7. CodeQL (PR)
Write-Section "7. CodeQL/code scanning (PR #$PR)"
$codeqlRaw = & gh api "/repos/$OWNER/$REPO/code-scanning/alerts?state=open&severity=critical,high&pr=$PR&per_page=100" 2>&1
if ($LASTEXITCODE -ne 0 -or $codeqlRaw -match 'Not Found|no analysis') {
    Write-Host "  (code scanning nincs bekapcsolva vagy nincs analizis)" -ForegroundColor DarkGray
    $warnings += "CodeQL disabled / no analysis"
} else {
    try {
        $codeqlList = $codeqlRaw | ConvertFrom-Json
        if ($codeqlList -and $codeqlList.Count -gt 0) {
            foreach ($c in $codeqlList) {
                $path = $c.most_recent_instance.location.path
                $line = $c.most_recent_instance.location.start_line
                $sev = $c.rule.security_severity_level
                Write-Host "  [$sev] $($c.tool.name) $($c.rule.id) ${path}:$line" -ForegroundColor Red
                $blockers += "CodeQL ${sev}: $($c.rule.id)"
            }
        } else { Write-Host "  (nincs high/critical code scanning alert a PR-en)" -ForegroundColor Green }
    } catch { Write-Host "  (CodeQL response nem parseolhato)" -ForegroundColor DarkGray }
}

# 8. Secret scanning
Write-Section "8. Secret scanning + push protection"
$secRaw = & gh api "/repos/$OWNER/$REPO" 2>&1
if ($LASTEXITCODE -eq 0) {
    $sec = $secRaw | ConvertFrom-Json
    $ss = $sec.security_and_analysis.secret_scanning.status
    $pp = $sec.security_and_analysis.secret_scanning_push_protection.status
    Write-Host "  secret_scanning: $ss | push_protection: $pp"
    if ($ss -eq "disabled") { $warnings += "secret_scanning DISABLED a repon" }
    if ($pp -eq "disabled") { $warnings += "push_protection DISABLED a repon" }
}

# V2 addon szekciok (11-20) - source az AGENTS.md + MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md
# Ez a fajl append-elodik a github-signal-check.ps1 vegere, DONTES elott.

# 11. PR state + mergeability polling
Write-Section "11. PR state + mergeability polling (V2)"
$prDet = & gh api "/repos/$OWNER/$REPO/pulls/$PR" 2>&1
if ($LASTEXITCODE -eq 0) {
    $pd = $prDet | ConvertFrom-Json
    Write-Host "  mergeable: $($pd.mergeable) | mergeable_state: $($pd.mergeable_state)"
    if ($pd.state -ne 'open' -and -not $pd.merged) { $blockers += "PR state!=open (#11)" }
    if ($pd.draft -eq $true) { $blockers += "PR draft (#11)" }
    if ($pd.mergeable -eq $false) { $blockers += "mergeable=false (#11)" }
    if ($null -eq $pd.mergeable) { $warnings += "mergeable=null POLLING (#11)" }
}

# 12. Legacy Commit Statuses
Write-Section "12. Legacy Commit Statuses API"
$leg = & gh api "/repos/$OWNER/$REPO/commits/$HEAD_SHA/status" 2>&1
if ($LASTEXITCODE -eq 0) {
    $legacy = $leg | ConvertFrom-Json
    Write-Host "  combined state: $($legacy.state) | total: $($legacy.total_count)"
    if ($legacy.state -eq 'failure' -and $legacy.total_count -gt 0) { $blockers += "Legacy state=failure (#12)" }
    elseif ($legacy.state -eq 'pending' -and $legacy.total_count -gt 0) { $warnings += "Legacy state=pending (#12)" }
}

# 13. Workflow runs (failed detailed)
Write-Section "13. Workflow runs (failed)"
$runsRawV2 = & gh api "/repos/$OWNER/$REPO/actions/runs?head_sha=$HEAD_SHA&per_page=10" 2>&1
$failedRunsV2 = @()
if ($LASTEXITCODE -eq 0) {
    $rdV2 = $runsRawV2 | ConvertFrom-Json
    $failedRunsV2 = @($rdV2.workflow_runs | Where-Object { $_.conclusion -in @('failure','timed_out','cancelled') })
    foreach ($fr in $failedRunsV2) {
        Write-Host "  [FAILED] $($fr.name) - run #$($fr.run_number)" -ForegroundColor Red
        $blockers += "Workflow FAIL: $($fr.name) (#13)"
    }
    if ($failedRunsV2.Count -eq 0) { Write-Host "  (nincs bukott run)" -ForegroundColor Green }
}

# 14. GraphQL review threads
Write-Section "14. Review threadek (GraphQL isResolved)"
$gqlQ = 'query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100){nodes{isResolved isOutdated}}}}}'
$gqlRaw = & gh api graphql -f "query=$gqlQ" -F "owner=$OWNER" -F "repo=$REPO" -F "number=$PR" 2>&1
if ($LASTEXITCODE -eq 0) {
    try {
        $gql = $gqlRaw | ConvertFrom-Json
        $threads = $gql.data.repository.pullRequest.reviewThreads.nodes
        if ($threads) {
            $unresolved = @($threads | Where-Object { $_.isResolved -eq $false })
            Write-Host "  threads: $($threads.Count) | unresolved: $($unresolved.Count)"
            if ($unresolved.Count -gt 0) { $blockers += "$($unresolved.Count) unresolved thread (#14)" }
        } else { Write-Host "  (nincs thread)" -ForegroundColor DarkGray }
    } catch { Write-Host "  (GraphQL nem parseolhato)" -ForegroundColor DarkGray }
}

# 15. Rulesets + branch protection
Write-Section "15. Rulesets + branch protection"
$rsRaw = & gh api "/repos/$OWNER/$REPO/rulesets?includes_parents=true" 2>&1
if ($LASTEXITCODE -eq 0) {
    $rs = Invoke-GhApi -Path "/repos/$OWNER/$REPO/rulesets?includes_parents=true" -JqFilter '.[] | {name,target,enforcement}'
    foreach ($r in $rs) {
        Write-Host "  [$($r.enforcement)] $($r.name)"
        if ($r.enforcement -eq 'evaluate') { $warnings += "Ruleset enforcement=evaluate (#15)" }
    }
    if (-not $rs -or @($rs).Count -eq 0) { $warnings += "nincs ruleset (#15)" }
}
$bpRaw = & gh api "/repos/$OWNER/$REPO/branches/main/protection" 2>&1
if ($LASTEXITCODE -eq 0) {
    $bp = & gh api "/repos/$OWNER/$REPO/branches/main/protection" 2>&1 | ConvertFrom-Json
    Write-Host "  main allow_force_pushes: $($bp.allow_force_pushes.enabled)"
    if ($bp.allow_force_pushes.enabled -eq $true) { $warnings += "allow_force_pushes=true (#15)" }
}

# 16. Dependency diff + slopsquatting
Write-Section "16. Dependency diff (slopsquatting)"
$df = & gh api "/repos/$OWNER/$REPO/pulls/$PR/files?per_page=100" 2>&1
$lockfiles = @(); $manifests = @(); $filesV2 = @()
if ($LASTEXITCODE -eq 0) {
    $filesV2 = $df | ConvertFrom-Json
    $lockfiles = @($filesV2 | Where-Object { $_.filename -match '(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|Cargo\.lock|poetry\.lock|Pipfile\.lock|go\.sum)$' })
    foreach ($f in $lockfiles) {
        Write-Host "  lockfile: $($f.filename) (+$($f.additions) -$($f.deletions))" -ForegroundColor Yellow
        $warnings += "Lockfile diff audit: $($f.filename) (#16)"
    }
    if ($lockfiles.Count -eq 0) { Write-Host "  (nincs lockfile diff)" -ForegroundColor Green }
    $manifests = @($filesV2 | Where-Object { $_.filename -match '(package\.json|pom\.xml|pyproject\.toml|requirements\.txt|Cargo\.toml|go\.mod)$' })
}

# 17. Lockfile integrity
Write-Section "17. Lockfile integrity (manifest lockfile nelkul TILOS)"
if ($manifests.Count -gt 0 -and $lockfiles.Count -eq 0) {
    Write-Host "  MANIFEST lockfile nelkul!" -ForegroundColor Red
    $blockers += "Manifest lockfile nelkul TILOS (#17)"
} else { Write-Host "  (OK)" -ForegroundColor Green }

# 18. Actions hardening
Write-Section "18. Workflow hardening check"
if ($filesV2.Count -gt 0) {
    $wf = @($filesV2 | Where-Object { $_.filename -match '^\.github/workflows/.*\.ya?ml$' })
    foreach ($w in $wf) {
        Write-Host "  workflow: $($w.filename)" -ForegroundColor Yellow
        $warnings += "Workflow audit (permissions, SHA-pin): $($w.filename) (#18)"
    }
    if ($wf.Count -eq 0) { Write-Host "  (nincs workflow diff)" -ForegroundColor Green }
}

# 19. Release attestation
Write-Section "19. Release artifact attestation"
$relRaw = & gh api "/repos/$OWNER/$REPO/releases/latest" 2>&1
if ($LASTEXITCODE -eq 0) {
    $rel = $relRaw | ConvertFrom-Json
    Write-Host "  Utolso release: $($rel.tag_name)"
    Write-Host "  (gh attestation verify release-elott kotelezo)" -ForegroundColor DarkGray
} else { Write-Host "  (nincs release)" -ForegroundColor DarkGray }

# 20. Bizonyitasi minimum + Dep Review
Write-Section "20. Bizonyitasi minimum + Dep Review"
$baseRef = if ($prInfo.baseRefName) { $prInfo.baseRefName } else { 'main' }
$drvRaw = & gh api "/repos/$OWNER/$REPO/dependency-graph/compare/$baseRef...$HEAD_SHA" 2>&1
if ($LASTEXITCODE -eq 0) {
    $drv = Invoke-GhApi -Path "/repos/$OWNER/$REPO/dependency-graph/compare/$baseRef...$HEAD_SHA" -JqFilter '.[] | select(.vulnerabilities != null and (.vulnerabilities | length) > 0) | {name:.name,severity:(.vulnerabilities[0].severity),change_type:.change_type}'
    foreach ($d in $drv) {
        if ($d.severity -in @('high','critical')) { $blockers += "Dep review $($d.severity): $($d.name) (#20)" }
    }
    if ($drv.Count -eq 0) { Write-Host "  (nincs vulnerable dep)" -ForegroundColor Green }
}
$ev = [ordered]@{ model = "Claude Opus 4.7"; mandate = "V2"; timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"); pr = "#$PR ($OWNER/$REPO)"; head_sha = $HEAD_SHA; blockers = $blockers.Count; warnings = $warnings.Count }
$ev.GetEnumerator() | ForEach-Object { Write-Host ("  " + $_.Key.PadRight(12) + ": " + $_.Value) }


# Final decision
Write-Section "DONTES"
if ($warnings.Count -gt 0) {
    Write-Host "FIGYELMEZTETESEK (nem blokkolo):" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
if ($blockers.Count -eq 0) {
    Write-Host "`n[PASS] Minden jelzes ZOLD. Merge-ready." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[BLOCK] Blokkolo jelzesek:" -ForegroundColor Red
    $blockers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host "`nTILOS merge/deploy. Javitsd a jelzeseket, majd futtasd ujra." -ForegroundColor Red
    exit 1
}
