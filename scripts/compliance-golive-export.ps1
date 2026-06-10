param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\compliance-golive'),
  [string]$TargetHost,
  [int]$TargetPort = 5432,
  [string]$TargetUser,
  [string]$TargetDatabase,
  [string]$DecisionPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\COMPLIANCE_GO_LIVE_DECISION_TEMPLATE_2026-06-09.json'),
  [string]$DockerImage = 'postgres:16-alpine',
  [switch]$UseDockerTools,
  [switch]$ExecuteQuery,
  [switch]$RequireApprovedDecision
)

$ErrorActionPreference = 'Stop'

if (-not $TargetHost) { $TargetHost = if ($env:PGHOST) { $env:PGHOST } else { 'localhost' } }
if (-not $TargetUser) { $TargetUser = if ($env:PGUSER) { $env:PGUSER } else { 'postgres' } }
if (-not $TargetDatabase -and $env:PGDATABASE) { $TargetDatabase = $env:PGDATABASE }

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()
$flagResults = [System.Collections.Generic.List[object]]::new()

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

function Resolve-Tool {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Resolve-DockerTool {
  $cmd = Get-Command docker -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Get-DockerToolHost {
  param([string]$HostName)
  if ($HostName -eq 'localhost' -or $HostName -eq '127.0.0.1') {
    return 'host.docker.internal'
  }
  return $HostName
}

function Get-RepoPath {
  param([string]$RelativePath)
  return Join-Path $WorkspaceRoot $RelativePath
}

function Test-RepoPath {
  param([string]$RelativePath)
  return Test-Path -LiteralPath (Get-RepoPath $RelativePath)
}

function Get-RepoContent {
  param([string]$RelativePath)
  $path = Get-RepoPath $RelativePath
  if (-not (Test-Path -LiteralPath $path)) { return '' }
  return Get-Content -LiteralPath $path -Raw
}

function Add-PathCheck {
  param([string]$RelativePath, [string]$Expected)
  Add-Check -Name $RelativePath -Status ($(if (Test-RepoPath $RelativePath) { 'PASS' } else { 'FAIL' })) `
    -Evidence $RelativePath -Expected $Expected
}

function Add-ContentCheck {
  param([string]$RelativePath, [string]$Pattern, [string]$Expected)
  $content = Get-RepoContent $RelativePath
  Add-Check -Name "$RelativePath contains $Pattern" -Status ($(if ($content -match [regex]::Escape($Pattern)) { 'PASS' } else { 'FAIL' })) `
    -Evidence $RelativePath -Expected $Expected
}

function Get-NormalizedBool {
  param([string]$Value)
  if ($null -eq $Value) { return $null }
  $v = $Value.Trim().ToLowerInvariant()
  if ($v -in @('true', '1', 'yes', 'y', 'on')) { return $true }
  if ($v -in @('false', '0', 'no', 'n', 'off')) { return $false }
  return $null
}

function ConvertTo-Status {
  param(
    [object]$Flag,
    [object]$DbRow,
    [object]$Decision
  )

  $value = $null
  $active = $null
  if ($DbRow) {
    $value = $DbRow.parameterValue
    $active = Get-NormalizedBool $DbRow.isActive
  }

  if ($Flag.gate -eq 'hard_true') {
    if (-not $DbRow) {
      if ($Flag.codeDefault -eq 'true') {
        return 'REVIEW'
      }
      return 'FAIL'
    }
    if ($active -ne $true) { return 'FAIL' }
    if ((Get-NormalizedBool $value) -ne $true) { return 'FAIL' }
    return 'PASS'
  }

  if ($Decision -and $Decision.decisionStatus -eq 'APPROVED') {
    $approved = $Decision.flags | Where-Object { $_.key -eq $Flag.key } | Select-Object -First 1
    if ($approved) {
      if (-not $DbRow) { return 'FAIL' }
      if ($active -ne $true) { return 'FAIL' }
      if ($approved.approvedValue -ne $value) { return 'FAIL' }
      return 'PASS'
    }
  }

  return 'REVIEW'
}

$flags = @(
  [pscustomobject]@{
    key = 'PMT_STRICT_ENFORCEMENT'
    codeDefault = 'true'
    gate = 'hard_true'
    reason = 'Pmt. strict validation should remain enabled unless a signed compliance waiver exists'
  },
  [pscustomobject]@{
    key = 'AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT'
    codeDefault = 'false'
    gate = 'hard_true'
    reason = 'V291 activates structured source-of-funds enforcement for >=50M HUF transactions'
  },
  [pscustomobject]@{
    key = 'AML_HIGH_VALUE_APPROVAL_ENFORCEMENT'
    codeDefault = 'false'
    gate = 'decision_required'
    reason = '10M+/enhanced AML hard-block vs warn-only is a business/compliance go-live decision'
  },
  [pscustomobject]@{
    key = 'AML_FATF_TIER_ENFORCEMENT'
    codeDefault = 'false'
    gate = 'decision_required'
    reason = 'FATF tier enforcement policy must be approved before go-live'
  },
  [pscustomobject]@{
    key = 'CIRCULAR_ACK_BLOCKING_ENFORCEMENT'
    codeDefault = 'false'
    gate = 'decision_required'
    reason = 'Mandatory circular acknowledgement blocking can stop cashier transactions and needs operational approval'
  }
)

Add-PathCheck -RelativePath 'docs\COMPLIANCE_FLAG_MATRIX_2026-06-09.md' -Expected 'Compliance flag matrix exists'
Add-PathCheck -RelativePath 'docs\operations\compliance-audit-checklist.md' -Expected 'Compliance audit checklist exists'
Add-PathCheck -RelativePath 'docs\COMPLIANCE_GO_LIVE_DECISION_TEMPLATE_2026-06-09.json' -Expected 'Go-live decision template exists'
Add-ContentCheck -RelativePath 'backend\src\main\resources\db\migration\V291__activate_source_of_funds_50m_enforcement.sql' `
  -Pattern "'AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT', 'true'" `
  -Expected '50M source-of-funds enforcement is activated by migration'
Add-ContentCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\PmtComplianceValidator.java' `
  -Pattern 'PMT_STRICT_ENFORCEMENT' `
  -Expected 'Pmt strict enforcement parameter is used'
Add-ContentCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\TransactionService.java' `
  -Pattern 'AML_HIGH_VALUE_APPROVAL_ENFORCEMENT' `
  -Expected 'High-value approval flag is used'
Add-ContentCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\AmlService.java' `
  -Pattern 'AML_FATF_TIER_ENFORCEMENT' `
  -Expected 'FATF tier enforcement flag is used'
Add-ContentCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\TransactionService.java' `
  -Pattern 'CIRCULAR_ACK_BLOCKING_ENFORCEMENT' `
  -Expected 'Circular acknowledgement blocking flag is used'

$psqlTool = Resolve-Tool 'psql'
$dockerTool = Resolve-DockerTool
if ($UseDockerTools -or (-not $psqlTool -and $dockerTool)) {
  $UseDockerTools = $true
}
Add-Check -Name 'tool:psql' -Status ($(if ($psqlTool) { 'PASS' } else { 'MISSING' })) `
  -Evidence ($(if ($psqlTool) { $psqlTool } else { 'not found on PATH' })) `
  -Expected 'Required only with -ExecuteQuery'
Add-Check -Name 'tool:docker' -Status ($(if ($dockerTool) { 'PASS' } else { 'MISSING' })) `
  -Evidence ($(if ($dockerTool) { $dockerTool } else { 'not found on PATH' })) `
  -Expected 'Fallback PostgreSQL client tools when native psql is missing'
Add-Check -Name 'postgres client tool mode' -Status ($(if ($UseDockerTools) { 'DOCKER' } else { 'NATIVE' })) `
  -Evidence ($(if ($UseDockerTools) { $DockerImage } else { 'PATH tools' })) `
  -Expected 'NATIVE when psql exists, DOCKER fallback otherwise'

$decision = $null
$decisionExists = Test-Path -LiteralPath $DecisionPath
Add-Check -Name 'decision file' -Status ($(if ($decisionExists) { 'PASS' } else { 'MISSING' })) `
  -Evidence $DecisionPath -Expected 'Decision template or approved decision JSON'
if ($decisionExists) {
  try {
    $decision = Get-Content -LiteralPath $DecisionPath -Raw | ConvertFrom-Json
    Add-Check -Name 'decision json parse' -Status 'PASS' -Evidence $DecisionPath -Expected 'Valid JSON'
    if ($RequireApprovedDecision -and $decision.decisionStatus -ne 'APPROVED') {
      Add-Check -Name 'approved decision status' -Status 'FAIL' -Evidence "decisionStatus=$($decision.decisionStatus)" -Expected 'APPROVED'
    } elseif ($decision.decisionStatus -eq 'APPROVED') {
      Add-Check -Name 'approved decision status' -Status 'PASS' -Evidence "decisionStatus=$($decision.decisionStatus)" -Expected 'APPROVED'
    } else {
      Add-Check -Name 'approved decision status' -Status 'REVIEW' -Evidence "decisionStatus=$($decision.decisionStatus)" -Expected 'APPROVED before Product Ready claim'
    }
  } catch {
    Add-Check -Name 'decision json parse' -Status 'FAIL' -Evidence $_.Exception.Message -Expected 'Valid JSON'
  }
}

$dbRows = @{}
if ($ExecuteQuery) {
  if (-not $TargetDatabase) {
    Add-Check -Name 'target database' -Status 'FAIL' -Evidence 'TargetDatabase/PGDATABASE is empty' -Expected 'Database name required with -ExecuteQuery'
  } elseif (-not $psqlTool -and -not ($UseDockerTools -and $dockerTool)) {
    Add-Check -Name 'query execution' -Status 'FAIL' -Evidence 'psql not found and Docker tool mode unavailable' -Expected 'psql or Docker available'
  } else {
    $keysSql = ($flags | ForEach-Object { "'" + $_.key.Replace("'", "''") + "'" }) -join ','
    $sql = @"
SELECT concat_ws(chr(9),
  parameter_key,
  replace(replace(parameter_value, chr(10), ' '), chr(13), ' '),
  parameter_type,
  category,
  is_active::text,
  COALESCE(updated_at::text, ''),
  COALESCE(updated_by, '')
)
FROM system_parameter
WHERE parameter_key IN ($keysSql)
ORDER BY parameter_key;
"@
    $stdoutPath = Join-Path $runDir 'system_parameter.tsv'
    $stderrPath = Join-Path $runDir 'system_parameter.stderr.log'
    if ($UseDockerTools) {
      $args = @('run', '--rm')
      if ($env:PGPASSWORD) {
        $args += @('-e', 'PGPASSWORD')
      }
      $args += $DockerImage
      $args += @(
        'psql',
        '-h', (Get-DockerToolHost $TargetHost),
        '-p', "$TargetPort",
        '-U', $TargetUser,
        '-d', $TargetDatabase,
        '-v', 'ON_ERROR_STOP=1',
        '-t',
        '-A',
        '-c', $sql
      )
      & $dockerTool @args 1> $stdoutPath 2> $stderrPath
      $exitCode = $LASTEXITCODE
    } else {
      $args = @(
        '-h', $TargetHost,
        '-p', "$TargetPort",
        '-U', $TargetUser,
        '-d', $TargetDatabase,
        '-v', 'ON_ERROR_STOP=1',
        '-t',
        '-A',
        '-c', $sql
      )
      & $psqlTool @args 1> $stdoutPath 2> $stderrPath
      $exitCode = $LASTEXITCODE
    }
    if ($exitCode -eq 0) {
      Add-Check -Name 'query execution' -Status 'PASS' -Evidence "stdout=$stdoutPath; stderr=$stderrPath" -Expected 'Query succeeds'
      $rows = Get-Content -LiteralPath $stdoutPath
      foreach ($line in $rows) {
        if (-not $line.Trim()) { continue }
        $parts = $line -split "`t", 7
        if ($parts.Count -ge 5) {
          $dbRows[$parts[0]] = [pscustomobject]@{
            parameterKey = $parts[0]
            parameterValue = $parts[1]
            parameterType = $parts[2]
            category = $parts[3]
            isActive = $parts[4]
            updatedAt = if ($parts.Count -gt 5) { $parts[5] } else { '' }
            updatedBy = if ($parts.Count -gt 6) { $parts[6] } else { '' }
          }
        }
      }
    } else {
      $err = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { '' }
      Add-Check -Name 'query execution' -Status 'FAIL' -Evidence "exit=$exitCode; stderr=$stderrPath; $err" -Expected 'Query succeeds'
    }
  }
} else {
  Add-Check -Name 'query execution' -Status 'SKIP' -Evidence 'Run with -ExecuteQuery and PGHOST/PGUSER/PGDATABASE or explicit parameters' -Expected 'No DB connection in default mode'
}

foreach ($flag in $flags) {
  $row = if ($dbRows.ContainsKey($flag.key)) { $dbRows[$flag.key] } else { $null }
  $status = if ($ExecuteQuery) { ConvertTo-Status -Flag $flag -DbRow $row -Decision $decision } else { 'PENDING_DB_EXPORT' }
  $flagResults.Add([pscustomobject]@{
      key = $flag.key
      status = $status
      gate = $flag.gate
      codeDefault = $flag.codeDefault
      dbValue = if ($row) { $row.parameterValue } else { $null }
      dbActive = if ($row) { $row.isActive } else { $null }
      updatedAt = if ($row) { $row.updatedAt } else { $null }
      updatedBy = if ($row) { $row.updatedBy } else { $null }
      reason = $flag.reason
    })
}

$failedChecks = @($checks | Where-Object { $_.status -eq 'FAIL' })
$failedFlags = @($flagResults | Where-Object { $_.status -eq 'FAIL' })
$reviewFlags = @($flagResults | Where-Object { $_.status -eq 'REVIEW' })

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  mode = if ($ExecuteQuery) { 'query' } else { 'preflight' }
  workspaceRoot = $WorkspaceRoot
  targetHost = if ($ExecuteQuery) { $TargetHost } else { $null }
  targetPort = if ($ExecuteQuery) { $TargetPort } else { $null }
  targetUser = if ($ExecuteQuery) { $TargetUser } else { $null }
  targetDatabase = if ($ExecuteQuery) { $TargetDatabase } else { $null }
  postgresClientToolMode = if ($UseDockerTools) { 'docker' } else { 'native' }
  dockerImage = if ($UseDockerTools) { $DockerImage } else { $null }
  decisionPath = $DecisionPath
  checks = $checks
  flags = $flagResults
  failed = $failedChecks.Count + $failedFlags.Count
  reviewRequired = $reviewFlags.Count
  pendingExternalEvidence = @(
    'Run this script with -ExecuteQuery against staging or production',
    'Attach approved compliance decision JSON with decisionStatus=APPROVED',
    'Attach POS smoke evidence for every enabled hard-block flag',
    'Attach audit-log evidence for blocked transactions and supervisor approvals'
  )
}

$jsonPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$reportPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Compliance go-live export')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Mode: $($summary.mode)")
$lines.Add("- Workspace: $WorkspaceRoot")
$lines.Add("- PostgreSQL client tools: $(if ($UseDockerTools) { "docker:$DockerImage" } else { 'native PATH tools' })")
$lines.Add("- Failed: $($summary.failed)")
$lines.Add("- Review required flags: $($summary.reviewRequired)")
$lines.Add('')
$lines.Add('## Checks')
$lines.Add('')
$lines.Add('| Check | Status | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($check in $checks) {
  $evidence = ($check.evidence -replace '\|', '/')
  $expected = ($check.expected -replace '\|', '/')
  $lines.Add("| $($check.name) | $($check.status) | $evidence | $expected |")
}
$lines.Add('')
$lines.Add('## Flags')
$lines.Add('')
$lines.Add('| Flag | Status | Gate | Code default | DB value | Active | Updated by | Reason |')
$lines.Add('| --- | --- | --- | --- | --- | --- | --- | --- |')
foreach ($flag in $flagResults) {
  $reason = ($flag.reason -replace '\|', '/')
  $lines.Add("| $($flag.key) | $($flag.status) | $($flag.gate) | $($flag.codeDefault) | $($flag.dbValue) | $($flag.dbActive) | $($flag.updatedBy) | $reason |")
}
$lines.Add('')
$lines.Add('## Pending External Evidence')
$lines.Add('')
foreach ($item in $summary.pendingExternalEvidence) {
  $lines.Add("- $item")
}
$lines.Add('')
$lines.Add('## Product Ready Meaning')
$lines.Add('')
if ($ExecuteQuery) {
  $lines.Add('This is DB evidence for the selected environment. Product Ready still requires approved decisions and POS/audit evidence for enabled enforcement paths.')
} else {
  $lines.Add('This preflight proves the export path is prepared. Product Ready still requires a staging/production query run and approved compliance decision artifact.')
}

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[compliance-golive] mode=$($summary.mode), failed=$($summary.failed), reviewRequired=$($summary.reviewRequired)"
Write-Host "[compliance-golive] report: $reportPath"
Write-Host "[compliance-golive] summary: $jsonPath"

if ($summary.failed -gt 0) {
  exit 1
}
exit 0
