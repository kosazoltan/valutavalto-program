param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\monitoring-preflight'),
  [switch]$CheckLive,
  [string]$BackendMetricsUrl = 'http://127.0.0.1:9090/actuator/prometheus',
  [string]$PrometheusReadyUrl = 'http://127.0.0.1:9091/-/ready',
  [string]$GrafanaHealthUrl = 'http://127.0.0.1:3000/api/health',
  [string]$AlertmanagerReadyUrl = 'http://127.0.0.1:9093/-/ready',
  [string]$PrometheusImage = 'prom/prometheus:v2.53.2'
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
  param(
    [string]$Area,
    [string]$Name,
    [string]$Status,
    [string]$Evidence,
    [string]$Expected
  )
  $checks.Add([pscustomObject]@{
      area = $Area
      name = $Name
      status = $Status
      evidence = $Evidence
      expected = $Expected
    })
}

function Read-RepoFile {
  param([string]$RelativePath)
  $path = Join-Path $WorkspaceRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    return ''
  }
  return Get-Content -LiteralPath $path -Raw
}

function Test-PathCheck {
  param([string]$Area, [string]$RelativePath, [string]$Expected)
  $path = Join-Path $WorkspaceRoot $RelativePath
  Add-Check -Area $Area -Name $RelativePath -Status ($(if (Test-Path -LiteralPath $path) { 'PASS' } else { 'FAIL' })) -Evidence $RelativePath -Expected $Expected
}

function Test-ContentCheck {
  param([string]$Area, [string]$RelativePath, [string]$Pattern, [string]$Expected)
  $content = Read-RepoFile $RelativePath
  Add-Check -Area $Area -Name "$RelativePath contains $Pattern" -Status ($(if ($content -match [regex]::Escape($Pattern)) { 'PASS' } else { 'FAIL' })) -Evidence $RelativePath -Expected $Expected
}

function Test-RegexCheck {
  param([string]$Area, [string]$RelativePath, [string]$Pattern, [string]$Expected)
  $content = Read-RepoFile $RelativePath
  Add-Check -Area $Area -Name "$RelativePath matches $Pattern" -Status ($(if ($content -match $Pattern) { 'PASS' } else { 'FAIL' })) -Evidence $RelativePath -Expected $Expected
}

function Test-JsonParseCheck {
  param([string]$Area, [string]$RelativePath, [string]$Expected)
  try {
    $content = Read-RepoFile $RelativePath
    $null = $content | ConvertFrom-Json -ErrorAction Stop
    Add-Check -Area $Area -Name "$RelativePath parses as JSON" -Status 'PASS' -Evidence $RelativePath -Expected $Expected
  } catch {
    Add-Check -Area $Area -Name "$RelativePath parses as JSON" -Status 'FAIL' -Evidence $_.Exception.Message -Expected $Expected
  }
}

