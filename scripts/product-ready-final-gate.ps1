param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-final-gate'),
  [string]$EvidenceTemplatePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json'),
  [string]$ExternalEvidencePath = $env:PRODUCT_READY_EXTERNAL_EVIDENCE_PATH,
  [switch]$RequireComplete
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

function New-GateStep {
  param(
    [string]$Name,
    [string]$Command,
    [string]$Meaning
  )

  [pscustomobject]@{
    name = $Name
    command = $Command
    meaning = $Meaning
  }
}

function Get-SafeFileName {
  param([string]$Value)
  return ($Value -replace '[^A-Za-z0-9_.-]', '_').Trim('_')
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

function Resolve-EvidencePath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return $null
  }

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }

  return Join-Path $WorkspaceRoot $Path
}

function Get-LatestCompleteDirectory {
  param([string]$RelativeDirectory)

  $fullDirectory = Join-Path $WorkspaceRoot $RelativeDirectory
  if (-not (Test-Path -LiteralPath $fullDirectory)) {
    return $null
  }

  $directories = Get-ChildItem -LiteralPath $fullDirectory -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $reportPath = Join-Path $directory.FullName 'report.md'
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    if ((Test-Path -LiteralPath $reportPath) -and (Test-Path -LiteralPath $summaryPath)) {
      return $directory
    }
  }

  return $null
}

function Get-ExternalEvidenceSummaryForPath {
  param([string]$EvidencePath)

  if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    return $null
  }

  $expectedFullPath = [System.IO.Path]::GetFullPath($EvidencePath)
  $externalRoot = Join-Path $WorkspaceRoot 'security-reports\product-ready-external-evidence'
  if (-not (Test-Path -LiteralPath $externalRoot)) {
    return $null
  }

  $directories = Get-ChildItem -LiteralPath $externalRoot -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    $reportPath = Join-Path $directory.FullName 'report.md'
    if (-not ((Test-Path -LiteralPath $summaryPath) -and (Test-Path -LiteralPath $reportPath))) {
      continue
    }

    try {
      $externalSummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    } catch {
      continue
    }

    $summaryEvidencePath = Resolve-EvidencePath -Path ([string]$externalSummary.evidencePath)
    if ([string]::IsNullOrWhiteSpace($summaryEvidencePath)) {
      continue
    }

    $summaryFullPath = [System.IO.Path]::GetFullPath($summaryEvidencePath)
    if ($summaryFullPath.Equals($expectedFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
      return [pscustomobject]@{
        report = Convert-ToRelativePath $reportPath
        summary = Convert-ToRelativePath $summaryPath
        evidencePath = Convert-ToRelativePath $summaryFullPath
        requireComplete = [bool]$externalSummary.requireComplete
        passed = $externalSummary.passed
        failed = $externalSummary.failed
        reviewRequired = $externalSummary.reviewRequired
      }
    }
  }

  return $null
}

function Get-ExternalEvidenceSummaryFromStepLog {
  param(
    [object]$StepResult,
    [string]$EvidencePath
  )

  if ($null -eq $StepResult -or [string]::IsNullOrWhiteSpace([string]$StepResult.log)) {
    return $null
  }

  if (-not (Test-Path -LiteralPath $StepResult.log)) {
    return $null
  }

  $logText = Get-Content -LiteralPath $StepResult.log -Raw
  if ($logText -notmatch '(?m)^\[product-ready-external-evidence\] summary:\s*(.+?)\s*$') {
    return $null
  }

  $summaryPath = Resolve-EvidencePath -Path ($Matches[1].Trim())
  if ([string]::IsNullOrWhiteSpace($summaryPath) -or -not (Test-Path -LiteralPath $summaryPath)) {
    return $null
  }

  $reportPath = Join-Path (Split-Path -Parent $summaryPath) 'report.md'
  if (-not (Test-Path -LiteralPath $reportPath)) {
    return $null
  }

  try {
    $externalSummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
  } catch {
    return $null
  }

  $expectedEvidencePath = Resolve-EvidencePath -Path $EvidencePath
  $summaryEvidencePath = Resolve-EvidencePath -Path ([string]$externalSummary.evidencePath)
  if ([string]::IsNullOrWhiteSpace($expectedEvidencePath) -or [string]::IsNullOrWhiteSpace($summaryEvidencePath)) {
    return $null
  }

  $expectedFullPath = [System.IO.Path]::GetFullPath($expectedEvidencePath)
  $summaryFullPath = [System.IO.Path]::GetFullPath($summaryEvidencePath)
  if (-not $summaryFullPath.Equals($expectedFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }

  return [pscustomobject]@{
    report = Convert-ToRelativePath $reportPath
    summary = Convert-ToRelativePath $summaryPath
    evidencePath = Convert-ToRelativePath $summaryFullPath
    requireComplete = [bool]$externalSummary.requireComplete
    passed = $externalSummary.passed
    failed = $externalSummary.failed
    reviewRequired = $externalSummary.reviewRequired
    source = 'external_evidence_gate.log'
  }
}

function Get-ProductReadyLocalGateSummaryFromStepLog {
  param([object]$StepResult)

  if ($null -eq $StepResult -or [string]::IsNullOrWhiteSpace([string]$StepResult.log)) {
    return $null
  }

  if (-not (Test-Path -LiteralPath $StepResult.log)) {
    return $null
  }

  $logText = Get-Content -LiteralPath $StepResult.log -Raw
  if ($logText -notmatch '(?m)^\[product-ready-local-gate\] summary:\s*(.+?)\s*$') {
    return $null
  }

  $summaryPath = $Matches[1].Trim()
  if ([string]::IsNullOrWhiteSpace($summaryPath)) {
    return $null
  }

  $resolvedPath = Resolve-EvidencePath -Path $summaryPath
  if ([string]::IsNullOrWhiteSpace($resolvedPath) -or -not (Test-Path -LiteralPath $resolvedPath)) {
    return $null
  }

  return $resolvedPath
}

function Get-OperatorRunbookSummaryForSource {
  param([string]$SourceDirectory)

  if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
    return $null
  }

  $expectedSource = Convert-ToRelativePath $SourceDirectory
  $runbookRoot = Join-Path $WorkspaceRoot 'security-reports\product-ready-external-evidence-runbook'
  if (-not (Test-Path -LiteralPath $runbookRoot)) {
    return $null
  }

  $directories = Get-ChildItem -LiteralPath $runbookRoot -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    $reportPath = Join-Path $directory.FullName 'report.md'
    if (-not ((Test-Path -LiteralPath $summaryPath) -and (Test-Path -LiteralPath $reportPath))) {
      continue
    }

    try {
      $runbookSummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    } catch {
      continue
    }

    if ([string]$runbookSummary.sourceHandoff -eq $expectedSource) {
      return [pscustomobject]@{
        report = Convert-ToRelativePath $reportPath
        summary = Convert-ToRelativePath $summaryPath
        operatorRunbookPath = [string]$runbookSummary.operatorRunbookPath
        sourceHandoffType = [string]$runbookSummary.sourceHandoffType
        sourceHandoff = [string]$runbookSummary.sourceHandoff
        evidencePath = [string]$runbookSummary.evidencePath
        missingEvidenceJsonPath = [string]$runbookSummary.missingEvidenceJsonPath
        missing = $runbookSummary.missing
      }
    }
  }

  return $null
}

