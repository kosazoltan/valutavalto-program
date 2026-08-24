#!/usr/bin/env pwsh
# CI wrapper for check-version-bump.ps1 (signed release + local installer builds).
# Sets GITHUB_OUTPUT keys: version, bumped (true|false) when running in Actions.
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
)

$ErrorActionPreference = 'Stop'

$gateScript = Join-Path $RepoRoot 'installer/scripts/check-version-bump.ps1'
$buildDir = Join-Path $RepoRoot 'installer/build'
$current = (Get-Content (Join-Path $RepoRoot 'package.json') -Raw | ConvertFrom-Json).version

$gateOutput = & pwsh -NoLogo -NoProfile -File $gateScript `
    -RepoRoot $RepoRoot `
    -BuildDir $buildDir `
    -CurrentVersion $current 2>&1

$gateOutput | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$versionLine = $gateOutput | Where-Object { $_ -match '^(BUMPED_VERSION|KEPT_VERSION)=\d+\.\d+\.\d+$' } | Select-Object -Last 1
if ($versionLine -notmatch '^(BUMPED_VERSION|KEPT_VERSION)=(\d+\.\d+\.\d+)$') {
    Write-Error 'VERSION BUMP GATE: missing BUMPED_VERSION|KEPT_VERSION line in gate output.'
    exit 2
}

$resolvedVersion = $Matches[2]
$bumped = $Matches[1] -eq 'BUMPED_VERSION'

Write-Host "CI version gate: v$resolvedVersion (bumped=$bumped)" -ForegroundColor Cyan

if ($env:GITHUB_OUTPUT) {
    "version=$resolvedVersion" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "bumped=$bumped" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

exit 0
