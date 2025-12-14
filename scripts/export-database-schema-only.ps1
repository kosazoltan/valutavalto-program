# Database Schema Only Export Script
# Exportálja csak a sémát (struktúrát), adatok nélkül
# Ez a fájl újrahasznosítható és Git-be commitolható

param(
    [string]$Host = "localhost",
    [int]$Port = 5432,
    [string]$Database = "valuta",
    [string]$Username = "valuta_user",
    [string]$Password = "valuta_pass"
)

$OutputFile = "database/schema/valuta_schema.sql"

Write-Host "=== Database Schema Export (Schema Only) ===" -ForegroundColor Cyan
Write-Host ""

# Create output directory
$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "✓ Created output directory: $outputDir" -ForegroundColor Green
}

# Export schema only
& "$PSScriptRoot\export-database.ps1" `
    -Host $Host `
    -Port $Port `
    -Database $Database `
    -Username $Username `
    -Password $Password `
    -OutputFile $OutputFile `
    -SchemaOnly

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Schema exported to: $OutputFile" -ForegroundColor Green
    Write-Host "This file can be committed to Git and reused." -ForegroundColor Yellow
}

