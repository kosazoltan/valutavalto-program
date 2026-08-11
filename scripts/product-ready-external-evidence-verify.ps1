param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-external-evidence'),
  [string]$EvidencePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json'),
  [switch]$RequireComplete
)

$ErrorActionPreference = 'Stop'
$ApprovalsVerifierContractVersion = '2026-06-09-evidence-ref-loopback-hardening'
$AcceptanceVerifierContractVersion = '2026-06-09-evidence-ref-loopback-hardening'
$MonitoringVerifierContractVersion = '2026-06-09-evidence-ref-loopback-hardening'

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
  if ($RequireComplete) { return 'FAIL' }
  return 'REVIEW'
}

function Get-PropertyValue {
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

function Test-TextPresent {
  param([object]$Value)
  return ($null -ne $Value -and -not [string]::IsNullOrWhiteSpace([string]$Value))
}

function Test-IsoDateLike {
  param([object]$Value)
  if (-not (Test-TextPresent $Value)) {
    return $false
  }

  try {
    [datetimeoffset]::Parse([string]$Value) | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Get-DateOffsetOrNull {
  param([object]$Value)
  if (-not (Test-TextPresent $Value)) {
    return $null
  }

  try {
    return [datetimeoffset]::Parse([string]$Value)
  } catch {
    return $null
  }
}

function Test-NumberAtLeast {
  param(
    [object]$Value,
    [double]$Minimum
  )

  if ($null -eq $Value) {
    return $false
  }

  try {
    $number = [double]$Value
    return $number -ge $Minimum
  } catch {
    return $false
  }
}

function Test-BooleanTrue {
  param([object]$Value)
  return ($Value -is [bool] -and $Value)
}

function Test-EvidenceRef {
  param([object]$Value)

  if (-not (Test-TextPresent $Value)) {
    return $false
  }

  $text = [string]$Value
  if ($text -match '^https://[^/\s]+') {
    return $true
  }

  if ([System.IO.Path]::IsPathRooted($text)) {
    return Test-Path -LiteralPath $text
  }

  return Test-Path -LiteralPath (Join-Path $WorkspaceRoot $text)
}

function Get-LocalJsonFromRef {
  param([object]$Value)

  $path = Resolve-LocalEvidencePath $Value
  if (-not (Test-TextPresent $path) -or -not (Test-Path -LiteralPath $path)) {
    return $null
  }

  try {
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Add-PrerequisiteTimestamp {
  param(
    [System.Collections.Generic.List[object]]$Timestamps,
    [string]$Name,
    [object]$Value
  )

  $parsed = Get-DateOffsetOrNull $Value
  if ($null -eq $parsed) {
    return
  }

  $Timestamps.Add([pscustomobject]@{
      name = $Name
      value = $Value
      parsed = $parsed
    })
}

function Get-FinalDecisionPrerequisiteTimestamps {
  param([object]$Evidence)

  $timestamps = [System.Collections.Generic.List[object]]::new()

  Add-PrerequisiteTimestamp -Timestamps $timestamps -Name 'generatedAt' -Value (Get-PropertyValue $Evidence 'generatedAt')

  $acceptance = Get-PropertyValue $Evidence 'acceptance'
  Add-PrerequisiteTimestamp -Timestamps $timestamps -Name 'acceptance.executedAt' -Value (Get-PropertyValue $acceptance 'executedAt')

  $drRestore = Get-PropertyValue $Evidence 'drRestore'
  Add-PrerequisiteTimestamp -Timestamps $timestamps -Name 'drRestore.executedAt' -Value (Get-PropertyValue $drRestore 'executedAt')

  $approvals = Get-PropertyValue $Evidence 'approvals'
  $approvalsSummary = Get-LocalJsonFromRef (Get-PropertyValue $approvals 'reportRef')
  $approvalsEvidence = Get-LocalJsonFromRef (Get-PropertyValue $approvalsSummary 'evidencePath')
  Add-PrerequisiteTimestamp -Timestamps $timestamps -Name 'approvals.approvedAt' -Value (Get-PropertyValue $approvalsEvidence 'approvedAt')

  $compliance = Get-PropertyValue $Evidence 'compliance'
  $complianceDecisionSummary = Get-LocalJsonFromRef (Get-PropertyValue $compliance 'approvedDecisionRef')
  $complianceDecision = Get-LocalJsonFromRef (Get-PropertyValue $complianceDecisionSummary 'decisionPath')
  Add-PrerequisiteTimestamp -Timestamps $timestamps -Name 'compliance.decidedAt' -Value (Get-PropertyValue $complianceDecision 'decidedAt')

  $monitoring = Get-PropertyValue $Evidence 'monitoring'
  $monitoringSummary = Get-LocalJsonFromRef (Get-PropertyValue $monitoring 'reportRef')
  $monitoringEvidence = Get-LocalJsonFromRef (Get-PropertyValue $monitoringSummary 'evidencePath')
  Add-PrerequisiteTimestamp -Timestamps $timestamps -Name 'monitoring.observedTo' -Value (Get-PropertyValue $monitoringEvidence 'observedTo')

  $installer = Get-PropertyValue $Evidence 'installer'
  $signedInstallerSummary = Get-LocalJsonFromRef (Get-PropertyValue $installer 'signedArtifactReportRef')
  Add-PrerequisiteTimestamp -Timestamps $timestamps -Name 'installer.signedArtifactReport.generatedAt' -Value (Get-PropertyValue $signedInstallerSummary 'generatedAt')
  $cleanVmSummary = Get-LocalJsonFromRef (Get-PropertyValue $installer 'cleanVmReportRef')
  Add-PrerequisiteTimestamp -Timestamps $timestamps -Name 'installer.cleanVmReport.generatedAt' -Value (Get-PropertyValue $cleanVmSummary 'generatedAt')

  return @($timestamps)
}

function Test-FinalDecisionTemporalConsistency {
  param(
    [object]$Evidence,
    [object]$FinalDecision
  )

  $decisionAt = Get-DateOffsetOrNull (Get-PropertyValue $FinalDecision 'decidedAt')
  if ($null -eq $decisionAt) {
    return $false
  }

  $timestamps = @(Get-FinalDecisionPrerequisiteTimestamps -Evidence $Evidence)
  foreach ($timestamp in $timestamps) {
    if ($timestamp.parsed -gt $decisionAt) {
      return $false
    }
  }

  return $timestamps.Count -gt 0
}

function Format-FinalDecisionTemporalEvidence {
  param(
    [object]$Evidence,
    [object]$FinalDecision
  )

  $decisionAt = Get-PropertyValue $FinalDecision 'decidedAt'
  $timestamps = @(Get-FinalDecisionPrerequisiteTimestamps -Evidence $Evidence)
  $parts = @("decidedAt=$decisionAt")
  foreach ($timestamp in $timestamps) {
    $parts += "$($timestamp.name)=$($timestamp.value)"
  }
  return ($parts -join '; ')
}

function Resolve-LocalEvidencePath {
  param([object]$Value)

  if (-not (Test-TextPresent $Value)) {
    return $null
  }

  $text = [string]$Value
  if ($text -match '^https://') {
    return $null
  }

  if ([System.IO.Path]::IsPathRooted($text)) {
    return $text
  }

  return Join-Path $WorkspaceRoot $text
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

function Get-SafeFileName {
  param([string]$Value)
  return ($Value -replace '[^A-Za-z0-9_.-]', '_').Trim('_')
}

function Add-StructuredReportReverification {
  param(
    [string]$Area,
    [string]$VerifierRelativePath,
    [object]$Summary
  )

  if (-not $RequireComplete) {
    return
  }

  $summaryEvidencePathValue = Get-PropertyValue $Summary 'evidencePath'
  $summaryEvidencePath = Resolve-LocalEvidencePath $summaryEvidencePathValue
  $evidenceExists = (Test-TextPresent $summaryEvidencePath -and (Test-Path -LiteralPath $summaryEvidencePath))
  Add-Check -Name "$Area report evidencePath exists for replay" -Status (Convert-ReviewStatus $evidenceExists) `
    -Evidence "evidencePath=$summaryEvidencePathValue" -Expected 'Structured report evidencePath points to a local evidence JSON for verifier replay'

  if (-not $evidenceExists) {
    return
  }

  $verifierPath = Join-Path $WorkspaceRoot $VerifierRelativePath
  $verifierExists = Test-Path -LiteralPath $verifierPath
  Add-Check -Name "$Area report verifier script exists for replay" -Status (Convert-ReviewStatus $verifierExists) `
    -Evidence $VerifierRelativePath -Expected 'Structured verifier script exists'

  if (-not $verifierExists) {
    return
  }

  $safeArea = Get-SafeFileName $Area
  $stdoutPath = Join-Path $runDir "$safeArea.reverify.stdout.log"
  $stderrPath = Join-Path $runDir "$safeArea.reverify.stderr.log"
  $combinedPath = Join-Path $runDir "$safeArea.reverify.log"
  $startedAt = Get-Date

  $process = Start-Process `
    -FilePath 'powershell' `
    -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $verifierPath, '-EvidencePath', $summaryEvidencePath, '-RequirePass') `
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
    "COMMAND: powershell -NoProfile -ExecutionPolicy Bypass -File $verifierPath -EvidencePath $summaryEvidencePath -RequirePass",
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

  Add-Check -Name "$Area report replay with current verifier" -Status (Convert-ReviewStatus ($process.ExitCode -eq 0)) `
    -Evidence $combinedPath -Expected 'Current structured verifier passes the original evidence JSON with -RequirePass'
}

function Add-StructuredCommandReplay {
  param(
    [string]$Area,
    [string]$VerifierRelativePath,
    [string[]]$ArgumentList,
    [string]$Expected
  )

  if (-not $RequireComplete) {
    return
  }

  $verifierPath = Join-Path $WorkspaceRoot $VerifierRelativePath
  $verifierExists = Test-Path -LiteralPath $verifierPath
  Add-Check -Name "$Area replay verifier script exists" -Status (Convert-ReviewStatus $verifierExists) `
    -Evidence $VerifierRelativePath -Expected 'Structured verifier script exists'

  if (-not $verifierExists) {
    return
  }

  $safeArea = Get-SafeFileName $Area
  $stdoutPath = Join-Path $runDir "$safeArea.replay.stdout.log"
  $stderrPath = Join-Path $runDir "$safeArea.replay.stderr.log"
  $combinedPath = Join-Path $runDir "$safeArea.replay.log"
  $processArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $verifierPath) + $ArgumentList
  $startedAt = Get-Date

  $process = Start-Process `
    -FilePath 'powershell' `
    -ArgumentList $processArgs `
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
    "COMMAND: powershell $($processArgs -join ' ')",
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

  Add-Check -Name "$Area replay with current verifier" -Status (Convert-ReviewStatus ($process.ExitCode -eq 0)) `
    -Evidence $combinedPath -Expected $Expected
}

function Add-RequiredTextCheck {
  param([string]$Name, [object]$Value, [string]$Expected)
  $passed = Test-TextPresent $Value
  Add-Check -Name $Name -Status (Convert-ReviewStatus $passed) -Evidence "$Name=$Value" -Expected $Expected
}

function Add-RequiredDateCheck {
  param([string]$Name, [object]$Value)
  $passed = Test-IsoDateLike $Value
  Add-Check -Name $Name -Status (Convert-ReviewStatus $passed) -Evidence "$Name=$Value" -Expected 'ISO-like timestamp'
}

function Add-RequiredEvidenceRefCheck {
  param([string]$Name, [object]$Value)
  $passed = Test-EvidenceRef $Value
  Add-Check -Name $Name -Status (Convert-ReviewStatus $passed) -Evidence "$Name=$Value" -Expected 'Existing repo/absolute path or https URL'
}

function Add-RequiredTrueCheck {
  param([string]$Name, [object]$Value)
  $passed = Test-BooleanTrue $Value
  Add-Check -Name $Name -Status (Convert-ReviewStatus $passed) -Evidence "$Name=$Value" -Expected 'true'
}

function Add-RequiredZeroCheck {
  param([string]$Name, [object]$Value)
  $passed = $false
  if ($null -ne $Value -and -not [string]::IsNullOrWhiteSpace([string]$Value)) {
    try {
      $passed = ([int]$Value -eq 0)
    } catch {
      $passed = $false
    }
  }
  Add-Check -Name $Name -Status (Convert-ReviewStatus $passed) -Evidence "$Name=$Value" -Expected '0'
}

function Add-RequiredMinNumberCheck {
  param([string]$Name, [object]$Value, [double]$Minimum)
  $passed = Test-NumberAtLeast -Value $Value -Minimum $Minimum
  Add-Check -Name $Name -Status (Convert-ReviewStatus $passed) -Evidence "$Name=$Value" -Expected ">= $Minimum"
}

function Add-RequiredStatusPassCheck {
  param([string]$Name, [object]$Value)
  $passed = ([string]$Value -eq 'PASS')
  Add-Check -Name $Name -Status (Convert-ReviewStatus $passed) -Evidence "$Name=$Value" -Expected 'PASS'
}

function Add-SectionExistsCheck {
  param([string]$Name, [object]$Value)
  $passed = $null -ne $Value
  Add-Check -Name "$Name section exists" -Status ($(if ($passed) { 'PASS' } else { 'FAIL' })) -Evidence $Name -Expected 'Section is present'
  return $passed
}

function Add-LocalEvidenceBundleChecks {
  param([object]$BundleRef)

  if (-not (Test-TextPresent $BundleRef)) {
    return
  }

  $bundlePath = Resolve-LocalEvidencePath $BundleRef
  $bundleIsLocal = Test-TextPresent $bundlePath
  Add-Check -Name 'localEvidenceBundleRef local file' -Status (Convert-ReviewStatus $bundleIsLocal) `
    -Evidence "localEvidenceBundleRef=$BundleRef" -Expected 'Local bundle JSON path, not remote URL'

  if (-not $bundleIsLocal) {
    return
  }

  $bundleExists = Test-Path -LiteralPath $bundlePath
  Add-Check -Name 'local evidence bundle exists' -Status (Convert-ReviewStatus $bundleExists) `
    -Evidence $bundlePath -Expected 'Bundle JSON exists'

  if (-not $bundleExists) {
    return
  }

  try {
    $bundle = Get-Content -LiteralPath $bundlePath -Raw | ConvertFrom-Json
    Add-Check -Name 'local evidence bundle json parse' -Status 'PASS' -Evidence $bundlePath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'local evidence bundle json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  $bundleSchemaVersion = Get-PropertyValue $bundle 'schemaVersion'
  Add-Check -Name 'local evidence bundle schemaVersion' -Status (Convert-ReviewStatus ($bundleSchemaVersion -eq 1)) `
    -Evidence "schemaVersion=$bundleSchemaVersion" -Expected '1'

  $bundleStatus = Get-PropertyValue $bundle 'status'
  Add-Check -Name 'local evidence bundle status' -Status (Convert-ReviewStatus ([string]$bundleStatus -eq 'LOCAL_EVIDENCE_BUNDLE_READY')) `
    -Evidence "status=$bundleStatus" -Expected 'LOCAL_EVIDENCE_BUNDLE_READY'

  $bundleFailed = Get-PropertyValue $bundle 'failed'
  Add-Check -Name 'local evidence bundle failed' -Status (Convert-ReviewStatus ($null -ne $bundleFailed -and [int]$bundleFailed -eq 0)) `
    -Evidence "failed=$bundleFailed" -Expected '0'

  $bundleArtifacts = @(Get-PropertyValue $bundle 'artifacts')
  Add-Check -Name 'local evidence bundle artifacts' -Status (Convert-ReviewStatus ($bundleArtifacts.Count -gt 0)) `
    -Evidence "artifacts=$($bundleArtifacts.Count)" -Expected 'At least one bundled artifact'

  $requiredAreas = @(
    'product_ready_local_gate',
    'product_ready_evidence_preflight',
    'product_ready_acceptance_coverage',
    'product_ready_staging_acceptance_preflight',
    'product_ready_approvals_preflight',
    'product_ready_external_evidence_preflight',
    'compliance_golive_preflight',
    'compliance_golive_decision_preflight',
    'audit_hash_chain_preflight',
    'dr_restore_drill',
    'monitoring_preflight',
    'product_ready_monitoring_evidence_preflight',
    'installer_smoke',
    'installer_clean_vm_smoke'
  )

  foreach ($requiredArea in $requiredAreas) {
    $artifact = $bundleArtifacts | Where-Object { [string](Get-PropertyValue $_ 'area') -eq $requiredArea } | Select-Object -First 1
    Add-Check -Name "local evidence bundle area:$requiredArea" -Status (Convert-ReviewStatus ($null -ne $artifact)) `
      -Evidence $requiredArea -Expected 'Required local evidence artifact is bundled'

    if ($null -eq $artifact) {
      continue
    }

    foreach ($kind in @('report', 'summary')) {
      $pathValue = Get-PropertyValue $artifact $kind
      $hashValue = [string](Get-PropertyValue $artifact "$($kind)Sha256")
      $artifactPath = Resolve-LocalEvidencePath $pathValue
      $pathExists = (Test-TextPresent $artifactPath -and (Test-Path -LiteralPath $artifactPath))
      Add-Check -Name "local evidence bundle $requiredArea $kind exists" -Status (Convert-ReviewStatus $pathExists) `
        -Evidence "$pathValue" -Expected "$kind file exists"

      if (-not $pathExists) {
        continue
      }

      $actualHash = Get-Sha256 -Path $artifactPath
      $hashMatches = (Test-TextPresent $hashValue -and $actualHash -eq $hashValue.ToUpperInvariant())
      Add-Check -Name "local evidence bundle $requiredArea $kind sha256" -Status (Convert-ReviewStatus $hashMatches) `
        -Evidence "expected=$hashValue; actual=$actualHash" -Expected 'Bundle hash matches current file'

      if ($kind -eq 'summary') {
        try {
          $artifactSummary = Get-Content -LiteralPath $artifactPath -Raw | ConvertFrom-Json
          Add-Check -Name "local evidence bundle $requiredArea summary content json parse" -Status 'PASS' `
            -Evidence "$pathValue" -Expected 'Bundled summary file is valid JSON'
        } catch {
          Add-Check -Name "local evidence bundle $requiredArea summary content json parse" -Status (Convert-ReviewStatus $false) `
            -Evidence $_.Exception.Message -Expected 'Bundled summary file is valid JSON'
          continue
        }

        $artifactSummaryFailed = Get-PropertyValue $artifactSummary 'failed'
        Add-Check -Name "local evidence bundle $requiredArea summary failed" -Status (Convert-ReviewStatus ($null -ne $artifactSummaryFailed -and [int]$artifactSummaryFailed -eq 0)) `
          -Evidence "failed=$artifactSummaryFailed" -Expected '0'

        $artifactMetadataFailed = Get-PropertyValue $artifact 'failed'
        $metadataMatchesSummary = ($null -ne $artifactMetadataFailed -and $null -ne $artifactSummaryFailed -and [int]$artifactMetadataFailed -eq [int]$artifactSummaryFailed)
        Add-Check -Name "local evidence bundle $requiredArea summary failed metadata" -Status (Convert-ReviewStatus $metadataMatchesSummary) `
          -Evidence "metadata=$artifactMetadataFailed; summary=$artifactSummaryFailed" -Expected 'Bundle artifact failed metadata matches the bundled summary failed value'
      }
    }

    if ($requiredArea -eq 'product_ready_local_gate') {
      $stepLogs = @(Get-PropertyValue $artifact 'stepLogs')
      Add-Check -Name 'local evidence bundle product_ready_local_gate stepLogs' -Status (Convert-ReviewStatus ($stepLogs.Count -gt 0)) `
        -Evidence "stepLogs=$($stepLogs.Count)" -Expected 'Bundled local gate step log hashes are present'

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

      $hasInstallerArtifactsStepLog = [bool]($stepLogs | Where-Object { [string](Get-PropertyValue $_ 'name') -eq 'installer_smoke_artifacts' } | Select-Object -First 1)
      if ($hasInstallerArtifactsStepLog) {
        $requiredStepNames += 'installer_smoke_artifacts'
      } else {
        $requiredStepNames += 'installer_smoke_synthetic'
      }

      foreach ($requiredStepName in $requiredStepNames) {
        $stepLog = $stepLogs | Where-Object { [string](Get-PropertyValue $_ 'name') -eq $requiredStepName } | Select-Object -First 1
        Add-Check -Name "local evidence bundle product_ready_local_gate stepLog:$requiredStepName" -Status (Convert-ReviewStatus ($null -ne $stepLog)) `
          -Evidence $requiredStepName -Expected 'Required local gate step log hash is bundled'

        if ($null -eq $stepLog) {
          continue
        }

        $exitCode = Get-PropertyValue $stepLog 'exitCode'
        Add-Check -Name "local evidence bundle product_ready_local_gate stepLog:$requiredStepName exitCode" -Status (Convert-ReviewStatus ($null -ne $exitCode -and [int]$exitCode -eq 0)) `
          -Evidence "exitCode=$exitCode" -Expected '0'

        $logValue = Get-PropertyValue $stepLog 'log'
        $logHashValue = [string](Get-PropertyValue $stepLog 'logSha256')
        $logPath = Resolve-LocalEvidencePath $logValue
        $logExists = (Test-TextPresent $logPath -and (Test-Path -LiteralPath $logPath))
        Add-Check -Name "local evidence bundle product_ready_local_gate stepLog:$requiredStepName exists" -Status (Convert-ReviewStatus $logExists) `
          -Evidence "$logValue" -Expected 'Local gate step log file exists'

        if (-not $logExists) {
          continue
        }

        $actualLogHash = Get-Sha256 -Path $logPath
        $logHashMatches = (Test-TextPresent $logHashValue -and $actualLogHash -eq $logHashValue.ToUpperInvariant())
        Add-Check -Name "local evidence bundle product_ready_local_gate stepLog:$requiredStepName sha256" -Status (Convert-ReviewStatus $logHashMatches) `
          -Evidence "expected=$logHashValue; actual=$actualLogHash" -Expected 'Bundle log hash matches current file'
      }
    }
  }
}

function Add-StructuredApprovalsReportChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'approvals.reportRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "approvals.reportRef=$ReportRef" -Expected 'Local structured owner approvals summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'approvals report summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured approvals summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $approvalsSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'approvals report summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'approvals report summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  $summaryStatus = Get-PropertyValue $approvalsSummary 'status'
  Add-Check -Name 'approvals report status' -Status (Convert-ReviewStatus ([string]$summaryStatus -eq 'PASS')) `
    -Evidence "status=$summaryStatus" -Expected 'PASS'

  $summaryFailed = Get-PropertyValue $approvalsSummary 'failed'
  Add-Check -Name 'approvals report failed' -Status (Convert-ReviewStatus ($null -ne $summaryFailed -and [int]$summaryFailed -eq 0)) `
    -Evidence "failed=$summaryFailed" -Expected '0'

  $summaryReview = Get-PropertyValue $approvalsSummary 'reviewRequired'
  Add-Check -Name 'approvals report reviewRequired' -Status (Convert-ReviewStatus ($null -ne $summaryReview -and [int]$summaryReview -eq 0)) `
    -Evidence "reviewRequired=$summaryReview" -Expected '0'

  $meaning = [string](Get-PropertyValue $approvalsSummary 'productReadyMeaning')
  Add-Check -Name 'approvals report verifier identity' -Status (Convert-ReviewStatus ($meaning -match 'Structured Product Ready owner approvals evidence verifier')) `
    -Evidence $meaning -Expected 'Generated by the structured Product Ready owner approvals verifier'

  $contractVersion = [string](Get-PropertyValue $approvalsSummary 'verifierContractVersion')
  Add-Check -Name 'approvals report verifier contract version' -Status (Convert-ReviewStatus ($contractVersion -eq $ApprovalsVerifierContractVersion)) `
    -Evidence "verifierContractVersion=$contractVersion" -Expected $ApprovalsVerifierContractVersion
  Add-StructuredReportReverification -Area 'approvals' -VerifierRelativePath 'scripts\product-ready-approvals-verify.ps1' -Summary $approvalsSummary

  $approvalsChecks = @(Get-PropertyValue $approvalsSummary 'checks')
  Add-Check -Name 'approvals report checks array' -Status (Convert-ReviewStatus ($approvalsChecks.Count -gt 0)) `
    -Evidence "checks=$($approvalsChecks.Count)" -Expected 'Structured verifier checks are included'

  $requiredCheckNames = @(
    'status',
    'environment',
    'approvedAt',
    'evidenceOwner',
    'completedEvidenceRef',
    'completedEvidenceRef not template/draft',
    'completedEvidenceRef not synthetic/local',
    'safety.redacted',
    'safety.containsSecrets',
    'safety.containsCustomerPersonalData'
  )

  foreach ($role in @('productOwner', 'operationsOwner', 'complianceOwner')) {
    $requiredCheckNames += @(
      "approvals.$role exists",
      "approvals.$role.name",
      "approvals.$role.approved",
      "approvals.$role.approvedAt",
      "approvals.$role.evidenceRef",
      "approvals.$role.evidenceRef not template/draft",
      "approvals.$role.evidenceRef not synthetic/local"
    )
  }

  foreach ($checkName in $requiredCheckNames) {
    $matchedCheck = $approvalsChecks | Where-Object { [string](Get-PropertyValue $_ 'name') -eq $checkName } | Select-Object -First 1
    $matchedStatus = if ($null -ne $matchedCheck) { [string](Get-PropertyValue $matchedCheck 'status') } else { '' }
    Add-Check -Name "approvals report check:$checkName" -Status (Convert-ReviewStatus ($matchedStatus -eq 'PASS')) `
      -Evidence "status=$matchedStatus" -Expected 'PASS'
  }
}

function Add-StructuredAcceptanceReportChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'acceptance.reportRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "acceptance.reportRef=$ReportRef" -Expected 'Local structured staging/production acceptance summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'acceptance report summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured acceptance summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $acceptanceSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'acceptance report summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'acceptance report summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  $summaryStatus = Get-PropertyValue $acceptanceSummary 'status'
  Add-Check -Name 'acceptance report status' -Status (Convert-ReviewStatus ([string]$summaryStatus -eq 'PASS')) `
    -Evidence "status=$summaryStatus" -Expected 'PASS'

  $summaryFailed = Get-PropertyValue $acceptanceSummary 'failed'
  Add-Check -Name 'acceptance report failed' -Status (Convert-ReviewStatus ($null -ne $summaryFailed -and [int]$summaryFailed -eq 0)) `
    -Evidence "failed=$summaryFailed" -Expected '0'

  $summaryReview = Get-PropertyValue $acceptanceSummary 'reviewRequired'
  Add-Check -Name 'acceptance report reviewRequired' -Status (Convert-ReviewStatus ($null -ne $summaryReview -and [int]$summaryReview -eq 0)) `
    -Evidence "reviewRequired=$summaryReview" -Expected '0'

  $meaning = [string](Get-PropertyValue $acceptanceSummary 'productReadyMeaning')
  Add-Check -Name 'acceptance report verifier identity' -Status (Convert-ReviewStatus ($meaning -match 'Structured staging/production acceptance evidence verifier')) `
    -Evidence $meaning -Expected 'Generated by the structured staging/production acceptance verifier'

  $contractVersion = [string](Get-PropertyValue $acceptanceSummary 'verifierContractVersion')
  Add-Check -Name 'acceptance report verifier contract version' -Status (Convert-ReviewStatus ($contractVersion -eq $AcceptanceVerifierContractVersion)) `
    -Evidence "verifierContractVersion=$contractVersion" -Expected $AcceptanceVerifierContractVersion
  Add-StructuredReportReverification -Area 'acceptance' -VerifierRelativePath 'scripts\product-ready-staging-acceptance-verify.ps1' -Summary $acceptanceSummary

  $acceptanceChecks = @(Get-PropertyValue $acceptanceSummary 'checks')
  Add-Check -Name 'acceptance report checks array' -Status (Convert-ReviewStatus ($acceptanceChecks.Count -gt 0)) `
    -Evidence "checks=$($acceptanceChecks.Count)" -Expected 'Structured verifier checks are included'

  $requiredCheckNames = @(
    'status',
    'environment',
    'executedAt',
    'operator',
    'source.baseUrl',
    'source.baseUrl deployed-url',
    'source.deploymentRef',
    'source.deploymentRef not synthetic/local',
    'source.dataSetRef',
    'source.dataSetRef not synthetic/local',
    'summary.failed',
    'summary.criticalFlowsPassed',
    'safety.redacted',
    'safety.containsSecrets',
    'safety.containsCustomerPersonalData'
  )

  foreach ($flow in @('buy', 'sell', 'conversion', 'transfer', 'storno', 'dayClosing', 'navCashRegister', 'receiptPrint', 'offlineSync')) {
    $requiredCheckNames += @(
      "requiredFlows.$flow",
      "flows.$flow exists",
      "flows.$flow.status",
      "flows.$flow.executedAt",
      "flows.$flow.evidenceRef",
      "flows.$flow.evidenceRef not template/draft",
      "flows.$flow.evidenceRef not synthetic/local"
    )
  }

  foreach ($checkName in $requiredCheckNames) {
    $matchedCheck = $acceptanceChecks | Where-Object { [string](Get-PropertyValue $_ 'name') -eq $checkName } | Select-Object -First 1
    $matchedStatus = if ($null -ne $matchedCheck) { [string](Get-PropertyValue $matchedCheck 'status') } else { '' }
    Add-Check -Name "acceptance report check:$checkName" -Status (Convert-ReviewStatus ($matchedStatus -eq 'PASS')) `
      -Evidence "status=$matchedStatus" -Expected 'PASS'
  }
}

function Test-CoverageCheckPassed {
  param(
    [object[]]$Checks,
    [string]$Name
  )

  $check = $Checks | Where-Object {
    [string](Get-PropertyValue $_ 'name') -eq $Name
  } | Select-Object -First 1

  if ($null -eq $check) {
    return $false
  }

  return (Test-BooleanTrue (Get-PropertyValue $check 'passed'))
}

function Test-CoverageCheckPassedByPrefix {
  param(
    [object[]]$Checks,
    [string]$NamePrefix
  )

  $check = $Checks | Where-Object {
    [string](Get-PropertyValue $_ 'name') -like "$NamePrefix*"
  } | Select-Object -First 1

  if ($null -eq $check) {
    return $false
  }

  return (Test-BooleanTrue (Get-PropertyValue $check 'passed'))
}

function Add-StructuredLocalAcceptanceCoverageChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'acceptance.localCoverageReportRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "acceptance.localCoverageReportRef=$ReportRef" -Expected 'Local structured critical-flow coverage summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'acceptance local coverage summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured acceptance coverage summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $coverageSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'acceptance local coverage summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'acceptance local coverage summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  $coverageFailed = Get-PropertyValue $coverageSummary 'failed'
  Add-Check -Name 'acceptance local coverage failed' -Status (Convert-ReviewStatus ($null -ne $coverageFailed -and [int]$coverageFailed -eq 0)) `
    -Evidence "failed=$coverageFailed" -Expected '0'

  $meaning = [string](Get-PropertyValue $coverageSummary 'productReadyMeaning')
  Add-Check -Name 'acceptance local coverage verifier identity' -Status (Convert-ReviewStatus ($meaning -match 'Local critical-flow coverage map')) `
    -Evidence $meaning -Expected 'Local critical-flow coverage map verifier'

  $coverageChecks = @(Get-PropertyValue $coverageSummary 'checks')
  Add-Check -Name 'acceptance local coverage checks array' -Status (Convert-ReviewStatus ($coverageChecks.Count -gt 0)) `
    -Evidence "checks=$($coverageChecks.Count)" -Expected 'Acceptance coverage verifier checks are included'

  foreach ($checkName in @(
      'coverage file exists',
      'coverage json parse',
      'schemaVersion',
      'status',
      'environment',
      'flows array'
    )) {
    Add-Check -Name "acceptance local coverage check:$checkName" -Status (Convert-ReviewStatus (Test-CoverageCheckPassed -Checks $coverageChecks -Name $checkName)) `
      -Evidence "check=$checkName" -Expected 'PASS'
  }

  foreach ($flow in @('buy', 'sell', 'conversion', 'transfer', 'storno', 'dayClosing', 'navCashRegister', 'receiptPrint', 'offlineSync')) {
    foreach ($checkName in @(
        "flow:$flow exists",
        "flow:$flow commands",
        "flow:$flow evidenceRefs"
      )) {
      Add-Check -Name "acceptance local coverage check:$checkName" -Status (Convert-ReviewStatus (Test-CoverageCheckPassed -Checks $coverageChecks -Name $checkName)) `
        -Evidence "check=$checkName" -Expected 'PASS'
    }

    Add-Check -Name "acceptance local coverage $flow file evidence" -Status (Convert-ReviewStatus (Test-CoverageCheckPassedByPrefix -Checks $coverageChecks -NamePrefix "flow:$flow file:")) `
      -Evidence "flow=$flow; checkPrefix=file" -Expected 'At least one mapped evidence file exists'
    Add-Check -Name "acceptance local coverage $flow pattern evidence" -Status (Convert-ReviewStatus (Test-CoverageCheckPassedByPrefix -Checks $coverageChecks -NamePrefix "flow:$flow pattern:")) `
      -Evidence "flow=$flow; checkPrefix=pattern" -Expected 'At least one mapped evidence pattern is present'
  }
}

function Get-StepByName {
  param(
    [object[]]$Steps,
    [string]$Name
  )

  return $Steps | Where-Object { [string](Get-PropertyValue $_ 'name') -eq $Name } | Select-Object -First 1
}

function Test-StepStatus {
  param(
    [object[]]$Steps,
    [string]$Name,
    [string[]]$AllowedStatuses = @('PASS')
  )

  $step = Get-StepByName -Steps $Steps -Name $Name
  if ($null -eq $step) {
    return $false
  }

  $status = [string](Get-PropertyValue $step 'status')
  return $AllowedStatuses -contains $status
}

function Get-StepEvidence {
  param(
    [object[]]$Steps,
    [string]$Name
  )

  $step = Get-StepByName -Steps $Steps -Name $Name
  if ($null -eq $step) {
    return ''
  }

  return [string](Get-PropertyValue $step 'evidence')
}

function Test-RowCountEvidenceAtLeastOne {
  param(
    [string]$Evidence,
    [string]$Name
  )

  if (-not (Test-TextPresent $Evidence)) {
    return $false
  }

  $pattern = "(?m)(^|[\r\n])$([regex]::Escape($Name))=(\d+)"
  if ($Evidence -notmatch $pattern) {
    return $false
  }

  return ([int]$Matches[2] -ge 1)
}

function Add-StructuredDrRestoreReportChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'drRestore.reportRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "drRestore.reportRef=$ReportRef" -Expected 'Local structured DR restore summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'drRestore report summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured DR restore summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $drSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'drRestore report summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'drRestore report summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  $mode = Get-PropertyValue $drSummary 'mode'
  Add-Check -Name 'drRestore report mode' -Status (Convert-ReviewStatus ([string]$mode -eq 'execute')) `
    -Evidence "mode=$mode" -Expected 'execute'

  $evidenceKind = Get-PropertyValue $drSummary 'evidenceKind'
  Add-Check -Name 'drRestore report evidence kind' -Status (Convert-ReviewStatus ([string]$evidenceKind -eq 'real-backup-drill')) `
    -Evidence "evidenceKind=$evidenceKind" -Expected 'real-backup-drill'

  $isolatedScratchTargetConfirmed = Get-PropertyValue $drSummary 'isolatedScratchTargetConfirmed'
  Add-Check -Name 'drRestore report isolated scratch target confirmed' -Status (Convert-ReviewStatus (Test-BooleanTrue $isolatedScratchTargetConfirmed)) `
    -Evidence "isolatedScratchTargetConfirmed=$isolatedScratchTargetConfirmed" -Expected 'true'

  $failed = Get-PropertyValue $drSummary 'failed'
  Add-Check -Name 'drRestore report failed' -Status (Convert-ReviewStatus ($null -ne $failed -and [int]$failed -eq 0)) `
    -Evidence "failed=$failed" -Expected '0'

  $targetDatabase = [string](Get-PropertyValue $drSummary 'targetDatabase')
  Add-Check -Name 'drRestore report target database safety' -Status (Convert-ReviewStatus ($targetDatabase -match '^valuta_dr_[A-Za-z0-9_-]+$')) `
    -Evidence "targetDatabase=$targetDatabase" -Expected 'Scratch DB name matches ^valuta_dr_[A-Za-z0-9_-]+$'

  $steps = @(Get-PropertyValue $drSummary 'steps')
  Add-Check -Name 'drRestore report steps array' -Status (Convert-ReviewStatus ($steps.Count -gt 0)) `
    -Evidence "steps=$($steps.Count)" -Expected 'DR restore drill steps are included'

  foreach ($stepName in @(
      'target database safety',
      'evidence kind',
      'isolated scratch target confirmation',
      'dump path',
      'dump format',
      'create scratch database',
      'restore duration',
      'critical row counts',
      'flyway latest state',
      'audit hash-chain smoke'
    )) {
    Add-Check -Name "drRestore report step:$stepName" -Status (Convert-ReviewStatus (Test-StepStatus -Steps $steps -Name $stepName)) `
      -Evidence "step=$stepName" -Expected 'PASS'
  }

  $restoreStepPass = (
    (Test-StepStatus -Steps $steps -Name 'pg_restore custom dump') -or
    (Test-StepStatus -Steps $steps -Name 'psql restore plain sql') -or
    (Test-StepStatus -Steps $steps -Name 'psql restore gzip sql')
  )
  Add-Check -Name 'drRestore report restore step' -Status (Convert-ReviewStatus $restoreStepPass) `
    -Evidence 'pg_restore custom dump OR psql restore plain sql OR psql restore gzip sql' -Expected 'PASS'

  $rowCountEvidence = Get-StepEvidence -Steps $steps -Name 'critical row counts'
  foreach ($tableName in @('transactions', 'audit_log', 'aml_report', 'customer', 'flyway_success')) {
    Add-Check -Name "drRestore report rowCount.$tableName" -Status (Convert-ReviewStatus (Test-RowCountEvidenceAtLeastOne -Evidence $rowCountEvidence -Name $tableName)) `
      -Evidence $rowCountEvidence -Expected "$tableName >= 1"
  }

  $auditEvidence = Get-StepEvidence -Steps $steps -Name 'audit hash-chain smoke'
  Add-Check -Name 'drRestore report audit hash-chain smoke clean' -Status (Convert-ReviewStatus ($auditEvidence -match 'missing_hash,broken_chain=0,0')) `
    -Evidence $auditEvidence -Expected 'missing_hash,broken_chain=0,0'
}

function Add-StructuredMonitoringReportChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'monitoring.reportRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "monitoring.reportRef=$ReportRef" -Expected 'Local structured deployed monitoring evidence summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'monitoring report summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured monitoring evidence summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $monitoringSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'monitoring report summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'monitoring report summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  $summaryStatus = Get-PropertyValue $monitoringSummary 'status'
  Add-Check -Name 'monitoring report status' -Status (Convert-ReviewStatus ([string]$summaryStatus -eq 'PASS')) `
    -Evidence "status=$summaryStatus" -Expected 'PASS'

  $summaryFailed = Get-PropertyValue $monitoringSummary 'failed'
  Add-Check -Name 'monitoring report failed' -Status (Convert-ReviewStatus ($null -ne $summaryFailed -and [int]$summaryFailed -eq 0)) `
    -Evidence "failed=$summaryFailed" -Expected '0'

  $summaryReview = Get-PropertyValue $monitoringSummary 'reviewRequired'
  Add-Check -Name 'monitoring report reviewRequired' -Status (Convert-ReviewStatus ($null -ne $summaryReview -and [int]$summaryReview -eq 0)) `
    -Evidence "reviewRequired=$summaryReview" -Expected '0'

  $meaning = [string](Get-PropertyValue $monitoringSummary 'productReadyMeaning')
  Add-Check -Name 'monitoring report verifier identity' -Status (Convert-ReviewStatus ($meaning -match 'Structured deployed monitoring evidence verifier')) `
    -Evidence $meaning -Expected 'Generated by the structured deployed monitoring evidence verifier'

  $contractVersion = [string](Get-PropertyValue $monitoringSummary 'verifierContractVersion')
  Add-Check -Name 'monitoring report verifier contract version' -Status (Convert-ReviewStatus ($contractVersion -eq $MonitoringVerifierContractVersion)) `
    -Evidence "verifierContractVersion=$contractVersion" -Expected $MonitoringVerifierContractVersion
  Add-StructuredReportReverification -Area 'monitoring' -VerifierRelativePath 'scripts\product-ready-monitoring-evidence-verify.ps1' -Summary $monitoringSummary

  $monitoringChecks = @(Get-PropertyValue $monitoringSummary 'checks')
  Add-Check -Name 'monitoring report checks array' -Status (Convert-ReviewStatus ($monitoringChecks.Count -gt 0)) `
    -Evidence "checks=$($monitoringChecks.Count)" -Expected 'Structured verifier checks are included'

  $requiredCheckNames = @(
    'status',
    'environment',
    'observedFrom',
    'observedTo',
    'observationHours',
    'observation window consistency',
    'operator',
    'source.prometheusBaseUrl',
    'source.prometheusBaseUrl deployed-url',
    'source.grafanaBaseUrl',
    'source.grafanaBaseUrl deployed-url',
    'source.alertmanagerBaseUrl',
    'source.alertmanagerBaseUrl deployed-url',
    'source.deploymentRef',
    'source.deploymentRef not synthetic/local',
    'checks.scrapeVerified',
    'checks.dashboardLoaded',
    'checks.alertDelivered',
    'checks.backendUp',
    'checks.postgresUp',
    'checks.hostMetricsPresent',
    'checks.clientErrorLogObservable',
    'evidenceRefs.scrapeRef',
    'evidenceRefs.dashboardRef',
    'evidenceRefs.alertDeliveryRef',
    'evidenceRefs.prometheusTargetsRef',
    'evidenceRefs.grafanaDashboardRef',
    'summary.failed',
    'summary.reviewRequired',
    'safety.redacted',
    'safety.containsSecrets',
    'safety.containsCustomerPersonalData'
  )

  foreach ($checkName in $requiredCheckNames) {
    $matchedCheck = $monitoringChecks | Where-Object { [string](Get-PropertyValue $_ 'name') -eq $checkName } | Select-Object -First 1
    $matchedStatus = if ($null -ne $matchedCheck) { [string](Get-PropertyValue $matchedCheck 'status') } else { '' }
    Add-Check -Name "monitoring report check:$checkName" -Status (Convert-ReviewStatus ($matchedStatus -eq 'PASS')) `
      -Evidence "status=$matchedStatus" -Expected 'PASS'
  }
}

function Get-CheckByAreaAndName {
  param(
    [object[]]$Checks,
    [string]$Area,
    [string]$Name
  )

  return $Checks | Where-Object {
    [string](Get-PropertyValue $_ 'area') -eq $Area -and
    [string](Get-PropertyValue $_ 'name') -eq $Name
  } | Select-Object -First 1
}

function Test-CheckPass {
  param(
    [object[]]$Checks,
    [string]$Area,
    [string]$Name
  )

  $check = Get-CheckByAreaAndName -Checks $Checks -Area $Area -Name $Name
  if ($null -eq $check) {
    return $false
  }

  return ([string](Get-PropertyValue $check 'status') -eq 'PASS')
}

function Test-AnyCheckPassByPrefix {
  param(
    [object[]]$Checks,
    [string]$Area,
    [string]$NamePrefix
  )

  $check = $Checks | Where-Object {
    [string](Get-PropertyValue $_ 'area') -eq $Area -and
    [string](Get-PropertyValue $_ 'name') -like "$NamePrefix*"
  } | Select-Object -First 1

  if ($null -eq $check) {
    return $false
  }

  return ([string](Get-PropertyValue $check 'status') -eq 'PASS')
}

function Test-NamedCheckPass {
  param(
    [object[]]$Checks,
    [string]$Name
  )

  $check = $Checks | Where-Object {
    [string](Get-PropertyValue $_ 'name') -eq $Name
  } | Select-Object -First 1

  if ($null -eq $check) {
    return $false
  }

  return ([string](Get-PropertyValue $check 'status') -eq 'PASS')
}

function Add-StructuredComplianceDecisionReportChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'compliance.approvedDecisionRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "compliance.approvedDecisionRef=$ReportRef" -Expected 'Local structured approved compliance decision summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'compliance decision summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured compliance decision summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $decisionSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'compliance decision summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'compliance decision summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  Add-Check -Name 'compliance decision requireApprovedDecision' -Status (Convert-ReviewStatus (Test-BooleanTrue (Get-PropertyValue $decisionSummary 'requireApprovedDecision'))) `
    -Evidence "requireApprovedDecision=$(Get-PropertyValue $decisionSummary 'requireApprovedDecision')" -Expected 'true'

  $decisionFailed = Get-PropertyValue $decisionSummary 'failed'
  Add-Check -Name 'compliance decision failed' -Status (Convert-ReviewStatus ($null -ne $decisionFailed -and [int]$decisionFailed -eq 0)) `
    -Evidence "failed=$decisionFailed" -Expected '0'

  $decisionReview = Get-PropertyValue $decisionSummary 'reviewRequired'
  Add-Check -Name 'compliance decision reviewRequired' -Status (Convert-ReviewStatus ($null -ne $decisionReview -and [int]$decisionReview -eq 0)) `
    -Evidence "reviewRequired=$decisionReview" -Expected '0'

  $meaning = [string](Get-PropertyValue $decisionSummary 'productReadyMeaning')
  Add-Check -Name 'compliance decision verifier identity' -Status (Convert-ReviewStatus ($meaning -match 'Approved compliance go-live decision gate')) `
    -Evidence $meaning -Expected 'Approved compliance go-live decision gate'

  $decisionPathValue = Get-PropertyValue $decisionSummary 'decisionPath'
  $decisionPath = Resolve-LocalEvidencePath $decisionPathValue
  $decisionPathExists = (Test-TextPresent $decisionPath -and (Test-Path -LiteralPath $decisionPath))
  Add-Check -Name 'compliance decision source file exists for replay' -Status (Convert-ReviewStatus $decisionPathExists) `
    -Evidence "decisionPath=$decisionPathValue" -Expected 'Approved compliance decision JSON exists for current verifier replay'
  if ($decisionPathExists) {
    Add-StructuredCommandReplay -Area 'compliance decision' `
      -VerifierRelativePath 'scripts\compliance-golive-decision-verify.ps1' `
      -ArgumentList @('-DecisionPath', $decisionPath, '-RequireApprovedDecision') `
      -Expected 'Current compliance decision verifier passes the referenced decision JSON with -RequireApprovedDecision'
  }

  $decisionChecks = @(Get-PropertyValue $decisionSummary 'checks')
  Add-Check -Name 'compliance decision checks array' -Status (Convert-ReviewStatus ($decisionChecks.Count -gt 0)) `
    -Evidence "checks=$($decisionChecks.Count)" -Expected 'Compliance decision verifier checks are included'

  $requiredCheckNames = @(
    'decision file exists',
    'decision json parse',
    'decision file secret pattern scan',
    'decisionStatus',
    'environment',
    'decidedAt',
    'decidedBy',
    'approvedByCompliance',
    'flags array'
  )

  foreach ($flag in @(
      'PMT_STRICT_ENFORCEMENT',
      'AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT',
      'AML_HIGH_VALUE_APPROVAL_ENFORCEMENT',
      'AML_FATF_TIER_ENFORCEMENT',
      'CIRCULAR_ACK_BLOCKING_ENFORCEMENT'
    )) {
    $requiredCheckNames += @(
      "flag:$flag exists",
      "flag:$flag approvedValue",
      "flag:$flag rationale"
    )
  }

  foreach ($checkName in $requiredCheckNames) {
    Add-Check -Name "compliance decision check:$checkName" -Status (Convert-ReviewStatus (Test-NamedCheckPass -Checks $decisionChecks -Name $checkName)) `
      -Evidence "check=$checkName" -Expected 'PASS'
  }
}

function Add-StructuredComplianceExportReportChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'compliance.exportReportRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "compliance.exportReportRef=$ReportRef" -Expected 'Local structured staging/production compliance export summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'compliance export summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured compliance export summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $exportSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'compliance export summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'compliance export summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  $mode = Get-PropertyValue $exportSummary 'mode'
  Add-Check -Name 'compliance export mode' -Status (Convert-ReviewStatus ([string]$mode -eq 'query')) `
    -Evidence "mode=$mode" -Expected 'query'

  foreach ($fieldName in @('targetHost', 'targetUser', 'targetDatabase')) {
    $fieldValue = Get-PropertyValue $exportSummary $fieldName
    Add-Check -Name "compliance export $fieldName" -Status (Convert-ReviewStatus (Test-TextPresent $fieldValue)) `
      -Evidence "$fieldName=$fieldValue" -Expected 'Recorded staging/production DB export target metadata'
  }

  $exportFailed = Get-PropertyValue $exportSummary 'failed'
  Add-Check -Name 'compliance export failed' -Status (Convert-ReviewStatus ($null -ne $exportFailed -and [int]$exportFailed -eq 0)) `
    -Evidence "failed=$exportFailed" -Expected '0'

  $exportReview = Get-PropertyValue $exportSummary 'reviewRequired'
  Add-Check -Name 'compliance export reviewRequired' -Status (Convert-ReviewStatus ($null -ne $exportReview -and [int]$exportReview -eq 0)) `
    -Evidence "reviewRequired=$exportReview" -Expected '0'

  $exportChecks = @(Get-PropertyValue $exportSummary 'checks')
  Add-Check -Name 'compliance export checks array' -Status (Convert-ReviewStatus ($exportChecks.Count -gt 0)) `
    -Evidence "checks=$($exportChecks.Count)" -Expected 'Compliance export verifier checks are included'

  foreach ($checkName in @(
      'decision file',
      'decision json parse',
      'approved decision status',
      'query execution'
    )) {
    Add-Check -Name "compliance export check:$checkName" -Status (Convert-ReviewStatus (Test-NamedCheckPass -Checks $exportChecks -Name $checkName)) `
      -Evidence "check=$checkName" -Expected 'PASS'
  }

  $flags = @(Get-PropertyValue $exportSummary 'flags')
  Add-Check -Name 'compliance export flags array' -Status (Convert-ReviewStatus ($flags.Count -gt 0)) `
    -Evidence "flags=$($flags.Count)" -Expected 'Compliance export flag results are included'

  $exportRunDir = Split-Path -Parent $reportPath
  $queryOutputPath = Join-Path $exportRunDir 'system_parameter.tsv'
  $queryOutputExists = Test-Path -LiteralPath $queryOutputPath
  Add-Check -Name 'compliance export raw query output exists' -Status (Convert-ReviewStatus $queryOutputExists) `
    -Evidence $queryOutputPath -Expected 'system_parameter.tsv from the query-mode verifier run exists next to summary.json'

  $queryOutputRaw = if ($queryOutputExists) {
    Get-Content -LiteralPath $queryOutputPath -Raw
  } else {
    ''
  }

  foreach ($flagName in @(
      'PMT_STRICT_ENFORCEMENT',
      'AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT',
      'AML_HIGH_VALUE_APPROVAL_ENFORCEMENT',
      'AML_FATF_TIER_ENFORCEMENT',
      'CIRCULAR_ACK_BLOCKING_ENFORCEMENT'
    )) {
    Add-Check -Name "compliance export raw query row:$flagName" -Status (Convert-ReviewStatus ($queryOutputRaw -match "(?m)^$([regex]::Escape($flagName))`t")) `
      -Evidence $queryOutputPath -Expected 'Raw system_parameter.tsv includes the exported flag row'

    $flag = $flags | Where-Object { [string](Get-PropertyValue $_ 'key') -eq $flagName } | Select-Object -First 1
    $flagStatus = if ($null -ne $flag) { [string](Get-PropertyValue $flag 'status') } else { '' }
    Add-Check -Name "compliance export flag:$flagName status" -Status (Convert-ReviewStatus ($flagStatus -eq 'PASS')) `
      -Evidence "status=$flagStatus" -Expected 'PASS'

    $updatedBy = if ($null -ne $flag) { [string](Get-PropertyValue $flag 'updatedBy') } else { '' }
    Add-Check -Name "compliance export flag:$flagName not synthetic" -Status (Convert-ReviewStatus ((Test-TextPresent $updatedBy) -and $updatedBy -ne 'synthetic')) `
      -Evidence "updatedBy=$updatedBy" -Expected 'Not synthetic evidence'
  }
}

function Add-StructuredSignedInstallerReportChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'installer.signedArtifactReportRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "installer.signedArtifactReportRef=$ReportRef" -Expected 'Local structured signed installer artifact summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'installer signed artifact summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured installer smoke summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $installerSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'installer signed artifact summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'installer signed artifact summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  Add-Check -Name 'installer signed artifact checkArtifacts' -Status (Convert-ReviewStatus (Test-BooleanTrue (Get-PropertyValue $installerSummary 'checkArtifacts'))) `
    -Evidence "checkArtifacts=$(Get-PropertyValue $installerSummary 'checkArtifacts')" -Expected 'true'
  Add-Check -Name 'installer signed artifact requireSignature' -Status (Convert-ReviewStatus (Test-BooleanTrue (Get-PropertyValue $installerSummary 'requireSignature'))) `
    -Evidence "requireSignature=$(Get-PropertyValue $installerSummary 'requireSignature')" -Expected 'true'
  $signedFailed = Get-PropertyValue $installerSummary 'failed'
  Add-Check -Name 'installer signed artifact failed' -Status (Convert-ReviewStatus ($null -ne $signedFailed -and [int]$signedFailed -eq 0)) `
    -Evidence "failed=$signedFailed" -Expected '0'
  $signedSkipped = Get-PropertyValue $installerSummary 'skipped'
  Add-Check -Name 'installer signed artifact skipped' -Status (Convert-ReviewStatus ($null -ne $signedSkipped -and [int]$signedSkipped -eq 0)) `
    -Evidence "skipped=$signedSkipped" -Expected '0'

  $installerChecks = @(Get-PropertyValue $installerSummary 'checks')
  Add-Check -Name 'installer signed artifact checks array' -Status (Convert-ReviewStatus ($installerChecks.Count -gt 0)) `
    -Evidence "checks=$($installerChecks.Count)" -Expected 'Installer artifact verifier checks are included'

  Add-StructuredCommandReplay -Area 'installer signed artifact' `
    -VerifierRelativePath 'scripts\installer-smoke-preflight.ps1' `
    -ArgumentList @('-CheckArtifacts', '-RequireSignature') `
    -Expected 'Current installer artifact verifier passes the current signed artifacts with -CheckArtifacts -RequireSignature'

  foreach ($area in @('penztar-client', 'kozponti-client')) {
    foreach ($checkName in @(
        'installer artifact exists',
        'installer artifact age',
        'installer artifact sha256',
        'installer artifact authenticode signature',
        'packaged forbidden secret filenames',
        'packaged text secret patterns',
        'asar forbidden secret filenames',
        'asar text secret patterns'
      )) {
      Add-Check -Name "installer signed artifact $area check:$checkName" -Status (Convert-ReviewStatus (Test-CheckPass -Checks $installerChecks -Area $area -Name $checkName)) `
        -Evidence "area=$area; check=$checkName" -Expected 'PASS'
    }
  }
}

function Add-StructuredCleanVmInstallerReportChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'installer.cleanVmReportRef structured local summary' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "installer.cleanVmReportRef=$ReportRef" -Expected 'Local structured clean Windows VM installer smoke summary.json'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'installer clean VM summary exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Structured clean Windows VM smoke summary JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $cleanVmSummary = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'installer clean VM summary json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'installer clean VM summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  Add-Check -Name 'installer clean VM executeInstall' -Status (Convert-ReviewStatus (Test-BooleanTrue (Get-PropertyValue $cleanVmSummary 'executeInstall'))) `
    -Evidence "executeInstall=$(Get-PropertyValue $cleanVmSummary 'executeInstall')" -Expected 'true'
  Add-Check -Name 'installer clean VM acceptVmMutation' -Status (Convert-ReviewStatus (Test-BooleanTrue (Get-PropertyValue $cleanVmSummary 'acceptVmMutation'))) `
    -Evidence "acceptVmMutation=$(Get-PropertyValue $cleanVmSummary 'acceptVmMutation')" -Expected 'true'
  Add-Check -Name 'installer clean VM confirmDisposableCleanVm' -Status (Convert-ReviewStatus (Test-BooleanTrue (Get-PropertyValue $cleanVmSummary 'confirmDisposableCleanVm'))) `
    -Evidence "confirmDisposableCleanVm=$(Get-PropertyValue $cleanVmSummary 'confirmDisposableCleanVm')" -Expected 'true'
  $skipUninstall = Get-PropertyValue $cleanVmSummary 'skipUninstall'
  Add-Check -Name 'installer clean VM skipUninstall' -Status (Convert-ReviewStatus ($null -ne $skipUninstall -and -not [bool]$skipUninstall)) `
    -Evidence "skipUninstall=$skipUninstall" -Expected 'false'
  $cleanVmFailed = Get-PropertyValue $cleanVmSummary 'failed'
  Add-Check -Name 'installer clean VM failed' -Status (Convert-ReviewStatus ($null -ne $cleanVmFailed -and [int]$cleanVmFailed -eq 0)) `
    -Evidence "failed=$cleanVmFailed" -Expected '0'
  $cleanVmSkipped = Get-PropertyValue $cleanVmSummary 'skipped'
  Add-Check -Name 'installer clean VM skipped' -Status (Convert-ReviewStatus ($null -ne $cleanVmSkipped -and [int]$cleanVmSkipped -eq 0)) `
    -Evidence "skipped=$cleanVmSkipped" -Expected '0'

  $meaning = [string](Get-PropertyValue $cleanVmSummary 'productReadyMeaning')
  Add-Check -Name 'installer clean VM verifier identity' -Status (Convert-ReviewStatus ($meaning -match 'Clean Windows VM installer smoke evidence')) `
    -Evidence $meaning -Expected 'Clean Windows VM installer smoke evidence'

  $cleanVmChecks = @(Get-PropertyValue $cleanVmSummary 'checks')
  Add-Check -Name 'installer clean VM checks array' -Status (Convert-ReviewStatus ($cleanVmChecks.Count -gt 0)) `
    -Evidence "checks=$($cleanVmChecks.Count)" -Expected 'Clean Windows VM verifier checks are included'
  Add-Check -Name 'installer clean VM environment check:vm mutation acknowledgement' -Status (Convert-ReviewStatus (Test-CheckPass -Checks $cleanVmChecks -Area 'environment' -Name 'vm mutation acknowledgement')) `
    -Evidence 'area=environment; check=vm mutation acknowledgement' -Expected 'PASS'
  Add-Check -Name 'installer clean VM environment check:disposable clean VM confirmation' -Status (Convert-ReviewStatus (Test-CheckPass -Checks $cleanVmChecks -Area 'environment' -Name 'disposable clean VM confirmation')) `
    -Evidence 'area=environment; check=disposable clean VM confirmation' -Expected 'PASS'

  foreach ($area in @('penztar-client', 'kozponti-client')) {
    foreach ($checkName in @(
        'installer artifact exists',
        'installer artifact age',
        'installer artifact sha256',
        'silent installer exit code',
        'installed executable exists',
        'launch smoke',
        'uninstaller exists',
        'silent uninstall exit code',
        'executable removed after uninstall'
      )) {
      Add-Check -Name "installer clean VM $area check:$checkName" -Status (Convert-ReviewStatus (Test-CheckPass -Checks $cleanVmChecks -Area $area -Name $checkName)) `
        -Evidence "area=$area; check=$checkName" -Expected 'PASS'
    }

    Add-Check -Name "installer clean VM $area runtime secret scan" -Status (Convert-ReviewStatus (Test-AnyCheckPassByPrefix -Checks $cleanVmChecks -Area $area -NamePrefix 'runtime secret scan:')) `
      -Evidence "area=$area; checkPrefix=runtime secret scan:" -Expected 'At least one runtime secret scan PASS'
  }
}

function Add-StructuredFinalEvidenceChecks {
  param([object]$ReportRef)

  if (-not (Test-TextPresent $ReportRef)) {
    return
  }

  $reportPath = Resolve-LocalEvidencePath $ReportRef
  $reportIsLocal = Test-TextPresent $reportPath
  Add-Check -Name 'finalDecision.externalEvidenceRef structured local json' -Status (Convert-ReviewStatus $reportIsLocal) `
    -Evidence "finalDecision.externalEvidenceRef=$ReportRef" -Expected 'Local completed Product Ready external evidence JSON'

  if (-not $reportIsLocal) {
    return
  }

  $reportExists = Test-Path -LiteralPath $reportPath
  Add-Check -Name 'finalDecision external evidence exists' -Status (Convert-ReviewStatus $reportExists) `
    -Evidence $reportPath -Expected 'Completed external evidence JSON exists'

  if (-not $reportExists) {
    return
  }

  try {
    $finalEvidence = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Add-Check -Name 'finalDecision external evidence json parse' -Status 'PASS' -Evidence $reportPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'finalDecision external evidence json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  $schemaVersion = Get-PropertyValue $finalEvidence 'schemaVersion'
  Add-Check -Name 'finalDecision external evidence schemaVersion' -Status (Convert-ReviewStatus ($schemaVersion -eq 1)) `
    -Evidence "schemaVersion=$schemaVersion" -Expected '1'

  $evidenceStatus = Get-PropertyValue $finalEvidence 'evidenceStatus'
  Add-Check -Name 'finalDecision external evidence status' -Status (Convert-ReviewStatus ([string]$evidenceStatus -eq 'COMPLETE')) `
    -Evidence "evidenceStatus=$evidenceStatus" -Expected 'COMPLETE'

  $environment = Get-PropertyValue $finalEvidence 'environment'
  Add-Check -Name 'finalDecision external evidence environment' -Status (Convert-ReviewStatus ($environment -in @('staging', 'production'))) `
    -Evidence "environment=$environment" -Expected 'staging or production'

  $localBundleRef = Get-PropertyValue $finalEvidence 'localEvidenceBundleRef'
  Add-Check -Name 'finalDecision external evidence local bundle ref' -Status (Convert-ReviewStatus (Test-EvidenceRef $localBundleRef)) `
    -Evidence "localEvidenceBundleRef=$localBundleRef" -Expected 'Existing local evidence bundle reference'

  $finalDecision = Get-PropertyValue $finalEvidence 'finalDecision'
  $claimValue = Get-PropertyValue $finalDecision 'readyForProductReadyClaim'
  Add-Check -Name 'finalDecision external evidence claim flag' -Status (Convert-ReviewStatus (Test-BooleanTrue $claimValue)) `
    -Evidence "readyForProductReadyClaim=$claimValue" -Expected 'true'
}

function Test-FinalGateStepPassed {
  param(
    [object[]]$Steps,
    [string]$Name
  )

  $step = $Steps | Where-Object { [string](Get-PropertyValue $_ 'name') -eq $Name } | Select-Object -First 1
  if ($null -eq $step) {
    return $false
  }

  return (Test-BooleanTrue (Get-PropertyValue $step 'passed'))
}

function Add-StructuredFinalGateSummaryChecks {
  param(
    [object]$SummaryRef,
    [object]$EvidenceRef
  )

  if (-not (Test-TextPresent $SummaryRef)) {
    return
  }

  $summaryPath = Resolve-LocalEvidencePath $SummaryRef
  $summaryIsLocal = Test-TextPresent $summaryPath
  Add-Check -Name 'finalDecision.finalGateSummaryRef structured local summary' -Status (Convert-ReviewStatus $summaryIsLocal) `
    -Evidence "finalDecision.finalGateSummaryRef=$SummaryRef" -Expected 'Local product-ready:final-gate:complete summary.json'

  if (-not $summaryIsLocal) {
    return
  }

  $summaryExists = Test-Path -LiteralPath $summaryPath
  Add-Check -Name 'finalDecision final gate summary exists' -Status (Convert-ReviewStatus $summaryExists) `
    -Evidence $summaryPath -Expected 'Final gate summary JSON exists'

  if (-not $summaryExists) {
    return
  }

  try {
    $finalGateSummary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    Add-Check -Name 'finalDecision final gate summary json parse' -Status 'PASS' -Evidence $summaryPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'finalDecision final gate summary json parse' -Status (Convert-ReviewStatus $false) `
      -Evidence $_.Exception.Message -Expected 'Valid JSON'
    return
  }

  Add-Check -Name 'finalDecision final gate requireComplete' -Status (Convert-ReviewStatus (Test-BooleanTrue (Get-PropertyValue $finalGateSummary 'requireComplete'))) `
    -Evidence "requireComplete=$(Get-PropertyValue $finalGateSummary 'requireComplete')" -Expected 'true'

  $failed = Get-PropertyValue $finalGateSummary 'failed'
  Add-Check -Name 'finalDecision final gate failed' -Status (Convert-ReviewStatus ($null -ne $failed -and [int]$failed -eq 0)) `
    -Evidence "failed=$failed" -Expected '0'

  $passed = Get-PropertyValue $finalGateSummary 'passed'
  Add-Check -Name 'finalDecision final gate passed count' -Status (Convert-ReviewStatus ($null -ne $passed -and [int]$passed -ge 3)) `
    -Evidence "passed=$passed" -Expected '>= 3'

  $verdict = [string](Get-PropertyValue $finalGateSummary 'verdict')
  Add-Check -Name 'finalDecision final gate verdict' -Status (Convert-ReviewStatus ($verdict -match 'complete external/staging/production evidence')) `
    -Evidence $verdict -Expected 'Final Product Ready gate passed with complete external/staging/production evidence'

  $steps = @(Get-PropertyValue $finalGateSummary 'steps')
  Add-Check -Name 'finalDecision final gate steps array' -Status (Convert-ReviewStatus ($steps.Count -gt 0)) `
    -Evidence "steps=$($steps.Count)" -Expected 'Final gate steps are included'

  foreach ($stepName in @('local_product_ready_gate', 'local_evidence_bundle', 'external_evidence_gate')) {
    Add-Check -Name "finalDecision final gate step:$stepName" -Status (Convert-ReviewStatus (Test-FinalGateStepPassed -Steps $steps -Name $stepName)) `
      -Evidence "step=$stepName" -Expected 'PASS'
  }

  $summaryEvidencePath = Get-PropertyValue $finalGateSummary 'finalGateEvidencePath'
  Add-Check -Name 'finalDecision final gate evidence path exists' -Status (Convert-ReviewStatus (Test-EvidenceRef $summaryEvidencePath)) `
    -Evidence "finalGateEvidencePath=$summaryEvidencePath" -Expected 'Final gate evidence JSON exists'

  if ((Test-TextPresent $EvidenceRef) -and (Test-TextPresent $summaryEvidencePath)) {
    $expectedPath = Resolve-LocalEvidencePath $EvidenceRef
    $actualPath = Resolve-LocalEvidencePath $summaryEvidencePath
    $matches = ((Test-TextPresent $expectedPath) -and (Test-TextPresent $actualPath) -and
      ([System.IO.Path]::GetFullPath($expectedPath) -eq [System.IO.Path]::GetFullPath($actualPath)))
    Add-Check -Name 'finalDecision final gate evidence path matches decision evidence' -Status (Convert-ReviewStatus $matches) `
      -Evidence "externalEvidenceRef=$EvidenceRef; finalGateEvidencePath=$summaryEvidencePath" -Expected 'Final gate summary points to the completed evidence JSON'
  }
}

try {
  $evidenceFileExists = Test-Path -LiteralPath $EvidencePath
  Add-Check -Name 'external evidence file exists' -Status ($(if ($evidenceFileExists) { 'PASS' } else { 'FAIL' })) `
    -Evidence $EvidencePath -Expected 'Product Ready external evidence JSON exists'

  if (-not $evidenceFileExists) {
    throw 'External evidence JSON is missing.'
  }

  $raw = Get-Content -LiteralPath $EvidencePath -Raw
  $secretPattern = '(?i)(password|passwd|secret|api[_-]?key|token|private[_-]?key|client[_-]?secret)\s*[:=]\s*["''][^"'']{8,}["'']'
  Add-Check -Name 'external evidence secret pattern scan' -Status ($(if ($raw -match $secretPattern) { 'FAIL' } else { 'PASS' })) `
    -Evidence $EvidencePath -Expected 'No secret values are stored in the evidence artifact'

  try {
    $evidence = $raw | ConvertFrom-Json
    Add-Check -Name 'external evidence json parse' -Status 'PASS' -Evidence $EvidencePath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'external evidence json parse' -Status 'FAIL' -Evidence $_.Exception.Message -Expected 'Valid JSON'
    throw
  }

  $schemaVersion = Get-PropertyValue $evidence 'schemaVersion'
  Add-Check -Name 'schemaVersion' -Status ($(if ($schemaVersion -eq 1) { 'PASS' } else { 'FAIL' })) `
    -Evidence "schemaVersion=$schemaVersion" -Expected '1'

  $evidenceStatus = Get-PropertyValue $evidence 'evidenceStatus'
  Add-Check -Name 'evidenceStatus' -Status (Convert-ReviewStatus ([string]$evidenceStatus -eq 'COMPLETE')) `
    -Evidence "evidenceStatus=$evidenceStatus" -Expected 'COMPLETE'

  $environment = Get-PropertyValue $evidence 'environment'
  Add-Check -Name 'environment' -Status (Convert-ReviewStatus ($environment -in @('staging', 'production'))) `
    -Evidence "environment=$environment" -Expected 'staging or production'

  Add-RequiredDateCheck -Name 'generatedAt' -Value (Get-PropertyValue $evidence 'generatedAt')
  $localEvidenceBundleRef = Get-PropertyValue $evidence 'localEvidenceBundleRef'
  Add-RequiredEvidenceRefCheck -Name 'localEvidenceBundleRef' -Value $localEvidenceBundleRef
  Add-LocalEvidenceBundleChecks -BundleRef $localEvidenceBundleRef
  Add-RequiredTextCheck -Name 'evidenceOwner' -Value (Get-PropertyValue $evidence 'evidenceOwner') -Expected 'Evidence owner is recorded'

  $approvals = Get-PropertyValue $evidence 'approvals'
  if (Add-SectionExistsCheck -Name 'approvals' -Value $approvals) {
    $approvalsReportRef = Get-PropertyValue $approvals 'reportRef'
    Add-RequiredEvidenceRefCheck -Name 'approvals.reportRef' -Value $approvalsReportRef
    Add-StructuredApprovalsReportChecks -ReportRef $approvalsReportRef
    Add-RequiredTextCheck -Name 'approvals.productOwner' -Value (Get-PropertyValue $approvals 'productOwner') -Expected 'Product owner approval is recorded'
    Add-RequiredTextCheck -Name 'approvals.operationsOwner' -Value (Get-PropertyValue $approvals 'operationsOwner') -Expected 'Operations approval is recorded'
    Add-RequiredTextCheck -Name 'approvals.complianceOwner' -Value (Get-PropertyValue $approvals 'complianceOwner') -Expected 'Compliance approval is recorded'
  }

  $acceptance = Get-PropertyValue $evidence 'acceptance'
  if (Add-SectionExistsCheck -Name 'acceptance' -Value $acceptance) {
    Add-RequiredStatusPassCheck -Name 'acceptance.status' -Value (Get-PropertyValue $acceptance 'status')
    Add-RequiredDateCheck -Name 'acceptance.executedAt' -Value (Get-PropertyValue $acceptance 'executedAt')
    $acceptanceReportRef = Get-PropertyValue $acceptance 'reportRef'
    Add-RequiredEvidenceRefCheck -Name 'acceptance.reportRef' -Value $acceptanceReportRef
    Add-StructuredAcceptanceReportChecks -ReportRef $acceptanceReportRef
    $localCoverageReportRef = Get-PropertyValue $acceptance 'localCoverageReportRef'
    Add-RequiredEvidenceRefCheck -Name 'acceptance.localCoverageReportRef' -Value $localCoverageReportRef
    Add-StructuredLocalAcceptanceCoverageChecks -ReportRef $localCoverageReportRef
    Add-RequiredZeroCheck -Name 'acceptance.failed' -Value (Get-PropertyValue $acceptance 'failed')
    Add-RequiredTrueCheck -Name 'acceptance.criticalFlowsPassed' -Value (Get-PropertyValue $acceptance 'criticalFlowsPassed')
    $coveredFlows = Get-PropertyValue $acceptance 'coveredFlows'
    foreach ($flow in @('buy', 'sell', 'conversion', 'transfer', 'storno', 'dayClosing', 'navCashRegister', 'receiptPrint', 'offlineSync')) {
      $covered = ($null -ne $coveredFlows -and @($coveredFlows) -contains $flow)
      Add-Check -Name "acceptance.coveredFlows.$flow" -Status (Convert-ReviewStatus $covered) -Evidence "covered=$covered" -Expected 'Flow is covered by staging/production acceptance evidence'
    }
  }

  $compliance = Get-PropertyValue $evidence 'compliance'
  if (Add-SectionExistsCheck -Name 'compliance' -Value $compliance) {
    Add-RequiredStatusPassCheck -Name 'compliance.status' -Value (Get-PropertyValue $compliance 'status')
    $approvedDecisionRef = Get-PropertyValue $compliance 'approvedDecisionRef'
    Add-RequiredEvidenceRefCheck -Name 'compliance.approvedDecisionRef' -Value $approvedDecisionRef
    Add-StructuredComplianceDecisionReportChecks -ReportRef $approvedDecisionRef
    $exportReportRef = Get-PropertyValue $compliance 'exportReportRef'
    Add-RequiredEvidenceRefCheck -Name 'compliance.exportReportRef' -Value $exportReportRef
    Add-StructuredComplianceExportReportChecks -ReportRef $exportReportRef
    $approvedDecisionStatus = Get-PropertyValue $compliance 'approvedDecisionStatus'
    Add-Check -Name 'compliance.approvedDecisionStatus' -Status (Convert-ReviewStatus ([string]$approvedDecisionStatus -eq 'APPROVED')) `
      -Evidence "approvedDecisionStatus=$approvedDecisionStatus" -Expected 'APPROVED'
    $exportedEnvironment = Get-PropertyValue $compliance 'exportedEnvironment'
    $exportedEnvironmentOk = ($exportedEnvironment -in @('staging', 'production') -and $exportedEnvironment -eq $environment)
    Add-Check -Name 'compliance.exportedEnvironment' -Status (Convert-ReviewStatus $exportedEnvironmentOk) `
      -Evidence "exportedEnvironment=$exportedEnvironment; environment=$environment" -Expected 'Matches top-level staging/production environment'
    Add-RequiredZeroCheck -Name 'compliance.failed' -Value (Get-PropertyValue $compliance 'failed')
  }

  $drRestore = Get-PropertyValue $evidence 'drRestore'
  if (Add-SectionExistsCheck -Name 'drRestore' -Value $drRestore) {
    Add-RequiredStatusPassCheck -Name 'drRestore.status' -Value (Get-PropertyValue $drRestore 'status')
    Add-RequiredDateCheck -Name 'drRestore.executedAt' -Value (Get-PropertyValue $drRestore 'executedAt')
    $drRestoreReportRef = Get-PropertyValue $drRestore 'reportRef'
    Add-RequiredEvidenceRefCheck -Name 'drRestore.reportRef' -Value $drRestoreReportRef
    Add-StructuredDrRestoreReportChecks -ReportRef $drRestoreReportRef
    Add-RequiredMinNumberCheck -Name 'drRestore.rtoMinutes' -Value (Get-PropertyValue $drRestore 'rtoMinutes') -Minimum 1
    Add-RequiredTrueCheck -Name 'drRestore.flywayVerified' -Value (Get-PropertyValue $drRestore 'flywayVerified')
    Add-RequiredTrueCheck -Name 'drRestore.auditHashChainVerified' -Value (Get-PropertyValue $drRestore 'auditHashChainVerified')
    $rowCounts = Get-PropertyValue $drRestore 'rowCounts'
    if (Add-SectionExistsCheck -Name 'drRestore.rowCounts' -Value $rowCounts) {
      foreach ($table in @('transactions', 'audit_log', 'aml_report', 'customer')) {
        Add-RequiredMinNumberCheck -Name "drRestore.rowCounts.$table" -Value (Get-PropertyValue $rowCounts $table) -Minimum 1
      }
    }
  }

  $monitoring = Get-PropertyValue $evidence 'monitoring'
  if (Add-SectionExistsCheck -Name 'monitoring' -Value $monitoring) {
    Add-RequiredStatusPassCheck -Name 'monitoring.status' -Value (Get-PropertyValue $monitoring 'status')
    $monitoringReportRef = Get-PropertyValue $monitoring 'reportRef'
    Add-RequiredEvidenceRefCheck -Name 'monitoring.reportRef' -Value $monitoringReportRef
    Add-StructuredMonitoringReportChecks -ReportRef $monitoringReportRef
    Add-RequiredMinNumberCheck -Name 'monitoring.observationHours' -Value (Get-PropertyValue $monitoring 'observationHours') -Minimum 168
    Add-RequiredTrueCheck -Name 'monitoring.scrapeVerified' -Value (Get-PropertyValue $monitoring 'scrapeVerified')
    Add-RequiredTrueCheck -Name 'monitoring.dashboardLoaded' -Value (Get-PropertyValue $monitoring 'dashboardLoaded')
    Add-RequiredTrueCheck -Name 'monitoring.alertDelivered' -Value (Get-PropertyValue $monitoring 'alertDelivered')
  }

  $installer = Get-PropertyValue $evidence 'installer'
  if (Add-SectionExistsCheck -Name 'installer' -Value $installer) {
    Add-RequiredStatusPassCheck -Name 'installer.status' -Value (Get-PropertyValue $installer 'status')
    $signedArtifactReportRef = Get-PropertyValue $installer 'signedArtifactReportRef'
    Add-RequiredEvidenceRefCheck -Name 'installer.signedArtifactReportRef' -Value $signedArtifactReportRef
    Add-StructuredSignedInstallerReportChecks -ReportRef $signedArtifactReportRef
    $cleanVmReportRef = Get-PropertyValue $installer 'cleanVmReportRef'
    Add-RequiredEvidenceRefCheck -Name 'installer.cleanVmReportRef' -Value $cleanVmReportRef
    Add-StructuredCleanVmInstallerReportChecks -ReportRef $cleanVmReportRef
    Add-RequiredTrueCheck -Name 'installer.signedArtifactsVerified' -Value (Get-PropertyValue $installer 'signedArtifactsVerified')

    $clients = @(Get-PropertyValue $installer 'clients')
    foreach ($clientName in @('penztar', 'kozponti')) {
      $client = $clients | Where-Object { (Get-PropertyValue $_ 'name') -eq $clientName } | Select-Object -First 1
      if (Add-SectionExistsCheck -Name "installer.clients.$clientName" -Value $client) {
        Add-RequiredTrueCheck -Name "installer.clients.$clientName.installed" -Value (Get-PropertyValue $client 'installed')
        Add-RequiredTrueCheck -Name "installer.clients.$clientName.launched" -Value (Get-PropertyValue $client 'launched')
        Add-RequiredTrueCheck -Name "installer.clients.$clientName.uninstalled" -Value (Get-PropertyValue $client 'uninstalled')
      }
    }
  }

  $finalDecision = Get-PropertyValue $evidence 'finalDecision'
  if (Add-SectionExistsCheck -Name 'finalDecision' -Value $finalDecision) {
    Add-RequiredTrueCheck -Name 'finalDecision.readyForProductReadyClaim' -Value (Get-PropertyValue $finalDecision 'readyForProductReadyClaim')
    Add-RequiredDateCheck -Name 'finalDecision.decidedAt' -Value (Get-PropertyValue $finalDecision 'decidedAt')
    Add-Check -Name 'finalDecision temporal consistency' `
      -Status (Convert-ReviewStatus (Test-FinalDecisionTemporalConsistency -Evidence $evidence -FinalDecision $finalDecision)) `
      -Evidence (Format-FinalDecisionTemporalEvidence -Evidence $evidence -FinalDecision $finalDecision) `
      -Expected 'Final decision decidedAt is not earlier than generatedAt, acceptance, DR, approvals, compliance, monitoring, and installer evidence timestamps'
    Add-RequiredTextCheck -Name 'finalDecision.decidedBy' -Value (Get-PropertyValue $finalDecision 'decidedBy') -Expected 'Final Product Ready decision owner is recorded'
    $externalEvidenceRef = Get-PropertyValue $finalDecision 'externalEvidenceRef'
    Add-RequiredEvidenceRefCheck -Name 'finalDecision.externalEvidenceRef' -Value $externalEvidenceRef
    $resolvedExternalEvidenceRef = Resolve-LocalEvidencePath $externalEvidenceRef
    $resolvedCurrentEvidencePath = Resolve-LocalEvidencePath $EvidencePath
    $externalEvidenceRefMatchesCurrent = (
      (Test-TextPresent $resolvedExternalEvidenceRef) -and
      (Test-TextPresent $resolvedCurrentEvidencePath) -and
      ([System.IO.Path]::GetFullPath($resolvedExternalEvidenceRef) -eq [System.IO.Path]::GetFullPath($resolvedCurrentEvidencePath))
    )
    Add-Check -Name 'finalDecision external evidence ref matches current evidence' -Status (Convert-ReviewStatus $externalEvidenceRefMatchesCurrent) `
      -Evidence "externalEvidenceRef=$externalEvidenceRef; evidencePath=$EvidencePath" -Expected 'Final decision references the exact external evidence JSON currently being verified'
    Add-StructuredFinalEvidenceChecks -ReportRef $externalEvidenceRef
    $finalGateSummaryRef = Get-PropertyValue $finalDecision 'finalGateSummaryRef'
    if (Test-TextPresent $finalGateSummaryRef) {
      Add-RequiredEvidenceRefCheck -Name 'finalDecision.finalGateSummaryRef' -Value $finalGateSummaryRef
      Add-StructuredFinalGateSummaryChecks -SummaryRef $finalGateSummaryRef -EvidenceRef $externalEvidenceRef
    }
  }
} catch {
  if (-not ($checks | Where-Object { $_.status -eq 'FAIL' })) {
    Add-Check -Name 'external evidence verifier exception' -Status 'FAIL' -Evidence $_.Exception.Message -Expected 'Verifier completes without exception'
  }
}

$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$failed = @($checks | Where-Object { $_.status -eq 'FAIL' }).Count
$reviewRequired = @($checks | Where-Object { $_.status -eq 'REVIEW' }).Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  evidencePath = $EvidencePath
  requireComplete = [bool]$RequireComplete
  passed = $passed
  failed = $failed
  reviewRequired = $reviewRequired
  checks = $checks
  productReadyMeaning = if ($RequireComplete) {
    'Final Product Ready external evidence gate. Product Ready requires zero FAIL and zero REVIEW.'
  } else {
    'Preflight shape check. DRAFT/REVIEW findings must be resolved before final Product Ready claim.'
  }
}

$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready external evidence verification')
$lines.Add('')
$lines.Add("- Generated at: $($summary.generatedAt)")
$lines.Add("- Evidence path: $EvidencePath")
$lines.Add("- Require complete: $([bool]$RequireComplete)")
$lines.Add("- Passed: $passed")
$lines.Add("- Failed: $failed")
$lines.Add("- Review required: $reviewRequired")
$lines.Add('')
$lines.Add('| Status | Check | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($check in $checks) {
  $evidenceText = ([string]$check.evidence).Replace('|', '\|')
  $expectedText = ([string]$check.expected).Replace('|', '\|')
  $lines.Add("| $($check.status) | $($check.name) | $evidenceText | $expectedText |")
}
$lines.Add('')
$lines.Add($summary.productReadyMeaning)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-external-evidence] checks: $passed passed, $failed failed, $reviewRequired review"
Write-Host "[product-ready-external-evidence] report: $reportPath"
Write-Host "[product-ready-external-evidence] summary: $summaryPath"

if ($failed -gt 0 -or ($RequireComplete -and $reviewRequired -gt 0)) {
  exit 1
}
