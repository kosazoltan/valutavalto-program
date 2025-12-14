# Git Secrets Check Script for Windows PowerShell
# Checks for secrets and sensitive data before commit

$ErrorActionPreference = "Stop"

# Colors
function Write-ColorOutput($ForegroundColor, $Message) {
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Check if patterns file exists
$PatternsFile = ".git-secrets-patterns"
if (-not (Test-Path $PatternsFile)) {
    Write-ColorOutput Yellow "Warning: .git-secrets-patterns not found"
    exit 0
}

# Get staged files
try {
    $StagedFiles = git diff --cached --name-only --diff-filter=ACM
} catch {
    Write-ColorOutput Yellow "No staged files or not in git repository"
    exit 0
}

if ([string]::IsNullOrEmpty($StagedFiles)) {
    exit 0
}

$FoundSecrets = $false
$Patterns = Get-Content $PatternsFile

foreach ($File in $StagedFiles) {
    # Skip binary files
    $FileExtension = [System.IO.Path]::GetExtension($File)
    $BinaryExtensions = @('.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg', '.pdf', '.zip', '.tar', '.gz', '.jar', '.war', '.class', '.o', '.so', '.dll', '.exe')
    if ($BinaryExtensions -contains $FileExtension) {
        continue
    }
    
    # Get file content from staged changes
    try {
        $FileContent = git show ":$File" 2>$null
        if ($null -eq $FileContent) {
            continue
        }
    } catch {
        continue
    }
    
    # Check each pattern
    foreach ($Pattern in $Patterns) {
        # Skip comments and empty lines
        if ($Pattern -match '^\s*#' -or $Pattern -match '^\s*$') {
            continue
        }
        
        # Check if pattern matches
        try {
            if ($FileContent -match $Pattern) {
                Write-ColorOutput Red "✗ SECRET DETECTED in $File"
                Write-ColorOutput Red "  Pattern: $Pattern"
                
                # Show matching lines (first 5)
                $Matches = [regex]::Matches($FileContent, $Pattern)
                $Count = 0
                foreach ($Match in $Matches) {
                    if ($Count -ge 5) { break }
                    $LineNumber = ($FileContent.Substring(0, $Match.Index) -split "`n").Count
                    Write-ColorOutput Yellow "  Line ~$LineNumber : $($Match.Value.Substring(0, [Math]::Min(80, $Match.Value.Length)))"
                    $Count++
                }
                Write-Host ""
                $FoundSecrets = $true
            }
        } catch {
            # Invalid regex pattern, skip
            continue
        }
    }
}

if ($FoundSecrets) {
    Write-ColorOutput Red "================================================"
    Write-ColorOutput Red "ERROR: Potential secrets detected in staged files!"
    Write-ColorOutput Red "Please remove secrets before committing."
    Write-ColorOutput Yellow "Tip: Use environment variables or .env files"
    Write-ColorOutput Yellow "See .gitignore for excluded files"
    Write-ColorOutput Red "================================================"
    exit 1
}

Write-ColorOutput Green "No secrets detected"
exit 0

