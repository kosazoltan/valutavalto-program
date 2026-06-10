param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\dr-restore-drills'),
  [string]$DumpPath,
  [string]$TargetHost = 'localhost',
  [int]$TargetPort = 5432,
  [string]$TargetUser = 'postgres',
  [string]$TargetDatabase,
  [string]$DockerImage = 'postgres:16-alpine',
  [ValidateSet('plan-only', 'synthetic-tooling-smoke', 'real-backup-drill')]
  [string]$EvidenceKind = 'plan-only',
  [switch]$UseDockerTools,
  [switch]$ExecuteRestore,
  [switch]$ConfirmIsolatedScratchTarget,
  [switch]$DropExistingScratchDb
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
if (-not $TargetDatabase) {
  $TargetDatabase = "valuta_dr_$timestamp"
}

$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$steps = [System.Collections.Generic.List[object]]::new()

function Add-Step {
  param(
    [string]$Name,
    [string]$Status,
    [string]$Evidence,
    [string]$Expected
  )

  $steps.Add([pscustomobject]@{
      name = $Name
      status = $Status
      evidence = $Evidence
      expected = $Expected
    })
}

function Resolve-Tool {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }
  return $null
}

function Get-DockerToolHost {
  param([string]$HostName)
  if ($HostName -eq 'localhost' -or $HostName -eq '127.0.0.1') {
    return 'host.docker.internal'
  }
  return $HostName
}

function Resolve-DockerTool {
  $docker = Resolve-Tool 'docker'
  if (-not $docker) {
    return $null
  }
  return $docker
}

function Format-Optional {
  param([string]$Value, [string]$Fallback)
  if ($Value) {
    return $Value
  }
  return $Fallback
}

function Invoke-LoggedExternal {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string[]]$ArgumentList
  )

  $safeName = ($Name -replace '[^a-zA-Z0-9_-]', '_')
  $stdoutPath = Join-Path $runDir "$safeName.stdout.log"
  $stderrPath = Join-Path $runDir "$safeName.stderr.log"
  & $FilePath @ArgumentList 1> $stdoutPath 2> $stderrPath
  $exitCode = $LASTEXITCODE
  Add-Step -Name $Name -Status ($(if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' })) `
    -Evidence "exit=$exitCode; stdout=$stdoutPath; stderr=$stderrPath" -Expected 'exit code 0'
  if ($exitCode -ne 0) {
    throw "$Name failed with exit code $exitCode"
  }
}

function Invoke-LoggedDockerTool {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string[]]$ToolArguments,
    [string]$MountSource,
    [string]$MountTarget = '/dr'
  )

  $docker = Resolve-DockerTool
  if (-not $docker) {
    throw 'docker not found on PATH'
  }

  $args = @('run', '--rm')
  if ($env:PGPASSWORD) {
    $args += @('-e', 'PGPASSWORD')
  }
  if ($MountSource) {
    $resolvedMount = (Resolve-Path -LiteralPath $MountSource).Path
    $args += @('-v', "${resolvedMount}:${MountTarget}:ro")
  }
  $args += $DockerImage
  $args += $ToolArguments

  Invoke-LoggedExternal -Name $Name -FilePath $docker -ArgumentList $args
}

