# Git Push and Deploy Script
# Push-olja a változásokat Git-be és deployolja az adatbázist/VPS-t

param(
    [string]$CommitMessage = "Auto-commit: Database schema and deployment updates",
    [string]$Branch = "main",
    [switch]$SkipCommit = $false,
    [switch]$DeployDatabase = $true,
    [switch]$DeployVps = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== Git Push and Deploy Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if in git repository
if (-not (Test-Path ".git")) {
    Write-Host "✗ Not a git repository!" -ForegroundColor Red
    exit 1
}

# Check git status
$status = git status --porcelain
if ([string]::IsNullOrEmpty($status) -and -not $SkipCommit) {
    Write-Host "✓ No changes to commit" -ForegroundColor Green
} else {
    if (-not $SkipCommit) {
        Write-Host "Step 1: Staging changes..." -ForegroundColor Yellow
        git add .
        
        Write-Host ""
        Write-Host "Step 2: Committing changes..." -ForegroundColor Yellow
        git commit -m $CommitMessage
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Commit failed!" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✓ Changes committed" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Step 3: Pushing to remote..." -ForegroundColor Yellow
    
    # Try main branch, fallback to master
    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -ne $Branch) {
        Write-Host "⚠ Current branch is '$currentBranch', pushing to '$Branch'..." -ForegroundColor Yellow
    }
    
    git push origin $Branch
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Changes pushed to remote" -ForegroundColor Green
    } else {
        Write-Host "⚠ Push failed or no remote configured" -ForegroundColor Yellow
    }
}

# Deploy database schema
if ($DeployDatabase) {
    Write-Host ""
    Write-Host "Step 4: Deploying database schema..." -ForegroundColor Yellow
    
    # Check if .env exists for database connection
    if (Test-Path ".env") {
        Write-Host "Using .env for database connection..." -ForegroundColor Gray
        & "scripts/deploy-database.ps1" -Force
    } else {
        Write-Host "⚠ .env file not found. Skipping database deployment." -ForegroundColor Yellow
        Write-Host "You can deploy manually with: .\scripts\deploy-database.ps1" -ForegroundColor Cyan
    }
}

# Deploy to VPS
if ($DeployVps) {
    Write-Host ""
    Write-Host "Step 5: Deploying to VPS..." -ForegroundColor Yellow
    & "scripts/deploy-to-vps.ps1" -Force
}

Write-Host ""
Write-Host "=== Git Push and Deploy completed ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "- GitHub Actions will automatically deploy if workflow is configured" -ForegroundColor Gray
Write-Host "- Or deploy manually: scripts/deploy-to-vps.ps1" -ForegroundColor Gray

