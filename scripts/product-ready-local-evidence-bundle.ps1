param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-local-evidence-bundle'),
  [string]$RequiredLocalGateSummaryPath = $env:PRODUCT_READY_LOCAL_GATE_SUMMARY_PATH
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()
$artifacts = [System.Collections.Generic.List[object]]::new()
$secretPattern = '(?i)(password|passwd|secret|api[_-]?key|token|private[_-]?key|client[_-]?secret)\s*[:=]\s*["''][^"'']{8,}["'']'

function Add-Check {
  param(
    [string]$Name,
    [bool]$Passed,
    [string]$Evidence,
    [string]$Expected
  )

  $checks.Add([pscustomobject]@{
      name = $Name
      passed = $Passed
      evidence = $Evidence
      expected = $Expected
    })
}

function Get-LatestReportDirectory {
  param(
    [string]$RelativeDirectory,
    [string]$RequiredSummaryProperty,
    [object]$RequiredSummaryValue,
    [switch]$RequireZeroFailed
  )

  $fullDirectory = Join-Path $WorkspaceRoot $RelativeDirectory
  if (-not (Test-Path -LiteralPath $fullDirectory)) {
    return $null
  }

  $directories = Get-ChildItem -LiteralPath $fullDirectory -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $reportPath = Join-Path $directory.FullName 'report.md'
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    if (-not ((Test-Path -LiteralPath $reportPath) -and (Test-Path -LiteralPath $summaryPath))) {
      continue
    }

    try {
      $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    } catch {
      continue
    }

    if ($RequireZeroFailed) {
      $failedValue = $summary.PSObject.Properties['failed']
      if ($null -eq $failedValue -or [int]$failedValue.Value -ne 0) {
        continue
      }
    }

    if (-not [string]::IsNullOrWhiteSpace($RequiredSummaryProperty)) {
      $property = $summary.PSObject.Properties[$RequiredSummaryProperty]
      if ($null -eq $property -or $property.Value -ne $RequiredSummaryValue) {
        continue
      }
    }

    return $directory
  }

  return $null
}

function Convert-ToRelativePath {
  param([string]$Path)

  $root = [System.IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('\', '/')
  $full = [System.IO.Path]::GetFullPath($Path)
  if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
  }
  return $full
}

function Resolve-WorkspacePath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return $null
  }

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $Path))
}

