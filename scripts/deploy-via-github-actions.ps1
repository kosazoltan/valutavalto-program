# GitHub Actions workflow indítása a telepítéshez
# Ez a script elindítja a GitHub Actions deployment workflow-t

param(
    [string]$Owner = "kosazoltan",
    [string]$Repo = "valutavalto-program",
    [string]$WorkflowId = "deploy-to-hetzner.yml"
)

$ErrorActionPreference = "Stop"

Write-Host "=== GitHub Actions Deployment Indítása ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Fontos:" -ForegroundColor Yellow
Write-Host "- A GitHub Secrets-eknek be kell lenniük állítva!" -ForegroundColor White
Write-Host "- HETZNER_SSH_PRIVATE_KEY" -ForegroundColor Gray
Write-Host "- HETZNER_SERVER_IP" -ForegroundColor Gray
Write-Host "- HETZNER_SSH_USER" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Biztosan elindítod a deployment workflow-t? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Mégse." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "A deployment workflow manuálisan indítható:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Menj a GitHub repository-ba:" -ForegroundColor White
Write-Host "   https://github.com/$Owner/$Repo" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Kattints az 'Actions' fülre" -ForegroundColor White
Write-Host ""
Write-Host "3. Válaszd ki a 'Deploy to Hetzner VPS' workflow-t" -ForegroundColor White
Write-Host ""
Write-Host "4. Kattints a 'Run workflow' gombra" -ForegroundColor White
Write-Host ""
Write-Host "5. Válaszd ki a 'main' branch-et" -ForegroundColor White
Write-Host ""
Write-Host "6. Kattints a zöld 'Run workflow' gombra" -ForegroundColor White
Write-Host ""
Write-Host "A workflow automatikusan:" -ForegroundColor Green
Write-Host "  ✓ SSH-val kapcsolódik a VPS-hez" -ForegroundColor Gray
Write-Host "  ✓ Deploy-olja az adatbázis sémát" -ForegroundColor Gray
Write-Host "  ✓ Deploy-olja a backend-et" -ForegroundColor Gray
Write-Host ""