function Get-EvidenceIntakeSummaryForSource {
  param([string]$SourceDirectory)

  if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
    return $null
  }

  $expectedManifest = (Convert-ToRelativePath (Join-Path $SourceDirectory 'missing-evidence.json'))
  $intakeRoot = Join-Path $WorkspaceRoot 'security-reports\product-ready-evidence-intake'
  if (-not (Test-Path -LiteralPath $intakeRoot)) {
    return $null
  }

  $directories = Get-ChildItem -LiteralPath $intakeRoot -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    $reportPath = Join-Path $directory.FullName 'report.md'
    if (-not ((Test-Path -LiteralPath $summaryPath) -and (Test-Path -LiteralPath $reportPath))) {
      continue
    }

    try {
      $intakeSummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    } catch {
      continue
    }

    if ([string]$intakeSummary.sourceManifestPath -eq $expectedManifest) {
      return [pscustomobject]@{
        report = Convert-ToRelativePath $reportPath
        summary = Convert-ToRelativePath $summaryPath
        evidenceIntakePath = [string]$intakeSummary.evidenceIntakePath
        operatorChecklistPath = [string]$intakeSummary.operatorChecklistPath
        sourceManifestPath = [string]$intakeSummary.sourceManifestPath
        missing = $intakeSummary.missing
        sections = $intakeSummary.sections
        checks = $intakeSummary.checks
      }
    }
  }

  return $null
}

function Get-EvidenceIntakeVerifySummaryForPath {
  param([string]$IntakePath)

  if ([string]::IsNullOrWhiteSpace($IntakePath)) {
    return $null
  }

  $expectedIntakePath = Convert-ToRelativePath (Resolve-EvidencePath -Path $IntakePath)
  $verifyRoot = Join-Path $WorkspaceRoot 'security-reports\product-ready-evidence-intake-verify'
  if (-not (Test-Path -LiteralPath $verifyRoot)) {
    return $null
  }

  $directories = Get-ChildItem -LiteralPath $verifyRoot -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    $reportPath = Join-Path $directory.FullName 'report.md'
    if (-not ((Test-Path -LiteralPath $summaryPath) -and (Test-Path -LiteralPath $reportPath))) {
      continue
    }

    try {
      $verifySummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    } catch {
      continue
    }

    if ([string]$verifySummary.intakePath -eq $expectedIntakePath) {
      return [pscustomobject]@{
        report = Convert-ToRelativePath $reportPath
        summary = Convert-ToRelativePath $summaryPath
        intakePath = [string]$verifySummary.intakePath
        status = [string]$verifySummary.status
        passed = $verifySummary.passed
        failed = $verifySummary.failed
      }
    }
  }

  return $null
}

function Get-StepSummaryPathFromLog {
  param(
    [object]$StepResult,
    [string]$LogPrefix
  )

  if ($null -eq $StepResult -or [string]::IsNullOrWhiteSpace([string]$StepResult.log)) {
    return $null
  }

  if (-not (Test-Path -LiteralPath $StepResult.log)) {
    return $null
  }

  $logText = Get-Content -LiteralPath $StepResult.log -Raw
  $pattern = "(?m)^\[$([regex]::Escape($LogPrefix))\] summary:\s*(.+?)\s*$"
  if ($logText -notmatch $pattern) {
    return $null
  }

  $summaryPath = Resolve-EvidencePath -Path ($Matches[1].Trim())
  if ([string]::IsNullOrWhiteSpace($summaryPath) -or -not (Test-Path -LiteralPath $summaryPath)) {
    return $null
  }

  return $summaryPath
}

function Get-OperatorRunbookSummaryFromStepLog {
  param(
    [object]$StepResult,
    [string]$SourceDirectory
  )

  $summaryPath = Get-StepSummaryPathFromLog -StepResult $StepResult -LogPrefix 'product-ready-external-evidence-runbook'
  if ([string]::IsNullOrWhiteSpace($summaryPath)) {
    return $null
  }

  $reportPath = Join-Path (Split-Path -Parent $summaryPath) 'report.md'
  if (-not (Test-Path -LiteralPath $reportPath)) {
    return $null
  }

  try {
    $runbookSummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
  } catch {
    return $null
  }

  $expectedSource = Convert-ToRelativePath $SourceDirectory
  if ([string]$runbookSummary.sourceHandoff -ne $expectedSource) {
    return $null
  }

  return [pscustomobject]@{
    report = Convert-ToRelativePath $reportPath
    summary = Convert-ToRelativePath $summaryPath
    operatorRunbookPath = [string]$runbookSummary.operatorRunbookPath
    sourceHandoffType = [string]$runbookSummary.sourceHandoffType
    sourceHandoff = [string]$runbookSummary.sourceHandoff
    evidencePath = [string]$runbookSummary.evidencePath
    missingEvidenceJsonPath = [string]$runbookSummary.missingEvidenceJsonPath
    missing = $runbookSummary.missing
    source = 'operator_runbook.log'
  }
}

