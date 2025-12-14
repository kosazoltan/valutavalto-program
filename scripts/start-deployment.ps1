# Deployment indítása - GitHub Actions workflow

Write-Host "=== Deployment Indítása ===" -ForegroundColor Green
Write-Host ""

$actionsUrl = "https://github.com/kosazoltan/valutavalto-program/actions/workflows/deploy-to-hetzner.yml"

Write-Host "GitHub Actions Deployment" -ForegroundColor Cyan
Write-Host ""
Write-Host "A deployment elindításához:" -ForegroundColor Yellow
Write-Host "1. Nyisd meg az Actions oldalt:" -ForegroundColor White
Write-Host "   $actionsUrl" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Kattints a 'Run workflow' gombra (jobb felső sarok)" -ForegroundColor White
Write-Host ""
Write-Host "3. Válaszd ki a 'main' branch-et" -ForegroundColor White
Write-Host ""
Write-Host "4. Kattints a zöld 'Run workflow' gombra" -ForegroundColor White
Write-Host ""
Write-Host "A workflow automatikusan:" -ForegroundColor Green
Write-Host "  ✓ SSH kapcsolat (GitHub Secrets: HETZNER_SSH_PRIVATE_KEY)" -ForegroundColor Gray
Write-Host "  ✓ Deploy adatbázis (GitHub Secrets: HETZNER_SERVER_IP)" -ForegroundColor Gray
Write-Host "  ✓ Deploy backend" -ForegroundColor Gray
Write-Host ""

# Megnyitás böngészőben
$response = Read-Host "Szeretnéd megnyitni a GitHub Actions oldalt a böngészőben? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Start-Process $actionsUrl
    Write-Host ""
    Write-Host "✓ Böngésző megnyitva!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ne felejtsd el:" -ForegroundColor Yellow
    Write-Host "- Kattints a 'Run workflow' gombra" -ForegroundColor White
    Write-Host "- Válaszd a 'main' branch-et" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Manuálisan nyisd meg:" -ForegroundColor Yellow
    Write-Host $actionsUrl -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Kész ===" -ForegroundColor Green

