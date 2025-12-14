# Database Import Script
# Importálja az adatbázis sémáját és adatait

param(
    [string]$Host = "localhost",
    [int]$Port = 5432,
    [string]$Database = "valuta",
    [string]$Username = "valuta_user",
    [string]$Password = "valuta_pass",
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    [switch]$DropDatabase = $false,
    [switch]$CreateDatabase = $false
)

Write-Host "=== Database Import Script ===" -ForegroundColor Cyan
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

# Check if input file exists
if (-not (Test-Path $InputFile)) {
    Write-Host "✗ Input file not found: $InputFile" -ForegroundColor Red
    exit 1
}

$env:PGPASSWORD = $Password

# Drop database if requested
if ($DropDatabase) {
    Write-Host "⚠ WARNING: Dropping database '$Database'!" -ForegroundColor Red
    Write-Host "This will delete ALL data!" -ForegroundColor Red
    $confirm = Read-Host "Are you sure? (type 'yes' to continue)"
    if ($confirm -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        Remove-Item Env:\PGPASSWORD
        exit 0
    }
    
    Write-Host "Dropping database..." -ForegroundColor Yellow
    try {
        # Connect to postgres database to drop the target database
        psql -h $Host -p $Port -U $Username -d postgres -c "DROP DATABASE IF EXISTS $Database;" 2>&1 | Out-Null
        Write-Host "✓ Database dropped" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to drop database: $_" -ForegroundColor Red
        Remove-Item Env:\PGPASSWORD
        exit 1
    }
}

# Create database if requested or if it doesn't exist
if ($CreateDatabase -or $DropDatabase) {
    Write-Host "Creating database..." -ForegroundColor Yellow
    try {
        psql -h $Host -p $Port -U $Username -d postgres -c "CREATE DATABASE $Database;" 2>&1 | Out-Null
        Write-Host "✓ Database created" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Database might already exist, continuing..." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Importing database..." -ForegroundColor Cyan
Write-Host "  Host: $Host" -ForegroundColor Gray
Write-Host "  Port: $Port" -ForegroundColor Gray
Write-Host "  Database: $Database" -ForegroundColor Gray
Write-Host "  Username: $Username" -ForegroundColor Gray
Write-Host "  Input: $InputFile" -ForegroundColor Gray
Write-Host ""

# Import database
try {
    $fileSize = (Get-Item $InputFile).Length / 1KB
    Write-Host "  File size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Gray
    Write-Host ""
    
    psql -h $Host -p $Port -U $Username -d $Database -f $InputFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ Database imported successfully!" -ForegroundColor Green
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