function Get-EvidenceIntakeSummaryFromStepLog {
  param(
    [object]$StepResult,
    [string]$SourceDirectory
  )

  $summaryPath = Get-StepSummaryPathFromLog -StepResult $StepResult -LogPrefix 'product-ready-evidence-intake'
  if ([string]::IsNullOrWhiteSpace($summaryPath)) {
    return $null
  }

  $reportPath = Join-Path (Split-Path -Parent $summaryPath) 'report.md'
  if (-not (Test-Path -LiteralPath $reportPath)) {
    return $null
  }

  try {
    $intakeSummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
  } catch {
    return $null
  }

  $expectedManifest = Convert-ToRelativePath (Join-Path $SourceDirectory 'missing-evidence.json')
  if ([string]$intakeSummary.sourceManifestPath -ne $expectedManifest) {
    return $null
  }

  return [pscustomobject]@{
    report = Convert-ToRelativePath $reportPath
    summary = Convert-ToRelativePath $summaryPath
    evidenceIntakePath = [string]$intakeSummary.evidenceIntakePath
    operatorChecklistPath = [string]$intakeSummary.operatorChecklistPath
    sourceManifestPath = [string]$intakeSummary.sourceManifestPath
    missing = $intakeSummary.missing
    sections = $intakeSummary.sections
    checks = $intakeSummary.checks
    source = 'evidence_intake.log'
  }
}

function Get-EvidenceIntakeVerifySummaryFromStepLog {
  param(
    [object]$StepResult,
    [string]$IntakePath
  )

  $summaryPath = Get-StepSummaryPathFromLog -StepResult $StepResult -LogPrefix 'product-ready-evidence-intake-verify'
  if ([string]::IsNullOrWhiteSpace($summaryPath)) {
    return $null
  }

  $reportPath = Join-Path (Split-Path -Parent $summaryPath) 'report.md'
  if (-not (Test-Path -LiteralPath $reportPath)) {
    return $null
  }

  try {
    $verifySummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
  } catch {
    return $null
  }

  $expectedIntakePath = Convert-ToRelativePath (Resolve-EvidencePath -Path $IntakePath)
  if ([string]$verifySummary.intakePath -ne $expectedIntakePath) {
    return $null
  }

  return [pscustomobject]@{
    report = Convert-ToRelativePath $reportPath
    summary = Convert-ToRelativePath $summaryPath
    intakePath = [string]$verifySummary.intakePath
    status = [string]$verifySummary.status
    passed = $verifySummary.passed
    failed = $verifySummary.failed
    source = 'evidence_intake_verify.log'
  }
}

function Get-SectionName {
  param([string]$CheckName)

  if ($CheckName -match '^approvals\.') { return 'approvals' }
  if ($CheckName -match '^acceptance\.') { return 'acceptance' }
  if ($CheckName -match '^compliance\.') { return 'compliance' }
  if ($CheckName -match '^drRestore\.') { return 'drRestore' }
  if ($CheckName -match '^monitoring\.') { return 'monitoring' }
  if ($CheckName -match '^installer\.') { return 'installer' }
  if ($CheckName -match '^finalDecision(?:\.| )') { return 'finalDecision' }
  if ($CheckName -match '^external evidence|^schemaVersion|^evidenceStatus|^environment|^generatedAt|^localEvidenceBundleRef|^evidenceOwner') {
    return 'topLevel'
  }
  return 'other'
}

function Get-SectionGuidance {
  param([string]$SectionName)

  $guidance = @{
    topLevel = [pscustomobject]@{
      owner = 'Release/evidence owner'
      template = 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:external-evidence:preflight')
      notes = 'Complete the top-level evidence metadata only after real staging/production evidence is attached.'
    }
    approvals = [pscustomobject]@{
      owner = 'Product owner, operations owner, compliance owner'
      template = 'docs\PRODUCT_READY_APPROVALS_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:approvals:preflight', 'npm run product-ready:approvals:complete')
      notes = 'Attach immutable owner sign-off evidence that references the completed staging/production evidence pack.'
    }
    acceptance = [pscustomobject]@{
      owner = 'Business acceptance operator'
      template = 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:staging-acceptance:preflight', 'npm run product-ready:staging-acceptance:complete')
      notes = 'Use real staging/production execution evidence for all critical flows, not local smoke evidence alone.'
    }
    compliance = [pscustomobject]@{
      owner = 'Compliance owner'
      template = 'docs\COMPLIANCE_GO_LIVE_DECISION_TEMPLATE_2026-06-09.json'
      commands = @('npm run compliance:golive:export', 'npm run compliance:golive:decision:approved')
      notes = 'Use an approved compliance decision and a staging/production parameter export from the declared environment.'
    }
    drRestore = [pscustomobject]@{
      owner = 'Operations/DB owner'
      template = 'docs\operations\dr-backup-runbook.md'
      commands = @('npm run dr:restore:preflight')
      notes = 'Run a real restore drill against an isolated scratch target and record RTO, Flyway, audit hash-chain and row-count proof.'
    }
    monitoring = [pscustomobject]@{
      owner = 'Operations/monitoring owner'
      template = 'docs\PRODUCT_READY_MONITORING_EVIDENCE_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:monitoring-evidence:preflight', 'npm run product-ready:monitoring-evidence:complete')
      notes = 'Attach deployed monitoring evidence with at least 168 observed hours and scrape/dashboard/alert proof.'
    }
    installer = [pscustomobject]@{
      owner = 'Release/desktop installer owner'
      template = 'docs\SECURITY_INSTALLER_CHECKLIST.md'
      commands = @('npm run installer:smoke:signed', 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\installer-clean-vm-smoke.ps1 -ExecuteInstall -AcceptVmMutation -ConfirmDisposableCleanVm')
      notes = 'Use signed release artifacts and disposable clean Windows VM install, launch and uninstall evidence for all three clients.'
    }
    finalDecision = [pscustomobject]@{
      owner = 'Final Product Ready decision owner'
      template = 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:final-gate:complete')
      notes = 'Approve only the completed evidence JSON after every external verifier check is PASS.'
    }
    other = [pscustomobject]@{
      owner = 'Release/evidence owner'
      template = 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:external-evidence:preflight')
      notes = 'Inspect the verifier report for this check and attach equivalent immutable staging/production evidence.'
    }
  }

  if ($guidance.ContainsKey($SectionName)) {
    return $guidance[$SectionName]
  }

  return $guidance.other
}

