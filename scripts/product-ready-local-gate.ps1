param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-local-gate'),
  [switch]$Full
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

function New-GateStep {
  param(
    [string]$Name,
    [string]$Command,
    [string]$Profile
  )

  [pscustomobject]@{
    name = $Name
    command = $Command
    profile = $Profile
  }
}

function Get-SafeFileName {
  param([string]$Value)
  return ($Value -replace '[^A-Za-z0-9_.-]', '_').Trim('_')
}

function Test-InstallerArtifactsExist {
  $artifactPaths = @(
    (Join-Path $WorkspaceRoot 'penztar-client\release\Penztar-Setup-2.27.96.exe'),
    (Join-Path $WorkspaceRoot 'kozponti-client\release\Kozponti-Munkaallomas-Setup-2.27.96.exe')
  )

  foreach ($artifactPath in $artifactPaths) {
    if (-not (Test-Path -LiteralPath $artifactPath)) {
      return $false
    }
  }

  return $true
}

$steps = [System.Collections.Generic.List[object]]::new()
$steps.Add((New-GateStep -Name 'flyway_validate' -Command 'npm run migration:flyway:validate' -Profile 'default'))
$steps.Add((New-GateStep -Name 'flyway_content_audit' -Command 'npm run migration:flyway:content-audit:product-ready' -Profile 'default'))
$steps.Add((New-GateStep -Name 'typecheck' -Command 'npm run typecheck' -Profile 'default'))
$steps.Add((New-GateStep -Name 'acceptance_local' -Command 'npm run acceptance:local' -Profile 'default'))
$steps.Add((New-GateStep -Name 'acceptance_coverage' -Command 'npm run product-ready:acceptance-coverage' -Profile 'default'))
$steps.Add((New-GateStep -Name 'staging_acceptance_preflight' -Command 'npm run product-ready:staging-acceptance:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'approvals_preflight' -Command 'npm run product-ready:approvals:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'compliance_flags' -Command 'npm run compliance:flags:test' -Profile 'default'))
$steps.Add((New-GateStep -Name 'compliance_golive_preflight' -Command 'npm run compliance:golive:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'compliance_golive_decision_preflight' -Command 'npm run compliance:golive:decision:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'compliance_golive_synthetic' -Command 'npm run compliance:golive:synthetic' -Profile 'default'))
$steps.Add((New-GateStep -Name 'audit_hash_chain_test' -Command 'npm run audit:hash-chain:test' -Profile 'default'))
$steps.Add((New-GateStep -Name 'audit_hash_chain_preflight' -Command 'npm run audit:hash-chain:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'security_gate' -Command 'powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1' -Profile 'default'))
$steps.Add((New-GateStep -Name 'installer_smoke_preflight' -Command 'npm run installer:smoke:preflight' -Profile 'default'))
if (Test-InstallerArtifactsExist) {
  $steps.Add((New-GateStep -Name 'installer_smoke_signed' -Command 'npm run installer:smoke:signed' -Profile 'default'))
} else {
  $steps.Add((New-GateStep -Name 'installer_smoke_synthetic' -Command 'npm run installer:smoke:synthetic' -Profile 'default'))
}
$steps.Add((New-GateStep -Name 'installer_clean_vm_preflight' -Command 'npm run installer:smoke:clean-vm' -Profile 'default'))
$steps.Add((New-GateStep -Name 'dr_restore_preflight' -Command 'npm run dr:restore:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'dr_restore_synthetic' -Command 'npm run dr:restore:synthetic' -Profile 'default'))
$steps.Add((New-GateStep -Name 'monitoring_preflight' -Command 'npm run monitoring:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'monitoring_synthetic' -Command 'npm run monitoring:synthetic' -Profile 'default'))
$steps.Add((New-GateStep -Name 'monitoring_evidence_preflight' -Command 'npm run product-ready:monitoring-evidence:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'product_ready_evidence_preflight' -Command 'npm run product-ready:evidence:preflight' -Profile 'default'))
$steps.Add((New-GateStep -Name 'product_ready_external_evidence_preflight' -Command 'npm run product-ready:external-evidence:preflight' -Profile 'default'))

if ($Full) {
  $steps.Add((New-GateStep -Name 'lint' -Command 'npm run lint' -Profile 'full'))
  $steps.Add((New-GateStep -Name 'build_all' -Command 'npm run build:all' -Profile 'full'))
}

$results = [System.Collections.Generic.List[object]]::new()

foreach ($step in $steps) {
  $safeName = Get-SafeFileName $step.name
  $stdoutPath = Join-Path $runDir "$safeName.stdout.log"
  $stderrPath = Join-Path $runDir "$safeName.stderr.log"
  $combinedPath = Join-Path $runDir "$safeName.log"
  $startedAt = Get-Date

  Write-Host "[product-ready-local-gate] running $($step.name): $($step.command)"

  $process = Start-Process `
    -FilePath 'cmd.exe' `
    -ArgumentList @('/d', '/c', $step.command) `
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
    "COMMAND: $($step.command)",
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

  $passed = ($process.ExitCode -eq 0)
  $durationSeconds = [math]::Round(($finishedAt - $startedAt).TotalSeconds, 2)
  $results.Add([pscustomobject]@{
      name = $step.name
      command = $step.command
      profile = $step.profile
      passed = $passed
      exitCode = $process.ExitCode
      durationSeconds = $durationSeconds
      log = $combinedPath
    })

  $status = if ($passed) { 'PASS' } else { 'FAIL' }
  Write-Host "[product-ready-local-gate] $($step.name): $status ($durationSeconds sec)"
}

$failed = @($results | Where-Object { -not $_.passed })
$passedCount = @($results | Where-Object { $_.passed }).Count
$failedCount = $failed.Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  fullProfile = [bool]$Full
  passed = $passedCount
  failed = $failedCount
  steps = $results
  verdict = if ($failedCount -eq 0) {
    'Local Product Ready gate passed. This is not final Product Ready proof without external/staging evidence.'
  } else {
    'Local Product Ready gate failed. Fix failed steps before continuing Product Ready validation.'
  }
  pendingExternalEvidence = @(
    'Staging or production full business acceptance execution evidence',
    'Real backup restore drill with row counts, Flyway state, audit hash-chain smoke, and measured RTO',
    'Deployed monitoring scrape, dashboard load, and alert delivery evidence',
    'Clean Windows VM installer smoke for penztar and kozponti clients',
    'Compliance go-live decision and environment export for relevant system_parameter values',
    'Completed docs\PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json artifact and passing product-ready:external-evidence:complete gate'
  )
}

$jsonPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$mdPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready local gate')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Workspace: $WorkspaceRoot")
$lines.Add("- Full profile: $([bool]$Full)")
$lines.Add("- Steps: $passedCount passed, $failedCount failed")
$lines.Add('')
$lines.Add('## Steps')
$lines.Add('')
$lines.Add('| Step | Profile | Status | Exit code | Duration sec | Log |')
$lines.Add('| --- | --- | --- | --- | --- | --- |')
foreach ($result in $results) {
  $status = if ($result.passed) { 'PASS' } else { 'FAIL' }
  $lines.Add("| $($result.name) | $($result.profile) | $status | $($result.exitCode) | $($result.durationSeconds) | $($result.log) |")
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
$lines.Add($summary.verdict)

$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

Write-Host "[product-ready-local-gate] steps: $passedCount passed, $failedCount failed"
Write-Host "[product-ready-local-gate] report: $mdPath"
Write-Host "[product-ready-local-gate] summary: $jsonPath"

if ($failedCount -gt 0) {
  exit 1
}
exit 0
