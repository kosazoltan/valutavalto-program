param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$PrometheusImage = 'prom/prometheus:v2.53.2'
)

$ErrorActionPreference = 'Stop'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $WorkspaceRoot 'scripts\monitoring-preflight.ps1') `
  -WorkspaceRoot $WorkspaceRoot `
  -PrometheusImage $PrometheusImage

if ($LASTEXITCODE -ne 0) {
  throw "monitoring-preflight.ps1 failed with exit code $LASTEXITCODE"
}
