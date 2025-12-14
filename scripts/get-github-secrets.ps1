# GitHub Secrets lekérése GitHub API-val
# Szükséges: GitHub Personal Access Token (repo scope)

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    [string]$Owner = "kosazoltan",
    [string]$Repo = "valutavalto-program"
)

$ErrorActionPreference = "Stop"

Write-Host "=== GitHub Secrets Lekérése ===" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "https://api.github.com/repos/$Owner/$Repo"

# Headers
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "Authorization" = "token $GitHubToken"
}

try {
    # Secrets listázása (csak a neveket adja vissza, nem az értékeket)
    Write-Host "GitHub Secrets listázása..." -ForegroundColor Yellow
    $secretsUrl = "$baseUrl/actions/secrets"
    
    $response = Invoke-RestMethod -Uri $secretsUrl -Headers $headers -Method Get
    
    Write-Host ""
    Write-Host "Talált Secrets:" -ForegroundColor Green
    Write-Host ""
    
    $secrets = $response.secrets
    if ($secrets.Count -eq 0) {
        Write-Host "Nincs beállított secret!" -ForegroundColor Yellow
    } else {
        foreach ($secret in $secrets) {
            Write-Host "  - $($secret.name)" -ForegroundColor White
            Write-Host "    Updated: $($secret.updated_at)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Fontos:" -ForegroundColor Yellow
    Write-Host "- A GitHub API nem adja vissza a secret értékeket biztonsági okokból" -ForegroundColor Gray
    Write-Host "- Csak a secret neveket és frissítési dátumokat lehet lekérni" -ForegroundColor Gray
    Write-Host "- Az értékeket csak a GitHub Actions workflow-ban lehet használni" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Szükséges Secrets a telepítéshez:" -ForegroundColor Cyan
    Write-Host "  1. HETZNER_SSH_PRIVATE_KEY" -ForegroundColor White
    Write-Host "  2. HETZNER_SERVER_IP" -ForegroundColor White
    Write-Host "  3. HETZNER_SSH_USER" -ForegroundColor White
    Write-Host "  4. DB_USERNAME (opcionális)" -ForegroundColor Gray
    Write-Host "  5. DB_PASSWORD (opcionális)" -ForegroundColor Gray
    Write-Host "  6. DB_NAME (opcionális)" -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "Hiba történt: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Lehetséges okok:" -ForegroundColor Yellow
    Write-Host "1. Hibás GitHub Token" -ForegroundColor Gray
    Write-Host "2. Nincs repo hozzáférés" -ForegroundColor Gray
    Write-Host "3. A token-nek 'repo' scope-ja kell" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "=== Kész ===" -ForegroundColor Green