function Invoke-Psql {
  param(
    [Parameter(Mandatory = $true)][string]$Sql,
    [string]$Database = $TargetDatabase
  )

  $psql = Resolve-Tool 'psql'
  $docker = Resolve-DockerTool
  $args = @(
    '-h', $TargetHost,
    '-p', "$TargetPort",
    '-U', $TargetUser,
    '-d', $Database,
    '-v', 'ON_ERROR_STOP=1',
    '-t',
    '-A',
    '-c', $Sql
  )
  $safeName = "psql_$([Math]::Abs($Sql.GetHashCode()))"
  $stdoutPath = Join-Path $runDir "$safeName.stdout.log"
  $stderrPath = Join-Path $runDir "$safeName.stderr.log"
  $filePath = $psql
  $argumentList = $args
  if (-not $filePath) {
    if (-not $UseDockerTools -or -not $docker) {
      throw 'psql not found on PATH and Docker tool mode is unavailable'
    }
    $argumentList = @('run', '--rm')
    if ($env:PGPASSWORD) {
      $argumentList += @('-e', 'PGPASSWORD')
    }
    $argumentList += $DockerImage
    $argumentList += @(
      'psql',
      '-h', (Get-DockerToolHost $TargetHost),
      '-p', "$TargetPort",
      '-U', $TargetUser,
      '-d', $Database,
      '-v', 'ON_ERROR_STOP=1',
      '-t',
      '-A',
      '-c', $Sql
    )
    $filePath = $docker
  }
  & $filePath @argumentList 1> $stdoutPath 2> $stderrPath
  $exitCode = $LASTEXITCODE
  $output = if (Test-Path $stdoutPath) { (Get-Content -LiteralPath $stdoutPath -Raw).Trim() } else { '' }
  if ($exitCode -ne 0) {
    $err = if (Test-Path $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { '' }
    throw "psql failed (exit $exitCode): $err"
  }
  return $output
}

function Get-DumpFormat {
  param([string]$Path)
  $lower = $Path.ToLowerInvariant()
  if ($lower.EndsWith('.dump') -or $lower.EndsWith('.backup')) { return 'custom' }
  if ($lower.EndsWith('.sql')) { return 'plain-sql' }
  if ($lower.EndsWith('.sql.gz')) { return 'plain-sql-gzip' }
  return 'unknown'
}

Add-Step -Name 'mode' -Status ($(if ($ExecuteRestore) { 'EXECUTE' } else { 'PLAN_ONLY' })) `
  -Evidence "ExecuteRestore=$([bool]$ExecuteRestore); TargetDatabase=$TargetDatabase" `
  -Expected 'Default is non-destructive PLAN_ONLY'

$evidenceKindOk = if ($ExecuteRestore) {
  $EvidenceKind -in @('synthetic-tooling-smoke', 'real-backup-drill')
} else {
  $EvidenceKind -eq 'plan-only'
}
Add-Step -Name 'evidence kind' -Status ($(if ($evidenceKindOk) { 'PASS' } else { 'FAIL' })) `
  -Evidence "EvidenceKind=$EvidenceKind; ExecuteRestore=$([bool]$ExecuteRestore)" `
  -Expected 'plan-only without execute; synthetic-tooling-smoke or real-backup-drill with execute'

Add-Step -Name 'isolated scratch target confirmation' `
  -Status ($(if ($ExecuteRestore) { if ($ConfirmIsolatedScratchTarget) { 'PASS' } else { 'FAIL' } } else { 'SKIP' })) `
  -Evidence "ConfirmIsolatedScratchTarget=$([bool]$ConfirmIsolatedScratchTarget)" `
  -Expected 'Operator explicitly confirms an isolated scratch target before execute mode'

$psqlTool = Resolve-Tool 'psql'
$pgRestoreTool = Resolve-Tool 'pg_restore'
$createdbTool = Resolve-Tool 'createdb'
$dropdbTool = Resolve-Tool 'dropdb'
$gzipTool = Resolve-Tool 'gzip'
$dockerTool = Resolve-DockerTool
$dockerToolMode = [bool]($UseDockerTools -or ((-not $psqlTool -or -not $createdbTool) -and $dockerTool))
if ($dockerToolMode) {
  $UseDockerTools = $true
}

Add-Step -Name 'tool:psql' -Status ($(if ($psqlTool) { 'PASS' } else { 'MISSING' })) -Evidence (Format-Optional $psqlTool 'not found') -Expected 'Required for execute mode'
Add-Step -Name 'tool:pg_restore' -Status ($(if ($pgRestoreTool) { 'PASS' } else { 'MISSING' })) -Evidence (Format-Optional $pgRestoreTool 'not found') -Expected 'Required for custom-format dump'
Add-Step -Name 'tool:createdb' -Status ($(if ($createdbTool) { 'PASS' } else { 'MISSING' })) -Evidence (Format-Optional $createdbTool 'not found') -Expected 'Required for execute mode'
Add-Step -Name 'tool:dropdb' -Status ($(if ($dropdbTool) { 'PASS' } else { 'MISSING' })) -Evidence (Format-Optional $dropdbTool 'not found') -Expected 'Required only with -DropExistingScratchDb'
Add-Step -Name 'tool:gzip' -Status ($(if ($gzipTool) { 'PASS' } else { 'MISSING' })) -Evidence (Format-Optional $gzipTool 'not found') -Expected 'Required for .sql.gz dump'
Add-Step -Name 'tool:docker' -Status ($(if ($dockerTool) { 'PASS' } else { 'MISSING' })) -Evidence (Format-Optional $dockerTool 'not found') -Expected 'Fallback PostgreSQL client tools when native tools are missing'
Add-Step -Name 'postgres client tool mode' -Status ($(if ($UseDockerTools) { 'DOCKER' } else { 'NATIVE' })) `
  -Evidence "$(if ($UseDockerTools) { $DockerImage } else { 'PATH tools' })" `
  -Expected 'NATIVE when local tools exist, DOCKER fallback otherwise'

$safeTargetName = $TargetDatabase -match '^valuta_dr_[A-Za-z0-9_-]+$'
Add-Step -Name 'target database safety' -Status ($(if ($safeTargetName) { 'PASS' } else { 'FAIL' })) `
  -Evidence $TargetDatabase -Expected 'Scratch DB name must match ^valuta_dr_[A-Za-z0-9_-]+$'

if ($DumpPath) {
  $resolvedDump = Resolve-Path -LiteralPath $DumpPath -ErrorAction SilentlyContinue
  Add-Step -Name 'dump path' -Status ($(if ($resolvedDump) { 'PASS' } else { 'FAIL' })) `
    -Evidence $DumpPath -Expected 'Dump file exists'
  if ($resolvedDump) {
    $DumpPath = $resolvedDump.Path
    $format = Get-DumpFormat $DumpPath
    Add-Step -Name 'dump format' -Status ($(if ($format -ne 'unknown') { 'PASS' } else { 'FAIL' })) `
      -Evidence $format -Expected '.dump, .backup, .sql or .sql.gz'
  }
} else {
  Add-Step -Name 'dump path' -Status 'SKIP' -Evidence 'No -DumpPath supplied' `
    -Expected 'Required only with -ExecuteRestore'
}

if ($ExecuteRestore) {
  if (-not $safeTargetName) {
    throw "Unsafe target database name: $TargetDatabase"
  }
  if (-not $DumpPath) {
    throw '-DumpPath is required with -ExecuteRestore'
  }
  if (-not (Test-Path -LiteralPath $DumpPath)) {
    throw "Dump file not found: $DumpPath"
  }
  if (-not $UseDockerTools -and (-not $psqlTool -or -not $createdbTool)) {
    throw 'psql and createdb are required with -ExecuteRestore unless Docker tool mode is available'
  }

  $format = Get-DumpFormat $DumpPath
  if ($format -eq 'custom' -and -not $UseDockerTools -and -not $pgRestoreTool) {
    throw 'pg_restore is required for custom-format dump'
  }
  if ($format -eq 'plain-sql-gzip' -and -not $UseDockerTools -and -not $gzipTool) {
    throw 'gzip is required for .sql.gz dump'
  }
  if ($format -eq 'unknown') {
    throw "Unsupported dump format: $DumpPath"
  }

  if ($DropExistingScratchDb) {
    if (-not $UseDockerTools -and -not $dropdbTool) {
      throw 'dropdb is required with -DropExistingScratchDb'
    }
    if ($UseDockerTools) {
      Invoke-LoggedDockerTool -Name 'drop existing scratch database' -ToolArguments @(
        'dropdb', '--if-exists', '-h', (Get-DockerToolHost $TargetHost), '-p', "$TargetPort", '-U', $TargetUser, $TargetDatabase
      )
    } else {
      Invoke-LoggedExternal -Name 'drop existing scratch database' -FilePath $dropdbTool -ArgumentList @(
        '--if-exists', '-h', $TargetHost, '-p', "$TargetPort", '-U', $TargetUser, $TargetDatabase
      )
    }
  }

  if ($UseDockerTools) {
    Invoke-LoggedDockerTool -Name 'create scratch database' -ToolArguments @(
      'createdb', '-h', (Get-DockerToolHost $TargetHost), '-p', "$TargetPort", '-U', $TargetUser, $TargetDatabase
    )
  } else {
    Invoke-LoggedExternal -Name 'create scratch database' -FilePath $createdbTool -ArgumentList @(
      '-h', $TargetHost, '-p', "$TargetPort", '-U', $TargetUser, $TargetDatabase
    )
  }

  $restoreStart = Get-Date
  $dumpDirectory = Split-Path -Parent $DumpPath
  $dumpFileName = Split-Path -Leaf $DumpPath
  $dockerDumpPath = "/dr/$dumpFileName"
  if ($format -eq 'custom') {
    if ($UseDockerTools) {
      Invoke-LoggedDockerTool -Name 'pg_restore custom dump' -MountSource $dumpDirectory -ToolArguments @(
        'pg_restore', '--no-owner', '--no-privileges', '--if-exists', '--clean',
        '-h', (Get-DockerToolHost $TargetHost), '-p', "$TargetPort", '-U', $TargetUser,
        '-d', $TargetDatabase, $dockerDumpPath
      )
    } else {
      Invoke-LoggedExternal -Name 'pg_restore custom dump' -FilePath $pgRestoreTool -ArgumentList @(
        '--no-owner', '--no-privileges', '--if-exists', '--clean',
        '-h', $TargetHost, '-p', "$TargetPort", '-U', $TargetUser,
        '-d', $TargetDatabase, $DumpPath
      )
    }
  } elseif ($format -eq 'plain-sql') {
    if ($UseDockerTools) {
      Invoke-LoggedDockerTool -Name 'psql restore plain sql' -MountSource $dumpDirectory -ToolArguments @(
        'psql', '-h', (Get-DockerToolHost $TargetHost), '-p', "$TargetPort", '-U', $TargetUser,
        '-d', $TargetDatabase, '-v', 'ON_ERROR_STOP=1', '-f', $dockerDumpPath
      )
    } else {
      Invoke-LoggedExternal -Name 'psql restore plain sql' -FilePath $psqlTool -ArgumentList @(
        '-h', $TargetHost, '-p', "$TargetPort", '-U', $TargetUser,
        '-d', $TargetDatabase, '-v', 'ON_ERROR_STOP=1', '-f', $DumpPath
      )
    }
  } else {
    if ($UseDockerTools) {
      $shellCommand = "gzip -dc '$dockerDumpPath' | psql -h '$(Get-DockerToolHost $TargetHost)' -p '$TargetPort' -U '$TargetUser' -d '$TargetDatabase' -v ON_ERROR_STOP=1"
      Invoke-LoggedDockerTool -Name 'psql restore gzip sql' -MountSource $dumpDirectory -ToolArguments @(
        'sh', '-c', $shellCommand
      )
    } else {
      $cmd = "`"$gzipTool`" -dc `"$DumpPath`" | `"$psqlTool`" -h `"$TargetHost`" -p $TargetPort -U `"$TargetUser`" -d `"$TargetDatabase`" -v ON_ERROR_STOP=1"
      Invoke-LoggedExternal -Name 'psql restore gzip sql' -FilePath 'cmd.exe' -ArgumentList @('/d', '/c', $cmd)
    }
  }
  $restoreEnd = Get-Date
  $duration = [Math]::Round(($restoreEnd - $restoreStart).TotalSeconds, 2)
  Add-Step -Name 'restore duration' -Status 'PASS' -Evidence "${duration}s" -Expected 'Measured RTO component'

  $rowCountSql = @"
SELECT 'audit_log=' || COALESCE((SELECT COUNT(*)::text FROM audit_log), 'missing')
UNION ALL
SELECT 'transactions=' || COALESCE((SELECT COUNT(*)::text FROM "transaction"), 'missing')
UNION ALL
SELECT 'aml_report=' || COALESCE((SELECT COUNT(*)::text FROM aml_report), 'missing')
UNION ALL
SELECT 'customer=' || COALESCE((SELECT COUNT(*)::text FROM customer), 'missing')
UNION ALL
SELECT 'flyway_success=' || COALESCE((SELECT COUNT(*)::text FROM flyway_schema_history WHERE success = true), 'missing');
"@
  $rowCounts = Invoke-Psql -Sql $rowCountSql
  Add-Step -Name 'critical row counts' -Status 'PASS' -Evidence $rowCounts -Expected 'Critical tables query succeeds'

  $flywaySql = "SELECT version || ':' || description || ':' || success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;"
  $flywayState = Invoke-Psql -Sql $flywaySql
  Add-Step -Name 'flyway latest state' -Status 'PASS' -Evidence $flywayState -Expected 'Latest Flyway rows readable'

  $auditSql = "SELECT COUNT(*) FILTER (WHERE entry_hash IS NULL)::text || ',' || COUNT(*) FILTER (WHERE previous_hash IS NULL AND id <> (SELECT MIN(id) FROM audit_log))::text FROM audit_log;"
  $auditHash = Invoke-Psql -Sql $auditSql
  Add-Step -Name 'audit hash-chain smoke' -Status 'PASS' -Evidence "missing_hash,broken_chain=$auditHash" -Expected 'Both values should be 0 for production-grade restore'
} else {
  Add-Step -Name 'restore execution' -Status 'SKIP' -Evidence 'Run with -ExecuteRestore -DumpPath <dump> in an isolated scratch DB environment' `
    -Expected 'No database changes in default mode'
}

