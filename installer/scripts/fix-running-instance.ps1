# Fix running instance: F-01 (random JWT secret) + F-04 (remove DB password from NSSM args)
# Safe to run on already-installed BestChange environment

$ErrorActionPreference = 'Stop'
$configPath = 'C:\ProgramData\BestChange\config\application-local.properties'

# --- F-01: Generate random JWT secret ---
Write-Host "F-01: Generating random JWT secret..."
$bytes = New-Object byte[] 48
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$newSecret = [Convert]::ToBase64String($bytes)
Write-Host "  New secret length: $($newSecret.Length) chars"

# Update config file
$config = Get-Content $configPath -Raw
$config = $config -replace 'jwt\.secret=.*', "jwt.secret=$newSecret"
Set-Content $configPath -Value $config -Encoding UTF8 -NoNewline
Write-Host "  Config updated: $configPath"

# Verify
$verify = Select-String -Path $configPath -Pattern 'jwt\.secret=' | ForEach-Object { $_.Line }
if ($verify -match 'BestChangeLocalPenztarJWT2026SecretKey') {
    Write-Host "  ERROR: Hardcoded secret still present!" -ForegroundColor Red
    exit 1
}
Write-Host "  F-01 VERIFIED: Hardcoded secret removed" -ForegroundColor Green

# --- FK-091: HQ vészkijárat (local profil, nem application-production.properties) ---
Write-Host ""
Write-Host "FK-091: Ensuring evening.closing.artifact-success-enabled=true..."
if ($config -notmatch '(?m)^evening\.closing\.artifact-success-enabled=') {
    $config = $config.TrimEnd() + "`nevening.closing.artifact-success-enabled=true`n"
    Set-Content $configPath -Value $config -Encoding UTF8 -NoNewline
    Write-Host "  FK-091: property appended" -ForegroundColor Green
} elseif ($config -match '(?m)^evening\.closing\.artifact-success-enabled=false') {
    $config = $config -replace '(?m)^evening\.closing\.artifact-success-enabled=false', 'evening.closing.artifact-success-enabled=true'
    Set-Content $configPath -Value $config -Encoding UTF8 -NoNewline
    Write-Host "  FK-091: property upgraded false -> true" -ForegroundColor Green
} else {
    Write-Host "  FK-091: already enabled" -ForegroundColor Green
}

# --- F-04: Remove DB password from NSSM AppParameters ---
Write-Host ""
Write-Host "F-04: Fixing NSSM AppParameters..."
$nssmPath = 'C:\ProgramData\BestChange\tools\nssm.exe'

# Read current params
$currentParams = & $nssmPath get BestChange-Backend AppParameters 2>&1
Write-Host "  Current: $currentParams"

# New params: only jar + config location + profile (no DB password)
$newParams = '-jar valuta-backend.jar --spring.config.additional-location=file:../config/ --spring.profiles.active=local'

# Stop backend, update, restart
Write-Host "  Stopping backend..."
& net stop BestChange-Backend 2>$null
Start-Sleep -Seconds 3

& $nssmPath set BestChange-Backend AppParameters $newParams
Write-Host "  Updated AppParameters: $newParams"

Write-Host "  Starting backend..."
& net start BestChange-Backend
Start-Sleep -Seconds 5

# Verify NSSM params
$verifyParams = & $nssmPath get BestChange-Backend AppParameters 2>&1
Write-Host "  Verify: $verifyParams"
if ($verifyParams -match 'password') {
    Write-Host "  ERROR: DB password still in AppParameters!" -ForegroundColor Red
    exit 1
}
Write-Host "  F-04 VERIFIED: DB password removed from AppParameters" -ForegroundColor Green

# --- Health check ---
Write-Host ""
Write-Host "Waiting for backend health (max 60s)..."
$ok = $false
for ($i = 1; $i -le 30; $i++) {
    Start-Sleep -Seconds 2
    try {
        $r = Invoke-WebRequest -Uri http://localhost:8080/actuator/health -UseBasicParsing -TimeoutSec 3
        if ($r.StatusCode -eq 200) {
            Write-Host "  Backend healthy after $($i*2)s" -ForegroundColor Green
            $ok = $true
            break
        }
    } catch {}
}
if (-not $ok) {
    Write-Host "  WARNING: Backend not healthy after 60s" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== ALL FIXES APPLIED ===" -ForegroundColor Green
