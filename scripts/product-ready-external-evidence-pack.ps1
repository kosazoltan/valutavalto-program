param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-external-evidence-pack'),
  [string]$EvidenceTemplatePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json'),
  [switch]$RefreshLocalBundle,
  [switch]$RequireNoMissing
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

function Resolve-RepoPath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return $null
  }

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }

  return Join-Path $WorkspaceRoot $Path
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

  $summaryPath = Resolve-RepoPath -Path ([string]$artifact.summary)
  if (-not (Test-Path -LiteralPath $summaryPath)) {
    throw "Bundled acceptance coverage summary is missing: $summaryPath"
  }

  $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
  if ([int]$summary.failed -ne 0 -or [string]$summary.productReadyMeaning -notmatch 'Local critical-flow coverage map') {
    throw "Bundled acceptance coverage summary is not a passing local critical-flow coverage report: $summaryPath"
  }

  return $summaryPath
}

function Invoke-CommandCapture {
  param(
    [string]$Name,
    [string]$Command,
    [bool]$AllowFailure = $false
  )

  $safeName = ($Name -replace '[^A-Za-z0-9_.-]', '_').Trim('_')
  $stdoutPath = Join-Path $runDir "$safeName.stdout.log"
  $stderrPath = Join-Path $runDir "$safeName.stderr.log"
  $combinedPath = Join-Path $runDir "$safeName.log"
  $startedAt = Get-Date

  Write-Host "[product-ready-external-evidence-pack] running ${Name}: $Command"
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

  if ($process.ExitCode -ne 0 -and -not $AllowFailure) {
    throw "$Name failed with exit code $($process.ExitCode). See $combinedPath"
  }

  return [pscustomobject]@{
    name = $Name
    command = $Command
    exitCode = $process.ExitCode
    durationSeconds = [math]::Round(($finishedAt - $startedAt).TotalSeconds, 2)
    log = $combinedPath
  }
}