$blockingFailure = @($steps | Where-Object { $_.status -eq 'FAIL' })
$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  mode = if ($ExecuteRestore) { 'execute' } else { 'plan-only' }
  workspaceRoot = $WorkspaceRoot
  targetHost = $TargetHost
  targetPort = $TargetPort
  targetUser = $TargetUser
  targetDatabase = $TargetDatabase
  dumpPath = $DumpPath
  evidenceKind = $EvidenceKind
  isolatedScratchTargetConfirmed = [bool]$ConfirmIsolatedScratchTarget
  postgresClientToolMode = if ($UseDockerTools) { 'docker' } else { 'native' }
  dockerImage = if ($UseDockerTools) { $DockerImage } else { $null }
  steps = $steps
  failed = $blockingFailure.Count
}

$summaryPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# DR restore drill report')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Mode: $($summary.mode)")
$lines.Add("- Evidence kind: $EvidenceKind")
$lines.Add("- Isolated scratch target confirmed: $([bool]$ConfirmIsolatedScratchTarget)")
$lines.Add("- Target: ${TargetHost}:${TargetPort}/$TargetDatabase")
$lines.Add("- Dump: $(Format-Optional $DumpPath 'not supplied')")
$lines.Add("- PostgreSQL client tools: $(if ($UseDockerTools) { "docker:$DockerImage" } else { 'native PATH tools' })")
$lines.Add('')
$lines.Add('## Steps')
$lines.Add('')
$lines.Add('| Step | Status | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($step in $steps) {
  $evidence = ($step.evidence -replace '\|', '/')
  $expected = ($step.expected -replace '\|', '/')
  $lines.Add("| $($step.name) | $($step.status) | $evidence | $expected |")
}
$lines.Add('')
$lines.Add('## Safety')
$lines.Add('')
$lines.Add('- Default mode is non-destructive and does not connect to or modify a database.')
$lines.Add('- Execute mode requires `-ExecuteRestore` and a scratch database name matching `valuta_dr_*`.')
$lines.Add('- If local PostgreSQL client binaries are missing, the script can use Dockerized client tools from the configured PostgreSQL image.')
$lines.Add('- Use `PGPASSWORD` or a `.pgpass` file for credentials; the script does not print passwords.')
$lines.Add('')
$lines.Add('## Product Ready Meaning')
$lines.Add('')
if ($ExecuteRestore) {
  $lines.Add('This report is a DR evidence artifact if the target environment was isolated and the row-count/Flyway/audit checks are reviewed.')
} else {
  $lines.Add('This report proves only that the DR drill path is prepared. Product Ready still requires an executed restore drill with a real backup.')
}

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[dr-restore-drill] mode=$($summary.mode), failed=$($summary.failed)"
Write-Host "[dr-restore-drill] report: $reportPath"
Write-Host "[dr-restore-drill] summary: $summaryPath"

if ($blockingFailure.Count -gt 0) {
  exit 1
}
exit 0
