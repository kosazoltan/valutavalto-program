param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-evidence-intake'),
  [string]$FinalGateRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-final-gate'),
  [string]$PackRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-external-evidence-pack'),
  [string]$ManifestPath = '',
  [string]$SourceHandoffDirectory = ''
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

function Convert-ToRelativePath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return ''
  }

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
    return ''
  }

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }

  return Join-Path $WorkspaceRoot $Path
}

function Get-LatestManifestPath {
  $roots = @($FinalGateRoot, $PackRoot)
  $candidates = [System.Collections.Generic.List[object]]::new()

  foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root)) {
      continue
    }

    foreach ($directory in (Get-ChildItem -LiteralPath $root -Directory)) {
      $candidate = Join-Path $directory.FullName 'missing-evidence.json'
      if (Test-Path -LiteralPath $candidate) {
        $file = Get-Item -LiteralPath $candidate
        $candidates.Add([pscustomobject]@{
            path = $candidate
            lastWriteTimeUtc = $file.LastWriteTimeUtc
          })
      }
    }
  }

  $latest = $candidates | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
  if ($null -eq $latest) {
    return ''
  }
  return [string]$latest.path
}

function Resolve-ManifestPath {
  if (-not [string]::IsNullOrWhiteSpace($ManifestPath)) {
    return Resolve-WorkspacePath -Path $ManifestPath
  }

  if (-not [string]::IsNullOrWhiteSpace($SourceHandoffDirectory)) {
    $sourceDir = Resolve-WorkspacePath -Path $SourceHandoffDirectory
    $sourceManifest = Join-Path $sourceDir 'missing-evidence.json'
    if (Test-Path -LiteralPath $sourceManifest) {
      return $sourceManifest
    }
    throw "Source handoff missing-evidence.json not found: $sourceManifest"
  }

  $latest = Get-LatestManifestPath
  if ([string]::IsNullOrWhiteSpace($latest)) {
    throw "No missing-evidence.json manifest found under $FinalGateRoot or $PackRoot"
  }
  return $latest
}

function Get-PropertyValue {
  param([object]$Object, [string]$Name)
  if ($null -eq $Object) { return $null }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { return $null }
  return $property.Value
}

