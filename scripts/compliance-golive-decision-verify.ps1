param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\compliance-golive-decision'),
  [string]$DecisionPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\COMPLIANCE_GO_LIVE_DECISION_TEMPLATE_2026-06-09.json'),
  [switch]$RequireApprovedDecision
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
  param(
    [string]$Name,
    [string]$Status,
    [string]$Evidence,
    [string]$Expected
  )

  $checks.Add([pscustomobject]@{
      name = $Name
      status = $Status
      evidence = $Evidence
      expected = $Expected
    })
}

function Test-Blank {
  param([object]$Value)
  if ($null -eq $Value) { return $true }
  return "$Value".Trim().Length -eq 0
}

function Add-RequiredTextCheck {
  param(
    [object]$Decision,
    [string]$PropertyName,
    [string]$Expected
  )

  $value = $Decision.$PropertyName
  $status = if (-not (Test-Blank $value)) {
    'PASS'
  } elseif ($RequireApprovedDecision) {
    'FAIL'
  } else {
    'REVIEW'
  }
  Add-Check -Name $PropertyName -Status $status -Evidence "$PropertyName=$value" -Expected $Expected
}

function Get-NormalizedBoolString {
  param([object]$Value)
  if ($null -eq $Value) { return $null }
  $v = "$Value".Trim().ToLowerInvariant()
  if ($v -in @('true', 'false')) { return $v }
  return $null
}

$requiredFlags = @(
  'PMT_STRICT_ENFORCEMENT',
  'AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT',
  'AML_HIGH_VALUE_APPROVAL_ENFORCEMENT',
  'AML_FATF_TIER_ENFORCEMENT',
  'CIRCULAR_ACK_BLOCKING_ENFORCEMENT'
)

Add-Check -Name 'decision file exists' -Status ($(if (Test-Path -LiteralPath $DecisionPath) { 'PASS' } else { 'FAIL' })) `
  -Evidence $DecisionPath -Expected 'Decision JSON exists'

$decision = $null
if (Test-Path -LiteralPath $DecisionPath) {
  try {
    $raw = Get-Content -LiteralPath $DecisionPath -Raw
    $decision = $raw | ConvertFrom-Json
    Add-Check -Name 'decision json parse' -Status 'PASS' -Evidence $DecisionPath -Expected 'Valid JSON'

    $secretPattern = '(?i)(password|secret|token|api[_-]?key|client[_-]?secret)\s*[:=]\s*["''][A-Za-z0-9_./+=:@-]{12,}["'']'
    Add-Check -Name 'decision file secret pattern scan' -Status ($(if ($raw -match $secretPattern) { 'FAIL' } else { 'PASS' })) `
      -Evidence $DecisionPath -Expected 'No secret values stored in decision artifact'
  } catch {
    Add-Check -Name 'decision json parse' -Status 'FAIL' -Evidence $_.Exception.Message -Expected 'Valid JSON'
  }
}

