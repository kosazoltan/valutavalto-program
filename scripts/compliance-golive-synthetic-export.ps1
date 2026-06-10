param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$DockerImage = 'postgres:16-alpine',
  [string]$ContainerName,
  [string]$PostgresContainerPassword
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
if (-not $ContainerName) {
  $ContainerName = "vv-compliance-golive-$timestamp"
}
if (-not $PostgresContainerPassword) {
  $PostgresContainerPassword = "vv-$timestamp-$([Guid]::NewGuid().ToString('N'))"
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
  throw 'docker not found on PATH'
}

$previousPgPassword = $env:PGPASSWORD
$existing = & docker ps -aq --filter "name=^/$ContainerName$"
if ($existing) {
  & docker rm -f $ContainerName | Out-Null
}

$seedSql = @"
CREATE TABLE system_parameter (
  parameter_key TEXT PRIMARY KEY,
  parameter_value TEXT NOT NULL,
  parameter_type TEXT NOT NULL,
  category TEXT NOT NULL,
  is_active BOOLEAN NOT NULL,
  updated_at TIMESTAMP,
  updated_by TEXT
);
INSERT INTO system_parameter(parameter_key, parameter_value, parameter_type, category, is_active, updated_at, updated_by) VALUES
('PMT_STRICT_ENFORCEMENT', 'true', 'BOOLEAN', 'COMPLIANCE', true, NOW(), 'synthetic'),
('AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT', 'true', 'BOOLEAN', 'COMPLIANCE', true, NOW(), 'synthetic'),
('AML_HIGH_VALUE_APPROVAL_ENFORCEMENT', 'false', 'BOOLEAN', 'COMPLIANCE', true, NOW(), 'synthetic'),
('AML_FATF_TIER_ENFORCEMENT', 'false', 'BOOLEAN', 'COMPLIANCE', true, NOW(), 'synthetic'),
('CIRCULAR_ACK_BLOCKING_ENFORCEMENT', 'false', 'BOOLEAN', 'COMPLIANCE', true, NOW(), 'synthetic');
"@

& docker run -d --name $ContainerName -e "POSTGRES_PASSWORD=$PostgresContainerPassword" -P $DockerImage | Out-Null
try {
  $deadline = (Get-Date).AddSeconds(45)
  $ready = $false
  do {
    Start-Sleep -Seconds 1
    & docker exec $ContainerName pg_isready -U postgres | Out-Null
    $ready = ($LASTEXITCODE -eq 0)
  } while (-not $ready -and (Get-Date) -lt $deadline)

  if (-not $ready) {
    throw 'temporary postgres container did not become ready'
  }

  $seeded = $false
  $lastSeedOutput = ''
  for ($attempt = 1; $attempt -le 5 -and -not $seeded; $attempt++) {
    $lastSeedOutput = $seedSql | & docker exec -i $ContainerName psql -U postgres -d postgres -v ON_ERROR_STOP=1 2>&1 | Out-String
    $seeded = ($LASTEXITCODE -eq 0)
    if (-not $seeded) {
      Start-Sleep -Seconds ([Math]::Min($attempt * 2, 8))
    }
  }

  if (-not $seeded) {
    $containerState = (& docker inspect -f '{{.State.Status}}' $ContainerName 2>$null | Out-String).Trim()
    $containerLogs = (& docker logs --tail 80 $ContainerName 2>&1 | Out-String).Trim()
    throw "failed to seed synthetic system_parameter table after retries; containerState=$containerState; psqlOutput=$lastSeedOutput; dockerLogs=$containerLogs"
  }

  $portLine = & docker port $ContainerName 5432/tcp
  if ($portLine -notmatch ':(\d+)$') {
    throw "cannot parse mapped postgres port: $portLine"
  }
  $mappedPort = [int]$Matches[1]

  $env:PGPASSWORD = $PostgresContainerPassword
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $WorkspaceRoot 'scripts\compliance-golive-export.ps1') `
    -ExecuteQuery `
    -UseDockerTools `
    -TargetHost localhost `
    -TargetPort $mappedPort `
    -TargetUser postgres `
    -TargetDatabase postgres `
    -DockerImage $DockerImage

  if ($LASTEXITCODE -ne 0) {
    throw "compliance-golive-export.ps1 failed with exit code $LASTEXITCODE"
  }
} finally {
  if ($null -eq $previousPgPassword) {
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
  } else {
    $env:PGPASSWORD = $previousPgPassword
  }
  & docker rm -f $ContainerName | Out-Null
}