function Get-ExternalEvidenceSummaryForPath {
  param([string]$EvidencePath)

  $root = Join-Path $WorkspaceRoot 'security-reports\product-ready-external-evidence'
  if (-not (Test-Path -LiteralPath $root)) {
    throw 'No product-ready-external-evidence report directory exists.'
  }

  $expectedEvidencePath = [System.IO.Path]::GetFullPath($EvidencePath)
  $directories = Get-ChildItem -LiteralPath $root -Directory | Sort-Object Name -Descending
  foreach ($directory in $directories) {
    $summaryPath = Join-Path $directory.FullName 'summary.json'
    $reportPath = Join-Path $directory.FullName 'report.md'
    if ((Test-Path -LiteralPath $summaryPath) -and (Test-Path -LiteralPath $reportPath)) {
      $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
      $summaryEvidencePath = Resolve-RepoPath -Path ([string]$summary.evidencePath)
      if ([string]::IsNullOrWhiteSpace($summaryEvidencePath)) {
        continue
      }

      if ([System.IO.Path]::GetFullPath($summaryEvidencePath).Equals($expectedEvidencePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return [pscustomobject]@{
          directory = $directory.FullName
          summaryPath = $summaryPath
          reportPath = $reportPath
          summary = $summary
        }
      }
    }
  }

  throw "No product-ready-external-evidence summary exists for evidence path: $EvidencePath"
}

function Get-SectionName {
  param([string]$CheckName)

  if ($CheckName -match '^approvals\.') { return 'approvals' }
  if ($CheckName -match '^acceptance\.') { return 'acceptance' }
  if ($CheckName -match '^compliance\.') { return 'compliance' }
  if ($CheckName -match '^drRestore\.') { return 'drRestore' }
  if ($CheckName -match '^monitoring\.') { return 'monitoring' }
  if ($CheckName -match '^installer\.') { return 'installer' }
  if ($CheckName -match '^finalDecision\.') { return 'finalDecision' }
  if ($CheckName -match '^local evidence bundle') { return 'localEvidenceBundle' }
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
      notes = 'Set evidenceStatus, environment, generatedAt, evidenceOwner and localEvidenceBundleRef for the completed staging/production evidence artifact.'
    }
    approvals = [pscustomobject]@{
      owner = 'Product owner, operations owner, compliance owner'
      template = 'docs\PRODUCT_READY_APPROVALS_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:approvals:preflight', 'npm run product-ready:approvals:complete')
      notes = 'Attach structured owner sign-off summary and keep approvals text fields aligned for human readability.'
    }
    acceptance = [pscustomobject]@{
      owner = 'Business acceptance operator'
      template = 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:staging-acceptance:preflight', 'npm run product-ready:staging-acceptance:complete', 'npm run product-ready:acceptance-coverage')
      notes = 'Use real staging/production execution evidence for every critical flow: buy, sell, conversion, transfer, storno, dayClosing, navCashRegister, receiptPrint, offlineSync. Local coverage is supporting evidence only.'
    }
    compliance = [pscustomobject]@{
      owner = 'Compliance owner'
      template = 'docs\COMPLIANCE_GO_LIVE_DECISION_TEMPLATE_2026-06-09.json'
      commands = @('npm run compliance:golive:export', 'npm run compliance:golive:decision:approved')
      notes = 'Use approved decision evidence and staging/production system_parameter export from the declared environment.'
    }
    drRestore = [pscustomobject]@{
      owner = 'Operations/DB owner'
      template = 'docs\operations\dr-backup-runbook.md'
      commands = @('npm run dr:restore:preflight')
      notes = 'Run a real restore drill against an isolated scratch target and record RTO, Flyway state, audit hash-chain smoke and row counts.'
    }
    monitoring = [pscustomobject]@{
      owner = 'Operations/monitoring owner'
      template = 'docs\PRODUCT_READY_MONITORING_EVIDENCE_TEMPLATE_2026-06-09.json'
      commands = @('npm run product-ready:monitoring-evidence:preflight', 'npm run product-ready:monitoring-evidence:complete')
      notes = 'Attach deployed monitoring evidence with at least 168 observed hours, scrape/dashboard/alert proof and safety declarations.'
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
      notes = 'Approve only the completed evidence JSON. finalDecision.finalGateSummaryRef is post-run proof after the final gate succeeds.'
    }
    localEvidenceBundle = [pscustomobject]@{
      owner = 'Build/release operator'
      template = 'security-reports\product-ready-local-evidence-bundle\<run>\bundle.json'
      commands = @('npm run product-ready:local-evidence-bundle')
      notes = 'Regenerate the local bundle after local gates change and reference the latest zero-failed bundle.'
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

if ($RefreshLocalBundle) {
  Invoke-CommandCapture -Name 'refresh_acceptance_coverage' -Command 'npm run product-ready:acceptance-coverage' | Out-Null
  Invoke-CommandCapture -Name 'refresh_local_evidence_bundle' -Command 'npm run product-ready:local-evidence-bundle' | Out-Null
}

if (-not (Test-Path -LiteralPath $EvidenceTemplatePath)) {
  throw "External evidence template is missing: $EvidenceTemplatePath"
}

$bundlePath = Get-LatestReadyBundle
$localCoverageSummaryPath = Get-BundledAcceptanceCoverageSummary -BundlePath $bundlePath
$evidence = Get-Content -LiteralPath $EvidenceTemplatePath -Raw | ConvertFrom-Json
$evidence.generatedAt = (Get-Date).ToString('o')
$evidence.localEvidenceBundleRef = Convert-ToRelativePath $bundlePath
$evidence.acceptance.localCoverageReportRef = Convert-ToRelativePath $localCoverageSummaryPath

$draftPath = Join-Path $runDir 'external-evidence.draft.json'
$evidence | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $draftPath -Encoding UTF8

$verifyCommand = "powershell -NoProfile -ExecutionPolicy Bypass -File scripts\product-ready-external-evidence-verify.ps1 -EvidencePath `"$draftPath`""
if ($RequireNoMissing) {
  $verifyCommand = "$verifyCommand -RequireComplete"
}
$verifyStep = Invoke-CommandCapture -Name 'external_evidence_preflight' -Command $verifyCommand -AllowFailure:([bool]$RequireNoMissing)
$externalReport = Get-ExternalEvidenceSummaryForPath -EvidencePath $draftPath

$checks = @($externalReport.summary.checks)
$missingChecks = @($checks | Where-Object { $_.status -ne 'PASS' })
$missingBySection = $missingChecks | Group-Object { Get-SectionName ([string]$_.name) } | Sort-Object Name

$missingPath = Join-Path $runDir 'missing-evidence.md'
$missingJsonPath = Join-Path $runDir 'missing-evidence.json'
$missingLines = [System.Collections.Generic.List[string]]::new()
$missingLines.Add('# Product Ready missing external evidence')
$missingLines.Add('')
$missingLines.Add("- Generated: $((Get-Date).ToString('o'))")
$missingLines.Add("- Draft evidence: $(Convert-ToRelativePath $draftPath)")
$missingLines.Add("- Local evidence bundle: $(Convert-ToRelativePath $bundlePath)")
$missingLines.Add("- Local acceptance coverage: $(Convert-ToRelativePath $localCoverageSummaryPath)")
$missingLines.Add("- Verifier report: $(Convert-ToRelativePath $externalReport.reportPath)")
$missingLines.Add("- Verifier summary: $(Convert-ToRelativePath $externalReport.summaryPath)")
$missingLines.Add("- Machine-readable missing evidence: $(Convert-ToRelativePath $missingJsonPath)")
$missingLines.Add("- Missing checks: $($missingChecks.Count)")
$missingLines.Add('')
$missingLines.Add('This file is an operations handoff. It does not prove Product Ready; it lists the staging/production evidence that must be attached before the complete final gate can pass.')
$missingLines.Add('')

$missingSectionObjects = [System.Collections.Generic.List[object]]::new()
foreach ($section in $missingBySection) {
  $guidance = Get-SectionGuidance -SectionName ([string]$section.Name)
  $missingLines.Add("## $($section.Name)")
  $missingLines.Add('')
  $missingLines.Add('### Collection guidance')
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

$missingLines.Add('## Final command')
$missingLines.Add('')
$missingLines.Add('After the draft evidence JSON is filled with real staging/production references and approvals, run:')
$missingLines.Add('')
$missingLines.Add('```powershell')
$missingLines.Add('npm run product-ready:final-gate:complete')
$missingLines.Add('```')
$missingLines | Set-Content -LiteralPath $missingPath -Encoding UTF8

$missingManifest = [pscustomobject]@{
  schemaVersion = 1
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  draftEvidencePath = Convert-ToRelativePath $draftPath
  localEvidenceBundleRef = Convert-ToRelativePath $bundlePath
  localCoverageReportRef = Convert-ToRelativePath $localCoverageSummaryPath
  verifierReport = Convert-ToRelativePath $externalReport.reportPath
  verifierSummary = Convert-ToRelativePath $externalReport.summaryPath
  missing = $missingChecks.Count
  sections = @($missingSectionObjects)
  finalCommand = 'npm run product-ready:final-gate:complete'
  productReadyMeaning = 'Machine-readable external evidence gap manifest. Product Ready requires zero missing checks and a passing final complete gate.'
}
$missingManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $missingJsonPath -Encoding UTF8

$summary = [pscustomObject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  draftEvidencePath = Convert-ToRelativePath $draftPath
  missingEvidencePath = Convert-ToRelativePath $missingPath
  missingEvidenceJsonPath = Convert-ToRelativePath $missingJsonPath
  localEvidenceBundleRef = Convert-ToRelativePath $bundlePath
  localCoverageReportRef = Convert-ToRelativePath $localCoverageSummaryPath
  verifierReport = Convert-ToRelativePath $externalReport.reportPath
  verifierSummary = Convert-ToRelativePath $externalReport.summaryPath
  verifierPassed = $externalReport.summary.passed
  verifierFailed = $externalReport.summary.failed
  verifierReviewRequired = $externalReport.summary.reviewRequired
  missing = $missingChecks.Count
  refreshLocalBundle = [bool]$RefreshLocalBundle
  requireNoMissing = [bool]$RequireNoMissing
  steps = @($verifyStep)
  verdict = if ($missingChecks.Count -eq 0) {
    'External evidence draft has no missing preflight checks. Run the final complete gate with verified staging/production evidence.'
  } else {
    'External evidence draft is incomplete. Fill the missing evidence before claiming Product Ready.'
  }
}

$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportLines = [System.Collections.Generic.List[string]]::new()
$reportLines.Add('# Product Ready external evidence pack')
$reportLines.Add('')
$reportLines.Add("- Generated: $($summary.generatedAt)")
$reportLines.Add("- Draft evidence: $($summary.draftEvidencePath)")
$reportLines.Add("- Local evidence bundle: $($summary.localEvidenceBundleRef)")
$reportLines.Add("- Local acceptance coverage: $($summary.localCoverageReportRef)")
$reportLines.Add("- Verifier report: $($summary.verifierReport)")
$reportLines.Add("- Missing checks: $($summary.missing)")
$reportLines.Add("- Missing evidence handoff: $($summary.missingEvidencePath)")
$reportLines.Add("- Machine-readable missing evidence: $($summary.missingEvidenceJsonPath)")
$reportLines.Add('')
$reportLines.Add('## Verdict')
$reportLines.Add('')
$reportLines.Add($summary.verdict)
$reportLines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-external-evidence-pack] draft: $draftPath"
Write-Host "[product-ready-external-evidence-pack] missing evidence: $missingPath"
Write-Host "[product-ready-external-evidence-pack] missing evidence json: $missingJsonPath"
Write-Host "[product-ready-external-evidence-pack] report: $reportPath"
Write-Host "[product-ready-external-evidence-pack] summary: $summaryPath"
Write-Host "[product-ready-external-evidence-pack] missing checks: $($missingChecks.Count)"

if ($RequireNoMissing -and $missingChecks.Count -gt 0) {
  exit 1
}
exit 0
