param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-evidence'),
  [switch]$CheckLive
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()
$liveChecks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
  param(
    [string]$Area,
    [string]$Name,
    [bool]$Passed,
    [string]$Evidence,
    [string]$Expected
  )

  $checks.Add([pscustomobject]@{
      area = $Area
      name = $Name
      passed = $Passed
      evidence = $Evidence
      expected = $Expected
    })
}

function Test-RepoPath {
  param([string]$RelativePath)
  $path = Join-Path $WorkspaceRoot $RelativePath
  return Test-Path -LiteralPath $path
}

function Get-RepoContent {
  param([string]$RelativePath)
  $path = Join-Path $WorkspaceRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    return ''
  }
  return Get-Content -LiteralPath $path -Raw
}

function Add-PathCheck {
  param([string]$Area, [string]$RelativePath, [string]$Expected)
  Add-Check -Area $Area -Name $RelativePath -Passed (Test-RepoPath $RelativePath) -Evidence $RelativePath -Expected $Expected
}

function Add-ContentCheck {
  param(
    [string]$Area,
    [string]$RelativePath,
    [string]$Pattern,
    [string]$Expected
  )
  $content = Get-RepoContent $RelativePath
  Add-Check -Area $Area -Name "$RelativePath contains $Pattern" -Passed ($content -match [regex]::Escape($Pattern)) -Evidence $RelativePath -Expected $Expected
}

function Add-ContentRegexCheck {
  param(
    [string]$Area,
    [string]$RelativePath,
    [string]$Pattern,
    [string]$Expected
  )
  $content = Get-RepoContent $RelativePath
  Add-Check -Area $Area -Name "$RelativePath matches $Pattern" -Passed ($content -match $Pattern) -Evidence $RelativePath -Expected $Expected
}

function Add-ContentNotRegexCheck {
  param(
    [string]$Area,
    [string]$RelativePath,
    [string]$Pattern,
    [string]$Expected
  )
  $content = Get-RepoContent $RelativePath
  Add-Check -Area $Area -Name "$RelativePath does not match $Pattern" -Passed ($content -notmatch $Pattern) -Evidence $RelativePath -Expected $Expected
}

function Get-RepoJson {
  param([string]$RelativePath)
  $path = Join-Path $WorkspaceRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    return $null
  }

  try {
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  }
  catch {
    return $null
  }
}

function ConvertTo-StringArray {
  param([object]$Value)
  if ($null -eq $Value) {
    return @()
  }

  if ($Value -is [System.Array]) {
    return @($Value | ForEach-Object { [string]$_ })
  }

  return @([string]$Value)
}

function Test-StringArrayExact {
  param([object]$Actual, [string[]]$Expected)
  $actualValues = @(ConvertTo-StringArray $Actual)
  if ($actualValues.Count -ne $Expected.Count) {
    return $false
  }

  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ($actualValues[$i] -ne $Expected[$i]) {
      return $false
    }
  }

  return $true
}

function Add-JsonArrayExactCheck {
  param(
    [string]$Area,
    [string]$RelativePath,
    [string]$JsonPath,
    [object]$Actual,
    [string[]]$Expected
  )

  $actualValues = @(ConvertTo-StringArray $Actual)
  Add-Check -Area $Area -Name "$RelativePath $JsonPath exact list" `
    -Passed (Test-StringArrayExact -Actual $actualValues -Expected $Expected) `
    -Evidence ($actualValues -join ',') `
    -Expected ($Expected -join ',')
}

function Add-LiveCheck {
  param([string]$Name, [bool]$Passed, [string]$Evidence, [string]$Expected)
  $liveChecks.Add([pscustomobject]@{
      name = $Name
      passed = $Passed
      evidence = $Evidence
      expected = $Expected
    })
}

$processUniqueOutputScripts = @(
  'scripts\audit-hash-chain-verify.ps1',
  'scripts\compliance-golive-decision-verify.ps1',
  'scripts\compliance-golive-export.ps1',
  'scripts\compliance-golive-synthetic-export.ps1',
  'scripts\dr-restore-drill.ps1',
  'scripts\dr-restore-synthetic-drill.ps1',
  'scripts\installer-clean-vm-smoke.ps1',
  'scripts\installer-smoke-preflight.ps1',
  'scripts\monitoring-preflight.ps1',
  'scripts\product-ready-acceptance-coverage-verify.ps1',
  'scripts\product-ready-approvals-verify.ps1',
  'scripts\product-ready-evidence-preflight.ps1',
  'scripts\product-ready-external-evidence-pack.ps1',
  'scripts\product-ready-external-evidence-runbook.ps1',
  'scripts\product-ready-evidence-intake.ps1',
  'scripts\product-ready-evidence-intake-verify.ps1',
  'scripts\product-ready-external-evidence-verify.ps1',
  'scripts\product-ready-final-gate.ps1',
  'scripts\product-ready-local-evidence-bundle.ps1',
  'scripts\product-ready-local-gate.ps1',
  'scripts\product-ready-missing-evidence-verify.ps1',
  'scripts\product-ready-monitoring-evidence-verify.ps1',
  'scripts\product-ready-staging-acceptance-verify.ps1',
  'scripts\security\run-security-gate.ps1',
  'scripts\smoke\run-full-smoke.ps1'
)

$processUniqueTimestampPattern = '\$timestamp\s*=\s*"\$\(Get-Date -Format ''yyyyMMdd-HHmmss-fff''\)-\$PID"'
foreach ($scriptPath in $processUniqueOutputScripts) {
  Add-ContentRegexCheck -Area 'evidence-tooling' -RelativePath $scriptPath -Pattern $processUniqueTimestampPattern `
    -Expected 'Evidence report output directory uses the standard process-unique timestamp format'
}

