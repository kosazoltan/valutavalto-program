# Database Deploy Script
# Törli és újraimportálja az adatbázis sémát (fresh start)

param(
    [string]$Host = "localhost",
    [int]$Port = 5432,
    [string]$Database = "valuta",
    [string]$Username = "valuta_user",
    [string]$Password = "valuta_pass",
    [string]$SchemaFile = "database/schema/valuta_schema.sql",
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== Database Deploy Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if psql is available
try {
    $psqlVersion = psql --version 2>&1
    Write-Host "✓ psql found: $psqlVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ psql not found!" -ForegroundColor Red
    Write-Host "Please install PostgreSQL client tools" -ForegroundColor Yellow
    exit 1
}

# Check if schema file exists
if (-not (Test-Path $SchemaFile)) {
    Write-Host "✗ Schema file not found: $SchemaFile" -ForegroundColor Red
    Write-Host "Please export schema first: .\scripts\export-database-schema-only.ps1" -ForegroundColor Yellow
    exit 1
}

$env:PGPASSWORD = $Password

Write-Host "⚠ WARNING: This will DROP and RECREATE the database!" -ForegroundColor Red
Write-Host "  Host: $Host" -ForegroundColor Gray
Write-Host "  Database: $Database" -ForegroundColor Gray
Write-Host "  Schema file: $SchemaFile" -ForegroundColor Gray
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Are you sure? (type 'yes' to continue)"
    if ($confirm -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        Remove-Item Env:\PGPASSWORD
        exit 0
    }
}

Write-Host ""
Write-Host "Step 1: Dropping existing database..." -ForegroundColor Yellow
try {
    # Connect to postgres database to drop the target database
    psql -h $Host -p $Port -U $Username -d postgres -c "DROP DATABASE IF EXISTS $Database;" 2>&1 | Out-Null
    Write-Host "✓ Database dropped" -ForegroundColor Green
} catch {
    Write-Host "⚠ Warning: Failed to drop database (might not exist): $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Creating new database..." -ForegroundColor Yellow
try {
    psql -h $Host -p $Port -U $Username -d postgres -c "CREATE DATABASE $Database;" 2>&1 | Out-Null
    Write-Host "✓ Database created" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create database: $_" -ForegroundColor Red
    Remove-Item Env:\PGPASSWORD
    exit 1
}

Write-Host ""
Write-Host "Step 3: Importing schema..." -ForegroundColor Yellow
$fileSize = (Get-Item $SchemaFile).Length / 1KB
Write-Host "  File size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Gray
Write-Host ""

try {
    psql -h $Host -p $Port -U $Username -d $Database -f $SchemaFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ Database deployed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Verifying database..." -ForegroundColor Cyan
        $tableCount = psql -h $Host -p $Port -U $Username -d $Database -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
        $tableCount = $tableCount.Trim()
        Write-Host "✓ Tables created: $tableCount" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "✗ Import failed!" -ForegroundColor Red
        Remove-Item Env:\PGPASSWORD
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Remove-Item Env:\PGPASSWORD
    exit 1
} finally {
    Remove-Item Env:\PGPASSWORD
}

Write-Host ""
Write-Host "=== Deployment completed ===" -ForegroundColor Green