function Get-ObjectProperty {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }

  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function Get-Sha256 {
  param([string]$Path)

  $stream = [System.IO.File]::OpenRead($Path)
  try {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
      $hashBytes = $sha256.ComputeHash($stream)
      return ([System.BitConverter]::ToString($hashBytes)).Replace('-', '').ToUpperInvariant()
    } finally {
      $sha256.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

function Add-ReportArtifact {
  param(
    [string]$Area,
    [string]$RelativeDirectory,
    [bool]$Required = $true,
    [string]$RequiredSummaryProperty = '',
    [object]$RequiredSummaryValue = $null,
    [switch]$RequireZeroFailed
  )

  $latest = Get-LatestReportDirectory -RelativeDirectory $RelativeDirectory `
    -RequiredSummaryProperty $RequiredSummaryProperty `
    -RequiredSummaryValue $RequiredSummaryValue `
    -RequireZeroFailed:$RequireZeroFailed
  $directoryExists = $null -ne $latest
  Add-Check -Name "$Area latest directory" -Passed ($directoryExists -or -not $Required) `
    -Evidence $RelativeDirectory -Expected 'Latest complete report directory exists'

  if (-not $directoryExists) {
    return
  }

  $reportPath = Join-Path $latest.FullName 'report.md'
  $summaryPath = Join-Path $latest.FullName 'summary.json'
  $reportExists = Test-Path -LiteralPath $reportPath
  $summaryExists = Test-Path -LiteralPath $summaryPath

  Add-Check -Name "$Area report.md" -Passed $reportExists -Evidence (Convert-ToRelativePath $reportPath) `
    -Expected 'Markdown report exists'
  Add-Check -Name "$Area summary.json" -Passed $summaryExists -Evidence (Convert-ToRelativePath $summaryPath) `
    -Expected 'JSON summary exists'

  if (-not ($reportExists -and $summaryExists)) {
    return
  }

  if ($Area -eq 'product_ready_local_gate' -and -not [string]::IsNullOrWhiteSpace($RequiredLocalGateSummaryPath)) {
    $requiredSummaryFullPath = Resolve-WorkspacePath $RequiredLocalGateSummaryPath
    $actualSummaryFullPath = [System.IO.Path]::GetFullPath($summaryPath)
    $currentSummaryMatches = $actualSummaryFullPath.Equals($requiredSummaryFullPath, [System.StringComparison]::OrdinalIgnoreCase)
    Add-Check -Name 'product_ready_local_gate current summary path' -Passed $currentSummaryMatches `
      -Evidence "required=$(Convert-ToRelativePath $requiredSummaryFullPath); bundled=$(Convert-ToRelativePath $actualSummaryFullPath)" `
      -Expected 'Bundle uses the current local_product_ready_gate summary from the final gate run'
  }

  $reportText = Get-Content -LiteralPath $reportPath -Raw
  $summaryText = Get-Content -LiteralPath $summaryPath -Raw
  $secretScanPassed = ($reportText -notmatch $secretPattern -and $summaryText -notmatch $secretPattern)
  Add-Check -Name "$Area secret pattern scan" -Passed $secretScanPassed -Evidence (Convert-ToRelativePath $latest.FullName) `
    -Expected 'No high-confidence secret values in report or summary'

  try {
    $summary = $summaryText | ConvertFrom-Json
    Add-Check -Name "$Area summary json parse" -Passed $true -Evidence (Convert-ToRelativePath $summaryPath) `
      -Expected 'Valid JSON summary'
  } catch {
    Add-Check -Name "$Area summary json parse" -Passed $false -Evidence $_.Exception.Message `
      -Expected 'Valid JSON summary'
    return
  }

  $stepLogArtifacts = [System.Collections.Generic.List[object]]::new()
  if ($Area -eq 'product_ready_local_gate') {
    $steps = @(Get-ObjectProperty $summary 'steps')
    Add-Check -Name 'product_ready_local_gate steps array' -Passed ($steps.Count -gt 0) `
      -Evidence "steps=$($steps.Count)" -Expected 'Local gate summary contains executed steps'

    $requiredStepNames = @(
      'flyway_validate',
      'flyway_content_audit',
      'typecheck',
      'acceptance_local',
      'acceptance_coverage',
      'staging_acceptance_preflight',
      'approvals_preflight',
      'compliance_flags',
      'compliance_golive_preflight',
      'compliance_golive_decision_preflight',
      'compliance_golive_synthetic',
      'audit_hash_chain_test',
      'audit_hash_chain_preflight',
      'security_gate',
      'installer_smoke_preflight',
      'installer_clean_vm_preflight',
      'dr_restore_preflight',
      'dr_restore_synthetic',
      'monitoring_preflight',
      'monitoring_synthetic',
      'monitoring_evidence_preflight',
      'product_ready_evidence_preflight',
      'product_ready_external_evidence_preflight'
    )

    $hasInstallerArtifactsStep = [bool]($steps | Where-Object { [string](Get-ObjectProperty $_ 'name') -eq 'installer_smoke_artifacts' } | Select-Object -First 1)
    if ($hasInstallerArtifactsStep) {
      $requiredStepNames += 'installer_smoke_artifacts'
    } else {
      $requiredStepNames += 'installer_smoke_synthetic'
    }

    foreach ($requiredStepName in $requiredStepNames) {
      $step = $steps | Where-Object { [string](Get-ObjectProperty $_ 'name') -eq $requiredStepName } | Select-Object -First 1
      Add-Check -Name "product_ready_local_gate step:$requiredStepName present" -Passed ($null -ne $step) `
        -Evidence $requiredStepName -Expected 'Required local gate step is present'

      if ($null -eq $step) {
        continue
      }

      $stepPassed = (Get-ObjectProperty $step 'passed') -eq $true
      Add-Check -Name "product_ready_local_gate step:$requiredStepName passed" -Passed $stepPassed `
        -Evidence "exitCode=$(Get-ObjectProperty $step 'exitCode')" -Expected 'Required local gate step passed'

      $logPath = [string](Get-ObjectProperty $step 'log')
      $logExists = (-not [string]::IsNullOrWhiteSpace($logPath) -and (Test-Path -LiteralPath $logPath))
      Add-Check -Name "product_ready_local_gate step:$requiredStepName log" -Passed $logExists `
        -Evidence $logPath -Expected 'Required local gate step log exists'

      if ($logExists) {
        $stepLogArtifacts.Add([pscustomobject]@{
            name = $requiredStepName
            command = Get-ObjectProperty $step 'command'
            exitCode = Get-ObjectProperty $step 'exitCode'
            log = Convert-ToRelativePath $logPath
            logSha256 = Get-Sha256 -Path $logPath
          })
      }
    }
  }

  $artifacts.Add([pscustomobject]@{
      area = $Area
      directory = Convert-ToRelativePath $latest.FullName
      report = Convert-ToRelativePath $reportPath
      reportSha256 = Get-Sha256 -Path $reportPath
      summary = Convert-ToRelativePath $summaryPath
      summarySha256 = Get-Sha256 -Path $summaryPath
      generatedAt = $summary.generatedAt
      passed = $summary.passed
      failed = $summary.failed
      reviewRequired = $summary.reviewRequired
      verdict = $summary.verdict
      productReadyMeaning = $summary.productReadyMeaning
      stepLogs = $stepLogArtifacts
    })
}

$requiredReports = @(
  @{ Area = 'product_ready_local_gate'; Directory = 'security-reports\product-ready-local-gate'; RequireZeroFailed = $true },
  @{ Area = 'product_ready_evidence_preflight'; Directory = 'security-reports\product-ready-evidence'; RequireZeroFailed = $true },
  @{ Area = 'product_ready_acceptance_coverage'; Directory = 'security-reports\product-ready-acceptance-coverage'; RequireZeroFailed = $true },
  @{ Area = 'product_ready_staging_acceptance_preflight'; Directory = 'security-reports\product-ready-staging-acceptance'; RequireZeroFailed = $true },
  @{ Area = 'product_ready_approvals_preflight'; Directory = 'security-reports\product-ready-approvals'; RequireZeroFailed = $true },
  @{ Area = 'product_ready_external_evidence_preflight'; Directory = 'security-reports\product-ready-external-evidence'; RequiredSummaryProperty = 'requireComplete'; RequiredSummaryValue = $false; RequireZeroFailed = $true },
  @{ Area = 'compliance_golive_preflight'; Directory = 'security-reports\compliance-golive'; RequireZeroFailed = $true },
  @{ Area = 'compliance_golive_decision_preflight'; Directory = 'security-reports\compliance-golive-decision'; RequiredSummaryProperty = 'requireApprovedDecision'; RequiredSummaryValue = $false; RequireZeroFailed = $true },
  @{ Area = 'audit_hash_chain_preflight'; Directory = 'security-reports\audit-hash-chain'; RequireZeroFailed = $true },
  @{ Area = 'dr_restore_drill'; Directory = 'security-reports\dr-restore-drills'; RequireZeroFailed = $true },
  @{ Area = 'monitoring_preflight'; Directory = 'security-reports\monitoring-preflight'; RequireZeroFailed = $true },
  @{ Area = 'product_ready_monitoring_evidence_preflight'; Directory = 'security-reports\product-ready-monitoring-evidence'; RequireZeroFailed = $true },
  @{ Area = 'installer_smoke'; Directory = 'security-reports\installer-smoke'; RequireZeroFailed = $true },
  @{ Area = 'installer_clean_vm_smoke'; Directory = 'security-reports\installer-clean-vm-smoke'; RequireZeroFailed = $true }
)

foreach ($report in $requiredReports) {
  Add-ReportArtifact -Area $report.Area `
    -RelativeDirectory $report.Directory `
    -RequiredSummaryProperty $report.RequiredSummaryProperty `
    -RequiredSummaryValue $report.RequiredSummaryValue `
    -RequireZeroFailed:([bool]$report.RequireZeroFailed)
}

$failed = @($checks | Where-Object { -not $_.passed })
$passedCount = @($checks | Where-Object { $_.passed }).Count
$failedCount = $failed.Count

$bundle = [pscustomobject]@{
  schemaVersion = 1
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  status = if ($failedCount -eq 0) { 'LOCAL_EVIDENCE_BUNDLE_READY' } else { 'LOCAL_EVIDENCE_BUNDLE_INCOMPLETE' }
  passed = $passedCount
  failed = $failedCount
  artifacts = $artifacts
  checks = $checks
  productReadyMeaning = 'Local handoff bundle for Product Ready evidence collection. This is not final Product Ready proof without complete external evidence.'
}

$bundlePath = Join-Path $runDir 'bundle.json'
$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$bundle | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $bundlePath -Encoding UTF8
$bundle | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready local evidence bundle')
$lines.Add('')
$lines.Add("- Generated at: $($bundle.generatedAt)")
$lines.Add("- Status: $($bundle.status)")
$lines.Add("- Passed: $passedCount")
$lines.Add("- Failed: $failedCount")
$lines.Add("- Bundle JSON: $(Convert-ToRelativePath $bundlePath)")
$lines.Add('')
$lines.Add('## Artifacts')
$lines.Add('')
$lines.Add('| Area | Report | Report SHA-256 | Summary | Summary SHA-256 |')
$lines.Add('| --- | --- | --- | --- | --- |')
foreach ($artifact in $artifacts) {
  $lines.Add("| $($artifact.area) | $($artifact.report) | $($artifact.reportSha256) | $($artifact.summary) | $($artifact.summarySha256) |")
}
$lines.Add('')
$lines.Add('## Checks')
$lines.Add('')
$lines.Add('| Result | Check | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($check in $checks) {
  $result = if ($check.passed) { 'PASS' } else { 'FAIL' }
  $evidenceText = ([string]$check.evidence).Replace('|', '\|')
  $expectedText = ([string]$check.expected).Replace('|', '\|')
  $lines.Add("| $result | $($check.name) | $evidenceText | $expectedText |")
}
$lines.Add('')
$lines.Add('## Verdict')
$lines.Add('')
$lines.Add($bundle.productReadyMeaning)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-local-evidence-bundle] checks: $passedCount passed, $failedCount failed"
Write-Host "[product-ready-local-evidence-bundle] report: $reportPath"
Write-Host "[product-ready-local-evidence-bundle] bundle: $bundlePath"
Write-Host "[product-ready-local-evidence-bundle] summary: $summaryPath"

if ($failedCount -gt 0) {
  exit 1
}