function New-FinalGateMissingEvidenceManifest {
  param([object]$ExternalEvidenceGateSummary)

  if ($null -eq $ExternalEvidenceGateSummary -or [string]::IsNullOrWhiteSpace([string]$ExternalEvidenceGateSummary.summary)) {
    return $null
  }

  $externalSummaryPath = Resolve-EvidencePath -Path ([string]$ExternalEvidenceGateSummary.summary)
  if (-not (Test-Path -LiteralPath $externalSummaryPath)) {
    throw "External evidence summary is missing: $externalSummaryPath"
  }

  $externalSummary = Get-Content -LiteralPath $externalSummaryPath -Raw | ConvertFrom-Json
  $finalGateEvidencePath = Resolve-EvidencePath -Path ([string]$ExternalEvidenceGateSummary.evidencePath)
  if (-not (Test-Path -LiteralPath $finalGateEvidencePath)) {
    throw "Final-gate evidence file is missing: $finalGateEvidencePath"
  }
  $finalGateEvidence = Get-Content -LiteralPath $finalGateEvidencePath -Raw | ConvertFrom-Json
  $missingChecks = @(@($externalSummary.checks) | Where-Object { [string]$_.status -ne 'PASS' })
  $missingBySection = $missingChecks | Group-Object { Get-SectionName ([string]$_.name) } | Sort-Object Name

  $missingPath = Join-Path $runDir 'missing-evidence.md'
  $missingJsonPath = Join-Path $runDir 'missing-evidence.json'
  $missingLines = [System.Collections.Generic.List[string]]::new()
  $missingLines.Add('# Product Ready final gate missing evidence')
  $missingLines.Add('')
  $missingLines.Add("- Generated: $((Get-Date).ToString('o'))")
  $missingLines.Add("- Final-gate evidence file: $($ExternalEvidenceGateSummary.evidencePath)")
  $missingLines.Add("- External evidence verifier summary: $($ExternalEvidenceGateSummary.summary)")
  $missingLines.Add("- Machine-readable missing evidence: $(Convert-ToRelativePath $missingJsonPath)")
  $missingLines.Add("- Missing checks: $($missingChecks.Count)")
  $missingLines.Add('')
  $missingLines.Add('This file is generated from the final gate scoped evidence JSON. It is an operations handoff, not Product Ready proof.')
  $missingLines.Add('')

  $missingSectionObjects = [System.Collections.Generic.List[object]]::new()
  foreach ($section in $missingBySection) {
    $guidance = Get-SectionGuidance -SectionName ([string]$section.Name)
    $missingLines.Add("## $($section.Name)")
    $missingLines.Add('')
    $missingLines.Add("- Owner: $($guidance.owner)")
    $missingLines.Add("- Source template/runbook: $($guidance.template)")
    $missingLines.Add("- Notes: $($guidance.notes)")
    $missingLines.Add('')
    $missingLines.Add('Suggested commands:')
    $missingLines.Add('')
    $missingLines.Add('```powershell')
    foreach ($command in @($guidance.commands)) {
      $missingLines.Add($command)
    }
    $missingLines.Add('```')
    $missingLines.Add('')
    $missingLines.Add('| Status | Check | Current evidence | Required evidence |')
    $missingLines.Add('| --- | --- | --- | --- |')

    $sectionChecks = [System.Collections.Generic.List[object]]::new()
    foreach ($check in $section.Group) {
      $evidenceText = ([string]$check.evidence).Replace('|', '\|')
      $expectedText = ([string]$check.expected).Replace('|', '\|')
      $missingLines.Add("| $($check.status) | $($check.name) | $evidenceText | $expectedText |")
      $sectionChecks.Add([pscustomobject]@{
          section = [string]$section.Name
          status = [string]$check.status
          name = [string]$check.name
          evidence = [string]$check.evidence
          expected = [string]$check.expected
        })
    }
    $missingLines.Add('')

    $missingSectionObjects.Add([pscustomobject]@{
        section = [string]$section.Name
        owner = $guidance.owner
        template = $guidance.template
        commands = @($guidance.commands)
        notes = $guidance.notes
        missing = $section.Group.Count
        checks = @($sectionChecks)
      })
  }

  $missingManifest = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString('o')
    workspaceRoot = $WorkspaceRoot
    finalGateEvidencePath = $ExternalEvidenceGateSummary.evidencePath
    localEvidenceBundleRef = $finalGateEvidence.localEvidenceBundleRef
    localCoverageReportRef = if ($finalGateEvidence.PSObject.Properties['acceptance']) { $finalGateEvidence.acceptance.localCoverageReportRef } else { $null }
    verifierReport = $ExternalEvidenceGateSummary.report
    verifierSummary = $ExternalEvidenceGateSummary.summary
    missingEvidencePath = Convert-ToRelativePath $missingPath
    missing = $missingChecks.Count
    sections = @($missingSectionObjects)
    finalCommand = 'npm run product-ready:final-gate:complete'
    productReadyMeaning = 'Machine-readable final-gate external evidence gap manifest. Product Ready requires zero missing checks and a passing complete final gate.'
  }

  $missingLines | Set-Content -LiteralPath $missingPath -Encoding UTF8
  $missingManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $missingJsonPath -Encoding UTF8

  return [pscustomobject]@{
    missingEvidencePath = Convert-ToRelativePath $missingPath
    missingEvidenceJsonPath = Convert-ToRelativePath $missingJsonPath
    missing = $missingChecks.Count
  }
}

function Get-LatestReadyBundle {
  $bundleRoot = Join-Path $WorkspaceRoot 'security-reports\product-ready-local-evidence-bundle'
  if (-not (Test-Path -LiteralPath $bundleRoot)) {
    throw 'No product-ready-local-evidence-bundle report directory exists.'
  }

  $directories = Get-ChildItem -LiteralPath $bundleRoot -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $bundlePath = Join-Path $directory.FullName 'bundle.json'
    if (-not (Test-Path -LiteralPath $bundlePath)) {
      continue
    }

    try {
      $bundle = Get-Content -LiteralPath $bundlePath -Raw | ConvertFrom-Json
    } catch {
      continue
    }

    if ([string]$bundle.status -eq 'LOCAL_EVIDENCE_BUNDLE_READY' -and [int]$bundle.failed -eq 0) {
      return $bundlePath
    }
  }

  throw 'No ready local evidence bundle exists.'
}

