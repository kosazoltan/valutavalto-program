param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-staging-acceptance'),
  [string]$EvidencePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json'),
  [switch]$RequirePass
)

$ErrorActionPreference = 'Stop'
$VerifierContractVersion = '2026-06-09-evidence-ref-loopback-hardening'

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

function Convert-ReviewStatus {
  param([bool]$Passed)
  if ($Passed) { return 'PASS' }
  if ($RequirePass) { return 'FAIL' }
  return 'REVIEW'
}

function Get-PropertyValue {
  param([object]$Object, [string]$Name)
  if ($null -eq $Object) { return $null }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { return $null }
  return $property.Value
}

function Test-TextPresent {
  param([object]$Value)
  return ($null -ne $Value -and -not [string]::IsNullOrWhiteSpace([string]$Value))
}

function Test-IsoDateLike {
  param([object]$Value)
  if (-not (Test-TextPresent $Value)) { return $false }
  try {
    [datetimeoffset]::Parse([string]$Value) | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Test-EvidenceRef {
  param([object]$Value)

  if (-not (Test-TextPresent $Value)) { return $false }
  $text = [string]$Value
  if ($text -match '^https://[^/\s]+') { return $true }
  if ([System.IO.Path]::IsPathRooted($text)) { return Test-Path -LiteralPath $text }
  return Test-Path -LiteralPath (Join-Path $WorkspaceRoot $text)
}

function Test-LoopbackOrWildcardHost {
  param([string]$HostName)

  if ([string]::IsNullOrWhiteSpace($HostName)) { return $true }

  $normalizedHost = $HostName.Trim().ToLowerInvariant().Trim('[', ']')
  if ($normalizedHost -eq 'localhost') { return $true }

  $ipAddress = $null
  if ([System.Net.IPAddress]::TryParse($normalizedHost, [ref]$ipAddress)) {
    if ($ipAddress.IsIPv4MappedToIPv6) {
      $ipAddress = $ipAddress.MapToIPv4()
    }

    return (
      [System.Net.IPAddress]::IsLoopback($ipAddress) -or
      $ipAddress.Equals([System.Net.IPAddress]::Any) -or
      $ipAddress.Equals([System.Net.IPAddress]::IPv6Any)
    )
  }

  return $false
}

function Test-TextContainsLoopbackOrWildcardUrl {
  param([object]$Value)

  if (-not (Test-TextPresent $Value)) { return $false }

  $text = [string]$Value
  if ($text -match '(?i)(localhost|\b127\.|::1|::ffff:127\.|0\.0\.0\.0|\[::\])') {
    return $true
  }

  foreach ($match in [regex]::Matches($text, '(?i)https?://[^\s"''<>)]+')) {
    try {
      $uri = [System.Uri]::new($match.Value)
      if (Test-LoopbackOrWildcardHost $uri.Host) { return $true }
    } catch {
      continue
    }
  }

  return $false
}

function Test-DeployedHttpUrl {
  param([object]$Value)

  if (-not (Test-TextPresent $Value)) { return $false }

  try {
    $uri = [System.Uri]::new([string]$Value)
  } catch {
    return $false
  }

  if ($uri.Scheme -notin @('http', 'https')) { return $false }

  if (Test-LoopbackOrWildcardHost $uri.Host) { return $false }

  return $true
}

function Test-NotSyntheticOrLocalText {
  param([object]$Value)

  if (-not (Test-TextPresent $Value)) { return $false }

  $text = [string]$Value
  return (
    $text -notmatch '(?i)(synthetic|mock|dummy|local-only)' -and
    -not (Test-TextContainsLoopbackOrWildcardUrl $text)
  )
}

function Test-NotTemplateOrDraftRef {
  param([object]$Value)

  if (-not (Test-TextPresent $Value)) { return $false }

  $text = [string]$Value
  return ($text -notmatch '(?i)(template|draft|staging-or-production|PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE|PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE)')
}

function Test-BooleanFalse {
  param([object]$Value)
  return ($Value -is [bool] -and -not $Value)
}

function Test-BooleanTrue {
  param([object]$Value)
  return ($Value -is [bool] -and $Value)
}

try {
  $exists = Test-Path -LiteralPath $EvidencePath
  Add-Check -Name 'acceptance evidence file exists' -Status ($(if ($exists) { 'PASS' } else { 'FAIL' })) `
    -Evidence $EvidencePath -Expected 'Staging/production acceptance evidence JSON exists'

  if (-not $exists) {
    throw "Acceptance evidence file is missing: $EvidencePath"
  }

  $raw = Get-Content -LiteralPath $EvidencePath -Raw
  $secretPattern = '(?i)(password|passwd|secret|api[_-]?key|token|private[_-]?key|client[_-]?secret)\s*[:=]\s*["''][^"'']{8,}["'']'
  Add-Check -Name 'acceptance evidence secret pattern scan' -Status ($(if ($raw -match $secretPattern) { 'FAIL' } else { 'PASS' })) `
    -Evidence $EvidencePath -Expected 'No high-confidence secret values in acceptance evidence'

  try {
    $evidence = $raw | ConvertFrom-Json
    Add-Check -Name 'acceptance evidence json parse' -Status 'PASS' -Evidence $EvidencePath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'acceptance evidence json parse' -Status 'FAIL' -Evidence $_.Exception.Message -Expected 'Valid JSON'
    throw
  }

  $schemaVersion = Get-PropertyValue $evidence 'schemaVersion'
  Add-Check -Name 'schemaVersion' -Status ($(if ($schemaVersion -eq 1) { 'PASS' } else { 'FAIL' })) `
    -Evidence "schemaVersion=$schemaVersion" -Expected '1'

  $status = Get-PropertyValue $evidence 'status'
  Add-Check -Name 'status' -Status (Convert-ReviewStatus ([string]$status -eq 'PASS')) `
    -Evidence "status=$status" -Expected 'PASS'

  $environment = Get-PropertyValue $evidence 'environment'
  Add-Check -Name 'environment' -Status (Convert-ReviewStatus ($environment -in @('staging', 'production'))) `
    -Evidence "environment=$environment" -Expected 'staging or production'

  $executedAt = Get-PropertyValue $evidence 'executedAt'
  Add-Check -Name 'executedAt' -Status (Convert-ReviewStatus (Test-IsoDateLike $executedAt)) `
    -Evidence "executedAt=$executedAt" -Expected 'ISO-like timestamp'

  $operator = Get-PropertyValue $evidence 'operator'
  Add-Check -Name 'operator' -Status (Convert-ReviewStatus (Test-TextPresent $operator)) `
    -Evidence "operator=$operator" -Expected 'Named operator'

  $source = Get-PropertyValue $evidence 'source'
  Add-Check -Name 'source section exists' -Status ($(if ($null -ne $source) { 'PASS' } else { 'FAIL' })) `
    -Evidence 'source' -Expected 'Source section is present'
  if ($null -ne $source) {
    foreach ($name in @('baseUrl', 'deploymentRef', 'dataSetRef')) {
      $value = Get-PropertyValue $source $name
      Add-Check -Name "source.$name" -Status (Convert-ReviewStatus (Test-TextPresent $value)) `
        -Evidence "$name=$value" -Expected 'Non-empty staging/production source metadata'
    }

    $baseUrl = Get-PropertyValue $source 'baseUrl'
    Add-Check -Name 'source.baseUrl deployed-url' -Status (Convert-ReviewStatus (Test-DeployedHttpUrl $baseUrl)) `
      -Evidence "baseUrl=$baseUrl" -Expected 'HTTP(S) staging/production URL, not localhost/loopback'

    foreach ($name in @('deploymentRef', 'dataSetRef')) {
      $value = Get-PropertyValue $source $name
      Add-Check -Name "source.$name not synthetic/local" -Status (Convert-ReviewStatus (Test-NotSyntheticOrLocalText $value)) `
        -Evidence "$name=$value" -Expected 'Real staging/production reference, not synthetic/local/mock evidence'
    }
  }

  $summaryObject = Get-PropertyValue $evidence 'summary'
  Add-Check -Name 'summary section exists' -Status ($(if ($null -ne $summaryObject) { 'PASS' } else { 'FAIL' })) `
    -Evidence 'summary' -Expected 'Summary section is present'
  if ($null -ne $summaryObject) {
    $failed = Get-PropertyValue $summaryObject 'failed'
    $criticalFlowsPassed = Get-PropertyValue $summaryObject 'criticalFlowsPassed'
    Add-Check -Name 'summary.failed' -Status (Convert-ReviewStatus ($null -ne $failed -and [int]$failed -eq 0)) `
      -Evidence "failed=$failed" -Expected '0'
    Add-Check -Name 'summary.criticalFlowsPassed' -Status (Convert-ReviewStatus (Test-BooleanTrue $criticalFlowsPassed)) `
      -Evidence "criticalFlowsPassed=$criticalFlowsPassed" -Expected 'true'
  }

  $requiredFlows = @(Get-PropertyValue $evidence 'requiredFlows')
  $flows = @(Get-PropertyValue $evidence 'flows')
  Add-Check -Name 'flows array' -Status (Convert-ReviewStatus ($flows.Count -gt 0)) `
    -Evidence "flows=$($flows.Count)" -Expected 'At least one flow entry'

  foreach ($requiredFlow in @('buy', 'sell', 'conversion', 'transfer', 'storno', 'dayClosing', 'navCashRegister', 'receiptPrint', 'offlineSync')) {
    $declaredRequired = ($requiredFlows -contains $requiredFlow)
    Add-Check -Name "requiredFlows.$requiredFlow" -Status (Convert-ReviewStatus $declaredRequired) `
      -Evidence "declared=$declaredRequired" -Expected 'Required flow is declared'

    $flow = $flows | Where-Object { [string](Get-PropertyValue $_ 'id') -eq $requiredFlow } | Select-Object -First 1
    Add-Check -Name "flows.$requiredFlow exists" -Status (Convert-ReviewStatus ($null -ne $flow)) `
      -Evidence "flow=$requiredFlow" -Expected 'Required flow evidence exists'

    if ($null -eq $flow) {
      continue
    }

    $flowStatus = Get-PropertyValue $flow 'status'
    Add-Check -Name "flows.$requiredFlow.status" -Status (Convert-ReviewStatus ([string]$flowStatus -eq 'PASS')) `
      -Evidence "status=$flowStatus" -Expected 'PASS'

    $flowExecutedAt = Get-PropertyValue $flow 'executedAt'
    Add-Check -Name "flows.$requiredFlow.executedAt" -Status (Convert-ReviewStatus (Test-IsoDateLike $flowExecutedAt)) `
      -Evidence "executedAt=$flowExecutedAt" -Expected 'ISO-like timestamp'

    $evidenceRef = Get-PropertyValue $flow 'evidenceRef'
    Add-Check -Name "flows.$requiredFlow.evidenceRef" -Status (Convert-ReviewStatus (Test-EvidenceRef $evidenceRef)) `
      -Evidence "evidenceRef=$evidenceRef" -Expected 'Existing repo/absolute path or https URL'
    Add-Check -Name "flows.$requiredFlow.evidenceRef not template/draft" -Status (Convert-ReviewStatus (Test-NotTemplateOrDraftRef $evidenceRef)) `
      -Evidence "evidenceRef=$evidenceRef" -Expected 'Real flow evidence reference, not a template/draft placeholder'
    Add-Check -Name "flows.$requiredFlow.evidenceRef not synthetic/local" -Status (Convert-ReviewStatus (Test-NotSyntheticOrLocalText $evidenceRef)) `
      -Evidence "evidenceRef=$evidenceRef" -Expected 'Real staging/production flow artifact, not synthetic/local/mock evidence'
  }

  $safety = Get-PropertyValue $evidence 'safety'
  Add-Check -Name 'safety section exists' -Status ($(if ($null -ne $safety) { 'PASS' } else { 'FAIL' })) `
    -Evidence 'safety' -Expected 'Safety section is present'
  if ($null -ne $safety) {
    Add-Check -Name 'safety.redacted' -Status (Convert-ReviewStatus (Test-BooleanTrue (Get-PropertyValue $safety 'redacted'))) `
      -Evidence "redacted=$(Get-PropertyValue $safety 'redacted')" -Expected 'true'
    Add-Check -Name 'safety.containsSecrets' -Status (Convert-ReviewStatus (Test-BooleanFalse (Get-PropertyValue $safety 'containsSecrets'))) `
      -Evidence "containsSecrets=$(Get-PropertyValue $safety 'containsSecrets')" -Expected 'false'
    Add-Check -Name 'safety.containsCustomerPersonalData' -Status (Convert-ReviewStatus (Test-BooleanFalse (Get-PropertyValue $safety 'containsCustomerPersonalData'))) `
      -Evidence "containsCustomerPersonalData=$(Get-PropertyValue $safety 'containsCustomerPersonalData')" -Expected 'false'
  }
} catch {
  if (-not ($checks | Where-Object { $_.status -eq 'FAIL' })) {
    Add-Check -Name 'staging acceptance verifier exception' -Status 'FAIL' -Evidence $_.Exception.Message `
      -Expected 'Verifier completes without exception'
  }
}

$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$failed = @($checks | Where-Object { $_.status -eq 'FAIL' }).Count
$review = @($checks | Where-Object { $_.status -eq 'REVIEW' }).Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  verifierContractVersion = $VerifierContractVersion
  workspaceRoot = $WorkspaceRoot
  evidencePath = $EvidencePath
  status = if ($failed -eq 0 -and $review -eq 0) { 'PASS' } elseif ($failed -eq 0) { 'REVIEW' } else { 'FAIL' }
  passed = $passed
  failed = $failed
  reviewRequired = $review
  checks = $checks
  productReadyMeaning = 'Structured staging/production acceptance evidence verifier. Product Ready requires PASS with zero failed and zero review checks.'
}

$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready staging/production acceptance verification')
$lines.Add('')
$lines.Add("- Generated at: $($summary.generatedAt)")
$lines.Add("- Verifier contract version: $($summary.verifierContractVersion)")
$lines.Add("- Evidence path: $EvidencePath")
$lines.Add("- Status: $($summary.status)")
$lines.Add("- Passed: $passed")
$lines.Add("- Failed: $failed")
$lines.Add("- Review required: $review")
$lines.Add('')
$lines.Add('| Result | Check | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($check in $checks) {
  $evidenceText = ([string]$check.evidence).Replace('|', '\|')
  $expectedText = ([string]$check.expected).Replace('|', '\|')
  $lines.Add("| $($check.status) | $($check.name) | $evidenceText | $expectedText |")
}
$lines.Add('')
$lines.Add($summary.productReadyMeaning)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-staging-acceptance] checks: $passed passed, $failed failed, $review review"
Write-Host "[product-ready-staging-acceptance] report: $reportPath"
Write-Host "[product-ready-staging-acceptance] summary: $summaryPath"

if ($failed -gt 0 -or ($RequirePass -and $review -gt 0)) {
  exit 1
}
