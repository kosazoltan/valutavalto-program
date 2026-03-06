# Deployment inditasa - GitHub Actions workflow

Write-Host "=== Deployment Inditasa ===" -ForegroundColor Green
Write-Host ""

$actionsUrl = "https://github.com/kosazoltan/valutavalto-program/actions/workflows/deploy-to-vps.yml"

Write-Host "GitHub Actions Deployment" -ForegroundColor Cyan
Write-Host ""
Write-Host "A deployment inditasahoz:" -ForegroundColor Yellow
Write-Host "1. Nyisd meg az Actions oldalt:" -ForegroundColor White
Write-Host "   $actionsUrl" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Kattints a Run workflow gombra (jobb felső sarok)" -ForegroundColor White
Write-Host ""
Write-Host "3. Valaszd ki a main branch-et" -ForegroundColor White
Write-Host ""
Write-Host "4. Kattints a zold Run workflow gombra" -ForegroundColor White
Write-Host ""
Write-Host "A workflow automatikusan:" -ForegroundColor Green
Write-Host "  SSH kapcsolat (GitHub Secrets: VPS_SSH_PRIVATE_KEY)" -ForegroundColor Gray
Write-Host "  Deploy adatbazis semat (valuta_schema.sql)" -ForegroundColor Gray
Write-Host "  Deploy backend (Spring Boot)" -ForegroundColor Gray
Write-Host "  Deploy frontend (React)" -ForegroundColor Gray
Write-Host ""

# Megnyitas bongeszoben
$response = Read-Host "Szeretned megnyitni a GitHub Actions oldalt a bongeszoben? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Start-Process $actionsUrl
    Write-Host ""
    Write-Host "Bongesző megnyitva!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ne felejtsd el:" -ForegroundColor Yellow
    Write-Host "- Kattints a Run workflow gombra" -ForegroundColor White
    Write-Host "- Valaszd a main branch-et" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Manuálisan nyisd meg:" -ForegroundColor Yellow
    Write-Host $actionsUrl -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Keszen ===" -ForegroundColor Green