function New-FieldMap {
  $rows = @(
    @{ check = 'evidenceStatus'; pointer = '/evidenceStatus'; required = 'COMPLETE'; action = 'Set only after every external evidence section passes fail-closed verification.' },
    @{ check = 'environment'; pointer = '/environment'; required = 'staging or production'; action = 'Name the real environment where evidence was collected.' },
    @{ check = 'evidenceOwner'; pointer = '/evidenceOwner'; required = 'Named evidence owner'; action = 'Record the accountable evidence owner.' },
    @{ check = 'approvals.reportRef'; pointer = '/approvals/reportRef'; required = 'Existing structured approvals summary.json'; action = 'Run approvals verifier against signed owner approvals.' },
    @{ check = 'approvals.productOwner'; pointer = '/approvals/productOwner'; required = 'Product owner approval'; action = 'Attach product owner approval evidence.' },
    @{ check = 'approvals.operationsOwner'; pointer = '/approvals/operationsOwner'; required = 'Operations owner approval'; action = 'Attach operations owner approval evidence.' },
    @{ check = 'approvals.complianceOwner'; pointer = '/approvals/complianceOwner'; required = 'Compliance owner approval'; action = 'Attach compliance owner approval evidence.' },
    @{ check = 'acceptance.status'; pointer = '/acceptance/status'; required = 'PASS'; action = 'Use real staging/production acceptance, not local-only smoke.' },
    @{ check = 'acceptance.executedAt'; pointer = '/acceptance/executedAt'; required = 'ISO timestamp'; action = 'Record when staging/production acceptance ran.' },
    @{ check = 'acceptance.reportRef'; pointer = '/acceptance/reportRef'; required = 'Existing structured acceptance summary.json'; action = 'Attach staging/production critical-flow acceptance report.' },
    @{ check = 'acceptance.failed'; pointer = '/acceptance/failed'; required = '0'; action = 'Resolve every failed staging/production acceptance check.' },
    @{ check = 'acceptance.criticalFlowsPassed'; pointer = '/acceptance/criticalFlowsPassed'; required = 'true'; action = 'Confirm all required critical flows passed.' },
    @{ check = 'compliance.status'; pointer = '/compliance/status'; required = 'PASS'; action = 'Use approved compliance go-live decision evidence.' },
    @{ check = 'compliance.approvedDecisionRef'; pointer = '/compliance/approvedDecisionRef'; required = 'Existing approved decision ref'; action = 'Attach approved compliance decision.' },
    @{ check = 'compliance.exportReportRef'; pointer = '/compliance/exportReportRef'; required = 'Existing staging/production export report'; action = 'Attach parameter export from the declared environment.' },
    @{ check = 'compliance.approvedDecisionStatus'; pointer = '/compliance/approvedDecisionStatus'; required = 'APPROVED'; action = 'Move decision from draft to approved only after compliance owner sign-off.' },
    @{ check = 'compliance.exportedEnvironment'; pointer = '/compliance/exportedEnvironment'; required = 'Matches /environment'; action = 'Ensure export and top-level environment names match.' },
    @{ check = 'compliance.failed'; pointer = '/compliance/failed'; required = '0'; action = 'Resolve every compliance verifier failure.' },
    @{ check = 'drRestore.status'; pointer = '/drRestore/status'; required = 'PASS'; action = 'Run real restore drill against isolated scratch target.' },
    @{ check = 'drRestore.executedAt'; pointer = '/drRestore/executedAt'; required = 'ISO timestamp'; action = 'Record restore drill execution time.' },
    @{ check = 'drRestore.reportRef'; pointer = '/drRestore/reportRef'; required = 'Existing real restore drill report'; action = 'Attach restore report with RTO/Flyway/hash/row-count proof.' },
    @{ check = 'drRestore.rtoMinutes'; pointer = '/drRestore/rtoMinutes'; required = '>= 1'; action = 'Record measured restore time.' },
    @{ check = 'drRestore.flywayVerified'; pointer = '/drRestore/flywayVerified'; required = 'true'; action = 'Verify Flyway after restore.' },
    @{ check = 'drRestore.auditHashChainVerified'; pointer = '/drRestore/auditHashChainVerified'; required = 'true'; action = 'Verify audit hash chain after restore.' },
    @{ check = 'drRestore.rowCounts.transactions'; pointer = '/drRestore/rowCounts/transactions'; required = '>= 1'; action = 'Record restored transaction row count.' },
    @{ check = 'drRestore.rowCounts.audit_log'; pointer = '/drRestore/rowCounts/audit_log'; required = '>= 1'; action = 'Record restored audit log row count.' },
    @{ check = 'drRestore.rowCounts.aml_report'; pointer = '/drRestore/rowCounts/aml_report'; required = '>= 1'; action = 'Record restored AML report row count.' },
    @{ check = 'drRestore.rowCounts.customer'; pointer = '/drRestore/rowCounts/customer'; required = '>= 1'; action = 'Record restored customer row count.' },
    @{ check = 'monitoring.status'; pointer = '/monitoring/status'; required = 'PASS'; action = 'Use deployed monitoring evidence.' },
    @{ check = 'monitoring.reportRef'; pointer = '/monitoring/reportRef'; required = 'Existing monitoring summary report'; action = 'Attach monitoring evidence report.' },
    @{ check = 'monitoring.observationHours'; pointer = '/monitoring/observationHours'; required = '>= 168'; action = 'Observe production/staging monitoring for at least 168 hours.' },
    @{ check = 'monitoring.scrapeVerified'; pointer = '/monitoring/scrapeVerified'; required = 'true'; action = 'Verify metrics scrape from deployed target.' },
    @{ check = 'monitoring.dashboardLoaded'; pointer = '/monitoring/dashboardLoaded'; required = 'true'; action = 'Verify dashboard loads.' },
    @{ check = 'monitoring.alertDelivered'; pointer = '/monitoring/alertDelivered'; required = 'true'; action = 'Verify alert delivery path.' },
    @{ check = 'installer.status'; pointer = '/installer/status'; required = 'PASS'; action = 'Use signed artifact and clean VM smoke evidence.' },
    @{ check = 'installer.signedArtifactReportRef'; pointer = '/installer/signedArtifactReportRef'; required = 'Existing signed artifact report'; action = 'Attach signature verification report.' },
    @{ check = 'installer.cleanVmReportRef'; pointer = '/installer/cleanVmReportRef'; required = 'Existing clean VM report'; action = 'Attach clean VM install/launch/uninstall report.' },
    @{ check = 'installer.signedArtifactsVerified'; pointer = '/installer/signedArtifactsVerified'; required = 'true'; action = 'Verify release artifact signatures.' },
    @{ check = 'finalDecision.readyForProductReadyClaim'; pointer = '/finalDecision/readyForProductReadyClaim'; required = 'true'; action = 'Set only after complete final gate passes.' },
    @{ check = 'finalDecision.decidedAt'; pointer = '/finalDecision/decidedAt'; required = 'ISO timestamp'; action = 'Record final Product Ready decision time.' },
    @{ check = 'finalDecision.decidedBy'; pointer = '/finalDecision/decidedBy'; required = 'Named final decision owner'; action = 'Record final decision owner.' },
    @{ check = 'finalDecision external evidence status'; pointer = '/evidenceStatus'; required = 'COMPLETE'; action = 'Final decision requires complete evidence status.' },
    @{ check = 'finalDecision external evidence environment'; pointer = '/environment'; required = 'staging or production'; action = 'Final decision requires real environment evidence.' },
    @{ check = 'finalDecision external evidence claim flag'; pointer = '/finalDecision/readyForProductReadyClaim'; required = 'true'; action = 'Final decision requires ready claim flag after proof.' }
  )

  $map = @{}
  foreach ($row in $rows) {
    $map[$row.check] = [pscustomobject]@{
      jsonPointer = $row.pointer
      requiredValue = $row.required
      operatorAction = $row.action
    }
  }
  return $map
}

