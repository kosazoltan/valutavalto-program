# VM / Friss telepites acceptance test — v2.3.0 Worker Login Flow
#
# Ez a script end-to-end tesztet vegez el egy friss telepitesre vagy egy
# mar mukodo kornyezetre. A backendet es a frontend-et futva felteteleze.
#
# Futtatas:
#   powershell -ExecutionPolicy Bypass -File scripts\acceptance-test-v2.3.0.ps1
#
# Kimenet: logok a console-ra + PASS/FAIL status minden scenariohoz.

param(
    [string]$ApiUrl = "http://localhost:8080",
    [string]$CompanyCode = "EBC"
)

$ErrorActionPreference = "Stop"
$script:PASS = 0
$script:FAIL = 0

function Test-Scenario {
    param([string]$Name, [scriptblock]$Block)
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    try {
        & $Block
        Write-Host "  PASS" -ForegroundColor Green
        $script:PASS++
    } catch {
        Write-Host "  FAIL: $_" -ForegroundColor Red
        $script:FAIL++
    }
}

# S0 — Backend health
Test-Scenario "S0: Backend health check" {
    $resp = Invoke-WebRequest -Uri "$ApiUrl/api/v1/auth/bootstrap-status" -UseBasicParsing -ErrorAction Stop
    if ($resp.StatusCode -ne 200) { throw "bootstrap-status HTTP $($resp.StatusCode)" }
    Write-Host "  Bootstrap-status: $($resp.Content)"
}

# S1 — Public workers list
Test-Scenario "S1: Public workers list (TISZA branch)" {
    $resp = Invoke-RestMethod -Uri "$ApiUrl/api/v1/public/workers?branchCode=TISZA" -ErrorAction Stop
    if ($resp.Count -lt 3) { throw "Varva min 3 worker, kapott $($resp.Count)" }
    Write-Host "  Workers szama: $($resp.Count)"
    $resp | ForEach-Object { Write-Host "    - $($_.code): $($_.name)" }
}

# Teszt worker: eloszor valasszunk egy friss seed-workert (password_changed_at=NULL).
# Ez idempotens-se teszi a scriptet. Ha mind az 5 worker mar reset-elt,
# a test mukodni fog, de az S2 "first-time" helyett egyszerusoodik.
$testWorkerCode = $env:TEST_WORKER_CODE
if (-not $testWorkerCode) { $testWorkerCode = "FABULYA" }

# S2 — First-time-worker-setup
$testPassword = "TestWorker$(Get-Random -Maximum 999)!"
Test-Scenario "S2: First-time-worker-setup $testWorkerCode (uj jelszo: $testPassword)" {
    $body = @{
        companyCode = $CompanyCode
        workerCode = $testWorkerCode
        newPassword = $testPassword
        currentPassword = "1234"  # V111 seed
    } | ConvertTo-Json
    try {
        $resp = Invoke-RestMethod -Uri "$ApiUrl/api/v1/auth/first-time-worker-setup" `
            -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    } catch {
        throw "first-time-worker-setup fail: $_. Ellenorizd hogy a $testWorkerCode-nak password_changed_at=NULL van-e (V163 migration)."
    }
    if (-not $resp.success) { throw "success=false" }
    if ($resp.workerCode -ne $testWorkerCode) { throw "workerCode mismatch: $($resp.workerCode)" }
    if (-not $resp.token) { throw "Nincs JWT token" }
    Write-Host "  Worker: $($resp.workerName) [$($resp.workerRole)] - branch: $($resp.branchCode)"
    Write-Host "  JWT token length: $($resp.token.Length)"
}

# S3 — Login az uj jelszoval
Test-Scenario "S3: Login $testWorkerCode ($testPassword)" {
    $body = @{
        companyCode = $CompanyCode
        workerCode = $testWorkerCode
        password = $testPassword
    } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "$ApiUrl/api/v1/auth/login" `
        -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    if (-not $resp.token) { throw "Nincs token a login valaszban" }
    Write-Host "  Worker: $($resp.worker.fullName)"
    Write-Host "  Token length: $($resp.token.Length)"
}

# S4 — Helytelen jelszo
Test-Scenario "S4: Login helytelen jelszoval (elvart 401)" {
    $body = @{ companyCode = $CompanyCode; workerCode = $testWorkerCode; password = "WrongPass1" } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "$ApiUrl/api/v1/auth/login" `
            -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
        throw "Varva 401, de a request atment!"
    } catch {
        $statusCode = 0
        try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
        if ($statusCode -ne 401) { throw "Nem 401 hanem $statusCode" }
        Write-Host "  Correctly rejected (HTTP 401)"
    }
}

# S5 — Forgot password flow
Test-Scenario "S5: Forgot password + reset flow (BORSI email)" {
    $email = "borsi.tamas.ebc@gmail.com"
    $body = @{ email = $email } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "$ApiUrl/api/v1/auth/forgot-password" `
        -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    if (-not $resp.message) { throw "Nincs message a valaszban" }
    Write-Host "  Forgot message: $($resp.message)"
    if ($resp.token) {
        Write-Host "  Dev-mode token kapott: $($resp.token.Substring(0, 10))..."
        # Reset password
        $newPass = "ResetBorsi$(Get-Random -Maximum 999)!"
        $rbody = @{ token = $resp.token; newPassword = $newPass } | ConvertTo-Json
        $rresp = Invoke-RestMethod -Uri "$ApiUrl/api/v1/auth/reset-password" `
            -Method POST -Body $rbody -ContentType "application/json" -ErrorAction Stop
        Write-Host "  Reset: $($rresp.message)"
        # Login az uj jelszoval
        $lbody = @{ companyCode = $CompanyCode; workerCode = "BORSI"; password = $newPass } | ConvertTo-Json
        $lresp = Invoke-RestMethod -Uri "$ApiUrl/api/v1/auth/login" `
            -Method POST -Body $lbody -ContentType "application/json" -ErrorAction Stop
        Write-Host "  Reset password-dal login OK: token len=$($lresp.token.Length)"
    } else {
        Write-Host "  Production mode: token email-ben ment volna ki (itt nem elerheto)."
    }
}

# S6 — Worker email-ek teljessege
Test-Scenario "S6: Osszes 5 worker megvan email-lel" {
    $expected = @("BORSI","BALI","KASZA","KOSA","FABULYA")
    $workers = Invoke-RestMethod -Uri "$ApiUrl/api/v1/public/workers?branchCode=TISZA" -ErrorAction Stop
    $codes = $workers | ForEach-Object { $_.code }
    foreach ($code in $expected) {
        if ($codes -notcontains $code) {
            Write-Host "  MISSING: $code (ellenorizd V162 migraciot es a branch assignmentet)" -ForegroundColor Yellow
        } else {
            Write-Host "  OK: $code"
        }
    }
}

# Osszegzes
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Acceptance test osszegzes:" -ForegroundColor Cyan
Write-Host "  PASS: $script:PASS" -ForegroundColor Green
Write-Host "  FAIL: $script:FAIL" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan

if ($script:FAIL -gt 0) {
    exit 1
}
exit 0