#Requires -Version 5.1
<#
.SYNOPSIS
  Postgres (Docker) + Spring Boot test profile + GET /actuator/health = 200.

.PARAMETER SkipDocker
  Do not run docker compose.

.PARAMETER KeepBackendRunning
  Leave Spring Boot running after success.
#>
param(
    [switch]$SkipDocker,
    [switch]$KeepBackendRunning,
    [int]$HealthWaitSec = 180
)

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Backend = Join-Path $Root 'backend'
$HealthUrl = 'http://127.0.0.1:8080/actuator/health'

function Wait-TcpOpen {
    param([string]$HostName = '127.0.0.1', [int]$Port = 5432, [int]$TimeoutSec = 60)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $c = [System.Net.Sockets.TcpClient]::new()
            $iar = $c.BeginConnect($HostName, $Port, $null, $null)
            if ($iar.AsyncWaitHandle.WaitOne(500) -and $c.Connected) {
                $c.Close()
                return $true
            }
            $c.Close()
        } catch { }
        Start-Sleep -Milliseconds 400
    }
    return $false
}

Write-Host "[verify-stack] Repo: $Root"

if (-not $SkipDocker) {
    Write-Host '[verify-stack] docker compose up -d postgres'
    Set-Location $Root
    docker compose up -d postgres 2>&1 | Out-Host
    if (-not (Wait-TcpOpen -Port 5432 -TimeoutSec 90)) {
        throw 'PostgreSQL port 5432 not reachable. Is Docker running?'
    }
    Write-Host '[verify-stack] PostgreSQL OK' -ForegroundColor Green
}

$runArgs = '--spring.profiles.active=test --spring.datasource.url=jdbc:postgresql://localhost:5432/valuta --spring.datasource.username=valuta_user --spring.datasource.password=valuta_pass'

Write-Host '[verify-stack] Starting Spring Boot (background process)...'
$logOut = [System.IO.Path]::GetTempFileName() + '-mvn-out.txt'
$logErr = [System.IO.Path]::GetTempFileName() + '-mvn-err.txt'
$runnerBat = [System.IO.Path]::GetTempFileName() + '-ztype-run.bat'
$batBody = @"
@echo off
cd /d "$Backend"
call mvnw.cmd spring-boot:run -DskipTests "-Dspring-boot.run.arguments=$runArgs" 1>"$logOut" 2>"$logErr"
"@
Set-Content -LiteralPath $runnerBat -Value $batBody -Encoding ASCII
$p = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/d', '/c', "call `"$runnerBat`"") -WorkingDirectory $Backend -PassThru -WindowStyle Hidden

$ok = $false
$deadline = (Get-Date).AddSeconds($HealthWaitSec)
while ((Get-Date) -lt $deadline) {
    try {
        $r = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 3
        if ($r.StatusCode -eq 200) {
            $body = if ($r.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($r.Content) } else { [string]$r.Content }
            Write-Host "[verify-stack] Health OK: $body" -ForegroundColor Green
            $ok = $true
            break
        }
    } catch { }
    if ($p.HasExited) {
        Write-Host "[verify-stack] Maven exited early, code=$($p.ExitCode)" -ForegroundColor Red
        break
    }
    Start-Sleep -Seconds 2
}

if (-not $KeepBackendRunning -and -not $p.HasExited) {
    Write-Host '[verify-stack] Stopping Spring Boot (tree)...'
    cmd.exe /d /c "taskkill /PID $($p.Id) /T /F" 2>$null | Out-Null
}

if (-not $ok) {
    Write-Host '[verify-stack] Last lines of mvn stderr:' -ForegroundColor Yellow
    if (Test-Path -LiteralPath $logErr) { Get-Content -LiteralPath $logErr -Tail 25 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ } }
    Write-Host '[verify-stack] Last lines of mvn stdout:' -ForegroundColor Yellow
    if (Test-Path -LiteralPath $logOut) { Get-Content -LiteralPath $logOut -Tail 25 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ } }
    throw '[verify-stack] FAILED: /actuator/health did not return 200 in time.'
}

Write-Host '[verify-stack] PASSED' -ForegroundColor Green
exit 0