$manifestFullPath = Resolve-ManifestPath
if (-not (Test-Path -LiteralPath $manifestFullPath)) {
  throw "Missing evidence manifest does not exist: $manifestFullPath"
}

$manifest = Get-Content -LiteralPath $manifestFullPath -Raw | ConvertFrom-Json
$finalGateEvidencePath = [string](Get-PropertyValue $manifest 'finalGateEvidencePath')
$draftEvidencePath = [string](Get-PropertyValue $manifest 'draftEvidencePath')
$sourceEvidencePath = if (-not [string]::IsNullOrWhiteSpace($finalGateEvidencePath)) {
  $finalGateEvidencePath
} else {
  $draftEvidencePath
}
$fieldMap = New-FieldMap

$intakeSections = [System.Collections.Generic.List[object]]::new()
foreach ($section in @(Get-PropertyValue $manifest 'sections')) {
  $sectionName = [string](Get-PropertyValue $section 'section')
  $sectionChecks = [System.Collections.Generic.List[object]]::new()
  foreach ($check in @(Get-PropertyValue $section 'checks')) {
    $checkName = [string](Get-PropertyValue $check 'name')
    $mapped = $fieldMap[$checkName]
    if ($null -eq $mapped) {
      $mapped = [pscustomobject]@{
        jsonPointer = ''
        requiredValue = [string](Get-PropertyValue $check 'expected')
        operatorAction = 'Fill the evidence JSON field referenced by this verifier check and re-run the complete verifier.'
      }
    }

    $sectionChecks.Add([pscustomobject]@{
        section = $sectionName
        name = $checkName
        sourceCheckName = $checkName
        sourceStatus = [string](Get-PropertyValue $check 'status')
        status = [string](Get-PropertyValue $check 'status')
        jsonPointer = $mapped.jsonPointer
        currentEvidence = [string](Get-PropertyValue $check 'evidence')
        expected = [string](Get-PropertyValue $check 'expected')
        requiredValue = $mapped.requiredValue
        operatorAction = $mapped.operatorAction
        evidenceRef = ''
        completedBy = ''
        completedAt = ''
      })
  }

  $intakeSections.Add([pscustomobject]@{
      section = $sectionName
      owner = [string](Get-PropertyValue $section 'owner')
      template = [string](Get-PropertyValue $section 'template')
      commands = @(Get-PropertyValue $section 'commands')
      notes = [string](Get-PropertyValue $section 'notes')
      missing = [int](Get-PropertyValue $section 'missing')
      checks = $sectionChecks
    })
}