function Invoke-LoggedDocker {
  param(
    [string]$Name,
    [string[]]$Arguments
  )

  $docker = Get-Command docker -ErrorAction SilentlyContinue
  if (-not $docker) {
    Add-Check -Area 'synthetic' -Name $Name -Status 'SKIP' -Evidence 'docker not found on PATH' -Expected 'Docker available for tool-native validation'
    return
  }

  $safeName = ($Name -replace '[^A-Za-z0-9_.-]', '_')
  $stdoutPath = Join-Path $runDir "$safeName.stdout.log"
  $stderrPath = Join-Path $runDir "$safeName.stderr.log"
  $oldErrorActionPreference = $ErrorActionPreference
  $oldNativeErrorPreference = $null
  if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -Scope Global -ErrorAction SilentlyContinue) {
    $oldNativeErrorPreference = $global:PSNativeCommandUseErrorActionPreference
    $global:PSNativeCommandUseErrorActionPreference = $false
  }
  try {
    $ErrorActionPreference = 'Continue'
    & $docker.Source @Arguments 1> $stdoutPath 2> $stderrPath
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $oldErrorActionPreference
    if ($null -ne $oldNativeErrorPreference) {
      $global:PSNativeCommandUseErrorActionPreference = $oldNativeErrorPreference
    }
  }
  Add-Check -Area 'synthetic' -Name $Name -Status ($(if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' })) `
    -Evidence "exit=$exitCode; stdout=$stdoutPath; stderr=$stderrPath" -Expected 'Tool exits 0'
}

function Test-LiveUrl {
  param([string]$Name, [string]$Url, [string]$ExpectedPattern)
  try {
    $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    $body = $resp.Content
    $ok = $resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500
    if ($ExpectedPattern) {
      $ok = $ok -and ($body -match $ExpectedPattern)
    }
    Add-Check -Area 'live' -Name $Name -Status ($(if ($ok) { 'PASS' } else { 'FAIL' })) -Evidence "$Url HTTP $($resp.StatusCode)" -Expected "Reachable; pattern=$ExpectedPattern"
  } catch {
    Add-Check -Area 'live' -Name $Name -Status 'FAIL' -Evidence "$Url $($_.Exception.Message)" -Expected "Reachable; pattern=$ExpectedPattern"
  }
}

$compose = 'deploy\hetzner\monitoring\docker-compose.monitoring.yml'
$prometheus = 'deploy\hetzner\monitoring\prometheus\prometheus.yml'
$alerts = 'deploy\hetzner\monitoring\prometheus\rules\valuta-alerts.yml'
$alertmanager = 'deploy\hetzner\monitoring\alertmanager\alertmanager.yml'
$datasources = 'deploy\hetzner\monitoring\grafana\provisioning\datasources\datasources.yml'
$dashboardProvider = 'deploy\hetzner\monitoring\grafana\provisioning\dashboards\dashboards.yml'
$overviewDashboard = 'deploy\hetzner\monitoring\grafana\dashboards\valuta-overview.json'

Test-PathCheck 'files' $compose 'Monitoring compose file exists'
Test-PathCheck 'files' $prometheus 'Prometheus config exists'
Test-PathCheck 'files' $alerts 'Prometheus alert rules exist'
Test-PathCheck 'files' $alertmanager 'Alertmanager config exists'
Test-PathCheck 'files' $datasources 'Grafana datasource provisioning exists'
Test-PathCheck 'files' $dashboardProvider 'Grafana dashboard provider exists'
Test-PathCheck 'files' $overviewDashboard 'Grafana overview dashboard JSON exists'

foreach ($service in @('prometheus:', 'grafana:', 'loki:', 'promtail:', 'alertmanager:', 'node-exporter:', 'postgres-exporter:')) {
  Test-ContentCheck 'compose' $compose $service "Compose defines $service"
}
foreach ($port in @('"127.0.0.1:9091:9090"', '"127.0.0.1:3000:3000"', '"127.0.0.1:9093:9093"', '"127.0.0.1:9187:9187"')) {
  Test-ContentCheck 'compose' $compose $port "Service port is loopback-bound"
}
Test-ContentCheck 'compose' $compose 'GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD:?kell a GRAFANA_ADMIN_PASSWORD env var}' 'Grafana password is required via env'
Test-ContentCheck 'compose' $compose 'POSTGRES_EXPORTER_PASSWORD:?kell a POSTGRES_EXPORTER_PASSWORD' 'Postgres exporter password is required via env'

foreach ($job in @('job_name: valuta-backend', 'job_name: node', 'job_name: postgres', 'job_name: caddy')) {
  Test-ContentCheck 'prometheus' $prometheus $job "Prometheus scrape job exists: $job"
}
Test-ContentCheck 'prometheus' $prometheus 'rule_files:' 'Prometheus loads rule files'
Test-ContentCheck 'prometheus' $prometheus 'alertmanager:9093' 'Prometheus sends alerts to Alertmanager'

foreach ($alert in @('BackendDown', 'HighErrorRate', 'HighP95Latency', 'JvmHeapPressure', 'HikariPoolExhausted', 'HostLowDisk', 'PostgresDown')) {
  Test-ContentCheck 'alerts' $alerts "alert: $alert" "Alert rule exists: $alert"
}
Test-RegexCheck 'alerts' $alerts 'severity:\s*critical' 'Critical severity alerts exist'

Test-ContentCheck 'alertmanager' $alertmanager 'smtp_auth_password_file: /run/secrets/smtp_app_password' 'SMTP password is loaded from secret file'
Test-ContentCheck 'alertmanager' $alertmanager 'receiver: email-all' 'Default route sends to email-all'
Test-ContentCheck 'alertmanager' $alertmanager 'send_resolved: true' 'Resolved notifications are enabled'

Test-ContentCheck 'grafana' $datasources 'url: http://prometheus:9090' 'Prometheus datasource configured'
Test-ContentCheck 'grafana' $datasources 'url: http://loki:3100' 'Loki datasource configured'
Test-ContentCheck 'grafana' $dashboardProvider 'path: /var/lib/grafana/dashboards' 'Dashboard provider path matches compose mount'
Test-JsonParseCheck 'grafana' $overviewDashboard 'Overview dashboard JSON is syntactically valid'
Test-ContentCheck 'grafana' $overviewDashboard '"uid": "valuta-overview"' 'Overview dashboard has stable UID'
Test-ContentCheck 'grafana' $overviewDashboard 'up{job=\"valuta-backend\"}' 'Overview dashboard tracks backend availability'
Test-ContentCheck 'grafana' $overviewDashboard 'hikaricp_connections_active' 'Overview dashboard tracks Hikari pool pressure'
Test-ContentCheck 'grafana' $overviewDashboard 'node_filesystem_avail_bytes' 'Overview dashboard tracks host disk pressure'

$docker = Get-Command docker -ErrorAction SilentlyContinue
if ($docker) {
  $composePath = Join-Path $WorkspaceRoot $compose
  $dockerLog = Join-Path $runDir 'docker-compose-config.log'
  $oldGrafanaPass = $env:GRAFANA_ADMIN_PASSWORD
  $oldPostgresPass = $env:POSTGRES_EXPORTER_PASSWORD
  try {
    $syntheticComposeSecret = "vv-monitoring-$timestamp-$([Guid]::NewGuid().ToString('N'))"
    $env:GRAFANA_ADMIN_PASSWORD = $syntheticComposeSecret
    $env:POSTGRES_EXPORTER_PASSWORD = $syntheticComposeSecret
    & $docker.Source compose -f $composePath config *> $dockerLog
    $exitCode = $LASTEXITCODE
    Add-Check -Area 'compose' -Name 'docker compose config' -Status ($(if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' })) -Evidence "exit=$exitCode; log=$dockerLog" -Expected 'Compose renders with dummy required env vars'
  } finally {
    $env:GRAFANA_ADMIN_PASSWORD = $oldGrafanaPass
    $env:POSTGRES_EXPORTER_PASSWORD = $oldPostgresPass
  }
} else {
  Add-Check -Area 'compose' -Name 'docker compose config' -Status 'SKIP' -Evidence 'docker not found on PATH' -Expected 'Optional local compose syntax check'
}

$prometheusConfigDir = Join-Path $WorkspaceRoot 'deploy\hetzner\monitoring\prometheus'
Invoke-LoggedDocker -Name 'promtool check config' -Arguments @(
  'run', '--rm',
  '--entrypoint', 'promtool',
  '-v', "${prometheusConfigDir}:/etc/prometheus:ro",
  $PrometheusImage,
  'check', 'config', '/etc/prometheus/prometheus.yml'
)
Invoke-LoggedDocker -Name 'promtool check rules' -Arguments @(
  'run', '--rm',
  '--entrypoint', 'promtool',
  '-v', "${prometheusConfigDir}:/etc/prometheus:ro",
  $PrometheusImage,
  'check', 'rules', '/etc/prometheus/rules/valuta-alerts.yml'
)

if ($CheckLive) {
  Test-LiveUrl 'backend actuator prometheus' $BackendMetricsUrl 'jvm_|http_server_requests|process_'
  Test-LiveUrl 'prometheus ready' $PrometheusReadyUrl 'Ready|ready'
  Test-LiveUrl 'grafana health' $GrafanaHealthUrl 'database|ok|version'
  Test-LiveUrl 'alertmanager ready' $AlertmanagerReadyUrl 'OK|Ready|ready'
} else {
  Add-Check -Area 'live' -Name 'live checks' -Status 'SKIP' -Evidence 'Run with -CheckLive to query local deployed stack' -Expected 'Optional live evidence'
}

$failed = @($checks | Where-Object { $_.status -eq 'FAIL' })
$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$skipped = @($checks | Where-Object { $_.status -eq 'SKIP' }).Count

$summary = [pscustomObject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  checkLive = [bool]$CheckLive
  passed = $passed
  failed = $failed.Count
  skipped = $skipped
  checks = $checks
}

$summaryPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Monitoring preflight report')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Local checks: $passed passed, $($failed.Count) failed, $skipped skipped")
$lines.Add("- Live checks enabled: $([bool]$CheckLive)")
$lines.Add('')
$lines.Add('| Area | Check | Status | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- | --- |')
foreach ($check in $checks) {
  $evidence = ($check.evidence -replace '\|', '/')
  $expected = ($check.expected -replace '\|', '/')
  $lines.Add("| $($check.area) | $($check.name) | $($check.status) | $evidence | $expected |")
}
$lines.Add('')
$lines.Add('## Product Ready Meaning')
$lines.Add('')
$lines.Add('This preflight proves the monitoring stack is configured and dashboard/alert artifacts are present. Product Ready still requires a deployed stack with live scrape, dashboard load, and alert delivery evidence.')
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[monitoring-preflight] passed=$passed, failed=$($failed.Count), skipped=$skipped"
Write-Host "[monitoring-preflight] report: $reportPath"
Write-Host "[monitoring-preflight] summary: $summaryPath"

if ($failed.Count -gt 0) {
  exit 1
}
exit 0