function Get-BundledAcceptanceCoverageSummary {
  param([string]$BundlePath)

  if (-not (Test-Path -LiteralPath $BundlePath)) {
    throw "Local evidence bundle is missing: $BundlePath"
  }

  $bundle = Get-Content -LiteralPath $BundlePath -Raw | ConvertFrom-Json
  $artifact = @($bundle.artifacts) |
    Where-Object { [string]$_.area -eq 'product_ready_acceptance_coverage' } |
    Select-Object -First 1

  if ($null -eq $artifact -or [string]::IsNullOrWhiteSpace([string]$artifact.summary)) {
    throw 'Local evidence bundle does not contain product_ready_acceptance_coverage summary artifact.'
  }

  $summaryPath = Resolve-EvidencePath -Path ([string]$artifact.summary)
  if (-not (Test-Path -LiteralPath $summaryPath)) {
    throw "Bundled acceptance coverage summary is missing: $summaryPath"
  }

  $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
  if ([int]$summary.failed -ne 0 -or [string]$summary.productReadyMeaning -notmatch 'Local critical-flow coverage map') {
    throw "Bundled acceptance coverage summary is not a passing local critical-flow coverage report: $summaryPath"
  }

  return $summaryPath
}

function New-FinalGateEvidenceFile {
  param(
    [string]$BundlePath,
    [string]$LocalCoverageSummaryPath,
    [string]$SourceEvidencePath
  )

  $sourcePath = Resolve-EvidencePath -Path $SourceEvidencePath
  if ([string]::IsNullOrWhiteSpace($sourcePath)) {
    $sourcePath = $EvidenceTemplatePath
  }

  if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "External evidence source is missing: $sourcePath"
  }

  $evidence = Get-Content -LiteralPath $sourcePath -Raw | ConvertFrom-Json
  $evidence.localEvidenceBundleRef = Convert-ToRelativePath $BundlePath
  if ($evidence.PSObject.Properties['acceptance']) {
    $evidence.acceptance.localCoverageReportRef = Convert-ToRelativePath $LocalCoverageSummaryPath
  }
  if (-not $evidence.generatedAt) {
    $evidence.generatedAt = (Get-Date).ToString('o')
  }

  $path = Join-Path $runDir 'external-evidence.final-gate.json'
  if ($evidence.PSObject.Properties['finalDecision']) {
    $evidence.finalDecision.externalEvidenceRef = Convert-ToRelativePath $path
  }
  $evidence | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path -Encoding UTF8
  return $path
}

function Invoke-GateStep {
  param([object]$Step)

  $safeName = Get-SafeFileName $Step.name
  $stdoutPath = Join-Path $runDir "$safeName.stdout.log"
  $stderrPath = Join-Path $runDir "$safeName.stderr.log"
  $combinedPath = Join-Path $runDir "$safeName.log"
  $startedAt = Get-Date

  Write-Host "[product-ready-final-gate] running $($Step.name): $($Step.command)"

  $process = Start-Process `
    -FilePath 'cmd.exe' `
    -ArgumentList @('/d', '/c', $Step.command) `
    -WorkingDirectory $WorkspaceRoot `
    -NoNewWindow `
    -Wait `
    -PassThru `
    -RedirectStandardOutput $stdoutPath `
    -RedirectStandardError $stderrPath

  $finishedAt = Get-Date
  $stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw } else { '' }
  $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { '' }
  @(
    "COMMAND: $($Step.command)",
    "EXIT_CODE: $($process.ExitCode)",
    "STARTED_AT: $($startedAt.ToString('o'))",
    "FINISHED_AT: $($finishedAt.ToString('o'))",
    '',
    '--- STDOUT ---',
    $stdout,
    '',
    '--- STDERR ---',
    $stderr
  ) | Set-Content -LiteralPath $combinedPath -Encoding UTF8

  $durationSeconds = [math]::Round(($finishedAt - $startedAt).TotalSeconds, 2)
  $passed = ($process.ExitCode -eq 0)
  $status = if ($passed) { 'PASS' } else { 'FAIL' }
  Write-Host "[product-ready-final-gate] $($Step.name): $status ($durationSeconds sec)"

  return [pscustomobject]@{
    name = $Step.name
    command = $Step.command
    meaning = $Step.meaning
    passed = $passed
    exitCode = $process.ExitCode
    durationSeconds = $durationSeconds
    log = $combinedPath
  }
}

function New-SkippedGateResult {
  param(
    [string]$Name,
    [string]$Command,
    [string]$Meaning,
    [string]$Reason
  )

  $safeName = Get-SafeFileName $Name
  $logPath = Join-Path $runDir "$safeName.skipped.log"
  @(
    "COMMAND: $Command",
    "EXIT_CODE: 1",
    "SKIPPED_AT: $((Get-Date).ToString('o'))",
    "REASON: $Reason"
  ) | Set-Content -LiteralPath $logPath -Encoding UTF8

  Write-Host "[product-ready-final-gate] ${Name}: SKIP ($Reason)"

  return [pscustomobject]@{
    name = $Name
    command = $Command
    meaning = $Meaning
    passed = $false
    skipped = $true
    exitCode = 1
    durationSeconds = 0
    log = $logPath
  }
}

$results = [System.Collections.Generic.List[object]]::new()

$localGateStep = New-GateStep -Name 'local_product_ready_gate' -Command 'npm run product-ready:local-gate' -Meaning 'Runs local typecheck, acceptance, compliance, audit, installer, DR, monitoring, and evidence preflight gates.'
$localGateResult = Invoke-GateStep -Step $localGateStep
$results.Add($localGateResult)

