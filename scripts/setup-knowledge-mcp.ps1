<#
.SYNOPSIS
    Knowledge MCP stack diagnostic (Cognee MCP + Obsidian Local REST API)

.DESCRIPTION
    Ellenorzi a session-memory auto-save infrastrukturat:
      1. Docker Desktop / Docker Engine fut-e
      2. Cognee backend (vagy mcp-cognee) elerheto-e
      3. Obsidian desktop app telepitve-e
      4. Obsidian Local REST API plugin fut-e (port 27124/27123)
      5. Env var-ok (COGNEE_URL, COGNEE_LLM_API_KEY, OBSIDIAN_API_KEY)

    Minden ellenorzes eredmenyet szines zaszlokkal kilistazza, majd
    a hianyzo lepesekhez linkeket / parancsokat ad.

.PARAMETER Verbose
    Részletes Docker container + curl output.

.EXAMPLE
    pwsh scripts/setup-knowledge-mcp.ps1
#>

param(
    [switch]$ShowDetails
)

$ErrorActionPreference = 'Continue'

function Write-Check {
    param(
        [string]$Label,
        [ValidateSet('OK','WARN','FAIL','INFO')]
        [string]$Status,
        [string]$Detail = ''
    )
    $icon = @{OK='OK '; WARN='!! '; FAIL='XX '; INFO='.. '}[$Status]
    $color = @{OK='Green'; WARN='Yellow'; FAIL='Red'; INFO='Cyan'}[$Status]
    Write-Host "[$icon] $Label" -NoNewline -ForegroundColor $color
    if ($Detail) { Write-Host " - $Detail" -ForegroundColor Gray } else { Write-Host '' }
}

Write-Host ""
Write-Host "=== Knowledge MCP stack diagnostic ===" -ForegroundColor Cyan
Write-Host "   (session-memory auto-save infra)" -ForegroundColor Gray
Write-Host ""

$issues = 0

# 1. Docker
Write-Host "[1/5] Docker Engine" -ForegroundColor White
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Check 'Docker CLI' 'FAIL' 'nincs telepitve'
    Write-Host '       -> https://docs.docker.com/desktop/install/windows-install/' -ForegroundColor Gray
    $issues++
} else {
    try {
        $ver = & docker version --format '{{.Server.Version}}' 2>$null
        if ($ver) {
            Write-Check 'Docker Engine' 'OK' "v$ver"
        } else {
            Write-Check 'Docker Engine' 'FAIL' 'daemon nem fut (Docker Desktop elinditva?)'
            $issues++
        }
    } catch {
        Write-Check 'Docker Engine' 'FAIL' $_.Exception.Message
        $issues++
    }
}

# 2. Cognee backend
Write-Host ""
Write-Host "[2/5] Cognee backend" -ForegroundColor White
$cogneeCandidates = @(
    @{ Url='http://localhost:8098'; Name='cognee-backend (raw REST)' },
    @{ Url='http://localhost:8820'; Name='mcp-cognee (supergateway)' },
    @{ Url=$env:COGNEE_URL;         Name='env:COGNEE_URL' }
)
$cogneeAlive = $false
foreach ($c in $cogneeCandidates) {
    if (-not $c.Url) { continue }
    try {
        $resp = Invoke-WebRequest -Uri "$($c.Url)/health" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            $body = $resp.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
            $ver = if ($body.version) { " v$($body.version)" } else { '' }
            Write-Check "Cognee at $($c.Url)" 'OK' "$($c.Name)$ver"
            $cogneeAlive = $true
            $env:DETECTED_COGNEE_URL = $c.Url
            break
        }
    } catch {
        Write-Check "Cognee at $($c.Url)" 'INFO' 'nem fut'
    }
}
if (-not $cogneeAlive) {
    Write-Check 'Cognee MCP/backend' 'FAIL' 'egyik sem elerheto'
    Write-Host '       -> docker compose -f docker-compose.yml -f docker-compose.mcp.yml --profile knowledge-mcp up -d' -ForegroundColor Gray
    $issues++
}

# 3. Cognee CLI (opcionalis, a ps1 script-tel hasznalatos)
Write-Host ""
Write-Host "[3/5] Cognee CLI (opcionalis)" -ForegroundColor White
$cogneeCli = Get-Command cognee -ErrorAction SilentlyContinue
if ($cogneeCli) {
    Write-Check 'cognee CLI' 'OK' $cogneeCli.Source
} else {
    Write-Check 'cognee CLI' 'WARN' 'nincs telepitve (REST API-n keresztul hasznalhato)'
    Write-Host '       -> pip install cognee   (ha CLI-t szeretnel)' -ForegroundColor Gray
}

