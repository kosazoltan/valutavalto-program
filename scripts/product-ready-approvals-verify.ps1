param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-approvals'),
  [string]$EvidencePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\PRODUCT_READY_APPROVALS_TEMPLATE_2026-06-09.json'),
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
  return ($text -notmatch '(?i)(template|draft|staging-or-production|PRODUCT_READY_APPROVALS_TEMPLATE|PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE)')
}

function Test-BooleanTrue {
  param([object]$Value)
  return ($Value -is [bool] -and $Value)
}

function Test-BooleanFalse {
  param([object]$Value)
  return ($Value -is [bool] -and -not $Value)
}

try {
  $exists = Test-Path -LiteralPath $EvidencePath
  Add-Check -Name 'approvals evidence file exists' -Status ($(if ($exists) { 'PASS' } else { 'FAIL' })) `
    -Evidence $EvidencePath -Expected 'Product Ready owner approvals evidence JSON exists'

  if (-not $exists) {
    throw "Approvals evidence file is missing: $EvidencePath"
  }

  $raw = Get-Content -LiteralPath $EvidencePath -Raw
  $secretPattern = '(?i)(password|passwd|secret|api[_-]?key|token|private[_-]?key|client[_-]?secret)\s*[:=]\s*["''][^"'']{8,}["'']'
  Add-Check -Name 'approvals evidence secret pattern scan' -Status ($(if ($raw -match $secretPattern) { 'FAIL' } else { 'PASS' })) `
    -Evidence $EvidencePath -Expected 'No high-confidence secret values in approvals evidence'

  try {
    $evidence = $raw | ConvertFrom-Json
    Add-Check -Name 'approvals evidence json parse' -Status 'PASS' -Evidence $EvidencePath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'approvals evidence json parse' -Status 'FAIL' -Evidence $_.Exception.Message -Expected 'Valid JSON'
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

  $approvedAt = Get-PropertyValue $evidence 'approvedAt'
  Add-Check -Name 'approvedAt' -Status (Convert-ReviewStatus (Test-IsoDateLike $approvedAt)) `
    -Evidence "approvedAt=$approvedAt" -Expected 'ISO-like timestamp'

  $evidenceOwner = Get-PropertyValue $evidence 'evidenceOwner'
  Add-Check -Name 'evidenceOwner' -Status (Convert-ReviewStatus (Test-TextPresent $evidenceOwner)) `
    -Evidence "evidenceOwner=$evidenceOwner" -Expected 'Named evidence owner'

  $completedEvidenceRef = Get-PropertyValue $evidence 'completedEvidenceRef'
  Add-Check -Name 'completedEvidenceRef' -Status (Convert-ReviewStatus (Test-EvidenceRef $completedEvidenceRef)) `
    -Evidence "completedEvidenceRef=$completedEvidenceRef" -Expected 'Existing completed external evidence JSON path or immutable HTTPS URL'
  Add-Check -Name 'completedEvidenceRef not template/draft' -Status (Convert-ReviewStatus (Test-NotTemplateOrDraftRef $completedEvidenceRef)) `
    -Evidence "completedEvidenceRef=$completedEvidenceRef" -Expected 'Completed evidence reference, not a template/draft placeholder'
  Add-Check -Name 'completedEvidenceRef not synthetic/local' -Status (Convert-ReviewStatus (Test-NotSyntheticOrLocalText $completedEvidenceRef)) `
    -Evidence "completedEvidenceRef=$completedEvidenceRef" -Expected 'Real staging/production evidence reference, not synthetic/local/mock evidence'

  $approvals = @(Get-PropertyValue $evidence 'approvals')
  Add-Check -Name 'approvals array' -Status (Convert-ReviewStatus ($approvals.Count -gt 0)) `
    -Evidence "approvals=$($approvals.Count)" -Expected 'At least one owner approval entry'

  foreach ($role in @('productOwner', 'operationsOwner', 'complianceOwner')) {
    $approval = $approvals | Where-Object { [string](Get-PropertyValue $_ 'role') -eq $role } | Select-Object -First 1
    Add-Check -Name "approvals.$role exists" -Status (Convert-ReviewStatus ($null -ne $approval)) `
      -Evidence "role=$role" -Expected 'Required owner approval entry exists'

    if ($null -eq $approval) {
      continue
    }

    $name = Get-PropertyValue $approval 'name'
    Add-Check -Name "approvals.$role.name" -Status (Convert-ReviewStatus (Test-TextPresent $name)) `
      -Evidence "name=$name" -Expected 'Named approver'

    $approved = Get-PropertyValue $approval 'approved'
    Add-Check -Name "approvals.$role.approved" -Status (Convert-ReviewStatus (Test-BooleanTrue $approved)) `
      -Evidence "approved=$approved" -Expected 'true'

    $roleApprovedAt = Get-PropertyValue $approval 'approvedAt'
    Add-Check -Name "approvals.$role.approvedAt" -Status (Convert-ReviewStatus (Test-IsoDateLike $roleApprovedAt)) `
      -Evidence "approvedAt=$roleApprovedAt" -Expected 'ISO-like timestamp'

    $evidenceRef = Get-PropertyValue $approval 'evidenceRef'
    Add-Check -Name "approvals.$role.evidenceRef" -Status (Convert-ReviewStatus (Test-EvidenceRef $evidenceRef)) `
      -Evidence "evidenceRef=$evidenceRef" -Expected 'Existing repo/absolute path or immutable HTTPS approval artifact'
    Add-Check -Name "approvals.$role.evidenceRef not template/draft" -Status (Convert-ReviewStatus (Test-NotTemplateOrDraftRef $evidenceRef)) `
      -Evidence "evidenceRef=$evidenceRef" -Expected 'Approval artifact reference, not a template/draft placeholder'
    Add-Check -Name "approvals.$role.evidenceRef not synthetic/local" -Status (Convert-ReviewStatus (Test-NotSyntheticOrLocalText $evidenceRef)) `
      -Evidence "evidenceRef=$evidenceRef" -Expected 'Real owner approval artifact, not synthetic/local/mock evidence'
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
    Add-Check -Name 'approvals verifier exception' -Status 'FAIL' -Evidence $_.Exception.Message `
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
  requirePass = [bool]$RequirePass
  status = if ($failed -eq 0 -and $review -eq 0) { 'PASS' } elseif ($failed -eq 0) { 'REVIEW' } else { 'FAIL' }
  passed = $passed
  failed = $failed
  reviewRequired = $review
  checks = $checks
  productReadyMeaning = 'Structured Product Ready owner approvals evidence verifier. Product Ready requires PASS with zero failed and zero review checks.'
}

$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready owner approvals verification')
$lines.Add('')
$lines.Add("- Generated at: $($summary.generatedAt)")
$lines.Add("- Verifier contract version: $($summary.verifierContractVersion)")
$lines.Add("- Evidence path: $EvidencePath")
$lines.Add("- Require pass: $([bool]$RequirePass)")
$lines.Add("- Status: $($summary.status)")
$lines.Add("- Passed: $passed")
$lines.Add("- Failed: $failed")
$lines.Add("- Review required: $review")
$lines.Add('')
$lines.Add('## Checks')
$lines.Add('')
$lines.Add('| Result | Check | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($check in $checks) {
  $evidenceText = ([string]$check.evidence).Replace('|', '\|')
  $expectedText = ([string]$check.expected).Replace('|', '\|')
  $lines.Add("| $($check.status) | $($check.name) | $evidenceText | $expectedText |")
}
$lines.Add('')
$lines.Add('## Product Ready meaning')
$lines.Add('')
$lines.Add($summary.productReadyMeaning)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-approvals] status: $($summary.status)"
Write-Host "[product-ready-approvals] checks: $passed passed, $failed failed, $review review"
Write-Host "[product-ready-approvals] report: $reportPath"
Write-Host "[product-ready-approvals] summary: $summaryPath"

if ($failed -gt 0) {
  exit 1
}
exit 0