$intakeJsonPath = Join-Path $runDir 'evidence-intake.json'
$operatorChecklistPath = Join-Path $runDir 'operator-intake-checklist.md'
$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'

$intake = [pscustomobject]@{
  schemaVersion = 1
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  sourceManifestPath = Convert-ToRelativePath $manifestFullPath
  finalGateEvidencePath = $finalGateEvidencePath
  draftEvidencePath = $draftEvidencePath
  sourceEvidencePath = $sourceEvidencePath
  localEvidenceBundleRef = [string](Get-PropertyValue $manifest 'localEvidenceBundleRef')
  localCoverageReportRef = [string](Get-PropertyValue $manifest 'localCoverageReportRef')
  verifierSummary = [string](Get-PropertyValue $manifest 'verifierSummary')
  missing = [int](Get-PropertyValue $manifest 'missing')
  sections = $intakeSections
  completionCommand = 'npm run product-ready:final-gate:complete'
  productReadyMeaning = 'Operator intake checklist for collecting real external/staging/production evidence. This file is not proof by itself.'
}
$intake | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $intakeJsonPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready external evidence intake checklist')
$lines.Add('')
$lines.Add("- Generated: $($intake.generatedAt)")
$lines.Add("- Source manifest: $($intake.sourceManifestPath)")
$lines.Add("- Evidence JSON: $($intake.sourceEvidencePath)")
$lines.Add("- Missing checks: $($intake.missing)")
$lines.Add('')
$lines.Add('This checklist is an intake aid only. Product Ready is proven only by a passing `npm run product-ready:final-gate:complete` against the filled evidence JSON.')
$lines.Add('')
foreach ($section in $intakeSections) {
  $lines.Add("## $($section.section)")
  $lines.Add('')
  $lines.Add("- Owner: $($section.owner)")
  $lines.Add("- Template: $($section.template)")
  $lines.Add("- Missing checks: $($section.missing)")
  $lines.Add("- Notes: $($section.notes)")
  $lines.Add("- Suggested commands: $([string]::Join('; ', @($section.commands)))")
  $lines.Add('')
  $lines.Add('| Done | Check | JSON pointer | Current evidence | Required value | Operator action | Evidence ref |')
  $lines.Add('| --- | --- | --- | --- | --- | --- | --- |')
  foreach ($check in @($section.checks)) {
    $current = ([string]$check.currentEvidence).Replace('|', '\|')
    $action = ([string]$check.operatorAction).Replace('|', '\|')
    $pointer = if ([string]::IsNullOrWhiteSpace([string]$check.jsonPointer)) { 'n/a' } else { "``$($check.jsonPointer)``" }
    $lines.Add("| [ ] | $($check.name) | $pointer | $current | $($check.requiredValue) | $action |  |")
  }
  $lines.Add('')
}
$lines.Add('## Completion')
$lines.Add('')
$lines.Add('After every evidence reference above is real, immutable, and entered into the filled external evidence JSON:')
$lines.Add('')
$lines.Add('```powershell')
$lines.Add('$env:PRODUCT_READY_EXTERNAL_EVIDENCE_PATH = "<filled-evidence.json>"')
$lines.Add('npm run product-ready:final-gate:complete')
$lines.Add('```')
$lines | Set-Content -LiteralPath $operatorChecklistPath -Encoding UTF8