if ($decision) {
  $status = if ($decision.decisionStatus -eq 'APPROVED') {
    'PASS'
  } elseif ($RequireApprovedDecision) {
    'FAIL'
  } else {
    'REVIEW'
  }
  Add-Check -Name 'decisionStatus' -Status $status -Evidence "decisionStatus=$($decision.decisionStatus)" -Expected 'APPROVED'

  $environment = "$($decision.environment)"
  $environmentOk = $environment -in @('staging', 'production')
  Add-Check -Name 'environment' -Status ($(if ($environmentOk) { 'PASS' } elseif ($RequireApprovedDecision) { 'FAIL' } else { 'REVIEW' })) `
    -Evidence "environment=$environment" -Expected 'staging or production'

  $decidedAtOk = $false
  if (-not (Test-Blank $decision.decidedAt)) {
    try {
      [datetimeoffset]::Parse("$($decision.decidedAt)") | Out-Null
      $decidedAtOk = $true
    } catch {
      $decidedAtOk = $false
    }
  }
  Add-Check -Name 'decidedAt' -Status ($(if ($decidedAtOk) { 'PASS' } elseif ($RequireApprovedDecision) { 'FAIL' } else { 'REVIEW' })) `
    -Evidence "decidedAt=$($decision.decidedAt)" -Expected 'ISO-like timestamp required for approved decision'
  Add-RequiredTextCheck -Decision $decision -PropertyName 'decidedBy' -Expected 'Decision owner is recorded'
  Add-RequiredTextCheck -Decision $decision -PropertyName 'approvedByCompliance' -Expected 'Compliance approver is recorded'

  $flagMap = @{}
  if ($decision.flags -is [array]) {
    foreach ($flag in $decision.flags) {
      if (-not (Test-Blank $flag.key)) {
        $flagMap["$($flag.key)"] = $flag
      }
    }
  }
  Add-Check -Name 'flags array' -Status ($(if ($decision.flags -is [array]) { 'PASS' } else { 'FAIL' })) `
    -Evidence "flagsCount=$(if ($decision.flags -is [array]) { $decision.flags.Count } else { 0 })" -Expected 'Decision contains flags array'

  foreach ($requiredFlag in $requiredFlags) {
    if (-not $flagMap.ContainsKey($requiredFlag)) {
      Add-Check -Name "flag:$requiredFlag exists" -Status 'FAIL' -Evidence 'missing' -Expected 'Required compliance go-live flag is listed'
      continue
    }

    $flag = $flagMap[$requiredFlag]
    Add-Check -Name "flag:$requiredFlag exists" -Status 'PASS' -Evidence $requiredFlag -Expected 'Required compliance go-live flag is listed'

    $approvedValue = Get-NormalizedBoolString $flag.approvedValue
    $approvedStatus = if ($approvedValue) {
      'PASS'
    } elseif ($RequireApprovedDecision) {
      'FAIL'
    } else {
      'REVIEW'
    }
    Add-Check -Name "flag:$requiredFlag approvedValue" -Status $approvedStatus `
      -Evidence "approvedValue=$($flag.approvedValue)" -Expected 'true or false, no null, before Product Ready claim'

    $rationaleStatus = if (-not (Test-Blank $flag.rationale)) {
      'PASS'
    } elseif ($RequireApprovedDecision) {
      'FAIL'
    } else {
      'REVIEW'
    }
    Add-Check -Name "flag:$requiredFlag rationale" -Status $rationaleStatus `
      -Evidence "rationale=$($flag.rationale)" -Expected 'Rationale is recorded'
  }
}

$failed = @($checks | Where-Object { $_.status -eq 'FAIL' })
$review = @($checks | Where-Object { $_.status -eq 'REVIEW' })
$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  decisionPath = $DecisionPath
  requireApprovedDecision = [bool]$RequireApprovedDecision
  passed = $passed
  failed = $failed.Count
  reviewRequired = $review.Count
  checks = $checks
  productReadyMeaning = if ($RequireApprovedDecision) {
    'Approved compliance go-live decision gate. Product Ready requires zero FAIL.'
  } else {
    'Preflight decision-shape check. DRAFT/REVIEW findings must be resolved before Product Ready claim.'
  }
}

$summaryPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Compliance go-live decision verification')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Decision path: $DecisionPath")
$lines.Add("- Require approved decision: $([bool]$RequireApprovedDecision)")
$lines.Add("- Checks: $passed passed, $($failed.Count) failed, $($review.Count) review")
$lines.Add('')
$lines.Add('## Checks')
$lines.Add('')
$lines.Add('| Check | Status | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($check in $checks) {
  $evidence = ($check.evidence -replace '\|', '/')
  $expected = ($check.expected -replace '\|', '/')
  $lines.Add("| $($check.name) | $($check.status) | $evidence | $expected |")
}
$lines.Add('')
$lines.Add('## Product Ready Meaning')
$lines.Add('')
$lines.Add($summary.productReadyMeaning)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[compliance-golive-decision] checks: $passed passed, $($failed.Count) failed, $($review.Count) review"
Write-Host "[compliance-golive-decision] report: $reportPath"
Write-Host "[compliance-golive-decision] summary: $summaryPath"

if ($failed.Count -gt 0) {
  exit 1
}
exit 0