$currentLocalGateSummaryPath = Get-ProductReadyLocalGateSummaryFromStepLog -StepResult $localGateResult
$localBundleCommand = if ($currentLocalGateSummaryPath) {
  "powershell -NoProfile -ExecutionPolicy Bypass -File scripts\product-ready-local-evidence-bundle.ps1 -RequiredLocalGateSummaryPath `"$currentLocalGateSummaryPath`""
} else {
  'npm run product-ready:local-evidence-bundle'
}
$localBundleStep = New-GateStep -Name 'local_evidence_bundle' -Command $localBundleCommand -Meaning 'Builds a hash-checked local evidence handoff bundle from the current local gate and latest passing local reports.'
if ($localGateResult.passed -and $currentLocalGateSummaryPath) {
  $results.Add((Invoke-GateStep -Step $localBundleStep))
} elseif ($localGateResult.passed) {
  $results.Add((New-SkippedGateResult -Name $localBundleStep.name `
        -Command $localBundleStep.command `
        -Meaning $localBundleStep.meaning `
        -Reason 'current local_product_ready_gate summary path could not be resolved; refusing to build a bundle from ambiguous latest reports'))
} else {
  $results.Add((New-SkippedGateResult -Name $localBundleStep.name `
        -Command $localBundleStep.command `
        -Meaning $localBundleStep.meaning `
        -Reason 'current local_product_ready_gate failed; refusing to build a bundle from stale previous reports'))
}

$bundlePath = $null
$localCoverageSummaryPath = $null
$finalGateEvidencePath = $null
$sourceExternalEvidencePath = Resolve-EvidencePath -Path $ExternalEvidencePath
if (-not ($results | Where-Object { -not $_.passed })) {
  try {
    $bundlePath = Get-LatestReadyBundle
    $localCoverageSummaryPath = Get-BundledAcceptanceCoverageSummary -BundlePath $bundlePath
    $finalGateEvidencePath = New-FinalGateEvidenceFile -BundlePath $bundlePath -LocalCoverageSummaryPath $localCoverageSummaryPath -SourceEvidencePath $sourceExternalEvidencePath
    $externalCommand = "powershell -NoProfile -ExecutionPolicy Bypass -File scripts\product-ready-external-evidence-verify.ps1 -EvidencePath `"$finalGateEvidencePath`""
    if ($RequireComplete) {
      $externalCommand = "$externalCommand -RequireComplete"
    }

    $results.Add((Invoke-GateStep -Step (New-GateStep -Name 'external_evidence_gate' -Command $externalCommand -Meaning 'Verifies Product Ready external/staging/production evidence against the current local bundle.')))
  } catch {
    $errorLog = Join-Path $runDir 'external_evidence_gate.prepare.log'
    $_.Exception.Message | Set-Content -LiteralPath $errorLog -Encoding UTF8
    $results.Add([pscustomobject]@{
        name = 'external_evidence_gate'
        command = 'prepare external evidence gate input'
        meaning = 'Prepares a final-gate-scoped evidence JSON with the current local bundle and local acceptance coverage references.'
        passed = $false
        exitCode = 1
        durationSeconds = 0
        log = $errorLog
      })
  }
}

$failed = @($results | Where-Object { -not $_.passed })
$passedCount = @($results | Where-Object { $_.passed }).Count
$failedCount = $failed.Count

$latestLocalGate = Get-LatestCompleteDirectory -RelativeDirectory 'security-reports\product-ready-local-gate'
$localBundleStepPassed = [bool]($results | Where-Object { $_.name -eq 'local_evidence_bundle' -and $_.passed } | Select-Object -First 1)
$externalEvidenceStepAttempted = [bool]($results | Where-Object { $_.name -eq 'external_evidence_gate' } | Select-Object -First 1)
$externalEvidenceStepResult = $results | Where-Object { $_.name -eq 'external_evidence_gate' } | Select-Object -First 1
$latestBundle = if ($localBundleStepPassed) { Get-LatestCompleteDirectory -RelativeDirectory 'security-reports\product-ready-local-evidence-bundle' } else { $null }
$latestExternal = if ($externalEvidenceStepAttempted) { Get-LatestCompleteDirectory -RelativeDirectory 'security-reports\product-ready-external-evidence' } else { $null }
$externalEvidenceGateSummary = Get-ExternalEvidenceSummaryFromStepLog -StepResult $externalEvidenceStepResult -EvidencePath $finalGateEvidencePath
$missingEvidenceSummary = $null
$operatorRunbookSummary = $null
$evidenceIntakeSummary = $null
$evidenceIntakeVerifySummary = $null

$externalEvidenceStepPassed = [bool]($results | Where-Object { $_.name -eq 'external_evidence_gate' -and $_.passed } | Select-Object -First 1)
if ($externalEvidenceStepAttempted -and $null -eq $externalEvidenceGateSummary) {
  $summaryMissingLog = Join-Path $runDir 'external_evidence_summary_link.log'
  "No current product-ready-external-evidence summary found in external_evidence_gate.log for final gate evidence path: $finalGateEvidencePath" |
    Set-Content -LiteralPath $summaryMissingLog -Encoding UTF8
  $results.Add([pscustomobject]@{
      name = 'external_evidence_summary_link'
      command = 'resolve external evidence verifier summary from external_evidence_gate.log'
      meaning = 'Ensures the final gate report includes the verifier pass/fail/review counts for its scoped evidence JSON.'
      passed = $false
      exitCode = 1
      durationSeconds = 0
      log = $summaryMissingLog
    })
}

if ($null -ne $externalEvidenceGateSummary) {
  $startedAt = Get-Date
  try {
    $missingEvidenceSummary = New-FinalGateMissingEvidenceManifest -ExternalEvidenceGateSummary $externalEvidenceGateSummary
    $finishedAt = Get-Date
    $manifestLog = Join-Path $runDir 'missing_evidence_manifest.log'
    @(
      "COMMAND: generate final-gate missing evidence manifest",
      "EXIT_CODE: 0",
      "STARTED_AT: $($startedAt.ToString('o'))",
      "FINISHED_AT: $($finishedAt.ToString('o'))",
      "MISSING_CHECKS: $($missingEvidenceSummary.missing)",
      "MISSING_EVIDENCE: $($missingEvidenceSummary.missingEvidencePath)",
      "MISSING_EVIDENCE_JSON: $($missingEvidenceSummary.missingEvidenceJsonPath)"
    ) | Set-Content -LiteralPath $manifestLog -Encoding UTF8
    $results.Add([pscustomobject]@{
        name = 'missing_evidence_manifest'
        command = 'generate final-gate missing evidence manifest'
        meaning = 'Writes a final-gate-scoped human and machine-readable missing external evidence handoff.'
        passed = $true
        exitCode = 0
        durationSeconds = [math]::Round(($finishedAt - $startedAt).TotalSeconds, 2)
        log = $manifestLog
      })
  } catch {
    $finishedAt = Get-Date
    $manifestLog = Join-Path $runDir 'missing_evidence_manifest.log'
    @(
      "COMMAND: generate final-gate missing evidence manifest",
      "EXIT_CODE: 1",
      "STARTED_AT: $($startedAt.ToString('o'))",
      "FINISHED_AT: $($finishedAt.ToString('o'))",
      "ERROR: $($_.Exception.Message)"
    ) | Set-Content -LiteralPath $manifestLog -Encoding UTF8
    $results.Add([pscustomobject]@{
        name = 'missing_evidence_manifest'
        command = 'generate final-gate missing evidence manifest'
        meaning = 'Writes a final-gate-scoped human and machine-readable missing external evidence handoff.'
        passed = $false
        exitCode = 1
        durationSeconds = [math]::Round(($finishedAt - $startedAt).TotalSeconds, 2)
        log = $manifestLog
      })
  }
}

if ($null -ne $missingEvidenceSummary) {
  $runbookCommand = "powershell -NoProfile -ExecutionPolicy Bypass -File scripts\product-ready-external-evidence-runbook.ps1 -SourceHandoffDirectory `"$runDir`""
  $operatorRunbookResult = Invoke-GateStep -Step (New-GateStep -Name 'operator_runbook' -Command $runbookCommand -Meaning 'Writes the operator runbook from the final-gate-scoped missing external evidence handoff.')
  $results.Add($operatorRunbookResult)
  $operatorRunbookSummary = Get-OperatorRunbookSummaryFromStepLog -StepResult $operatorRunbookResult -SourceDirectory $runDir

  $intakeCommand = "powershell -NoProfile -ExecutionPolicy Bypass -File scripts\product-ready-evidence-intake.ps1 -SourceHandoffDirectory `"$runDir`""
  $evidenceIntakeResult = Invoke-GateStep -Step (New-GateStep -Name 'evidence_intake' -Command $intakeCommand -Meaning 'Writes a fillable operator intake checklist from the final-gate-scoped missing external evidence manifest.')
  $results.Add($evidenceIntakeResult)
  $evidenceIntakeSummary = Get-EvidenceIntakeSummaryFromStepLog -StepResult $evidenceIntakeResult -SourceDirectory $runDir
  if ($null -ne $evidenceIntakeSummary) {
    $intakeVerifyCommand = "powershell -NoProfile -ExecutionPolicy Bypass -File scripts\product-ready-evidence-intake-verify.ps1 -IntakePath `"$($evidenceIntakeSummary.evidenceIntakePath)`""
    $evidenceIntakeVerifyResult = Invoke-GateStep -Step (New-GateStep -Name 'evidence_intake_verify' -Command $intakeVerifyCommand -Meaning 'Verifies the generated evidence intake package against the scoped missing evidence manifest.')
    $results.Add($evidenceIntakeVerifyResult)
    $evidenceIntakeVerifySummary = Get-EvidenceIntakeVerifySummaryFromStepLog -StepResult $evidenceIntakeVerifyResult -IntakePath $evidenceIntakeSummary.evidenceIntakePath
  }
}

$operatorRunbookStepPassed = [bool]($results | Where-Object { $_.name -eq 'operator_runbook' -and $_.passed } | Select-Object -First 1)
if ($operatorRunbookStepPassed -and $null -eq $operatorRunbookSummary) {
  $runbookSummaryMissingLog = Join-Path $runDir 'operator_runbook_summary_link.log'
  "No current product-ready-external-evidence-runbook summary found in operator_runbook.log for final gate source directory: $runDir" |
    Set-Content -LiteralPath $runbookSummaryMissingLog -Encoding UTF8
  $results.Add([pscustomobject]@{
      name = 'operator_runbook_summary_link'
      command = 'resolve operator runbook summary from operator_runbook.log'
      meaning = 'Ensures the final gate report includes the operator runbook generated from its scoped missing evidence manifest.'
      passed = $false
      exitCode = 1
      durationSeconds = 0
      log = $runbookSummaryMissingLog
    })
}

$evidenceIntakeStepPassed = [bool]($results | Where-Object { $_.name -eq 'evidence_intake' -and $_.passed } | Select-Object -First 1)
if ($evidenceIntakeStepPassed -and $null -eq $evidenceIntakeSummary) {
  $intakeSummaryMissingLog = Join-Path $runDir 'evidence_intake_summary_link.log'
  "No current product-ready-evidence-intake summary found in evidence_intake.log for final gate source directory: $runDir" |
    Set-Content -LiteralPath $intakeSummaryMissingLog -Encoding UTF8
  $results.Add([pscustomobject]@{
      name = 'evidence_intake_summary_link'
      command = 'resolve evidence intake summary from evidence_intake.log'
      meaning = 'Ensures the final gate report includes the operator intake checklist generated from its scoped missing evidence manifest.'
      passed = $false
      exitCode = 1
      durationSeconds = 0
      log = $intakeSummaryMissingLog
    })
}

$evidenceIntakeVerifyStepPassed = [bool]($results | Where-Object { $_.name -eq 'evidence_intake_verify' -and $_.passed } | Select-Object -First 1)
if ($evidenceIntakeVerifyStepPassed -and $null -eq $evidenceIntakeVerifySummary) {
  $intakeVerifySummaryMissingLog = Join-Path $runDir 'evidence_intake_verify_summary_link.log'
  "No current product-ready-evidence-intake-verify summary found in evidence_intake_verify.log for intake path: $($evidenceIntakeSummary.evidenceIntakePath)" |
    Set-Content -LiteralPath $intakeVerifySummaryMissingLog -Encoding UTF8
  $results.Add([pscustomobject]@{
      name = 'evidence_intake_verify_summary_link'
      command = 'resolve evidence intake verifier summary from evidence_intake_verify.log'
      meaning = 'Ensures the final gate report includes the structural verifier summary for its generated evidence intake package.'
      passed = $false
      exitCode = 1
      durationSeconds = 0
      log = $intakeVerifySummaryMissingLog
    })
}

$failed = @($results | Where-Object { -not $_.passed })
$passedCount = @($results | Where-Object { $_.passed }).Count
$failedCount = $failed.Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  requireComplete = [bool]$RequireComplete
  passed = $passedCount
  failed = $failedCount
  steps = $results
  currentLocalEvidenceBundleRef = if ($bundlePath) { Convert-ToRelativePath $bundlePath } else { $null }
  currentLocalCoverageReportRef = if ($localCoverageSummaryPath) { Convert-ToRelativePath $localCoverageSummaryPath } else { $null }
  sourceExternalEvidencePath = if ($sourceExternalEvidencePath) { Convert-ToRelativePath $sourceExternalEvidencePath } else { $null }
  finalGateEvidencePath = if ($finalGateEvidencePath) { Convert-ToRelativePath $finalGateEvidencePath } else { $null }
  externalEvidenceGateSummary = $externalEvidenceGateSummary
  missingEvidenceSummary = $missingEvidenceSummary
  operatorRunbookSummary = $operatorRunbookSummary
  evidenceIntakeSummary = $evidenceIntakeSummary
  evidenceIntakeVerifySummary = $evidenceIntakeVerifySummary
  latestReports = [pscustomobject]@{
    localGate = if ($latestLocalGate) { Convert-ToRelativePath (Join-Path $latestLocalGate.FullName 'report.md') } else { $null }
    localEvidenceBundle = if ($latestBundle) { Convert-ToRelativePath (Join-Path $latestBundle.FullName 'report.md') } else { $null }
    externalEvidence = if ($latestExternal) { Convert-ToRelativePath (Join-Path $latestExternal.FullName 'report.md') } else { $null }
    operatorRunbook = if ($operatorRunbookSummary) { $operatorRunbookSummary.report } else { $null }
    evidenceIntake = if ($evidenceIntakeSummary) { $evidenceIntakeSummary.report } else { $null }
    evidenceIntakeVerify = if ($evidenceIntakeVerifySummary) { $evidenceIntakeVerifySummary.report } else { $null }
  }
  verdict = if ($failedCount -eq 0 -and $RequireComplete) {
    'Final Product Ready gate passed with complete external/staging/production evidence.'
  } elseif ($failedCount -eq 0) {
    'Final Product Ready preflight passed locally. Product Ready is still not proven until the complete external evidence gate passes.'
  } else {
    'Final Product Ready gate failed. Fix failed steps or attach the missing complete external/staging/production evidence.'
  }
}

$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready final gate')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Workspace: $WorkspaceRoot")
$lines.Add("- Require complete external evidence: $([bool]$RequireComplete)")
$lines.Add("- Steps: $passedCount passed, $failedCount failed")
$lines.Add("- Current local evidence bundle: $($summary.currentLocalEvidenceBundleRef)")
$lines.Add("- Current local acceptance coverage: $($summary.currentLocalCoverageReportRef)")
$lines.Add("- Source external evidence: $($summary.sourceExternalEvidencePath)")
$lines.Add("- Final-gate evidence file: $($summary.finalGateEvidencePath)")
if ($summary.externalEvidenceGateSummary) {
  $lines.Add("- External evidence checks: $($summary.externalEvidenceGateSummary.passed) passed, $($summary.externalEvidenceGateSummary.failed) failed, $($summary.externalEvidenceGateSummary.reviewRequired) review")
}
if ($summary.missingEvidenceSummary) {
  $lines.Add("- Missing evidence handoff: $($summary.missingEvidenceSummary.missingEvidencePath)")
  $lines.Add("- Machine-readable missing evidence: $($summary.missingEvidenceSummary.missingEvidenceJsonPath)")
  $lines.Add("- Missing evidence checks: $($summary.missingEvidenceSummary.missing)")
}
if ($summary.operatorRunbookSummary) {
  $lines.Add("- Operator runbook: $($summary.operatorRunbookSummary.operatorRunbookPath)")
  $lines.Add("- Operator runbook summary: $($summary.operatorRunbookSummary.summary)")
}
if ($summary.evidenceIntakeSummary) {
  $lines.Add("- Evidence intake JSON: $($summary.evidenceIntakeSummary.evidenceIntakePath)")
  $lines.Add("- Evidence intake checklist: $($summary.evidenceIntakeSummary.operatorChecklistPath)")
}
if ($summary.evidenceIntakeVerifySummary) {
  $lines.Add("- Evidence intake verifier: $($summary.evidenceIntakeVerifySummary.summary)")
}
$lines.Add('')
$lines.Add('## Steps')
$lines.Add('')
$lines.Add('| Step | Status | Exit code | Duration sec | Meaning | Log |')
$lines.Add('| --- | --- | --- | --- | --- | --- |')
foreach ($result in $results) {
  $status = if ($result.passed) { 'PASS' } else { 'FAIL' }
  $meaningText = ([string]$result.meaning).Replace('|', '\|')
  $lines.Add("| $($result.name) | $status | $($result.exitCode) | $($result.durationSeconds) | $meaningText | $($result.log) |")
}
$lines.Add('')
$lines.Add('## Latest Reports')
$lines.Add('')
$lines.Add("- Local gate: $($summary.latestReports.localGate)")
$lines.Add("- Local evidence bundle: $($summary.latestReports.localEvidenceBundle)")
$lines.Add("- External evidence: $($summary.latestReports.externalEvidence)")
$lines.Add("- Operator runbook: $($summary.latestReports.operatorRunbook)")
$lines.Add("- Evidence intake: $($summary.latestReports.evidenceIntake)")
$lines.Add("- Evidence intake verifier: $($summary.latestReports.evidenceIntakeVerify)")
if ($summary.externalEvidenceGateSummary) {
  $lines.Add("- External evidence summary for final gate file: $($summary.externalEvidenceGateSummary.summary)")
}
if ($summary.missingEvidenceSummary) {
  $lines.Add("- Missing evidence handoff: $($summary.missingEvidenceSummary.missingEvidencePath)")
  $lines.Add("- Machine-readable missing evidence: $($summary.missingEvidenceSummary.missingEvidenceJsonPath)")
}
if ($summary.operatorRunbookSummary) {
  $lines.Add("- Operator runbook summary: $($summary.operatorRunbookSummary.summary)")
  $lines.Add("- Operator runbook source handoff: $($summary.operatorRunbookSummary.sourceHandoff)")
}
if ($summary.evidenceIntakeSummary) {
  $lines.Add("- Evidence intake summary: $($summary.evidenceIntakeSummary.summary)")
  $lines.Add("- Evidence intake checklist: $($summary.evidenceIntakeSummary.operatorChecklistPath)")
}
if ($summary.evidenceIntakeVerifySummary) {
  $lines.Add("- Evidence intake verifier summary: $($summary.evidenceIntakeVerifySummary.summary)")
  $lines.Add("- Evidence intake verifier status: $($summary.evidenceIntakeVerifySummary.status)")
}
$lines.Add('')
$lines.Add('## Verdict')
$lines.Add('')
$lines.Add($summary.verdict)

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-final-gate] steps: $passedCount passed, $failedCount failed"
Write-Host "[product-ready-final-gate] report: $reportPath"
Write-Host "[product-ready-final-gate] summary: $summaryPath"

if ($failedCount -gt 0) {
  exit 1
}
exit 0
