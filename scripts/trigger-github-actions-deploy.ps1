# GitHub Actions Workflow elindítása API-n keresztül

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubAuthToken,
    [string]$Owner = "kosazoltan",
    [string]$Repo = "valutavalto-program",
    [string]$WorkflowFile = "deploy-to-hetzner.yml",
    [string]$Ref = "main"
)

$ErrorActionPreference = "Stop"

Write-Host "=== GitHub Actions Workflow Indítása ===" -ForegroundColor Cyan
Write-Host ""

$apiUrl = "https://api.github.com/repos/$Owner/$Repo/actions/workflows/$WorkflowFile/dispatches"

$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "Authorization" = "token $GitHubAuthToken"
    "Content-Type" = "application/json"
}

$body = @{
    ref = $Ref
} | ConvertTo-Json

try {
    Write-Host "Workflow indítása: $WorkflowFile" -ForegroundColor Yellow
    Write-Host "Branch: $Ref" -ForegroundColor Gray
    Write-Host ""
    
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
    
    Write-Host "✓ Workflow elindítva!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nézd meg a folyamatot:" -ForegroundColor Cyan
    Write-Host "https://github.com/$Owner/$Repo/actions" -ForegroundColor Gray
    Write-Host ""
    
    # Megnyitás böngészőben
    Start-Process "https://github.com/$Owner/$Repo/actions"
    
} catch {
    Write-Host ""
    Write-Host "✗ Hiba történt: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Lehetséges okok:" -ForegroundColor Yellow
    Write-Host "1. Hibás GitHub Token" -ForegroundColor Gray
    Write-Host "2. Nincs 'workflow' scope a token-hez" -ForegroundColor Gray
    Write-Host "3. A workflow fájl nem található" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Alternatíva: Nyisd meg manuálisan:" -ForegroundColor Cyan
    Write-Host "https://github.com/$Owner/$Repo/actions/workflows/$WorkflowFile" -ForegroundColor Gray
    exit 1
}