# 4. Obsidian Local REST API
Write-Host ""
Write-Host "[4/5] Obsidian Local REST API" -ForegroundColor White
$obsInstallPath = "$env:LOCALAPPDATA\Programs\Obsidian"
if (Test-Path $obsInstallPath) {
    Write-Check 'Obsidian asztali app' 'OK' $obsInstallPath
} else {
    Write-Check 'Obsidian asztali app' 'FAIL' 'nincs telepitve'
    Write-Host '       -> https://obsidian.md/download' -ForegroundColor Gray
    $issues++
}

$obsReachable = $false
foreach ($probe in @(@{u='https://localhost:27124'; p='https'}, @{u='http://localhost:27123'; p='http'})) {
    try {
        $null = Invoke-WebRequest -Uri $probe.u -TimeoutSec 2 -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        Write-Check "Obsidian REST API $($probe.p)" 'OK' $probe.u
        $obsReachable = $true
        $env:DETECTED_OBSIDIAN_URL = $probe.u
        break
    } catch {
        if ($_.Exception.Message -match 'authorized' -or $_.Exception.Response.StatusCode -eq 401) {
            Write-Check "Obsidian REST API $($probe.p)" 'OK' "$($probe.u) (401 = plugin fut, API key nelkul)"
            $obsReachable = $true
            $env:DETECTED_OBSIDIAN_URL = $probe.u
            break
        }
    }
}
if (-not $obsReachable) {
    Write-Check 'Obsidian Local REST API plugin' 'FAIL' 'port 27124/27123 nem valaszol'
    Write-Host '       -> Obsidian > Settings > Community plugins > Browse' -ForegroundColor Gray
    Write-Host '       -> "Local REST API" (coddingtonbear) install + enable' -ForegroundColor Gray
    Write-Host '       -> Settings > Local REST API > API key masolas' -ForegroundColor Gray
    $issues++
}

# 5. Env var-ok
Write-Host ""
Write-Host "[5/5] Env var-ok" -ForegroundColor White
if ($env:COGNEE_LLM_API_KEY) {
    Write-Check 'COGNEE_LLM_API_KEY' 'OK' "beallitva (***$($env:COGNEE_LLM_API_KEY.Substring([Math]::Max(0,$env:COGNEE_LLM_API_KEY.Length-4))))"
} else {
    if ($cogneeAlive -and $env:DETECTED_COGNEE_URL -eq 'http://localhost:8098') {
        Write-Check 'COGNEE_LLM_API_KEY' 'INFO' 'felesleges (a mar futo cognee-backend sajat kulcsot hasznal)'
    } else {
        Write-Check 'COGNEE_LLM_API_KEY' 'WARN' 'nincs beallitva (szukseges mcp-cognee konteneres modban)'
        Write-Host '       -> $env:COGNEE_LLM_API_KEY = "sk-..."' -ForegroundColor Gray
    }
}

if ($env:OBSIDIAN_API_KEY) {
    Write-Check 'OBSIDIAN_API_KEY' 'OK' "beallitva (***$($env:OBSIDIAN_API_KEY.Substring([Math]::Max(0,$env:OBSIDIAN_API_KEY.Length-4))))"
} else {
    Write-Check 'OBSIDIAN_API_KEY' 'WARN' 'nincs beallitva'
    Write-Host '       -> $env:OBSIDIAN_API_KEY = "<key from Obsidian Settings>"' -ForegroundColor Gray
    if ($obsReachable) { $issues++ }
}

# Osszegzes
Write-Host ""
Write-Host "=== Osszefoglalas ===" -ForegroundColor Cyan
if ($issues -eq 0) {
    Write-Host "[OK ] MINDEN READY - session-memory-auto-save.ps1 mar futtathato" -ForegroundColor Green
    Write-Host ""
    Write-Host "Teszt:" -ForegroundColor White
    Write-Host "  pwsh scripts/session-memory-auto-save.ps1 -DryRun" -ForegroundColor Gray
} else {
    Write-Host "[!! ] $issues problema detektalva - lepesek fent" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Javaslat (minimum):" -ForegroundColor White
    Write-Host "  1. Cognee: ha kell uj instance -> docker compose up -d a --profile knowledge-mcp-vel" -ForegroundColor Gray
    Write-Host "  2. Obsidian: Local REST API plugin manualis install + API key export" -ForegroundColor Gray
    Write-Host "  3. Env: `$env:COGNEE_URL, `$env:COGNEE_LLM_API_KEY, `$env:OBSIDIAN_API_KEY" -ForegroundColor Gray
}
Write-Host ""

exit $issues