param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\audit-hash-chain'),
  [string]$TargetHost,
  [int]$TargetPort = 5432,
  [string]$TargetUser,
  [string]$TargetDatabase,
  [switch]$ExecuteQuery,
  [string]$ApiUrl,
  [string]$BearerToken
)

$ErrorActionPreference = 'Stop'

if (-not $TargetHost) { $TargetHost = if ($env:PGHOST) { $env:PGHOST } else { 'localhost' } }
if (-not $TargetUser) { $TargetUser = if ($env:PGUSER) { $env:PGUSER } else { 'postgres' } }
if (-not $TargetDatabase -and $env:PGDATABASE) { $TargetDatabase = $env:PGDATABASE }

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

function Resolve-Tool {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Get-RepoPath {
  param([string]$RelativePath)
  return Join-Path $WorkspaceRoot $RelativePath
}

function Get-RepoContent {
  param([string]$RelativePath)
  $path = Get-RepoPath $RelativePath
  if (-not (Test-Path -LiteralPath $path)) { return '' }
  return Get-Content -LiteralPath $path -Raw
}

function Add-PathCheck {
  param([string]$RelativePath, [string]$Expected)
  $exists = Test-Path -LiteralPath (Get-RepoPath $RelativePath)
  Add-Check -Name $RelativePath -Status ($(if ($exists) { 'PASS' } else { 'FAIL' })) `
    -Evidence $RelativePath -Expected $Expected
}

function Add-ContentCheck {
  param([string]$RelativePath, [string]$Pattern, [string]$Expected)
  $content = Get-RepoContent $RelativePath
  Add-Check -Name "$RelativePath contains $Pattern" -Status ($(if ($content -match [regex]::Escape($Pattern)) { 'PASS' } else { 'FAIL' })) `
    -Evidence $RelativePath -Expected $Expected
}

Add-PathCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\AuditLogService.java' -Expected 'Legacy audit helper service exists'
Add-PathCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\AuditEventService.java' -Expected 'Structured audit event service exists'
Add-PathCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\controller\AuditDiagnosticsController.java' -Expected 'Audit diagnostics endpoint exists'
Add-PathCheck -RelativePath 'backend\src\test\java\hu\puzzleir\valuta\service\AuditLogServiceHashChainTest.java' -Expected 'Legacy audit helper hash-chain regression test exists'
Add-ContentCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\service\AuditLogService.java' `
  -Pattern 'applyHashChain(entry);' `
  -Expected 'AuditLogService helper paths apply hash-chain before save'
Add-ContentCheck -RelativePath 'backend\src\main\java\hu\puzzleir\valuta\controller\AuditDiagnosticsController.java' `
  -Pattern '/hash-chain-verify' `
  -Expected 'API hash-chain verification endpoint is exposed'
Add-ContentCheck -RelativePath 'docs\operations\monitoring-runbook.md' `
  -Pattern 'Audit log hash-chain breaks' `
  -Expected 'Monitoring runbook treats hash-chain breaks as a monitored signal'
Add-ContentCheck -RelativePath 'docs\operations\compliance-audit-checklist.md' `
  -Pattern 'Audit log hash-lánc havi automata verify' `
  -Expected 'Compliance checklist documents the monthly audit hash-chain requirement'

$psqlTool = Resolve-Tool 'psql'
Add-Check -Name 'tool:psql' -Status ($(if ($psqlTool) { 'PASS' } else { 'MISSING' })) `
  -Evidence ($(if ($psqlTool) { $psqlTool } else { 'not found on PATH' })) `
  -Expected 'Required only with -ExecuteQuery'

$dbMetrics = [ordered]@{}
if ($ExecuteQuery) {
  if (-not $TargetDatabase) {
    Add-Check -Name 'target database' -Status 'FAIL' -Evidence 'TargetDatabase/PGDATABASE is empty' -Expected 'Database name required with -ExecuteQuery'
  } elseif (-not $psqlTool) {
    Add-Check -Name 'query execution' -Status 'FAIL' -Evidence 'psql not found' -Expected 'psql available'
  } else {
    $sql = @"
WITH ordered AS (
  SELECT
    id,
    company_id,
    entry_hash,
    previous_hash,
    row_number() OVER (
      PARTITION BY company_id
      ORDER BY COALESCE(ts, created_at AT TIME ZONE 'UTC'), id
    ) AS rn,
    lag(entry_hash) OVER (
      PARTITION BY company_id
      ORDER BY COALESCE(ts, created_at AT TIME ZONE 'UTC'), id
    ) AS expected_previous_hash
  FROM audit_log
)
SELECT concat_ws(chr(9), 'rows', COUNT(*)::text) FROM ordered
UNION ALL
SELECT concat_ws(chr(9), 'missing_entry_hash', COUNT(*) FILTER (WHERE entry_hash IS NULL)::text) FROM ordered
UNION ALL
SELECT concat_ws(chr(9), 'invalid_entry_hash_format', COUNT(*) FILTER (WHERE entry_hash IS NOT NULL AND entry_hash !~ '^[0-9a-f]{64}$')::text) FROM ordered
UNION ALL
SELECT concat_ws(chr(9), 'broken_previous_hash_link', COUNT(*) FILTER (
  WHERE rn > 1 AND previous_hash IS DISTINCT FROM expected_previous_hash
)::text) FROM ordered
UNION ALL
SELECT concat_ws(chr(9), 'company_null_rows', COUNT(*) FILTER (WHERE company_id IS NULL)::text) FROM ordered;
"@
    $stdoutPath = Join-Path $runDir 'audit_hash_chain.tsv'
    $stderrPath = Join-Path $runDir 'audit_hash_chain.stderr.log'
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
    $proc = Start-Process -FilePath $psqlTool -ArgumentList $args -NoNewWindow -Wait -PassThru `
      -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    if ($proc.ExitCode -eq 0) {
      Add-Check -Name 'query execution' -Status 'PASS' -Evidence "stdout=$stdoutPath; stderr=$stderrPath" -Expected 'Query succeeds'
      foreach ($line in Get-Content -LiteralPath $stdoutPath) {
        if (-not $line.Trim()) { continue }
        $parts = $line -split "`t", 2
        if ($parts.Count -eq 2) { $dbMetrics[$parts[0]] = [int]$parts[1] }
      }
      foreach ($metric in @('missing_entry_hash', 'invalid_entry_hash_format', 'broken_previous_hash_link')) {
        $value = if ($dbMetrics.Contains($metric)) { $dbMetrics[$metric] } else { -1 }
        Add-Check -Name "metric:$metric" -Status ($(if ($value -eq 0) { 'PASS' } else { 'FAIL' })) `
          -Evidence "$metric=$value" -Expected '0'
      }
    } else {
      $err = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { '' }
      Add-Check -Name 'query execution' -Status 'FAIL' -Evidence "exit=$($proc.ExitCode); stderr=$stderrPath; $err" -Expected 'Query succeeds'
    }
  }
} else {
  Add-Check -Name 'query execution' -Status 'SKIP' -Evidence 'Run with -ExecuteQuery and PGHOST/PGUSER/PGDATABASE or explicit parameters' -Expected 'No DB connection in default mode'
}

if ($ApiUrl) {
  $headers = @{}
  if ($BearerToken) {
    $headers['Authorization'] = "Bearer $BearerToken"
  }
  try {
    $response = Invoke-RestMethod -Uri $ApiUrl -Headers $headers -Method Get -TimeoutSec 20
    $intact = [bool]$response.intact
    Add-Check -Name 'api hash-chain verify' -Status ($(if ($intact) { 'PASS' } else { 'FAIL' })) `
      -Evidence "checkedCount=$($response.checkedCount); firstBrokenEntryId=$($response.firstBrokenEntryId)" `
      -Expected 'intact=true'
  } catch {
    Add-Check -Name 'api hash-chain verify' -Status 'FAIL' -Evidence $_.Exception.Message -Expected 'Authenticated API call succeeds'
  }
} else {
  Add-Check -Name 'api hash-chain verify' -Status 'SKIP' -Evidence 'No -ApiUrl supplied' -Expected 'Optional authenticated endpoint check'
}

$failed = @($checks | Where-Object { $_.status -eq 'FAIL' })
$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  mode = if ($ExecuteQuery) { 'query' } else { 'preflight' }
  workspaceRoot = $WorkspaceRoot
  targetHost = if ($ExecuteQuery) { $TargetHost } else { $null }
  targetPort = if ($ExecuteQuery) { $TargetPort } else { $null }
  targetUser = if ($ExecuteQuery) { $TargetUser } else { $null }
  targetDatabase = if ($ExecuteQuery) { $TargetDatabase } else { $null }
  apiUrl = $ApiUrl
  checks = $checks
  dbMetrics = $dbMetrics
  failed = $failed.Count
  pendingExternalEvidence = @(
    'Run this script with -ExecuteQuery against staging or production',
    'Run the authenticated /api/v1/diagnostics/audit/hash-chain-verify endpoint in staging or production',
    'Schedule monthly or daily execution and attach the generated report to compliance evidence',
    'Wire alerting so any broken link or missing hash becomes an incident'
  )
}

$jsonPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$reportPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Audit hash-chain verification')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Mode: $($summary.mode)")
$lines.Add("- Workspace: $WorkspaceRoot")
$lines.Add("- Failed: $($summary.failed)")
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
$lines.Add('## Pending External Evidence')
$lines.Add('')
foreach ($item in $summary.pendingExternalEvidence) {
  $lines.Add("- $item")
}
$lines.Add('')
$lines.Add('## Product Ready Meaning')
$lines.Add('')
if ($ExecuteQuery) {
  $lines.Add('This is audit-log DB integrity evidence for the selected environment. Product Ready still requires scheduled execution and alert handling evidence.')
} else {
  $lines.Add('This preflight proves the local verification path exists. Product Ready still requires a staging/production query or authenticated API verification run.')
}

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[audit-hash-chain] mode=$($summary.mode), failed=$($summary.failed)"
Write-Host "[audit-hash-chain] report: $reportPath"
Write-Host "[audit-hash-chain] summary: $jsonPath"

if ($summary.failed -gt 0) {
  exit 1
}
exit 0
