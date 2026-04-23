# GitHub Actions hardening checker - AGENTS.md #18
# Ellenorzesek a .github/workflows/*.yml fajlokon:
# 1. Top-level permissions: contents: read (vagy explicit definialva)
# 2. Third-party action SHA-pin (nem tag/branch)
# 3. pull_request_target fork checkout NINCS (kiveve security-approved)
# 4. Untrusted input env-en keresztul (nem kozvetlen run: scriptben)

param([switch]$Strict)

$ErrorActionPreference = 'Continue'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$workflowDir = Join-Path $RepoRoot ".github/workflows"
$warnings = @()
$blockers = @()

function Write-Step { param($Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }

Write-Step "GitHub Actions hardening check"

if (-not (Test-Path $workflowDir)) {
    Write-Host "  (.github/workflows nincs)" -ForegroundColor DarkGray
    exit 0
}

$workflows = Get-ChildItem -Path $workflowDir -Filter "*.yml" -File
Write-Host "  Talalhato workflows: $($workflows.Count)"

foreach ($wf in $workflows) {
    $content = Get-Content $wf.FullName -Raw
    Write-Host "`n  --- $($wf.Name) ---" -ForegroundColor Yellow

    # 1. Top-level permissions check
    if ($content -match '(?m)^permissions:' -or $content -match 'permissions:\s*\n\s*contents:') {
        Write-Host "    [OK] top-level permissions definialva" -ForegroundColor Green
    } else {
        Write-Host "    [WARN] nincs top-level permissions" -ForegroundColor Yellow
        $warnings += "$($wf.Name): nincs top-level permissions"
    }

    # 2. Third-party action SHA-pin
    $uses = [regex]::Matches($content, 'uses:\s*([^\s@]+)@([^\s]+)')
    foreach ($m in $uses) {
        $action = $m.Groups[1].Value
        $ref = $m.Groups[2].Value
        # GitHub official actions: actions/*, github/* -> tag is elfogadhato
        if ($action -match '^(actions|github)/' -or $action -match '^\./') { continue }
        # Third-party: SHA kell (40 hex karakter)
        if ($ref -notmatch '^[a-f0-9]{40}$') {
            Write-Host "    [WARN] $action@$ref NEM SHA-val van pin-elve" -ForegroundColor Yellow
            $warnings += "$($wf.Name): $action@$ref SHA-pin hianyzik"
        }
    }

    # 3. pull_request_target + checkout fork
    if ($content -match 'pull_request_target') {
        if ($content -match 'actions/checkout[\s\S]*?ref:\s*\$\{\{\s*github\.event\.pull_request\.head\.sha\s*\}\}') {
            Write-Host "    [BLOCK] pull_request_target + fork checkout!" -ForegroundColor Red
            $blockers += "$($wf.Name): pull_request_target + fork checkout TILOS"
        } else {
            Write-Host "    [WARN] pull_request_target (ellenorizd fork checkout-ot)" -ForegroundColor Yellow
            $warnings += "$($wf.Name): pull_request_target hasznalat"
        }
    }

    # 4. Untrusted input direktben run: scriptben (egyszeru minta)
    $untrustedPatterns = @(
        '\$\{\{\s*github\.event\.pull_request\.title\s*\}\}',
        '\$\{\{\s*github\.event\.pull_request\.body\s*\}\}',
        '\$\{\{\s*github\.event\.issue\.title\s*\}\}',
        '\$\{\{\s*github\.event\.issue\.body\s*\}\}',
        '\$\{\{\s*github\.event\.comment\.body\s*\}\}'
    )
    foreach ($pattern in $untrustedPatterns) {
        $runMatches = [regex]::Matches($content, "run:\s*\|[\s\S]*?$pattern")
        if ($runMatches.Count -gt 0) {
            Write-Host "    [BLOCK] untrusted input kozvetlen run: scriptben ($pattern)" -ForegroundColor Red
            $blockers += "$($wf.Name): untrusted input run: (env kell)"
        }
    }
}

Write-Step "Eredmeny"
if ($warnings.Count -gt 0) {
    Write-Host "Figyelmeztetesek ($($warnings.Count)):" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
if ($blockers.Count -eq 0) {
    Write-Host "`n[PASS] Actions hardening OK" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[BLOCK] Kritikus jelzesek:" -ForegroundColor Red
    $blockers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    if ($Strict) { exit 1 } else { exit 0 }
}
