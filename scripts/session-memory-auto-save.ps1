<#
.SYNOPSIS
    Session memory auto-save wrapper (Cognee MCP + Obsidian Vault)

.DESCRIPTION
    Windows PowerShell megfelelo a scripts/session-memory-save.sh-nak.
    Automatikusan felismeri a mai session memory YAML-t
    (docs/knowledge/memory/YYYY-MM-DD-*.yaml), majd megprobalja szinkronizalni:
      - Cognee MCP server (env:COGNEE_URL / http://localhost:8820)
      - Obsidian Vault Local REST API (env:OBSIDIAN_API_KEY + host/port)

    Ha egyik szerver sem fut vagy nincs konfiguralva, csak logol es kilep 0-val.

.PARAMETER SessionFile
    Opcionalis: a konkret YAML fajl eleresi utja. Ha nincs megadva, a ma datum
    szerinti .yaml-t keresi a docs/knowledge/memory/ konyvtarban.

.PARAMETER DryRun
    Csak megmutatja, mit csinalna, tenyleges ingestion nelkul.

.EXAMPLE
    pwsh scripts/session-memory-auto-save.ps1
    # Auto-detektalja ma napot, szinkronizal ha van config.

.EXAMPLE
    pwsh scripts/session-memory-auto-save.ps1 -SessionFile docs/knowledge/memory/2026-04-24-cash-balance.yaml

.EXAMPLE
    pwsh scripts/session-memory-auto-save.ps1 -DryRun
#>

param(
    [string]$SessionFile,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Level, [string]$Message)
    $ts = Get-Date -Format 'HH:mm:ss'
    $prefix = "[session-save $ts]"
    switch ($Level) {
        'OK'    { Write-Host "$prefix $Message" -ForegroundColor Green }
        'WARN'  { Write-Host "$prefix $Message" -ForegroundColor Yellow }
        'ERR'   { Write-Host "$prefix $Message" -ForegroundColor Red }
        default { Write-Host "$prefix $Message" }
    }
}

# 1. Session file felismerese
if (-not $SessionFile) {
    $today = Get-Date -Format 'yyyy-MM-dd'
    $memoryDir = Join-Path $PSScriptRoot '..\docs\knowledge\memory'
    if (-not (Test-Path $memoryDir)) {
        Write-Log 'ERR' "Memory dir nem letezik: $memoryDir"
        exit 1
    }
    $candidates = Get-ChildItem -Path $memoryDir -Filter "$today-*.yaml" -ErrorAction SilentlyContinue
    if ($candidates.Count -eq 0) {
        Write-Log 'WARN' "Ma napra ($today) nincs session YAML. Semmi dolgunk."
        exit 0
    }
    if ($candidates.Count -gt 1) {
        Write-Log 'WARN' "$($candidates.Count) session YAML ma napra. Mind szinkronizalasra kerul."
    }
    $sessionFiles = $candidates | ForEach-Object { $_.FullName }
} else {
    if (-not (Test-Path $SessionFile)) {
        Write-Log 'ERR' "Megadott session fajl nem letezik: $SessionFile"
        exit 1
    }
    $sessionFiles = @($SessionFile)
}

$cogneeErr = 0
$obsidianErr = 0

foreach ($sf in $sessionFiles) {
    $sessionName = [System.IO.Path]::GetFileNameWithoutExtension($sf)
    Write-Log 'INFO' "Processing: $sf ($sessionName)"

    # 2. Cognee MCP
    $cogneeUrl = $env:COGNEE_URL
    if (-not $cogneeUrl) { $cogneeUrl = 'http://localhost:8820' }

    $cogneeAlive = $false
    try {
        $null = Invoke-WebRequest -Uri "$cogneeUrl/health" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        $cogneeAlive = $true
    } catch { }

    if ($cogneeAlive) {
        if ($DryRun) {
            Write-Log 'INFO' "[DRY] Cognee ingest skipped: $sf"
        } else {
            $cogneeCli = Get-Command cognee -ErrorAction SilentlyContinue
            if ($cogneeCli) {
                try {
                    & cognee add-file $sf --metadata "session=$sessionName,type=handoff,date=$(Get-Date -Format 'yyyy-MM-dd')"
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log 'OK' "Cognee: ingested $sessionName"
                    } else {
                        Write-Log 'ERR' "Cognee CLI exit=$LASTEXITCODE"
                        $cogneeErr = 1
                    }
                } catch {
                    Write-Log 'ERR' "Cognee CLI hiba: $($_.Exception.Message)"
                    $cogneeErr = 1
                }
            } else {
                Write-Log 'WARN' "Cognee CLI nincs telepitve (pip install cognee), skip"
            }
        }
    } else {
        Write-Log 'WARN' "Cognee nem fut $cogneeUrl -- skip ($sessionName)"
    }

    # 3. Obsidian Vault
    $obsKey = $env:OBSIDIAN_API_KEY
    if (-not $obsKey) {
        Write-Log 'WARN' "OBSIDIAN_API_KEY nincs beallitva -- skip ($sessionName)"
        continue
    }

    $obsHost = if ($env:OBSIDIAN_HOST) { $env:OBSIDIAN_HOST } else { 'localhost' }
    $obsPort = if ($env:OBSIDIAN_PORT) { $env:OBSIDIAN_PORT } else { '27124' }
    $obsProto = if ($env:OBSIDIAN_PROTOCOL) { $env:OBSIDIAN_PROTOCOL } else { 'https' }
    $obsUrl = "${obsProto}://${obsHost}:${obsPort}"

    $obsAlive = $false
    try {
        $null = Invoke-WebRequest -Uri "$obsUrl/" -Headers @{ Authorization = "Bearer $obsKey" } `
            -TimeoutSec 3 -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        $obsAlive = $true
    } catch { }

    if (-not $obsAlive) {
        Write-Log 'WARN' "Obsidian nem fut $obsUrl -- skip ($sessionName)"
        continue
    }

    $qmdFile = [System.IO.Path]::ChangeExtension($sf, '.qmd')
    if (Test-Path $qmdFile) {
        $content = Get-Content $qmdFile -Raw -Encoding UTF8
    } else {
        $yamlBody = Get-Content $sf -Raw -Encoding UTF8
        $content = "---`n$yamlBody`n---`n"
    }

    $obsPath = "Sessions/$sessionName.md"

    if ($DryRun) {
        $size = [System.Text.Encoding]::UTF8.GetByteCount($content)
        Write-Log 'INFO' "[DRY] Obsidian PUT $obsPath ($size bytes)"
    } else {
        try {
            $resp = Invoke-WebRequest -Uri "$obsUrl/vault/$obsPath" -Method Put `
                -Headers @{ Authorization = "Bearer $obsKey"; 'Content-Type' = 'text/markdown; charset=utf-8' } `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($content)) `
                -SkipCertificateCheck -UseBasicParsing -ErrorAction Stop
            if ($resp.StatusCode -in 200, 204) {
                Write-Log 'OK' "Obsidian: PUT $obsPath (HTTP $($resp.StatusCode))"
            } else {
                Write-Log 'ERR' "Obsidian PUT unexpected HTTP $($resp.StatusCode)"
                $obsidianErr = 2
            }
        } catch {
            Write-Log 'ERR' "Obsidian PUT hiba: $($_.Exception.Message)"
            $obsidianErr = 2
        }
    }
}

$exitCode = $cogneeErr + $obsidianErr
if ($exitCode -eq 0) {
    Write-Log 'OK' "Session memory auto-save COMPLETE"
} else {
    Write-Log 'WARN' "Session memory auto-save partial (exit=$exitCode)"
}
exit $exitCode