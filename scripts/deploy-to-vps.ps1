# Deploy to Hetzner VPS Script
# Deploy-olja az adatbázist és/vagy a backend-et a VPS-re

param(
    [Parameter(Mandatory=$true)]
    [string]$VpsHost,
    [string]$SshUser = "root",
    [string]$SshKey = "$env:USERPROFILE\.ssh\id_rsa",
    [string]$ProjectPath = "/var/www/valutavalto",
    [switch]$DeployDatabase = $false,
    [switch]$DeployBackend = $false,
    [switch]$All = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== Deploy to Hetzner VPS ===" -ForegroundColor Cyan
Write-Host ""

if ($All) {
    $DeployDatabase = $true
    $DeployBackend = $true
}

if (-not $DeployDatabase -and -not $DeployBackend) {
    Write-Host "✗ Please specify what to deploy: -DeployDatabase, -DeployBackend, or -All" -ForegroundColor Red
    exit 1
}

# Check if SSH key exists
if (-not (Test-Path $SshKey)) {
    Write-Host "✗ SSH key not found: $SshKey" -ForegroundColor Red
    exit 1
}

Write-Host "Connection:" -ForegroundColor Cyan
Write-Host "  VPS Host: $VpsHost" -ForegroundColor Gray
Write-Host "  SSH User: $SshUser" -ForegroundColor Gray
Write-Host "  Project Path: $ProjectPath" -ForegroundColor Gray
Write-Host ""

# Test SSH connection
Write-Host "Testing SSH connection..." -ForegroundColor Yellow
try {
    ssh -i $SshKey -o StrictHostKeyChecking=no $SshUser@$VpsHost "echo 'SSH connection successful'" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "SSH connection failed"
    }
    Write-Host "✓ SSH connection successful" -ForegroundColor Green
} catch {
    Write-Host "✗ SSH connection failed: $_" -ForegroundColor Red
    exit 1
}

# Deploy database
if ($DeployDatabase) {
    Write-Host ""
    Write-Host "=== Deploying Database ===" -ForegroundColor Cyan
    
    # Check if schema file exists
    $SchemaFile = "database/schema/valuta_schema.sql"
    if (-not (Test-Path $SchemaFile)) {
        Write-Host "⚠ Schema file not found, exporting..." -ForegroundColor Yellow
        & "$PSScriptRoot\export-database-schema-only.ps1"
    }
    
    # Copy schema file to VPS
    Write-Host "Copying schema file to VPS..." -ForegroundColor Yellow
    try {
        scp -i $SshKey $SchemaFile "$SshUser@${VpsHost}:/tmp/valuta_schema.sql"
        Write-Host "✓ Schema file copied" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to copy schema file: $_" -ForegroundColor Red
        exit 1
    }
    
    # Import database on VPS
    Write-Host "Importing database on VPS..." -ForegroundColor Yellow
    try {
        # Load DB credentials from .env if exists
        $dbHost = "localhost"
        $dbPort = "5432"
        $dbName = "valuta"
        $dbUser = "valuta_user"
        $dbPass = "valuta_pass"
        
        if (Test-Path ".env") {
            Get-Content ".env" | ForEach-Object {
                if ($_ -match 'DB_HOST=(.+)') { $dbHost = $matches[1].Trim() }
                if ($_ -match 'DB_PORT=(.+)') { $dbPort = $matches[1].Trim() }
                if ($_ -match 'DB_NAME=(.+)') { $dbName = $matches[1].Trim() }
                if ($_ -match 'DB_USERNAME=(.+)') { $dbUser = $matches[1].Trim() }
                if ($_ -match 'DB_PASSWORD=(.+)') { $dbPass = $matches[1].Trim() }
            }
        }
        
        $importCmd = @"
cd $ProjectPath
export PGPASSWORD='$dbPass'
psql -h $dbHost -p $dbPort -U $dbUser -d postgres -c "DROP DATABASE IF EXISTS $dbName;" 2>&1
psql -h $dbHost -p $dbPort -U $dbUser -d postgres -c "CREATE DATABASE $dbName;" 2>&1
psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -f /tmp/valuta_schema.sql
unset PGPASSWORD
"@
        
        ssh -i $SshKey $SshUser@$VpsHost $importCmd
        Write-Host "✓ Database deployed" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to import database: $_" -ForegroundColor Red
        exit 1
    }
}

# Deploy backend
if ($DeployBackend) {
    Write-Host ""
    Write-Host "=== Deploying Backend ===" -ForegroundColor Cyan
    
    Write-Host "Pulling latest code from Git..." -ForegroundColor Yellow
    try {
        $gitPullCmd = @"
cd $ProjectPath
git pull origin main
"@
        ssh -i $SshKey $SshUser@$VpsHost $gitPullCmd
        Write-Host "✓ Code pulled" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Git pull failed (might not be a git repo): $_" -ForegroundColor Yellow
    }
    
    Write-Host "Building and restarting backend..." -ForegroundColor Yellow
    try {
        $buildCmd = @"
cd $ProjectPath/backend
mvn clean package -DskipTests
docker-compose down
docker-compose up -d --build
"@
        ssh -i $SshKey $SshUser@$VpsHost $buildCmd
        Write-Host "✓ Backend deployed and restarted" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to deploy backend: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Deployment completed ===" -ForegroundColor Green
