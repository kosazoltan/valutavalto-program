# Database Export Script
# Exportálja az adatbázis sémáját és adatait (opcionálisan)

param(
    [string]$Host = "localhost",
    [int]$Port = 5432,
    [string]$Database = "valuta",
    [string]$Username = "valuta_user",
    [string]$Password = "valuta_pass",
    [string]$OutputFile = "database/export/valuta_export_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql",
    [switch]$SchemaOnly = $false,
    [switch]$DataOnly = $false
)

Write-Host "=== Database Export Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if pg_dump is available
try {
    $pgDumpVersion = pg_dump --version 2>&1
    Write-Host "✓ pg_dump found: $pgDumpVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ pg_dump not found!" -ForegroundColor Red
    Write-Host "Please install PostgreSQL client tools" -ForegroundColor Yellow
    exit 1
}

# Create output directory
$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "✓ Created output directory: $outputDir" -ForegroundColor Green
}

# Build pg_dump command
$env:PGPASSWORD = $Password

$pgDumpArgs = @(
    "--host=$Host"
    "--port=$Port"
    "--username=$Username"
    "--dbname=$Database"
    "--file=$OutputFile"
    "--no-owner"
    "--no-privileges"
    "--verbose"
)

if ($SchemaOnly) {
    $pgDumpArgs += "--schema-only"
    Write-Host "Exporting SCHEMA ONLY (no data)" -ForegroundColor Yellow
} elseif ($DataOnly) {
    $pgDumpArgs += "--data-only"
    Write-Host "Exporting DATA ONLY (no schema)" -ForegroundColor Yellow
} else {
    Write-Host "Exporting SCHEMA + DATA" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Exporting database..." -ForegroundColor Cyan
Write-Host "  Host: $Host" -ForegroundColor Gray
Write-Host "  Port: $Port" -ForegroundColor Gray
Write-Host "  Database: $Database" -ForegroundColor Gray
Write-Host "  Username: $Username" -ForegroundColor Gray
Write-Host "  Output: $OutputFile" -ForegroundColor Gray
Write-Host ""

# Run pg_dump
try {
    & pg_dump $pgDumpArgs
    
    if ($LASTEXITCODE -eq 0) {
        $fileSize = (Get-Item $OutputFile).Length / 1KB
        Write-Host ""
        Write-Host "✓ Database exported successfully!" -ForegroundColor Green
        Write-Host "  File: $OutputFile" -ForegroundColor Gray
        Write-Host "  Size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To import:" -ForegroundColor Yellow
        Write-Host "  psql -h $Host -p $Port -U $Username -d $Database -f $OutputFile" -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "✗ Export failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "✗ Error: $_" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item Env:\PGPASSWORD
}

