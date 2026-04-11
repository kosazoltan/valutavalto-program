param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path 'security-reports\smoke-runs'),
  [int]$BackendStartupTimeoutSec = 150,
  [int]$FrontendStartupTimeoutSec = 90,
  [int]$PenztarStartupTimeoutSec = 120,
  [string]$PenztarBootstrapCompanyCode = $env:PENZTAR_BOOTSTRAP_COMPANY_CODE,
  [string]$PenztarBootstrapWorkerCode = $env:PENZTAR_BOOTSTRAP_WORKER_CODE,
  [string]$PenztarBootstrapPassword = $env:PENZTAR_BOOTSTRAP_PASSWORD,
  [string]$PenztarBootstrapRoleCode = $env:PENZTAR_BOOTSTRAP_ROLE_CODE
)

$ErrorActionPreference = 'Stop'

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $OutputRoot $timestamp
$null = New-Item -ItemType Directory -Path $runDir -Force

$summary = [System.Collections.Generic.List[object]]::new()

function Invoke-LoggedCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Command
  )

  $safeName = ($Name -replace '[^a-zA-Z0-9_-]', '_')
  $logPath = Join-Path $runDir "$safeName.log"
  Write-Host "[SMOKE] Step: $Name"

  $cmdLine = 'cd /d "' + $WorkspaceRoot + '" && ' + $Command + ' > "' + $logPath + '" 2>&1'
  cmd.exe /d /c $cmdLine
  $exitCode = $LASTEXITCODE

  if (Test-Path $logPath) {
    Get-Content -Path $logPath
  }

  $summary.Add([pscustomobject]@{
      step = $Name
      type = 'command'
      exitCode = $exitCode
      log = $logPath
      passed = ($exitCode -eq 0)
    })

  if ($exitCode -ne 0) {
    throw "Step failed: $Name (exit code $exitCode). Log: $logPath"
  }
}

function Wait-ForCondition {
  param(
    [Parameter(Mandatory = $true)][scriptblock]$Condition,
    [Parameter(Mandatory = $true)][int]$TimeoutSec,
    [int]$PollSec = 2
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if (& $Condition) {
      return $true
    }
    Start-Sleep -Seconds $PollSec
  }
  return $false
}

function Stop-ProcessTree {
  param([Parameter(Mandatory = $true)][int]$ProcessId)

  cmd.exe /d /c "taskkill /PID $ProcessId /T /F" *> $null
}

function Invoke-LoggedProcessSmoke {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string[]]$ArgumentList,
    [Parameter(Mandatory = $true)][int]$TimeoutSec,
    [scriptblock]$SuccessCondition,
    [string]$SuccessPattern
  )

  $safeName = ($Name -replace '[^a-zA-Z0-9_-]', '_')
  $stdoutPath = Join-Path $runDir "$safeName.stdout.log"
  $stderrPath = Join-Path $runDir "$safeName.stderr.log"

  Write-Host "[SMOKE] Runtime step: $Name"

  $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

  $success = $false
  try {
    $success = Wait-ForCondition -TimeoutSec $TimeoutSec -Condition {
      if ($SuccessPattern) {
        if ((Test-Path $stdoutPath) -and (Select-String -Path $stdoutPath -Pattern $SuccessPattern -Quiet -ErrorAction SilentlyContinue)) {
          return $true
        }
        if ((Test-Path $stderrPath) -and (Select-String -Path $stderrPath -Pattern $SuccessPattern -Quiet -ErrorAction SilentlyContinue)) {
          return $true
        }
      }

      if ($SuccessCondition) {
        return (& $SuccessCondition)
      }

      return $false
    }
  } finally {
    if ($proc -and -not $proc.HasExited) {
      Stop-ProcessTree -ProcessId $proc.Id
    }
  }

  $summary.Add([pscustomobject]@{
      step = $Name
      type = 'runtime-smoke'
      exitCode = if ($success) { 0 } else { 1 }
      stdout = $stdoutPath
      stderr = $stderrPath
      passed = $success
    })

  if (-not $success) {
    throw "Runtime step failed: $Name (timeout: ${TimeoutSec}s). Stdout: $stdoutPath | Stderr: $stderrPath"
  }
}