$staleTimestampPattern = '^\s*\$timestamp\s*=\s*Get-Date\s+-Format\s+[''"]yyyyMMdd-HHmmss(?:-fff)?[''"]'
$staleTimestampScopePattern = '^(scripts\\product-ready-|scripts\\audit-hash-chain-verify\.ps1|scripts\\compliance-golive-|scripts\\dr-restore-|scripts\\installer-|scripts\\monitoring-|scripts\\security\\run-security-gate\.ps1|scripts\\smoke\\run-full-smoke\.ps1)'
$staleTimestampMatches = [System.Collections.Generic.List[string]]::new()
Get-ChildItem -LiteralPath (Join-Path $WorkspaceRoot 'scripts') -Recurse -File -Filter '*.ps1' |
  ForEach-Object {
    $relativePath = $_.FullName.Substring($WorkspaceRoot.Length).TrimStart('\', '/')
    if ($relativePath -notmatch $staleTimestampScopePattern) {
      return
    }

    foreach ($match in Select-String -LiteralPath $_.FullName -Pattern $staleTimestampPattern) {
      $staleTimestampMatches.Add(('{0}:{1}' -f $relativePath, $match.LineNumber))
    }
  }
Add-Check -Area 'evidence-tooling' -Name 'no stale non-process-unique timestamp assignments' `
  -Passed ($staleTimestampMatches.Count -eq 0) `
  -Evidence ($(if ($staleTimestampMatches.Count -eq 0) { 'none' } else { $staleTimestampMatches -join '; ' })) `
  -Expected 'No evidence/security report script uses timestamp-only output directories'

# Product Ready planning and local acceptance evidence.
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_AUDIT_2026-06-09.md' -Expected 'Audit plan and delta document exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' -Expected 'Product Ready critical-flow acceptance coverage manifest exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json' -Expected 'Product Ready staging/production acceptance evidence template exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_APPROVALS_TEMPLATE_2026-06-09.json' -Expected 'Product Ready owner approvals evidence template exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\COMPLIANCE_FLAG_MATRIX_2026-06-09.md' -Expected 'Compliance flag matrix exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\COMPLIANCE_GO_LIVE_DECISION_TEMPLATE_2026-06-09.json' -Expected 'Compliance go-live decision template exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json' -Expected 'Product Ready external evidence template exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md' -Expected 'Product Ready external evidence operator runbook exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'docs\MANUAL_TEST_CHECKLIST.md' -Expected 'Manual acceptance checklist exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\acceptance-test-v2.3.0.ps1' -Expected 'API acceptance script exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-acceptance-coverage-verify.ps1' -Expected 'Product Ready acceptance coverage verifier exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Expected 'Product Ready staging/production acceptance evidence verifier exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-approvals-verify.ps1' -Expected 'Product Ready owner approvals evidence verifier exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Expected 'Product Ready local evidence bundle script exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Expected 'Product Ready final gate aggregator exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Expected 'Product Ready external evidence handoff pack script exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Expected 'Product Ready external evidence operator runbook generator exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-missing-evidence-verify.ps1' -Expected 'Product Ready missing evidence manifest verifier exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"acceptance:local"' -Expected 'Root local acceptance script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"acceptance:local:postgres-lock"' -Expected 'PostgreSQL row-lock acceptance script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"acceptance:local:postgres-seeded"' -Expected 'Seeded PostgreSQL acceptance script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"acceptance:local:flows"' -Expected 'Business flow acceptance script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:acceptance-coverage"' -Expected 'Product Ready acceptance coverage verifier is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:staging-acceptance:preflight"' -Expected 'Product Ready staging acceptance preflight verifier is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:staging-acceptance:complete"' -Expected 'Product Ready staging acceptance fail-closed verifier is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:approvals:preflight"' -Expected 'Product Ready owner approvals preflight verifier is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:approvals:complete"' -Expected 'Product Ready owner approvals fail-closed verifier is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:local-evidence-bundle"' -Expected 'Product Ready local evidence bundle script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:final-gate:preflight"' -Expected 'Product Ready final preflight gate script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:final-gate:complete"' -Expected 'Product Ready final complete gate script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern 'hu.puzzleir.valuta.integration.*Test' -Expected 'Backend business flow tests are wired into local acceptance'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' -Pattern '"offlineSync"' -Expected 'Critical offline sync flow is explicitly mapped'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' -Pattern '"receiptPrint"' -Expected 'Critical receipt print flow is explicitly mapped'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' -Pattern '"transfer"' -Expected 'Critical transfer/átadás-átvétel flow is explicitly mapped'

$criticalAcceptanceFlows = @(
  'buy',
  'sell',
  'conversion',
  'transfer',
  'storno',
  'dayClosing',
  'navCashRegister',
  'receiptPrint',
  'offlineSync'
)
$acceptanceCoverageJson = Get-RepoJson 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json'
$stagingAcceptanceJson = Get-RepoJson 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json'
$externalEvidenceJson = Get-RepoJson 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json'
Add-JsonArrayExactCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' `
  -JsonPath 'requiredFlows' -Actual $acceptanceCoverageJson.requiredFlows -Expected $criticalAcceptanceFlows
Add-JsonArrayExactCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' `
  -JsonPath 'flows[].id' -Actual @($acceptanceCoverageJson.flows | ForEach-Object { $_.id }) -Expected $criticalAcceptanceFlows
Add-JsonArrayExactCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json' `
  -JsonPath 'requiredFlows' -Actual $stagingAcceptanceJson.requiredFlows -Expected $criticalAcceptanceFlows
Add-JsonArrayExactCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json' `
  -JsonPath 'flows[].id' -Actual @($stagingAcceptanceJson.flows | ForEach-Object { $_.id }) -Expected $criticalAcceptanceFlows
Add-JsonArrayExactCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json' `
  -JsonPath 'acceptance.coveredFlows' -Actual $externalEvidenceJson.acceptance.coveredFlows -Expected $criticalAcceptanceFlows

Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json' -Pattern '"requiredFlows"' -Expected 'Staging acceptance template declares required critical flows'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json' -Pattern '"transfer"' -Expected 'Staging acceptance template requires transfer/átadás-átvétel flow evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json' -Pattern '"navCashRegister"' -Expected 'Staging acceptance template includes NAV cash-register flow'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json' -Pattern '"containsSecrets"' -Expected 'Staging acceptance template records secret-safety status'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-acceptance-coverage-verify.ps1' -Pattern 'requiredFlows' -Expected 'Acceptance coverage verifier checks every required critical flow'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'RequirePass' -Expected 'Staging acceptance verifier can fail-closed for Product Ready'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'containsCustomerPersonalData' -Expected 'Staging acceptance verifier checks report PII safety declaration'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'offlineSync' -Expected 'Staging acceptance verifier requires offline sync evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern "'transfer'" -Expected 'Staging acceptance verifier requires transfer/átadás-átvétel evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'Test-DeployedHttpUrl' -Expected 'Staging acceptance verifier rejects localhost/loopback source URLs'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'Test-LoopbackOrWildcardHost' -Expected 'Staging acceptance verifier uses parsed IP loopback/wildcard host rejection'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'IsLoopback' -Expected 'Staging acceptance verifier rejects IPv4/IPv6 loopback addresses'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'IsIPv4MappedToIPv6' -Expected 'Staging acceptance verifier rejects IPv4-mapped IPv6 loopback addresses'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'source.baseUrl deployed-url' -Expected 'External evidence verifier requires deployed staging acceptance source URL checks'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'SHA256' -Expected 'Local evidence bundle records SHA-256 hashes for handoff reports'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'secret pattern scan' -Expected 'Local evidence bundle scans handoff reports for high-confidence secret values'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'stepLogs' -Expected 'Local evidence bundle records local gate step log hashes'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'flyway_validate' -Expected 'Local evidence bundle verifies Flyway validation local gate evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'security_gate' -Expected 'Local evidence bundle verifies the full security gate local step evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'product_ready_staging_acceptance_preflight' -Expected 'Local evidence bundle includes structured staging acceptance preflight report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'product_ready_acceptance_coverage' -Expected 'Local evidence bundle includes the local critical-flow acceptance coverage report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'RequiredLocalGateSummaryPath' -Expected 'Local evidence bundle can fail closed against an explicit current local gate summary'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'product_ready_local_gate current summary path' -Expected 'Local evidence bundle rejects stale local gate summaries when a current summary is required'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'npm run product-ready:local-gate' -Expected 'Final gate runs the local Product Ready gate'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'scripts\product-ready-local-evidence-bundle.ps1 -RequiredLocalGateSummaryPath' -Expected 'Final gate creates a local evidence bundle tied to the current local gate summary'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-ProductReadyLocalGateSummaryFromStepLog' -Expected 'Final gate extracts the current local gate summary path for the local evidence bundle'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'current local_product_ready_gate summary path could not be resolved' -Expected 'Final gate fails closed when the current local gate summary path cannot be resolved'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'current local_product_ready_gate failed; refusing to build a bundle from stale previous reports' -Expected 'Final gate does not build a stale local evidence bundle after a failed local gate'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern '$latestBundle = if ($localBundleStepPassed)' -Expected 'Final gate summary only links a current bundle when the bundle step passed'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern '$latestExternal = if ($externalEvidenceStepAttempted)' -Expected 'Final gate summary only links external verifier reports when the external step ran'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'product-ready-external-evidence-verify.ps1' -Expected 'Final gate runs the external evidence verifier'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'RequireComplete' -Expected 'Final gate can fail-closed on complete external Product Ready evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'ExternalEvidencePath' -Expected 'Final complete gate can verify a filled external evidence JSON artifact'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'PRODUCT_READY_EXTERNAL_EVIDENCE_PATH' -Expected 'Final complete gate can receive the filled evidence path from the environment'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-ExternalEvidenceSummaryForPath' -Expected 'Final gate records the external evidence verifier summary for its scoped evidence file'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-ExternalEvidenceSummaryFromStepLog' -Expected 'Final gate binds the external verifier summary to the current external_evidence_gate log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'external_evidence_gate.log' -Expected 'Final gate refuses ambiguous latest external evidence summaries'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-BundledAcceptanceCoverageSummary' -Expected 'Final gate derives the local coverage summary from the selected local evidence bundle'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'product_ready_acceptance_coverage' -Expected 'Final gate requires the local evidence bundle to contain the acceptance coverage artifact'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'localCoverageReportRef' -Expected 'Final gate injects the current local critical-flow coverage summary into the scoped evidence file'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'externalEvidenceGateSummary' -Expected 'Final gate summary exposes external evidence passed/failed/review counts'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'missingEvidenceSummary' -Expected 'Final gate summary exposes final-gate-scoped missing external evidence handoff paths'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'ConfirmDisposableCleanVm' -Expected 'Final gate missing-evidence operator command requires disposable clean VM confirmation'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'New-FinalGateMissingEvidenceManifest' -Expected 'Final gate writes human and machine-readable missing external evidence manifests'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'section = [string]$section.Name' -Expected 'Final gate missing-evidence manifest repeats the parent section on each listed check'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'if ($null -ne $externalEvidenceGateSummary)' -Expected 'Final gate writes the missing evidence manifest even when complete external evidence verification fails after producing a summary'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'external_evidence_summary_link' -Expected 'Final gate fails closed if the external verifier summary cannot be linked'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'operator_runbook' -Expected 'Final gate writes an operator runbook from the scoped missing external evidence handoff'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-OperatorRunbookSummaryForSource' -Expected 'Final gate links the operator runbook summary for its run directory'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'operatorRunbookSummary' -Expected 'Final gate summary exposes operator runbook paths'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'SourceHandoffDirectory' -Expected 'Operator runbook generator can use the current final-gate handoff before final-gate summary.json exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake.ps1' -Pattern 'operator-intake-checklist.md' -Expected 'Evidence intake generator writes a human fillable checklist'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake.ps1' -Pattern 'evidence-intake.json' -Expected 'Evidence intake generator writes a machine-readable intake package'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake.ps1' -Pattern 'SourceHandoffDirectory' -Expected 'Evidence intake generator can use the current final-gate handoff before final-gate summary.json exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake.ps1' -Pattern 'section = $sectionName' -Expected 'Evidence intake preserves the source manifest section on every check'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake.ps1' -Pattern 'sourceCheckName = $checkName' -Expected 'Evidence intake preserves the source manifest check name for traceability'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake.ps1' -Pattern 'sourceEvidencePath' -Expected 'Evidence intake records the source evidence JSON for final-gate and external-pack handoffs'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake-verify.ps1' -Expected 'Evidence intake structural verifier exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern 'product-ready:evidence-intake:verify' -Expected 'Root package exposes Product Ready evidence intake verification command'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake-verify.ps1' -Pattern 'sourceManifestPath' -Expected 'Evidence intake verifier resolves the source missing evidence manifest'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake-verify.ps1' -Pattern 'sourceEvidencePath' -Expected 'Evidence intake verifier checks the source evidence JSON path'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake-verify.ps1' -Pattern 'sourceCheckName' -Expected 'Evidence intake verifier checks source check name traceability'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake-verify.ps1' -Pattern 'sourceStatus' -Expected 'Evidence intake verifier checks source status traceability'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-evidence-intake-verify.ps1' -Pattern 'Evidence intake structural verifier' -Expected 'Evidence intake verifier distinguishes traceability proof from Product Ready completion'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'evidence_intake' -Expected 'Final gate writes an evidence intake package from the scoped missing evidence handoff'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-EvidenceIntakeSummaryForSource' -Expected 'Final gate links the evidence intake summary for its run directory'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-OperatorRunbookSummaryFromStepLog' -Expected 'Final gate binds the operator runbook summary to the current operator_runbook log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-EvidenceIntakeSummaryFromStepLog' -Expected 'Final gate binds the evidence intake summary to the current evidence_intake log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-EvidenceIntakeVerifySummaryFromStepLog' -Expected 'Final gate binds the intake verifier summary to the current evidence_intake_verify log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'evidenceIntakeSummary' -Expected 'Final gate summary exposes evidence intake paths'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'evidence_intake_verify' -Expected 'Final gate verifies its generated evidence intake package'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'Get-EvidenceIntakeVerifySummaryForPath' -Expected 'Final gate links the evidence intake verifier summary'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'evidenceIntakeVerifySummary' -Expected 'Final gate summary exposes evidence intake verifier results'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern 'product-ready:evidence:intake' -Expected 'Root package exposes Product Ready evidence intake generation command'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json' -Pattern '"localEvidenceBundleRef"' -Expected 'External Product Ready evidence requires the local evidence bundle reference'
Add-ContentNotRegexCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json' -Pattern '"localEvidenceBundleRef"\s*:\s*"security-reports/product-ready-local-evidence-bundle/20[0-9]{6}-[0-9]{6}-[0-9]{3}(?:-[0-9]+)?/bundle\.json"' -Expected 'External evidence template must not contain a stale concrete local evidence bundle run; pack/final-gate inject the current bundle'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json' -Pattern '"transfer"' -Expected 'External Product Ready evidence coveredFlows includes transfer/átadás-átvétel'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json' -Pattern '"reportRef"' -Expected 'External Product Ready evidence approvals section requires the structured approvals report reference'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json' -Pattern '"externalEvidenceRef"' -Expected 'Final Product Ready decision must reference the completed evidence JSON'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json' -Pattern '"finalGateSummaryRef"' -Expected 'Final Product Ready decision can record the successful final gate summary as post-run proof'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-LocalEvidenceBundleChecks' -Expected 'External evidence verifier validates the local evidence bundle internals'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Bundle hash matches current file' -Expected 'External evidence verifier checks bundled report hashes'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'summary content json parse' -Expected 'External evidence verifier parses bundled local artifact summaries, not just bundle metadata'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'summary failed metadata' -Expected 'External evidence verifier cross-checks bundled summary failed values against artifact metadata'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Bundle log hash matches current file' -Expected 'External evidence verifier checks bundled local gate step log hashes'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern "'security_gate'" -Expected 'External evidence verifier requires the bundled security gate step log hash'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern "'staging_acceptance_preflight'" -Expected 'Local evidence bundle captures every default local gate step log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern "'monitoring_evidence_preflight'" -Expected 'Local evidence bundle captures monitoring evidence preflight step log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'installer_smoke_artifacts' -Expected 'Local evidence bundle captures the active installer artifact/synthetic step log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern "'staging_acceptance_preflight'" -Expected 'External evidence verifier requires every default local gate step log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern "'monitoring_evidence_preflight'" -Expected 'External evidence verifier requires monitoring evidence preflight step log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'installer_smoke_artifacts' -Expected 'External evidence verifier requires the active installer artifact/synthetic step log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredFinalEvidenceChecks' -Expected 'External evidence verifier validates finalDecision.externalEvidenceRef content'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredFinalGateSummaryChecks' -Expected 'External evidence verifier validates finalDecision.finalGateSummaryRef content'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'finalDecision temporal consistency' -Expected 'External evidence verifier rejects final decisions dated before prerequisite evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredApprovalsReportChecks' -Expected 'External evidence verifier validates the structured approvals report referenced by approvals.reportRef'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'approvals report reviewRequired' -Expected 'External evidence verifier requires zero review findings in the structured approvals report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern '"approvals.$role.evidenceRef"' -Expected 'External evidence verifier checks each required owner approval evidenceRef inside the structured approvals report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-approvals-verify.ps1' -Pattern 'completedEvidenceRef not template/draft' -Expected 'Approvals verifier rejects template/draft completed evidence references'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-approvals-verify.ps1' -Pattern 'evidenceRef not synthetic/local' -Expected 'Approvals verifier rejects synthetic/local owner approval artifacts'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-approvals-verify.ps1' -Pattern 'Test-TextContainsLoopbackOrWildcardUrl' -Expected 'Approvals verifier rejects loopback/wildcard URLs in approval evidence references'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-approvals-verify.ps1' -Pattern 'IsIPv4MappedToIPv6' -Expected 'Approvals verifier rejects IPv4-mapped IPv6 loopback evidence references'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-approvals-verify.ps1' -Pattern 'verifierContractVersion' -Expected 'Approvals verifier emits a contract version for external evidence freshness'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'approvals report verifier contract version' -Expected 'External evidence verifier rejects stale approvals verifier summaries'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern "Add-StructuredReportReverification -Area 'approvals'" -Expected 'External evidence verifier replays approvals evidence with the current verifier'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'completedEvidenceRef not template/draft' -Expected 'External evidence verifier requires hardened completed evidence reference checks'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'approvals.$role.evidenceRef not synthetic/local' -Expected 'External evidence verifier requires hardened owner approval artifact checks'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-final-gate.ps1' -Pattern 'finalDecision.externalEvidenceRef' -Expected 'Final gate injects the scoped completed evidence JSON reference before verification'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'finalDecision final gate requireComplete' -Expected 'Optional post-run final gate summary proof must be complete when supplied'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Final gate summary points to the completed evidence JSON' -Expected 'Final decision final gate summary must match the completed evidence JSON'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'finalDecision external evidence ref matches current evidence' -Expected 'External evidence verifier requires finalDecision.externalEvidenceRef to point to the current evidence JSON'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'product_ready_staging_acceptance_preflight' -Expected 'External evidence verifier requires bundled structured staging acceptance preflight evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'product_ready_approvals_preflight' -Expected 'External evidence verifier requires bundled structured approvals preflight evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredAcceptanceReportChecks' -Expected 'External evidence verifier validates the structured acceptance report referenced by acceptance.reportRef'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'acceptance report reviewRequired' -Expected 'External evidence verifier requires zero review findings in the structured acceptance report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern '"flows.$flow.evidenceRef"' -Expected 'External evidence verifier checks each critical flow evidenceRef inside the structured acceptance report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'flows.$requiredFlow.evidenceRef not template/draft' -Expected 'Staging acceptance verifier rejects template/draft flow evidence references'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'flows.$requiredFlow.evidenceRef not synthetic/local' -Expected 'Staging acceptance verifier rejects synthetic/local flow evidence references'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'Test-TextContainsLoopbackOrWildcardUrl' -Expected 'Staging acceptance verifier rejects loopback/wildcard URLs in flow evidence references'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Pattern 'verifierContractVersion' -Expected 'Staging acceptance verifier emits a contract version for external evidence freshness'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'acceptance report verifier contract version' -Expected 'External evidence verifier rejects stale staging acceptance verifier summaries'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern "Add-StructuredReportReverification -Area 'acceptance'" -Expected 'External evidence verifier replays staging acceptance evidence with the current verifier'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'flows.$flow.evidenceRef not template/draft' -Expected 'External evidence verifier requires hardened flow evidence template/draft checks'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'flows.$flow.evidenceRef not synthetic/local' -Expected 'External evidence verifier requires hardened flow evidence synthetic/local checks'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredLocalAcceptanceCoverageChecks' -Expected 'External evidence verifier validates the structured local coverage report referenced by acceptance.localCoverageReportRef'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'acceptance local coverage failed' -Expected 'External evidence verifier requires zero failed checks in local acceptance coverage report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'acceptance local coverage $flow pattern evidence' -Expected 'External evidence verifier checks pattern-level local coverage evidence for each critical flow'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredComplianceDecisionReportChecks' -Expected 'External evidence verifier validates the structured compliance decision report referenced by compliance.approvedDecisionRef'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'compliance decision requireApprovedDecision' -Expected 'External evidence verifier requires approved compliance decision gate mode'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern "Add-StructuredCommandReplay -Area 'compliance decision'" -Expected 'External evidence verifier replays approved compliance decisions with the current verifier'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredComplianceExportReportChecks' -Expected 'External evidence verifier validates the structured compliance export report referenced by compliance.exportReportRef'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'compliance export mode' -Expected 'External evidence verifier requires query-mode staging/production compliance export'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'compliance export raw query output exists' -Expected 'External evidence verifier requires raw compliance DB query output next to the structured export summary'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'compliance export raw query row:$flagName' -Expected 'External evidence verifier cross-checks every compliance flag against the raw query output'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Not synthetic evidence' -Expected 'External evidence verifier rejects synthetic compliance export as final proof'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredDrRestoreReportChecks' -Expected 'External evidence verifier validates the structured DR restore report referenced by drRestore.reportRef'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'drRestore report evidence kind' -Expected 'External evidence verifier rejects synthetic DR smoke as final proof'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'drRestore report isolated scratch target confirmed' -Expected 'External evidence verifier requires explicit isolated scratch target confirmation'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'drRestore report audit hash-chain smoke clean' -Expected 'External evidence verifier requires clean DR audit hash-chain smoke evidence'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'drRestore report rowCount.$tableName' -Expected 'External evidence verifier checks critical DR row counts inside the restore report'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredMonitoringReportChecks' -Expected 'External evidence verifier validates the structured monitoring report referenced by monitoring.reportRef'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'monitoring report reviewRequired' -Expected 'External evidence verifier requires zero review findings in the structured monitoring report'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'observation window consistency' -Expected 'Monitoring evidence verifier checks declared hours against observedFrom/observedTo'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'observation window consistency' -Expected 'External evidence verifier requires structured monitoring observation-window consistency'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'checks.alertDelivered' -Expected 'External evidence verifier checks alert delivery inside the structured monitoring report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredSignedInstallerReportChecks' -Expected 'External evidence verifier validates the signed installer artifact report referenced by installer.signedArtifactReportRef'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'installer signed artifact requireSignature' -Expected 'External evidence verifier requires signed installer artifact verification to run with RequireSignature'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'installer artifact authenticode signature' -Expected 'External evidence verifier checks Authenticode signature PASS results for all installer artifacts'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern "Add-StructuredCommandReplay -Area 'installer signed artifact'" -Expected 'External evidence verifier replays signed installer artifact verification with the current verifier'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'Add-StructuredCleanVmInstallerReportChecks' -Expected 'External evidence verifier validates the clean Windows VM installer report referenced by installer.cleanVmReportRef'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'installer clean VM executeInstall' -Expected 'External evidence verifier requires clean VM smoke to run with ExecuteInstall'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'installer clean VM confirmDisposableCleanVm' -Expected 'External evidence verifier requires explicit disposable clean VM confirmation'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'runtime secret scan:' -Expected 'External evidence verifier checks runtime secret scan PASS evidence from clean VM smoke'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\repository\WorkerRepositoryPostgresLockIT.java' -Expected 'PostgreSQL pessimistic row-lock integration test exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\integration\SeededPostgresAcceptanceIT.java' -Expected 'Seeded PostgreSQL business acceptance integration test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\pom.xml' -Pattern 'org.testcontainers' -Expected 'Testcontainers is available for PostgreSQL integration evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\repository\WorkerRepositoryPostgresLockIT.java' -Pattern 'lock_timeout' -Expected 'PostgreSQL lock test proves the second transaction cannot acquire the row lock'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\integration\SeededPostgresAcceptanceIT.java' -Pattern 'seededPostgresBuySellAndDaySessionRoundTrip' -Expected 'Seeded PostgreSQL test covers buy/sell/day-session round-trip'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\integration\SeededPostgresAcceptanceIT.java' -Pattern 'receiptLookupIsCompanyScopedOnSeededPostgresData' -Expected 'Seeded PostgreSQL test covers company-scoped receipt lookup'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' -Pattern 'SeededPostgresAcceptanceIT.java' -Expected 'Acceptance coverage manifest includes seeded PostgreSQL business-flow evidence'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\integration\TransactionFlowTest.java' -Expected 'Transaction buy/sell flow test exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\integration\AmlFlowTest.java' -Expected 'AML flow test exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\integration\ClosingFlowTest.java' -Expected 'Closing flow test exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\DailyClosingMissedAlertService.java' -Expected 'Daily closing missed P0 alert service exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\config\DailyClosingMissedAlertScheduler.java' -Expected 'Daily closing missed P0 alert scheduler exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\DailyClosingMissedAlertServiceTest.java' -Expected 'Daily closing missed alert regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\config\DailyClosingMissedAlertScheduler.java' -Pattern '@Scheduled(cron = "0 30 8 * * *", zone = "Europe/Budapest")' -Expected 'Daily closing missed alert runs daily in Budapest time'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\DailyClosingMissedAlertService.java' -Pattern 'DAILY_CLOSING_MISSED_ALERT' -Expected 'Daily closing missed alert writes a dedicated audit action'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\DailyClosingMissedAlertService.java' -Pattern 'existsByActionAndReferenceForCompany' -Expected 'Daily closing missed alert is idempotent per company and date'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\DailyClosingMissedAlertService.java' -Pattern 'findSupervisorsAndAbove' -Expected 'Daily closing missed alert notifies company supervisors/managers/admins'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\repository\BranchRepository.java' -Pattern 'findActiveClosingMonitoredBranches' -Expected 'Daily closing missed alert uses an explicit system-level branch scope'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern 'DailyClosingMissedAlertServiceTest' -Expected 'Daily closing missed alert test is wired into local backend acceptance'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' -Pattern 'DailyClosingMissedAlertServiceTest.java' -Expected 'Day closing critical-flow coverage includes missed-closing alert proof'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\dto\customer\CreateCustomerDto.java' -Pattern 'private Boolean isPep;' -Expected 'Customer create DTO carries explicit PEP status'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\dto\customer\CustomerDto.java' -Pattern 'private Boolean isPep;' -Expected 'Customer response DTO exposes explicit PEP status'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\mapper\CustomerMapper.java' -Pattern '.isPep(dto.getIsPep())' -Expected 'Customer mapper transfers explicit PEP status from create/update DTOs'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\CustomerService.java' -Pattern 'customer.setIsPep(request.getIsPep())' -Expected 'Customer update persists explicit PEP status'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\CustomerServiceTest.java' -Pattern 'createCustomer — PEP státusz perzisztálódik' -Expected 'CustomerService regression test covers PEP persistence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern 'CustomerServiceTest' -Expected 'CustomerService regression test is wired into local backend acceptance'
Add-PathCheck -Area 'acceptance' -RelativePath 'frontend-react\src\utils\privacyNotice.ts' -Expected 'Frontend privacy notice acknowledgement helper exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\utils\privacyNotice.ts' -Pattern 'ADATKEZELESI_TAJEKOZTATO_ACK' -Expected 'Privacy notice acknowledgement writes an audit-friendly marker'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\customers\CustomerCreatePage.tsx' -Pattern 'customer-is-pep-select' -Expected 'Customer create form requires an explicit PEP choice'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\customers\CustomerCreatePage.tsx' -Pattern 'customer-privacy-notice-checkbox' -Expected 'Customer create form requires privacy notice acknowledgement'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\customers\CustomerDetailPage.tsx' -Pattern 'customer-detail-is-pep-select' -Expected 'Customer detail/edit form exposes PEP status'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\transactions\components\CustomerPanel.tsx' -Pattern 'customer-privacy-notice-checkbox' -Expected 'Transaction manual customer entry requires privacy notice acknowledgement'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\customers\CustomerCreatePage.test.tsx' -Pattern 'ADATKEZELESI_TAJEKOZTATO_ACK v2026-06-09' -Expected 'Customer create test proves privacy acknowledgement is sent in the payload'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\transactions\components\CustomerPanel.test.tsx' -Pattern 'ADATKEZELESI_TAJEKOZTATO_ACK v2026-06-09' -Expected 'Transaction customer panel test proves privacy acknowledgement is sent in the payload'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\integration\RateCalculationIntegrationTest.java' -Expected 'Rate calculation flow test exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\integration\TradeFlowTest.java' -Expected 'Trade flow test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"compliance:flags:test"' -Expected 'Compliance flag regression script is wired'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\compliance-golive-export.ps1' -Expected 'Compliance go-live parameter export script exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\compliance-golive-synthetic-export.ps1' -Expected 'Compliance go-live synthetic DB export script exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\compliance-golive-decision-verify.ps1' -Expected 'Compliance go-live decision verifier exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Expected 'Product Ready external evidence verifier exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"compliance:golive:preflight"' -Expected 'Compliance go-live preflight script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"compliance:golive:export"' -Expected 'Compliance go-live DB export script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"compliance:golive:synthetic"' -Expected 'Compliance go-live synthetic export script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"compliance:golive:decision:preflight"' -Expected 'Compliance go-live decision preflight script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"compliance:golive:decision:approved"' -Expected 'Compliance go-live approved decision gate is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:external-evidence:preflight"' -Expected 'Product Ready external evidence preflight script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:external-evidence:complete"' -Expected 'Product Ready external evidence complete gate is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:external-evidence:pack"' -Expected 'Product Ready external evidence handoff pack script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:external-evidence:pack:refresh"' -Expected 'Product Ready external evidence pack refresh script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:external-evidence:pack:complete"' -Expected 'Product Ready external evidence pack fail-closed script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:missing-evidence:verify"' -Expected 'Product Ready missing evidence manifest verifier is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:missing-evidence:closed"' -Expected 'Product Ready missing evidence manifest fail-closed verifier is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:external-evidence:runbook"' -Expected 'Product Ready external evidence operator runbook generator is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:external-evidence:runbook:refresh"' -Expected 'Product Ready external evidence operator runbook refresh generator is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\compliance-golive-export.ps1' -Pattern 'UseDockerTools' -Expected 'Compliance go-live export can use Dockerized psql'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\compliance-golive-decision-verify.ps1' -Pattern 'RequireApprovedDecision' -Expected 'Compliance decision verifier can fail-closed for Product Ready approval'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\compliance-golive-decision-verify.ps1' -Pattern 'approvedByCompliance' -Expected 'Compliance decision verifier requires compliance approver evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'RequireComplete' -Expected 'External evidence verifier can fail-closed for final Product Ready proof'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'observationHours' -Expected 'External evidence verifier requires the monitoring observation window'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'criticalFlowsPassed' -Expected 'External evidence verifier requires staging/production critical flow acceptance evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'missing-evidence.md' -Expected 'External evidence pack writes an operations handoff missing-evidence checklist'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'missing-evidence.json' -Expected 'External evidence pack writes a machine-readable missing-evidence manifest'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'section = [string]$section.Name' -Expected 'External evidence pack missing manifest repeats the parent section on each listed check'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'Collection guidance' -Expected 'External evidence pack adds section-level evidence collection guidance'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'Get-ExternalEvidenceSummaryForPath' -Expected 'External evidence pack links verifier summary by exact evidencePath'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'Machine-readable external evidence gap manifest' -Expected 'External evidence pack labels the JSON manifest product-ready meaning'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'localEvidenceBundleRef' -Expected 'External evidence pack injects the current local bundle reference into the draft'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'Get-BundledAcceptanceCoverageSummary' -Expected 'External evidence pack derives the local coverage summary from the selected local evidence bundle'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'product_ready_acceptance_coverage' -Expected 'External evidence pack requires the local evidence bundle to contain the acceptance coverage artifact'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'ConfirmDisposableCleanVm' -Expected 'External evidence pack operator command requires disposable clean VM confirmation'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'refresh_acceptance_coverage' -Expected 'External evidence pack refresh mode regenerates local critical-flow coverage before drafting evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'localCoverageReportRef' -Expected 'External evidence pack injects the current local critical-flow coverage summary into the draft'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'RequireNoMissing' -Expected 'External evidence pack can fail-closed when missing evidence remains'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern '-RequireComplete' -Expected 'External evidence pack complete mode runs the verifier fail-closed'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-missing-evidence-verify.ps1' -Pattern 'RequireClosed' -Expected 'Missing evidence manifest verifier can fail-closed when missing checks remain'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-missing-evidence-verify.ps1' -Pattern '$PID' -Expected 'Missing evidence verifier uses process-unique output directories'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-missing-evidence-verify.ps1' -Pattern 'product-ready-final-gate' -Expected 'Missing evidence verifier can inspect final-gate-scoped missing evidence manifests'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-missing-evidence-verify.ps1' -Pattern 'finalGateEvidencePath' -Expected 'Missing evidence verifier accepts final-gate evidence source references'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-missing-evidence-verify.ps1' -Pattern 'missing total matches section missing counts' -Expected 'Missing evidence manifest verifier checks section missing totals'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-missing-evidence-verify.ps1' -Pattern 'Nested check carries its parent section name' -Expected 'Missing evidence manifest verifier rejects section-less nested checks'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-missing-evidence-verify.ps1' -Pattern 'Missing evidence manifest structural verifier' -Expected 'Missing evidence manifest verifier distinguishes structural proof from Product Ready proof'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md' -Pattern 'Do not paste secrets' -Expected 'External evidence runbook warns against secret leakage'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md' -Pattern 'npm run product-ready:final-gate:complete' -Expected 'External evidence runbook points to the final fail-closed Product Ready gate'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md' -Pattern 'PRODUCT_READY_EXTERNAL_EVIDENCE_PATH' -Expected 'External evidence runbook shows how to pass the filled evidence JSON into the final gate'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md' -Pattern 'transfer;' -Expected 'External evidence runbook explicitly lists transfer/átadás-átvétel as required staging acceptance flow'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md' -Pattern 'acceptance.coveredFlows' -Expected 'External evidence runbook tells operators to fill the coveredFlows list'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md' -Pattern 'acceptance.localCoverageReportRef' -Expected 'External evidence runbook documents the local critical-flow coverage reference'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md' -Pattern 'product-ready:external-evidence:pack:refresh' -Expected 'External evidence runbook points operators to the pack refresh command that injects local bundle and coverage refs'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-pack.ps1' -Pattern 'conversion, transfer, storno' -Expected 'External evidence pack handoff guidance explicitly includes transfer/átadás-átvétel in critical flow list'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'Evidence JSON field map' -Expected 'External evidence runbook generator creates a JSON pointer field map'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'ExternalEvidencePath' -Expected 'External evidence runbook generator includes the direct final gate evidence path command'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'missing-evidence.md' -Expected 'External evidence runbook generator includes the latest missing-evidence handoff'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'missing-evidence.json' -Expected 'External evidence runbook generator links the machine-readable missing-evidence manifest'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern '(Test-Path -LiteralPath $missingJsonPath)' -Expected 'External evidence runbook generator accepts only pack handoffs with machine-readable missing-evidence manifests'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'Get-LatestFinalGateHandoff' -Expected 'External evidence runbook generator prefers final-gate-scoped missing evidence handoffs'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'sourceHandoffType' -Expected 'External evidence runbook summary records whether the source handoff came from final gate or the pack'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'external-evidence.final-gate.json' -Expected 'External evidence runbook can link final-gate scoped evidence JSON artifacts'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'RefreshPack' -Expected 'External evidence runbook generator can refresh the source evidence pack'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern '/finalDecision/externalEvidenceRef' -Expected 'External evidence runbook field map includes final decision completed evidence reference'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern '/finalDecision/finalGateSummaryRef' -Expected 'External evidence runbook field map includes final decision final gate summary reference'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern '/acceptance/coveredFlows' -Expected 'External evidence runbook field map includes acceptance coveredFlows'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern 'Optional post-run successful product-ready:final-gate:complete summary.json ref' -Expected 'External evidence runbook marks final gate summary as post-run proof, not same-run prerequisite'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-external-evidence-runbook.ps1' -Pattern '/approvals/reportRef' -Expected 'External evidence runbook field map includes structured approvals report reference'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\audit-hash-chain-verify.ps1' -Expected 'Audit hash-chain verification script exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\AuditLogServiceHashChainTest.java' -Expected 'Legacy audit helper hash-chain regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"audit:hash-chain:test"' -Expected 'Audit hash-chain regression test script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"audit:hash-chain:preflight"' -Expected 'Audit hash-chain preflight script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"audit:hash-chain:verify"' -Expected 'Audit hash-chain DB verification script is wired'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\installer-smoke-preflight.ps1' -Expected 'Installer smoke preflight script exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\installer-smoke-synthetic-artifacts.ps1' -Expected 'Installer synthetic artifact smoke script exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\installer-clean-vm-smoke.ps1' -Expected 'Clean Windows VM installer smoke script exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"installer:smoke:preflight"' -Expected 'Installer smoke preflight script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"installer:smoke:signed"' -Expected 'Installer signed artifact verification script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"installer:smoke:synthetic"' -Expected 'Installer synthetic artifact smoke script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"installer:smoke:clean-vm"' -Expected 'Clean Windows VM installer smoke script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\installer-smoke-preflight.ps1' -Pattern 'Get-FileHash' -Expected 'Installer artifact verification generates SHA-256 evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\installer-smoke-preflight.ps1' -Pattern 'RequireSignature' -Expected 'Installer smoke can fail-closed on missing signed release artifact evidence'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\installer-smoke-preflight.ps1' -Pattern 'Get-AuthenticodeSignature' -Expected 'Installer smoke verifies Authenticode signature status'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\installer-smoke-preflight.ps1' -Pattern 'packaged forbidden secret filenames' -Expected 'Installer smoke scans packaged resources for forbidden secret filenames'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\installer-smoke-preflight.ps1' -Pattern 'asar text secret patterns' -Expected 'Installer smoke scans app.asar text files for high-confidence secret patterns'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\installer-clean-vm-smoke.ps1' -Pattern 'AcceptVmMutation' -Expected 'Clean VM smoke requires explicit mutation acknowledgement'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\installer-clean-vm-smoke.ps1' -Pattern 'ConfirmDisposableCleanVm' -Expected 'Clean VM smoke requires explicit disposable clean VM confirmation'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\installer-clean-vm-smoke.ps1' -Pattern 'runtime secret scan' -Expected 'Clean VM smoke scans installed files/logs/userData for secret leakage'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"package:penztar"' -Expected 'Root penztar installer package script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"package:kozponti"' -Expected 'Root kozponti installer package script is wired'
Add-PathCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-gate.ps1' -Expected 'Product Ready local gate aggregator exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"product-ready:local-gate"' -Expected 'Product Ready local gate script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"migration:flyway:validate"' -Expected 'Flyway migration naming/version validation script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern '"migration:flyway:content-audit:product-ready"' -Expected 'Product Ready Flyway content audit script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-gate.ps1' -Pattern 'flyway_validate' -Expected 'Product Ready local gate runs Flyway validation'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-gate.ps1' -Pattern 'flyway_content_audit' -Expected 'Product Ready local gate runs Flyway content audit'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-gate.ps1' -Pattern 'security_gate' -Expected 'Product Ready local gate runs the full security gate'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-gate.ps1' -Pattern 'scripts/security/run-security-gate.ps1' -Expected 'Product Ready local gate executes the repository security gate script'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\dev-tools\flyway-content-audit.py' -Pattern '--fail-severity' -Expected 'Flyway content audit supports Product Ready severity threshold'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\dev-tools\flyway-content-audit.py' -Pattern 'DROP-INDEX' -Expected 'Flyway content audit flags DROP INDEX constraint/index drift risk'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-gate.ps1' -Pattern 'staging_acceptance_preflight' -Expected 'Product Ready local gate runs structured staging acceptance preflight'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-gate.ps1' -Pattern 'approvals_preflight' -Expected 'Product Ready local gate runs structured owner approvals preflight'
Add-ContentCheck -Area 'acceptance' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'product_ready_approvals_preflight' -Expected 'Local evidence bundle includes structured owner approvals preflight report'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\package.json' -Pattern '"test:e2e:smoke"' -Expected 'Frontend Playwright smoke script is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\playwright.config.ts' -Pattern 'PLAYWRIGHT_E2E_PORT' -Expected 'Frontend Playwright smoke port can be isolated from the default dev server port'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\playwright.config.ts' -Pattern '--strictPort' -Expected 'Frontend Playwright smoke fails deterministically if the configured E2E port is occupied'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\playwright.config.ts' -Pattern '3100' -Expected 'Frontend Playwright smoke uses a dedicated default E2E port instead of the normal 3000 dev port'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\e2e\smoke.spec.ts' -Pattern 'toBeGreaterThan(0)' -Expected 'Frontend Playwright smoke asserts that at least one interactive login UI element rendered'
Add-ContentNotRegexCheck -Area 'acceptance' -RelativePath 'frontend-react\e2e\smoke.spec.ts' -Pattern 'toBeGreaterThanOrEqual\s*\(\s*0\s*\)' -Expected 'Frontend Playwright smoke must not use a tautological non-negative element-count assertion'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\e2e\smoke.spec.ts' -Pattern 'unexpectedUnauthorizedResponses' -Expected 'Frontend Playwright smoke rejects unexpected 401 browser responses'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\e2e\smoke.spec.ts' -Pattern 'isExpectedUnauthenticatedResourceError' -Expected 'Frontend Playwright smoke only suppresses the known unauthenticated refresh-cookie browser console noise'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\e2e\smoke.spec.ts' -Pattern 'expect(criticalErrors).toEqual([])' -Expected 'Frontend Playwright smoke rejects every critical browser console error'
Add-ContentNotRegexCheck -Area 'acceptance' -RelativePath 'frontend-react\e2e\smoke.spec.ts' -Pattern 'toBeLessThanOrEqual\s*\(\s*2\s*\)' -Expected 'Frontend Playwright smoke must not allow critical browser console errors'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\dto\cashregister\CashRegisterCommandRequest.java' -Expected 'Explicit NAV cash-register command request DTO exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\CashRegisterService.java' -Pattern 'DAY_OPEN_COMMAND = NAV_AEE_NAMESPACE + "|OP"' -Expected 'Cash-register day-open uses legacy NAV command payload'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\CashRegisterService.java' -Pattern 'CURRENCY_LIST_SET_COMMAND' -Expected 'Cash-register currency-list load command is implemented'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\controller\CashRegisterController.java' -Pattern '"/command"' -Expected 'Cash-register explicit command endpoint is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\CashRegisterServiceTest.java' -Pattern 'executeCommandCurrencyListSetBuildsDeterministicLegacyPayload' -Expected 'Cash-register explicit command regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\controller\CashRegisterControllerTest.java' -Pattern 'executeCommand_returns502WhenEventContainsErrorStatus' -Expected 'Cash-register command controller fail-closed regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern 'CashRegisterServiceTest,CashRegisterControllerTest,NavIntegrationServiceTest' -Expected 'Cash-register NAV command tests are wired into local backend acceptance'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\resources\db\migration\V301__bank_api_config.sql' -Expected 'Bank API config migration exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\entity\BankApiConfig.java' -Expected 'Bank API config entity exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\controller\BankApiConfigController.java' -Expected 'Bank API admin config controller exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\entity\BankApiConfig.java' -Pattern 'EncryptedStringConverter' -Expected 'Bank API client secret is encrypted at persistence boundary'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\dto\bankapi\BankApiConfigDto.java' -Pattern 'clientSecretConfigured' -Expected 'Bank API config DTO masks secret value'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\RaiffeisenRateService.java' -Pattern 'REST_PRIMARY_WITH_HTML_FALLBACK' -Expected 'Raiffeisen REST mode explicitly falls back until bank contract is proven'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\RaiffeisenRateService.java' -Pattern 'recordRun' -Expected 'Raiffeisen fetch writes last-run status'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\controller\BankIntegrationStatusController.java' -Pattern 'lastRunStatus' -Expected 'Bank integration monitoring exposes Raiffeisen last-run status'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\BankApiConfigServiceTest.java' -Pattern 'toDto_masksClientSecret' -Expected 'Bank API config secret masking regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\RaiffeisenRateServiceConfigTest.java' -Pattern 'fetchAndCacheRates_recordsSuccess' -Expected 'Raiffeisen config/status regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\controller\BankApiConfigControllerTest.java' -Pattern 'list_doesNotExposeSecret' -Expected 'Bank API config controller secret masking test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern 'BankApiConfigServiceTest,RaiffeisenRateServiceConfigTest,BankApiConfigControllerTest' -Expected 'Bank API config tests are wired into local backend acceptance'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\resources\db\migration\V302__profit_log_compensation_key.sql' -Expected 'WAC profit compensation idempotency migration exists'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\resources\db\migration\V303__transfer_serial_sequence.sql' -Expected 'Transfer serial sequence migration exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\WacService.java' -Pattern 'compensation_key' -Expected 'WAC reversal compensation writes idempotency key'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\TransactionReversalService.java' -Pattern 'recordReversalCompensationIfEnabled(origId, compensationId' -Expected 'Storno/refund WAC compensation is tied to the concrete compensating transaction'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\WacServiceTest.java' -Pattern 'sameCompensationTransaction_skipsDuplicate' -Expected 'WAC duplicate compensation regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'package.json' -Pattern 'WacServiceTest,TransactionReversalServiceTest' -Expected 'WAC/storno profit tests are wired into local backend acceptance'
Add-PathCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\dto\receipt\CancelledTransactionReceiptRequest.java' -Expected 'MEGSEM cancelled-transaction receipt DTO exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\controller\ReceiptController.java' -Pattern '/cancelled-transaction' -Expected 'MEGSEM cancelled-transaction receipt endpoint is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\ReceiptService.java' -Pattern 'CANCELLED_TRANSACTION_RECEIPT_CREATED' -Expected 'MEGSEM cancelled receipt writes audit log'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\services\api\transactions.ts' -Pattern 'createCancelledTransaction' -Expected 'Frontend MEGSEM receipt API wrapper is wired'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\transactions\CashierTransactionPage.tsx' -Pattern 'receiptApi.createCancelledTransaction' -Expected 'Cashier MEGSEM flow records cancelled receipt'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\transactions\TransactionPage.tsx' -Pattern 'receiptApi.createCancelledTransaction' -Expected 'Legacy transaction MEGSEM flow records cancelled receipt'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\receipts\ReceiptPage.tsx' -Pattern 'CANCELLED_TRANSACTION' -Expected 'Receipt browser labels/filters MEGSEM receipts'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\types\receipt.ts' -Pattern 'cancelled_transaction' -Expected 'MEGSEM print job type is part of frontend receipt contract'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\receipts\ReceiptPage.tsx' -Pattern 'buildCancelledTransactionPrintData' -Expected 'MEGSEM server receipt is mapped to physical print data'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\components\electron\ReceiptPreviewModal.tsx' -Pattern 'cancelled_transaction' -Expected 'MEGSEM receipt preview renders dedicated print block'
Add-ContentCheck -Area 'acceptance' -RelativePath 'penztar-client\electron\printer.ts' -Pattern 'generateCancelledTransactionLines' -Expected 'Electron printer renders MEGSEM ESC/POS content'
Add-ContentCheck -Area 'acceptance' -RelativePath 'penztar-client\electron\serial-printer.ts' -Pattern 'cancelled_transaction' -Expected 'Serial printer renders MEGSEM content'
Add-ContentCheck -Area 'acceptance' -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\ReceiptServiceB7Test.java' -Pattern 'createCancelledTransactionReceipt_persistsStandaloneReceiptAndAudit' -Expected 'MEGSEM receipt backend regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\services\api\transactions.test.ts' -Pattern '/receipts/cancelled-transaction' -Expected 'MEGSEM receipt frontend API regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\services\api\transactions.test.ts' -Pattern '/transfers/77/storno' -Expected 'Transfer storno frontend API regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\services\api\transactions.test.ts' -Pattern '/transfers/77/storno-preview' -Expected 'Transfer storno preview frontend API regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\transfers\TransferPage.tsx' -Pattern 'transferApi.getStornoPreview' -Expected 'Transfer storno UI loads server-side preview before confirmation'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\transfers\TransferPage.tsx' -Pattern 'stornoPreviewRequestRef' -Expected 'Transfer storno UI ignores stale preview responses'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\transfers\TransferPage.tsx' -Pattern 'stornoTarget.stornoSerialNumber ?? `${stornoTarget.transferNumber}-SZ`' -Expected 'Transfer storno UI displays server preview serial with local fallback'
Add-ContentCheck -Area 'acceptance' -RelativePath 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json' -Pattern 'npm --prefix frontend-react test -- --run src/services/api/transactions.test.ts' -Expected 'Storno acceptance coverage lists the frontend API regression command'
Add-ContentCheck -Area 'acceptance' -RelativePath 'frontend-react\src\pages\receipts\ReceiptPage.types.test.ts' -Pattern 'buildCancelledTransactionPrintData' -Expected 'MEGSEM print data mapping regression test exists'
Add-ContentCheck -Area 'acceptance' -RelativePath 'penztar-client\electron\__tests__\printer.test.ts' -Pattern 'cancelled_transaction' -Expected 'MEGSEM Electron printer regression test exists'

# DR and backup evidence.
Add-PathCheck -Area 'dr' -RelativePath 'docs\operations\dr-backup-runbook.md' -Expected 'DR/backup runbook exists'
Add-PathCheck -Area 'dr' -RelativePath 'scripts\dr-restore-drill.ps1' -Expected 'DR restore drill evidence script exists'
Add-PathCheck -Area 'dr' -RelativePath 'scripts\dr-restore-synthetic-drill.ps1' -Expected 'Synthetic Docker DR restore drill script exists'
Add-ContentCheck -Area 'dr' -RelativePath 'package.json' -Pattern '"dr:restore:preflight"' -Expected 'DR restore drill preflight script is wired'
Add-ContentCheck -Area 'dr' -RelativePath 'package.json' -Pattern '"dr:restore:synthetic"' -Expected 'Synthetic DR restore drill script is wired'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\dr-restore-drill.ps1' -Pattern 'UseDockerTools' -Expected 'DR restore drill can use Dockerized PostgreSQL client tools'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\dr-restore-drill.ps1' -Pattern 'EvidenceKind' -Expected 'DR restore drill labels plan-only, synthetic, and real backup evidence separately'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\dr-restore-drill.ps1' -Pattern 'ConfirmIsolatedScratchTarget' -Expected 'DR restore drill requires explicit isolated scratch target confirmation in execute mode'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\dr-restore-synthetic-drill.ps1' -Pattern 'minimal-dr.sql' -Expected 'Synthetic drill creates a minimal restore dump'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\dr-restore-synthetic-drill.ps1' -Pattern 'synthetic-tooling-smoke' -Expected 'Synthetic DR drill labels its report as tooling smoke, not final Product Ready proof'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\dr-restore-drill.ps1' -Pattern "SELECT 'transactions='" -Expected 'DR restore drill reports transactions row count using final evidence schema naming'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\dr-restore-drill.ps1' -Pattern "SELECT 'customer='" -Expected 'DR restore drill reports customer row count'
Add-ContentCheck -Area 'dr' -RelativePath 'scripts\dr-restore-synthetic-drill.ps1' -Pattern 'CREATE TABLE customer' -Expected 'Synthetic DR drill exercises the customer row-count proof path'
Add-PathCheck -Area 'dr' -RelativePath 'deploy\hetzner\scripts\backup-pg.sh' -Expected 'Hetzner pg_dump backup script exists'
Add-PathCheck -Area 'dr' -RelativePath 'deploy\hetzner\scripts\setup-backup.sh' -Expected 'Hetzner backup installer exists'
Add-PathCheck -Area 'dr' -RelativePath 'deploy\hetzner\systemd\valuta-backup.service' -Expected 'Backup systemd service exists'
Add-PathCheck -Area 'dr' -RelativePath 'deploy\hetzner\systemd\valuta-backup.timer' -Expected 'Backup systemd timer exists'
Add-PathCheck -Area 'dr' -RelativePath 'deploy\hetzner\backup\install-b2-backup.sh' -Expected 'Backblaze B2 backup installer exists'
Add-ContentCheck -Area 'dr' -RelativePath 'docs\operations\dr-backup-runbook.md' -Pattern 'pg_restore' -Expected 'Restore command is documented'
Add-ContentCheck -Area 'dr' -RelativePath 'docs\operations\dr-backup-runbook.md' -Pattern 'audit_log' -Expected 'Audit-log restore/hash-chain check is documented'
Add-ContentCheck -Area 'dr' -RelativePath 'docs\operations\dr-backup-runbook.md' -Pattern 'flyway_schema_history' -Expected 'Flyway state check is documented'
Add-PathCheck -Area 'dr' -RelativePath 'deploy\hetzner\ha\failover-to-standby.sh' -Expected 'Failover script exists'
Add-PathCheck -Area 'dr' -RelativePath 'deploy\hetzner\ha\README.md' -Expected 'HA/failover README exists'

# Monitoring evidence.
Add-PathCheck -Area 'monitoring' -RelativePath 'docs\operations\monitoring-runbook.md' -Expected 'Monitoring runbook exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'docs\PRODUCT_READY_MONITORING_EVIDENCE_TEMPLATE_2026-06-09.json' -Expected 'Product Ready deployed monitoring evidence template exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'scripts\monitoring-preflight.ps1' -Expected 'Monitoring preflight evidence script exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'scripts\monitoring-synthetic-check.ps1' -Expected 'Monitoring synthetic validation script exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Expected 'Product Ready deployed monitoring evidence verifier exists'
Add-ContentCheck -Area 'monitoring' -RelativePath 'package.json' -Pattern '"monitoring:preflight"' -Expected 'Monitoring preflight script is wired'
Add-ContentCheck -Area 'monitoring' -RelativePath 'package.json' -Pattern '"monitoring:synthetic"' -Expected 'Monitoring synthetic validation script is wired'
Add-ContentCheck -Area 'monitoring' -RelativePath 'package.json' -Pattern '"product-ready:monitoring-evidence:preflight"' -Expected 'Product Ready monitoring evidence preflight script is wired'
Add-ContentCheck -Area 'monitoring' -RelativePath 'package.json' -Pattern '"product-ready:monitoring-evidence:complete"' -Expected 'Product Ready monitoring evidence fail-closed script is wired'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-local-gate.ps1' -Pattern 'monitoring_evidence_preflight' -Expected 'Product Ready local gate runs structured monitoring evidence preflight'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-local-evidence-bundle.ps1' -Pattern 'product_ready_monitoring_evidence_preflight' -Expected 'Local evidence bundle includes structured monitoring evidence preflight report'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'product_ready_monitoring_evidence_preflight' -Expected 'External evidence verifier requires bundled structured monitoring evidence preflight'
Add-ContentCheck -Area 'monitoring' -RelativePath 'docs\PRODUCT_READY_MONITORING_EVIDENCE_TEMPLATE_2026-06-09.json' -Pattern '"observationHours"' -Expected 'Monitoring evidence template records the observation window'
Add-ContentCheck -Area 'monitoring' -RelativePath 'docs\PRODUCT_READY_MONITORING_EVIDENCE_TEMPLATE_2026-06-09.json' -Pattern '"alertDelivered"' -Expected 'Monitoring evidence template records alert delivery proof'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'RequirePass' -Expected 'Monitoring evidence verifier can fail-closed for Product Ready'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'clientErrorLogObservable' -Expected 'Monitoring evidence verifier checks client error log observability'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'Test-DeployedHttpUrl' -Expected 'Monitoring evidence verifier rejects localhost/loopback monitoring URLs'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'Test-LoopbackOrWildcardHost' -Expected 'Monitoring evidence verifier uses parsed IP loopback/wildcard host rejection'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'Test-TextContainsLoopbackOrWildcardUrl' -Expected 'Monitoring evidence verifier rejects loopback/wildcard URLs in deployment references'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'verifierContractVersion' -Expected 'Monitoring evidence verifier emits a contract version for external evidence freshness'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'monitoring report verifier contract version' -Expected 'External evidence verifier rejects stale monitoring verifier summaries'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern "Add-StructuredReportReverification -Area 'monitoring'" -Expected 'External evidence verifier replays monitoring evidence with the current verifier'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'IsLoopback' -Expected 'Monitoring evidence verifier rejects IPv4/IPv6 loopback addresses'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Pattern 'IsIPv4MappedToIPv6' -Expected 'Monitoring evidence verifier rejects IPv4-mapped IPv6 loopback addresses'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\product-ready-external-evidence-verify.ps1' -Pattern 'source.prometheusBaseUrl deployed-url' -Expected 'External evidence verifier requires deployed monitoring source URL checks'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\monitoring-preflight.ps1' -Pattern 'promtool check config' -Expected 'Monitoring preflight validates Prometheus config with promtool'
Add-ContentCheck -Area 'monitoring' -RelativePath 'scripts\monitoring-preflight.ps1' -Pattern 'promtool check rules' -Expected 'Monitoring preflight validates Prometheus alert rules with promtool'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\monitoring\docker-compose.monitoring.yml' -Expected 'Monitoring compose stack exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\monitoring\prometheus\prometheus.yml' -Expected 'Prometheus scrape config exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\monitoring\prometheus\rules\valuta-alerts.yml' -Expected 'Prometheus alert rules exist'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\monitoring\alertmanager\alertmanager.yml' -Expected 'Alertmanager config exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\monitoring\grafana\provisioning\datasources\datasources.yml' -Expected 'Grafana datasource provisioning exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\monitoring\grafana\provisioning\dashboards\dashboards.yml' -Expected 'Grafana dashboard provisioning exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\monitoring\grafana\dashboards\valuta-overview.json' -Expected 'Grafana overview dashboard exists'
Add-ContentCheck -Area 'monitoring' -RelativePath 'backend\src\main\resources\application-production.properties' -Pattern 'management.server.address=${MANAGEMENT_ADDRESS:127.0.0.1}' -Expected 'Production actuator is loopback-only by default'
Add-ContentCheck -Area 'monitoring' -RelativePath 'backend\src\main\resources\application-production.properties' -Pattern 'management.prometheus.metrics.export.enabled=true' -Expected 'Prometheus export is enabled in production config'
Add-PathCheck -Area 'monitoring' -RelativePath 'backend\src\main\resources\db\migration\V182__client_error_log_table.sql' -Expected 'Client error log table migration exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\scripts\setup-client-error-cleanup.sh' -Expected 'Client error cleanup installer exists'
Add-PathCheck -Area 'monitoring' -RelativePath 'deploy\hetzner\systemd\valuta-client-error-cleanup.timer' -Expected 'Client error cleanup timer exists'

# Production URL evidence.
Add-PathCheck -Area 'production-url' -RelativePath 'config\production-urls.json' -Expected 'Production URL SSOT exists'
Add-ContentCheck -Area 'production-url' -RelativePath 'config\production-urls.json' -Pattern '"health_url": "https://excvaluta.com/api/v1/auth/bootstrap-status"' -Expected 'Production health URL is declared'

if ($CheckLive) {
  try {
    $urls = Get-Content -LiteralPath (Join-Path $WorkspaceRoot 'config\production-urls.json') -Raw | ConvertFrom-Json
    $resp = Invoke-WebRequest -Uri $urls.health_url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    Add-LiveCheck -Name 'production health_url' -Passed ($resp.StatusCode -eq 200) -Evidence "$($urls.health_url) HTTP $($resp.StatusCode)" -Expected 'HTTP 200'
  } catch {
    Add-LiveCheck -Name 'production health_url' -Passed $false -Evidence $_.Exception.Message -Expected 'HTTP 200'
  }
}

$failed = @($checks | Where-Object { -not $_.passed })
$passedCount = @($checks | Where-Object { $_.passed }).Count
$failedCount = $failed.Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  checkLive = [bool]$CheckLive
  passed = $passedCount
  failed = $failedCount
  checks = $checks
  liveChecks = $liveChecks
  pendingExternalEvidence = @(
    'Production/staging full business acceptance execution evidence',
    'Production backup timer status and latest off-site backup retrieval evidence',
    'Test restore drill with row counts, Flyway state, audit hash-chain check, and measured RTO',
    'Monitoring stack live scrape/dashboard/alert test evidence',
    'Installer smoke on clean Windows VM for penztar and kozponti clients',
    'Compliance go-live decision/export for relevant system_parameter values',
    'Completed Product Ready external evidence artifact and passing product-ready:external-evidence:complete gate',
    'Local evidence handoff bundle generated by product-ready:local-evidence-bundle'
  )
}

$jsonPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$mdPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready evidence preflight')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Workspace: $WorkspaceRoot")
$lines.Add("- Local checks: $passedCount passed, $failedCount failed")
$lines.Add("- Live checks enabled: $([bool]$CheckLive)")
$lines.Add('')
$lines.Add('## Local Evidence Checks')
$lines.Add('')
$lines.Add('| Area | Check | Status | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- | --- |')
foreach ($check in $checks) {
  $status = if ($check.passed) { 'PASS' } else { 'FAIL' }
  $lines.Add("| $($check.area) | $($check.name) | $status | $($check.evidence) | $($check.expected) |")
}

if ($liveChecks.Count -gt 0) {
  $lines.Add('')
  $lines.Add('## Live Checks')
  $lines.Add('')
  $lines.Add('| Check | Status | Evidence | Expected |')
  $lines.Add('| --- | --- | --- | --- |')
  foreach ($check in $liveChecks) {
    $status = if ($check.passed) { 'PASS' } else { 'FAIL' }
    $lines.Add("| $($check.name) | $status | $($check.evidence) | $($check.expected) |")
  }
}

$lines.Add('')
$lines.Add('## Pending External Evidence')
$lines.Add('')
foreach ($item in $summary.pendingExternalEvidence) {
  $lines.Add("- $item")
}
$lines.Add('')
$lines.Add('## Verdict')
$lines.Add('')
if ($failedCount -eq 0) {
  $lines.Add('Local repo prerequisites for evidence collection are present. Product Ready is still not proven until the pending external evidence is attached.')
} else {
  $lines.Add('Some local repo prerequisites are missing. Fix the failed rows before treating the evidence package as ready for staging/production validation.')
}

$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

Write-Host "[product-ready-evidence] local checks: $passedCount passed, $failedCount failed"
Write-Host "[product-ready-evidence] report: $mdPath"
Write-Host "[product-ready-evidence] summary: $jsonPath"

if ($failedCount -gt 0) {
  exit 1
}
exit 0