foreach ($section in $intakeSections) {
  $safeSection = ($section.section -replace '[^A-Za-z0-9_.-]', '_').Trim('_')
  $sectionPath = Join-Path $runDir "section-$safeSection.md"
  $sectionLines = [System.Collections.Generic.List[string]]::new()
  $sectionLines.Add("# Evidence intake: $($section.section)")
  $sectionLines.Add('')
  $sectionLines.Add("- Owner: $($section.owner)")
  $sectionLines.Add("- Template: $($section.template)")
  $sectionLines.Add("- Suggested commands: $([string]::Join('; ', @($section.commands)))")
  $sectionLines.Add('')
  foreach ($check in @($section.checks)) {
    $sectionLines.Add("## $($check.name)")
    $sectionLines.Add('')
    $sectionLines.Add("- Section: $($check.section)")
    $sectionLines.Add("- JSON pointer: $($check.jsonPointer)")
    $sectionLines.Add("- Current evidence: $($check.currentEvidence)")
    $sectionLines.Add("- Required value: $($check.requiredValue)")
    $sectionLines.Add("- Operator action: $($check.operatorAction)")
    $sectionLines.Add("- Evidence ref:")
    $sectionLines.Add("- Completed by:")
    $sectionLines.Add("- Completed at:")
    $sectionLines.Add('')
  }
  $sectionLines | Set-Content -LiteralPath $sectionPath -Encoding UTF8
}

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  sourceManifestPath = Convert-ToRelativePath $manifestFullPath
  evidenceIntakePath = Convert-ToRelativePath $intakeJsonPath
  operatorChecklistPath = Convert-ToRelativePath $operatorChecklistPath
  sourceEvidencePath = $sourceEvidencePath
  missing = $intake.missing
  sections = $intakeSections.Count
  checks = ($intakeSections | ForEach-Object { @($_.checks).Count } | Measure-Object -Sum).Sum
  verdict = if ($intake.missing -eq 0) {
    'No missing checks in source manifest. Run the complete final gate with the filled evidence JSON.'
  } else {
    'Evidence intake package generated. Product Ready remains unproven until every missing check is backed by real external evidence and the complete final gate passes.'
  }
}
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportLines = [System.Collections.Generic.List[string]]::new()
$reportLines.Add('# Product Ready evidence intake package')
$reportLines.Add('')
$reportLines.Add("- Generated: $($summary.generatedAt)")
$reportLines.Add("- Source manifest: $($summary.sourceManifestPath)")
$reportLines.Add("- Evidence JSON: $($summary.sourceEvidencePath)")
$reportLines.Add("- Intake JSON: $($summary.evidenceIntakePath)")
$reportLines.Add("- Operator checklist: $($summary.operatorChecklistPath)")
$reportLines.Add("- Sections: $($summary.sections)")
$reportLines.Add("- Checks: $($summary.checks)")
$reportLines.Add("- Missing: $($summary.missing)")
$reportLines.Add('')
$reportLines.Add('## Verdict')
$reportLines.Add('')
$reportLines.Add($summary.verdict)
$reportLines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-evidence-intake] intake: $intakeJsonPath"
Write-Host "[product-ready-evidence-intake] checklist: $operatorChecklistPath"
Write-Host "[product-ready-evidence-intake] summary: $summaryPath"
exit 0