try {
  Invoke-LoggedCommand -Name 'security_gate' -Command 'powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1'

  Invoke-LoggedCommand -Name 'backend_build' -Command 'cd backend && .\mvnw.cmd -DskipTests clean package'

  Invoke-LoggedProcessSmoke -Name 'backend_runtime' -FilePath 'powershell' -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-Command',
    "Set-Location '$WorkspaceRoot\backend'; .\mvnw.cmd spring-boot:run -DskipTests '-Dspring-boot.run.arguments=--spring.profiles.active=test --spring.datasource.url=jdbc:postgresql://localhost:5432/valuta --spring.datasource.username=valuta_user --spring.datasource.password=valuta_pass --server.port=18080'"
  ) -TimeoutSec $BackendStartupTimeoutSec -SuccessCondition {
    $status = Test-NetConnection -ComputerName '127.0.0.1' -Port 18080 -WarningAction SilentlyContinue
    return $status.TcpTestSucceeded
  }

  Invoke-LoggedCommand -Name 'frontend_lint_test_build' -Command 'cd frontend-react && npm run lint && npm test && npm run build'

  Invoke-LoggedProcessSmoke -Name 'frontend_runtime' -FilePath 'powershell' -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-Command',
    "Set-Location '$WorkspaceRoot\frontend-react'; npm run dev -- --host 127.0.0.1 --port 3300 --strictPort"
  ) -TimeoutSec $FrontendStartupTimeoutSec -SuccessCondition {
    try {
      $resp = Invoke-WebRequest -Uri 'http://127.0.0.1:3300' -Method Get -TimeoutSec 5 -UseBasicParsing
      return $resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500
    } catch {
      return $false
    }
  }

  Invoke-LoggedCommand -Name 'penztar_lint_typecheck_ipc_build' -Command 'cd penztar-client && npm run lint && npm run typecheck && npm run check:ipc && npm run build'

  $penztarBootstrapPrefix = ''
  if ($PenztarBootstrapCompanyCode -and $PenztarBootstrapWorkerCode -and $PenztarBootstrapPassword) {
    $penztarBootstrapPrefix =
      'set "PENZTAR_BOOTSTRAP_COMPANY_CODE=' + $PenztarBootstrapCompanyCode + '" && ' +
      'set "PENZTAR_BOOTSTRAP_WORKER_CODE=' + $PenztarBootstrapWorkerCode + '" && ' +
      'set "PENZTAR_BOOTSTRAP_PASSWORD=' + $PenztarBootstrapPassword + '" && '

    if ($PenztarBootstrapRoleCode) {
      $penztarBootstrapPrefix += 'set "PENZTAR_BOOTSTRAP_ROLE_CODE=' + $PenztarBootstrapRoleCode + '" && '
    }
  }

  Invoke-LoggedProcessSmoke -Name 'penztar_runtime' -FilePath 'cmd.exe' -ArgumentList @(
    '/d',
    '/c',
    ('cd /d "' + $WorkspaceRoot + '" && ' + $penztarBootstrapPrefix + 'start-penztar.cmd')
  ) -TimeoutSec $PenztarStartupTimeoutSec -SuccessPattern 'SyncEngine elind|VITE\s+v8\.0\.0\s+ready'

  $summaryPath = Join-Path $runDir 'summary.json'
  ($summary | ConvertTo-Json -Depth 5) | Set-Content -Path $summaryPath -Encoding UTF8

  Write-Host "[SMOKE] PASSED"
  Write-Host "[SMOKE] Logs: $runDir"
  exit 0
}
catch {
  $summaryPath = Join-Path $runDir 'summary.json'
  ($summary | ConvertTo-Json -Depth 5) | Set-Content -Path $summaryPath -Encoding UTF8

  Write-Error "[SMOKE] FAILED: $($_.Exception.Message)"
  Write-Host "[SMOKE] Logs: $runDir"
  exit 1
}
