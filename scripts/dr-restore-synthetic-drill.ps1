param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$DockerImage = 'postgres:16-alpine',
  [string]$ContainerName,
  [string]$PostgresContainerPassword
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
if (-not $ContainerName) {
  $ContainerName = "vv-dr-restore-drill-$timestamp"
}
if (-not $PostgresContainerPassword) {
  $PostgresContainerPassword = "vv-$timestamp-$([Guid]::NewGuid().ToString('N'))"
}

$dumpDir = Join-Path ([System.IO.Path]::GetTempPath()) "vv-dr-restore-drill-$timestamp"
$dumpPath = Join-Path $dumpDir 'minimal-dr.sql'
New-Item -ItemType Directory -Path $dumpDir -Force | Out-Null

@'
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  entry_hash TEXT NOT NULL,
  previous_hash TEXT
);
CREATE TABLE "transaction" (
  id BIGSERIAL PRIMARY KEY
);
CREATE TABLE aml_report (
  id BIGSERIAL PRIMARY KEY
);
CREATE TABLE customer (
  id BIGSERIAL PRIMARY KEY
);
CREATE TABLE flyway_schema_history (
  installed_rank INTEGER PRIMARY KEY,
  version TEXT,
  description TEXT,
  success BOOLEAN NOT NULL
);
INSERT INTO audit_log(entry_hash, previous_hash) VALUES ('hash-1', NULL), ('hash-2', 'hash-1');
INSERT INTO "transaction" DEFAULT VALUES;
INSERT INTO aml_report DEFAULT VALUES;
INSERT INTO customer DEFAULT VALUES;
INSERT INTO flyway_schema_history(installed_rank, version, description, success) VALUES (1, '1', 'baseline', true);
'@ | Set-Content -LiteralPath $dumpPath -Encoding UTF8

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
  throw 'docker not found on PATH'
}

$previousPgPassword = $env:PGPASSWORD
$existing = & docker ps -aq --filter "name=^/$ContainerName$"
if ($existing) {
  & docker rm -f $ContainerName | Out-Null
}

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

  $portLine = & docker port $ContainerName 5432/tcp
  if ($portLine -notmatch ':(\d+)$') {
    throw "cannot parse mapped postgres port: $portLine"
  }
  $mappedPort = [int]$Matches[1]

  $env:PGPASSWORD = $PostgresContainerPassword
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $WorkspaceRoot 'scripts\dr-restore-drill.ps1') `
    -ExecuteRestore `
    -UseDockerTools `
    -EvidenceKind synthetic-tooling-smoke `
    -ConfirmIsolatedScratchTarget `
    -DumpPath $dumpPath `
    -TargetHost localhost `
    -TargetPort $mappedPort `
    -TargetUser postgres `
    -TargetDatabase "valuta_dr_synthetic_$timestamp" `
    -DockerImage $DockerImage

  if ($LASTEXITCODE -ne 0) {
    throw "dr-restore-drill.ps1 failed with exit code $LASTEXITCODE"
  }
} finally {
  if ($null -eq $previousPgPassword) {
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
  } else {
    $env:PGPASSWORD = $previousPgPassword
  }
  & docker rm -f $ContainerName | Out-Null
  Remove-Item -LiteralPath $dumpDir -Recurse -Force -ErrorAction SilentlyContinue
}
