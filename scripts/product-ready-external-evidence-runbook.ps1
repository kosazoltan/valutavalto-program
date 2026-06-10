param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-external-evidence-runbook'),
  [string]$PackRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-external-evidence-pack'),
  [string]$FinalGateRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-final-gate'),
  [string]$SourceHandoffDirectory = '',
  [string]$RunbookTemplatePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md'),
  [switch]$RefreshPack
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

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
    return $Path
  }

  return Join-Path $WorkspaceRoot $Path
}

function Invoke-CommandCapture {
  param(
    [string]$Name,
    [string]$Command
  )

  $safeName = ($Name -replace '[^A-Za-z0-9_.-]', '_').Trim('_')
  $stdoutPath = Join-Path $runDir "$safeName.stdout.log"
  $stderrPath = Join-Path $runDir "$safeName.stderr.log"
  $combinedPath = Join-Path $runDir "$safeName.log"
  $startedAt = Get-Date

  Write-Host "[product-ready-external-evidence-runbook] running ${Name}: $Command"
  $process = Start-Process `
    -FilePath 'cmd.exe' `
    -ArgumentList @('/d', '/c', $Command) `
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
    "COMMAND: $Command",
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

  if ($process.ExitCode -ne 0) {
    throw "$Name failed with exit code $($process.ExitCode). See $combinedPath"
  }

  return [pscustomobject]@{
    name = $Name
    command = $Command
    exitCode = $process.ExitCode
    durationSeconds = [math]::Round(($finishedAt - $startedAt).TotalSeconds, 2)
    log = Convert-ToRelativePath $combinedPath
  }
}

function Get-LatestFinalGateHandoff {
  if (-not (Test-Path -LiteralPath $FinalGateRoot)) {
    return $null
  }

  $directories = Get-ChildItem -LiteralPath $FinalGateRoot -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    $missingPath = Join-Path $directory.FullName 'missing-evidence.md'
    $missingJsonPath = Join-Path $directory.FullName 'missing-evidence.json'
    $evidencePath = Join-Path $directory.FullName 'external-evidence.final-gate.json'
    if ((Test-Path -LiteralPath $summaryPath) -and
        (Test-Path -LiteralPath $missingPath) -and
        (Test-Path -LiteralPath $missingJsonPath) -and
        (Test-Path -LiteralPath $evidencePath)) {
  return [pscustomobject]@{
        sourceType = 'final-gate'
        directory = $directory.FullName
        summaryPath = $summaryPath
        missingPath = $missingPath
        missingJsonPath = $missingJsonPath
        evidencePath = $evidencePath
        summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
        missingManifest = Get-Content -LiteralPath $missingJsonPath -Raw | ConvertFrom-Json
      }
    }
  }

  return $null
}

function Get-FinalGateHandoffFromDirectory {
  param([string]$Directory)

  $fullDirectory = Resolve-WorkspacePath -Path $Directory
  if ([string]::IsNullOrWhiteSpace($fullDirectory) -or -not (Test-Path -LiteralPath $fullDirectory -PathType Container)) {
    throw "Requested final-gate handoff directory does not exist: $Directory"
  }

  $summaryPath = Join-Path $fullDirectory 'summary.json'
  $missingPath = Join-Path $fullDirectory 'missing-evidence.md'
  $missingJsonPath = Join-Path $fullDirectory 'missing-evidence.json'
  $evidencePath = Join-Path $fullDirectory 'external-evidence.final-gate.json'
  if (-not ((Test-Path -LiteralPath $missingPath) -and
      (Test-Path -LiteralPath $missingJsonPath) -and
      (Test-Path -LiteralPath $evidencePath))) {
    throw "Requested final-gate handoff is incomplete. Required files: missing-evidence.md, missing-evidence.json, external-evidence.final-gate.json under $fullDirectory"
  }

  return [pscustomobject]@{
    sourceType = 'final-gate'
    directory = $fullDirectory
    summaryPath = if (Test-Path -LiteralPath $summaryPath) { $summaryPath } else { '' }
    missingPath = $missingPath
    missingJsonPath = $missingJsonPath
    evidencePath = $evidencePath
    summary = if (Test-Path -LiteralPath $summaryPath) { Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json } else { $null }
    missingManifest = Get-Content -LiteralPath $missingJsonPath -Raw | ConvertFrom-Json
  }
}

function Get-LatestPackHandoff {
  if (-not (Test-Path -LiteralPath $PackRoot)) {
    return $null
  }

  $directories = Get-ChildItem -LiteralPath $PackRoot -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    $missingPath = Join-Path $directory.FullName 'missing-evidence.md'
    $missingJsonPath = Join-Path $directory.FullName 'missing-evidence.json'
    $draftPath = Join-Path $directory.FullName 'external-evidence.draft.json'
    if ((Test-Path -LiteralPath $summaryPath) -and
        (Test-Path -LiteralPath $missingPath) -and
        (Test-Path -LiteralPath $missingJsonPath) -and
        (Test-Path -LiteralPath $draftPath)) {
      return [pscustomobject]@{
        sourceType = 'external-evidence-pack'
        directory = $directory.FullName
        summaryPath = $summaryPath
        missingPath = $missingPath
        missingJsonPath = $missingJsonPath
        evidencePath = $draftPath
        summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
        missingManifest = Get-Content -LiteralPath $missingJsonPath -Raw | ConvertFrom-Json
      }
    }
  }

  return $null
}

function Get-LatestEvidenceHandoff {
  if (-not [string]::IsNullOrWhiteSpace($SourceHandoffDirectory)) {
    return Get-FinalGateHandoffFromDirectory -Directory $SourceHandoffDirectory
  }

  $finalGate = Get-LatestFinalGateHandoff
  if ($null -ne $finalGate) {
    return $finalGate
  }

  $pack = Get-LatestPackHandoff
  if ($null -ne $pack) {
    return $pack
  }

  throw "No complete final-gate or external evidence pack handoff exists under: $FinalGateRoot or $PackRoot"
}

if ($RefreshPack) {
  Invoke-CommandCapture -Name 'refresh_external_evidence_pack' -Command 'npm run product-ready:external-evidence:pack:refresh' | Out-Null
}

if (-not (Test-Path -LiteralPath $RunbookTemplatePath)) {
  throw "Runbook template is missing: $RunbookTemplatePath"
}

$handoff = Get-LatestEvidenceHandoff
$operatorRunbookPath = Join-Path $runDir 'operator-runbook.md'
$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'

$fieldMap = @(
  [pscustomobject]@{ section = 'topLevel'; check = 'evidenceStatus'; jsonPointer = '/evidenceStatus'; requiredValue = 'COMPLETE' },
  [pscustomobject]@{ section = 'topLevel'; check = 'environment'; jsonPointer = '/environment'; requiredValue = 'staging or production' },
  [pscustomobject]@{ section = 'topLevel'; check = 'evidenceOwner'; jsonPointer = '/evidenceOwner'; requiredValue = 'Named evidence owner' },
  [pscustomobject]@{ section = 'approvals'; check = 'approvals.reportRef'; jsonPointer = '/approvals/reportRef'; requiredValue = 'Structured owner approvals summary.json ref' },
  [pscustomobject]@{ section = 'approvals'; check = 'approvals.productOwner'; jsonPointer = '/approvals/productOwner'; requiredValue = 'Named product owner approval' },
  [pscustomobject]@{ section = 'approvals'; check = 'approvals.operationsOwner'; jsonPointer = '/approvals/operationsOwner'; requiredValue = 'Named operations approval' },
  [pscustomobject]@{ section = 'approvals'; check = 'approvals.complianceOwner'; jsonPointer = '/approvals/complianceOwner'; requiredValue = 'Named compliance approval' },
  [pscustomobject]@{ section = 'acceptance'; check = 'acceptance.status'; jsonPointer = '/acceptance/status'; requiredValue = 'PASS' },
  [pscustomobject]@{ section = 'acceptance'; check = 'acceptance.executedAt'; jsonPointer = '/acceptance/executedAt'; requiredValue = 'ISO timestamp' },
  [pscustomobject]@{ section = 'acceptance'; check = 'acceptance.reportRef'; jsonPointer = '/acceptance/reportRef'; requiredValue = 'Structured staging/production acceptance summary.json ref' },
  [pscustomobject]@{ section = 'acceptance'; check = 'acceptance.localCoverageReportRef'; jsonPointer = '/acceptance/localCoverageReportRef'; requiredValue = 'Local coverage report ref' },
  [pscustomobject]@{ section = 'acceptance'; check = 'acceptance.failed'; jsonPointer = '/acceptance/failed'; requiredValue = '0' },
  [pscustomobject]@{ section = 'acceptance'; check = 'acceptance.criticalFlowsPassed'; jsonPointer = '/acceptance/criticalFlowsPassed'; requiredValue = 'true' },
  [pscustomobject]@{ section = 'acceptance'; check = 'acceptance.coveredFlows'; jsonPointer = '/acceptance/coveredFlows'; requiredValue = 'buy, sell, conversion, transfer, storno, dayClosing, navCashRegister, receiptPrint, offlineSync' },
  [pscustomobject]@{ section = 'compliance'; check = 'compliance.status'; jsonPointer = '/compliance/status'; requiredValue = 'PASS' },
  [pscustomobject]@{ section = 'compliance'; check = 'compliance.approvedDecisionRef'; jsonPointer = '/compliance/approvedDecisionRef'; requiredValue = 'Approved decision ref' },
  [pscustomobject]@{ section = 'compliance'; check = 'compliance.exportReportRef'; jsonPointer = '/compliance/exportReportRef'; requiredValue = 'Staging/production export report ref' },
  [pscustomobject]@{ section = 'compliance'; check = 'compliance.approvedDecisionStatus'; jsonPointer = '/compliance/approvedDecisionStatus'; requiredValue = 'APPROVED' },
  [pscustomobject]@{ section = 'compliance'; check = 'compliance.exportedEnvironment'; jsonPointer = '/compliance/exportedEnvironment'; requiredValue = 'Matches /environment' },
  [pscustomobject]@{ section = 'compliance'; check = 'compliance.failed'; jsonPointer = '/compliance/failed'; requiredValue = '0' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.status'; jsonPointer = '/drRestore/status'; requiredValue = 'PASS' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.executedAt'; jsonPointer = '/drRestore/executedAt'; requiredValue = 'ISO timestamp' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.reportRef'; jsonPointer = '/drRestore/reportRef'; requiredValue = 'Real restore drill report ref' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.rtoMinutes'; jsonPointer = '/drRestore/rtoMinutes'; requiredValue = '>= 1' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.flywayVerified'; jsonPointer = '/drRestore/flywayVerified'; requiredValue = 'true' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.auditHashChainVerified'; jsonPointer = '/drRestore/auditHashChainVerified'; requiredValue = 'true' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.rowCounts.transactions'; jsonPointer = '/drRestore/rowCounts/transactions'; requiredValue = '>= 1' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.rowCounts.audit_log'; jsonPointer = '/drRestore/rowCounts/audit_log'; requiredValue = '>= 1' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.rowCounts.aml_report'; jsonPointer = '/drRestore/rowCounts/aml_report'; requiredValue = '>= 1' },
  [pscustomobject]@{ section = 'drRestore'; check = 'drRestore.rowCounts.customer'; jsonPointer = '/drRestore/rowCounts/customer'; requiredValue = '>= 1' },
  [pscustomobject]@{ section = 'monitoring'; check = 'monitoring.status'; jsonPointer = '/monitoring/status'; requiredValue = 'PASS' },
  [pscustomobject]@{ section = 'monitoring'; check = 'monitoring.reportRef'; jsonPointer = '/monitoring/reportRef'; requiredValue = 'Monitoring evidence report ref' },
  [pscustomobject]@{ section = 'monitoring'; check = 'monitoring.observationHours'; jsonPointer = '/monitoring/observationHours'; requiredValue = '>= 168' },
  [pscustomobject]@{ section = 'monitoring'; check = 'monitoring.scrapeVerified'; jsonPointer = '/monitoring/scrapeVerified'; requiredValue = 'true' },
  [pscustomobject]@{ section = 'monitoring'; check = 'monitoring.dashboardLoaded'; jsonPointer = '/monitoring/dashboardLoaded'; requiredValue = 'true' },
  [pscustomobject]@{ section = 'monitoring'; check = 'monitoring.alertDelivered'; jsonPointer = '/monitoring/alertDelivered'; requiredValue = 'true' },
  [pscustomobject]@{ section = 'installer'; check = 'installer.status'; jsonPointer = '/installer/status'; requiredValue = 'PASS' },
  [pscustomobject]@{ section = 'installer'; check = 'installer.signedArtifactReportRef'; jsonPointer = '/installer/signedArtifactReportRef'; requiredValue = 'Signed artifact report ref' },
  [pscustomobject]@{ section = 'installer'; check = 'installer.cleanVmReportRef'; jsonPointer = '/installer/cleanVmReportRef'; requiredValue = 'Clean VM smoke report ref' },
  [pscustomobject]@{ section = 'installer'; check = 'installer.signedArtifactsVerified'; jsonPointer = '/installer/signedArtifactsVerified'; requiredValue = 'true' },
  [pscustomobject]@{ section = 'finalDecision'; check = 'finalDecision.readyForProductReadyClaim'; jsonPointer = '/finalDecision/readyForProductReadyClaim'; requiredValue = 'true' },
  [pscustomobject]@{ section = 'finalDecision'; check = 'finalDecision.decidedAt'; jsonPointer = '/finalDecision/decidedAt'; requiredValue = 'ISO timestamp' },
  [pscustomobject]@{ section = 'finalDecision'; check = 'finalDecision.decidedBy'; jsonPointer = '/finalDecision/decidedBy'; requiredValue = 'Named final decision owner' },
  [pscustomobject]@{ section = 'finalDecision'; check = 'finalDecision.externalEvidenceRef'; jsonPointer = '/finalDecision/externalEvidenceRef'; requiredValue = 'Completed external evidence JSON ref' },
  [pscustomobject]@{ section = 'finalDecision'; check = 'finalDecision.finalGateSummaryRef'; jsonPointer = '/finalDecision/finalGateSummaryRef'; requiredValue = 'Optional post-run successful product-ready:final-gate:complete summary.json ref' }
)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add((Get-Content -LiteralPath $RunbookTemplatePath -Raw))
$lines.Add('')
$lines.Add('## Generated current-state handoff')
$lines.Add('')
$lines.Add("- Generated: $((Get-Date).ToString('o'))")
$lines.Add("- Source handoff type: $($handoff.sourceType)")
$lines.Add("- Source handoff: $(Convert-ToRelativePath $handoff.directory)")
$lines.Add("- Evidence JSON: $(Convert-ToRelativePath $handoff.evidencePath)")
$lines.Add("- Missing evidence handoff: $(Convert-ToRelativePath $handoff.missingPath)")
if (-not [string]::IsNullOrWhiteSpace([string]$handoff.missingJsonPath)) {
  $lines.Add("- Machine-readable missing evidence: $(Convert-ToRelativePath $handoff.missingJsonPath)")
}
$missingCount = if ($null -ne $handoff.missingManifest -and $null -ne $handoff.missingManifest.missing) { [int]$handoff.missingManifest.missing } else { [int]$handoff.summary.missing }
$lines.Add("- Missing checks: $missingCount")
$lines.Add('')
$lines.Add('## Final Gate Command')
$lines.Add('')
$lines.Add('After the filled evidence JSON passes `product-ready-external-evidence-verify.ps1 -RequireComplete`, run the final gate against that same completed artifact:')
$lines.Add('')
$lines.Add('```powershell')
$lines.Add('$env:PRODUCT_READY_EXTERNAL_EVIDENCE_PATH = "<filled-evidence.json>"')
$lines.Add('npm run product-ready:final-gate:complete')
$lines.Add('powershell -NoProfile -ExecutionPolicy Bypass -File scripts/product-ready-final-gate.ps1 -RequireComplete -ExternalEvidencePath <filled-evidence.json>')
$lines.Add('```')
$lines.Add('')
$lines.Add('## Evidence JSON field map')
$lines.Add('')
$lines.Add('| Section | Verifier check | JSON pointer | Required value |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($field in $fieldMap) {
  $pointer = [string]$field.jsonPointer
  $lines.Add("| $($field.section) | $($field.check) | ``$pointer`` | $($field.requiredValue) |")
}
$lines.Add('')
$lines.Add('## Latest missing evidence table')
$lines.Add('')
$lines.Add((Get-Content -LiteralPath $handoff.missingPath -Raw))
$lines | Set-Content -LiteralPath $operatorRunbookPath -Encoding UTF8

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  sourceHandoffType = $handoff.sourceType
  sourceHandoff = Convert-ToRelativePath $handoff.directory
  evidencePath = Convert-ToRelativePath $handoff.evidencePath
  missingEvidencePath = Convert-ToRelativePath $handoff.missingPath
  missingEvidenceJsonPath = if (-not [string]::IsNullOrWhiteSpace([string]$handoff.missingJsonPath)) { Convert-ToRelativePath $handoff.missingJsonPath } else { '' }
  operatorRunbookPath = Convert-ToRelativePath $operatorRunbookPath
  missing = $missingCount
  fieldMapEntries = $fieldMap.Count
  refreshPack = [bool]$RefreshPack
  verdict = if ($missingCount -eq 0) {
    'No missing checks in the source pack. Run the fail-closed final gate with the verified evidence JSON.'
  } else {
    'External evidence is still incomplete. Use the operator runbook to collect real staging/production evidence.'
  }
}
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportLines = [System.Collections.Generic.List[string]]::new()
$reportLines.Add('# Product Ready external evidence operator runbook')
$reportLines.Add('')
$reportLines.Add("- Generated: $($summary.generatedAt)")
$reportLines.Add("- Operator runbook: $($summary.operatorRunbookPath)")
$reportLines.Add("- Source handoff type: $($summary.sourceHandoffType)")
$reportLines.Add("- Source handoff: $($summary.sourceHandoff)")
$reportLines.Add("- Evidence: $($summary.evidencePath)")
$reportLines.Add("- Missing evidence JSON: $($summary.missingEvidenceJsonPath)")
$reportLines.Add("- Missing checks: $($summary.missing)")
$reportLines.Add("- Field map entries: $($summary.fieldMapEntries)")
$reportLines.Add('')
$reportLines.Add('## Verdict')
$reportLines.Add('')
$reportLines.Add($summary.verdict)
$reportLines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-external-evidence-runbook] operator runbook: $operatorRunbookPath"
Write-Host "[product-ready-external-evidence-runbook] report: $reportPath"
Write-Host "[product-ready-external-evidence-runbook] summary: $summaryPath"
Write-Host "[product-ready-external-evidence-runbook] missing checks: $($summary.missing)"
