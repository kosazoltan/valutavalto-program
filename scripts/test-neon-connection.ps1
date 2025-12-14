# Neon PostgreSQL Connection Test Script
# Teszteli a Neon adatbázis kapcsolatot

$ErrorActionPreference = "Stop"

# Load environment variables from .env file
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
} else {
    Write-Host "✗ .env fájl nem található!" -ForegroundColor Red
    exit 1
}

Write-Host "=== Neon PostgreSQL Connection Test ===" -ForegroundColor Cyan
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

# Build connection string
$connectionString = "postgresql://$($env:DB_USERNAME):$($env:DB_PASSWORD)@$($env:DB_HOST):$($env:DB_PORT)/$($env:DB_NAME)?sslmode=require&channel_binding=require"

Write-Host "Testing connection..." -ForegroundColor Yellow
Write-Host "  Host: $($env:DB_HOST)" -ForegroundColor Gray
Write-Host "  Database: $($env:DB_NAME)" -ForegroundColor Gray
Write-Host "  Username: $($env:DB_USERNAME)" -ForegroundColor Gray
Write-Host ""

# Test connection
try {
    $result = psql $connectionString -c "SELECT version();" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Connection successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "PostgreSQL version:" -ForegroundColor Cyan
        $result | Select-Object -Skip 2 | Select-Object -SkipLast 1
        Write-Host ""
        
        # Test database tables
        Write-Host "Checking database tables..." -ForegroundColor Yellow
        $tables = psql $connectionString -c "\dt" 2>&1
        if ($tables -match "Did not find any relations") {
            Write-Host "⚠ Database is empty (no tables found)" -ForegroundColor Yellow
            Write-Host "Run: .\scripts\import-database.ps1 -InputFile database/schema/valuta_schema.sql" -ForegroundColor Cyan
        } else {
            Write-Host "✓ Tables found:" -ForegroundColor Green
            $tables | Select-String -Pattern "public \|" | ForEach-Object {
                $_.Line -replace '\s+', ' ' -replace '\|', '|' | Write-Host
            }
        }
    } else {
        Write-Host "✗ Connection failed!" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Connection test completed ===" -ForegroundColor Green

