param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path,
    [int]$BackendDependencyCheckTimeoutSec = 600,
    [int]$ScannerTimeoutSec = 180,
    [string]$NvdApiKey = $env:NVD_API_KEY
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-DotEnvValue {
    param(
        [string]$FilePath,
        [string]$Key
    )

    if (!(Test-Path -LiteralPath $FilePath)) {
        return $null
    }

    foreach ($line in Get-Content -LiteralPath $FilePath -ErrorAction Stop) {
        if ($line -match "^\s*$Key=(.*)$") {
            return $matches[1].Trim()
        }
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($NvdApiKey)) {
    $dotEnvPath = Join-Path $RepoRoot ".env"
    $NvdApiKey = Get-DotEnvValue -FilePath $dotEnvPath -Key "NVD_API_KEY"
}

if ($NvdApiKey -and $NvdApiKey.Trim().Length -gt 0) {
    # Allow explicit parameter override while still supporting environment-based use.
    $env:NVD_API_KEY = $NvdApiKey
}

# Local IDE / dev: remote DB often has no flyway_schema_history yet. CI sets CI=true -> strict unless overridden.
if ($env:CI -ne "true" -and [string]::IsNullOrWhiteSpace($env:DB_PREFLIGHT_REMOTE_MODE)) {
    $env:DB_PREFLIGHT_REMOTE_MODE = "optional"
}

function New-DirIfMissing {
    param([string]$PathValue)
    if (!(Test-Path -LiteralPath $PathValue)) {
        New-Item -ItemType Directory -Path $PathValue | Out-Null
    }
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ==="
}

function Invoke-Check {
    param(
        [string]$Name,
        [string]$WorkingDir,
        [string]$Command,
        [string]$OutputFile
    )

    $result = [ordered]@{
        check = $Name
        status = "PASSED"
        command = $Command
        output = $OutputFile
        note = ""
    }

    try {
        Push-Location $WorkingDir
        try {
            $output = Invoke-Expression $Command 2>&1 | Out-String
            $output | Set-Content -LiteralPath $OutputFile -Encoding UTF8
        }
        finally {
            Pop-Location
        }
    }
    catch {
        $result.status = "FAILED"
        $result.note = $_.Exception.Message
        if (!(Test-Path -LiteralPath $OutputFile)) {
            "Command failed: $Command`n$($_.Exception.Message)" | Set-Content -LiteralPath $OutputFile -Encoding UTF8
        }
    }

    return [PSCustomObject]$result
}

function Invoke-OptionalCheck {
    param(
        [string]$Name,
        [string]$WorkingDir,
        [string]$Command,
        [string]$OutputFile,
        [string]$ProbeCommand
    )

    $probeFailed = $false
    try {
        Push-Location $WorkingDir
        try {
            Invoke-Expression $ProbeCommand 2>&1 | Out-Null
        }
        finally {
            Pop-Location
        }
    }
    catch {
        $probeFailed = $true
    }

    if ($probeFailed) {
        "Skipped: prerequisite missing for [$Name]. Probe: $ProbeCommand" | Set-Content -LiteralPath $OutputFile -Encoding UTF8
        return [PSCustomObject]@{
            check = $Name
            status = "BLOCKED"
            command = $Command
            output = $OutputFile
            note = "Missing prerequisite"
        }
    }

    return Invoke-Check -Name $Name -WorkingDir $WorkingDir -Command $Command -OutputFile $OutputFile
}

function Remove-TempFileSafe {
    param([string]$PathValue)

    if (!(Test-Path -LiteralPath $PathValue)) {
        return
    }

    for ($i = 0; $i -lt 3; $i++) {
        try {
            Remove-Item -LiteralPath $PathValue -Force -ErrorAction Stop
            return
        }
        catch {
            Start-Sleep -Milliseconds 200
        }
    }
}

function Test-IgnoredSecurityPath {
    param([string]$FullPath)

    return $FullPath -match '[\\/](node_modules|dist|dist-electron|build|target|coverage|security-reports|\.git|\.venv)[\\/]'
}

function Get-RgExcludeArgs {
    return @(
        '-g "!**/node_modules/**"'
        '-g "!**/dist/**"'
        '-g "!**/dist-electron/**"'
        '-g "!**/build/**"'
        '-g "!**/target/**"'
        '-g "!**/coverage/**"'
        '-g "!**/security-reports/**"'
        '-g "!**/.git/**"'
        '-g "!**/.venv/**"'
        '-g "!**/*.test.*"'
        '-g "!**/*.spec.*"'
    ) -join ' '
}

function Invoke-CheckWithTimeout {
    param(
        [string]$Name,
        [string]$WorkingDir,
        [string]$Command,
        [string]$OutputFile,
        [int]$TimeoutSeconds,
        [string]$DisplayCommand = $Command,
        [ValidateSet("standard", "no-match-pass")]
        [string]$Mode = "standard"
    )

    $result = [ordered]@{
        check = $Name
        status = "PASSED"
        command = $DisplayCommand
        output = $OutputFile
        note = ""
    }

    $timeoutMs = [Math]::Max(1, $TimeoutSeconds) * 1000
    $stdout = ""
    $stderr = ""
    $stdoutTemp = [System.IO.Path]::GetTempFileName()
    $stderrTemp = [System.IO.Path]::GetTempFileName()

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "cmd.exe"
        $psi.Arguments = ('/d /s /c "{0} 1>""{1}"" 2>""{2}"""' -f $Command, $stdoutTemp, $stderrTemp)
        $psi.WorkingDirectory = $WorkingDir
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        [void]$proc.Start()

        if (-not $proc.WaitForExit($timeoutMs)) {
            try { $proc.Kill($true) } catch {}
            $result.status = "BLOCKED"
            $result.note = "Timeout after $TimeoutSeconds seconds"
        }
        else {
            $exitCode = $proc.ExitCode
            if ($null -eq $exitCode) {
                $result.status = "FAILED"
                $result.note = "Exit code unknown"
            }
            elseif ($Mode -eq "no-match-pass") {
                if ($exitCode -eq 1) {
                    $result.status = "PASSED"
                    $result.note = "No matches found"
                }
                elseif ($exitCode -eq 0) {
                    $result.status = "FAILED"
                    $result.note = "Security pattern matches found"
                }
                else {
                    $result.status = "BLOCKED"
                    $result.note = "Scanner error (exit code $exitCode)"
                }
            }
            elseif ($exitCode -ne 0) {
                $result.status = "FAILED"
                $result.note = "Exit code $exitCode"
            }
        }

    }
    catch {
        $result.status = "FAILED"
        $result.note = $_.Exception.Message
    }
    finally {
        if (Test-Path -LiteralPath $stdoutTemp) {
            try { $stdout = Get-Content -LiteralPath $stdoutTemp -Raw -ErrorAction Stop } catch {}
        }
        if (Test-Path -LiteralPath $stderrTemp) {
            try { $stderr = Get-Content -LiteralPath $stderrTemp -Raw -ErrorAction Stop } catch {}
        }

        $combined = @(
            "Command: $DisplayCommand",
            "Status: $($result.status)",
            "Note: $($result.note)",
            "",
            "--- STDOUT ---",
            $stdout,
            "",
            "--- STDERR ---",
            $stderr
        ) -join "`r`n"
        $combined | Set-Content -LiteralPath $OutputFile -Encoding UTF8

        Remove-TempFileSafe -PathValue $stdoutTemp
        Remove-TempFileSafe -PathValue $stderrTemp
    }

    return [PSCustomObject]$result
}

function Invoke-OptionalCheckWithTimeout {
    param(
        [string]$Name,
        [string]$WorkingDir,
        [string]$Command,
        [string]$OutputFile,
        [string]$ProbeCommand,
        [int]$TimeoutSeconds,
        [string]$DisplayCommand = $Command,
        [ValidateSet("standard", "no-match-pass")]
        [string]$Mode = "standard"
    )

    $probeFailed = $false
    try {
        Push-Location $WorkingDir
        try {
            Invoke-Expression $ProbeCommand 2>&1 | Out-Null
        }
        finally {
            Pop-Location
        }
    }
    catch {
        $probeFailed = $true
    }

    if ($probeFailed) {
        "Skipped: prerequisite missing for [$Name]. Probe: $ProbeCommand" | Set-Content -LiteralPath $OutputFile -Encoding UTF8
        return [PSCustomObject]@{
            check = $Name
            status = "BLOCKED"
            command = $DisplayCommand
            output = $OutputFile
            note = "Missing prerequisite"
        }
    }

    return Invoke-CheckWithTimeout `
        -Name $Name `
        -WorkingDir $WorkingDir `
        -Command $Command `
        -OutputFile $OutputFile `
        -TimeoutSeconds $TimeoutSeconds `
        -DisplayCommand $DisplayCommand `
        -Mode $Mode
}

Write-Section "Security gate bootstrap"

if (!(Test-Path -LiteralPath $RepoRoot)) {
    throw "RepoRoot not found: $RepoRoot"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportsRoot = Join-Path $RepoRoot "security-reports"
$reportDir = Join-Path $reportsRoot $timestamp
$latestDir = Join-Path $reportsRoot "latest"

New-DirIfMissing -PathValue $reportsRoot
New-DirIfMissing -PathValue $reportDir

$results = New-Object System.Collections.Generic.List[object]

$backendDir = Join-Path $RepoRoot "backend"
$frontendDir = Join-Path $RepoRoot "frontend-react"
$electronDir = Join-Path $RepoRoot "penztar-client"
$gateStatusPath = Join-Path $reportDir "gate-status.json"

$hasJava = (Test-Path -LiteralPath (Join-Path $RepoRoot "pom.xml")) -or (Test-Path -LiteralPath (Join-Path $backendDir "pom.xml")) -or (Test-Path -LiteralPath (Join-Path $RepoRoot "build.gradle")) -or (Test-Path -LiteralPath (Join-Path $RepoRoot "build.gradle.kts"))
$hasNode = (Test-Path -LiteralPath (Join-Path $RepoRoot "package.json")) -or (Test-Path -LiteralPath (Join-Path $frontendDir "package.json")) -or (Test-Path -LiteralPath (Join-Path $electronDir "package.json"))
$hasReact = (Test-Path -LiteralPath (Join-Path $frontendDir "vite.config.ts")) -or (Test-Path -LiteralPath (Join-Path $frontendDir "vite.config.js")) -or (Test-Path -LiteralPath (Join-Path $frontendDir "next.config.js")) -or (Test-Path -LiteralPath (Join-Path $frontendDir "next.config.ts"))
$hasElectron = Test-Path -LiteralPath (Join-Path $electronDir "package.json")
$hasPython = Get-ChildItem -Path $RepoRoot -Recurse -File -Include "requirements.txt", "pyproject.toml", "Pipfile" -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-IgnoredSecurityPath -FullPath $_.FullName) } |
    Select-Object -First 1
$pythonDependencyFile = if ($hasPython) { $hasPython.FullName } else { $null }

$rgExcludes = Get-RgExcludeArgs

Write-Section "Dependency and vulnerability checks"
Write-Host ("NVD API key configured: " + $(if ($env:NVD_API_KEY) { "YES" } else { "NO" }))

$dbPreflightScript = Join-Path $RepoRoot "scripts\security\mandatory-db-preflight.ps1"
if (Test-Path -LiteralPath $dbPreflightScript) {
    $escapedRepoRoot = $RepoRoot.Replace('"', '""')
    $dbPreflightCommand = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$dbPreflightScript`" -RepoRoot `"$escapedRepoRoot`""
    $results.Add((Invoke-CheckWithTimeout `
        -Name "mandatory_db_preflight" `
        -WorkingDir $RepoRoot `
        -Command $dbPreflightCommand `
        -TimeoutSeconds $ScannerTimeoutSec `
        -OutputFile (Join-Path $reportDir "mandatory_db_preflight.txt")))
}
else {
    $missingPreflightOutput = Join-Path $reportDir "mandatory_db_preflight.txt"
    "Mandatory DB preflight script missing: $dbPreflightScript" | Set-Content -LiteralPath $missingPreflightOutput -Encoding UTF8
    $results.Add([PSCustomObject]@{
        check = "mandatory_db_preflight"
        status = "BLOCKED"
        command = "mandatory-db-preflight.ps1"
        output = $missingPreflightOutput
        note = "Missing mandatory DB preflight script"
    })
}

if ($env:NVD_API_KEY -and $env:NVD_API_KEY.Trim().Length -gt 0) {
    $nvdCheckOutput = Join-Path $reportDir "nvd_api_key_check.txt"
    try {
        $response = Invoke-WebRequest -UseBasicParsing `
            -Uri "https://services.nvd.nist.gov/rest/json/cves/2.0?resultsPerPage=1" `
            -Headers @{ apiKey = $env:NVD_API_KEY } `
            -TimeoutSec 30

        $status = if ($response.StatusCode -eq 200) { "PASSED" } else { "FAILED" }
        $note = "HTTP $($response.StatusCode)"
        "NVD API key test status: $note" | Set-Content -LiteralPath $nvdCheckOutput -Encoding UTF8
    }
    catch {
        $status = "BLOCKED"
        $note = $_.Exception.Message
        "NVD API key test blocked: $note" | Set-Content -LiteralPath $nvdCheckOutput -Encoding UTF8
    }

    $results.Add([PSCustomObject]@{
        check = "nvd_api_key_check"
        status = $status
        command = "NVD API v2 test"
        output = $nvdCheckOutput
        note = $note
    })
}

if ($hasJava -and (Test-Path -LiteralPath $backendDir)) {
    # Use Maven Wrapper to avoid local Maven PATH dependency and apply explicit timeout.
    $backendCommand = "mvnw.cmd dependency-check:check -DfailBuildOnCVSS=7"
    $backendDisplayCommand = "mvnw.cmd dependency-check:check -DfailBuildOnCVSS=7"
    if ($env:NVD_API_KEY -and $env:NVD_API_KEY.Trim().Length -gt 0) {
        $backendCommand = "mvnw.cmd dependency-check:check -DfailBuildOnCVSS=7 -DnvdApiKey=$env:NVD_API_KEY"
        $backendDisplayCommand = "mvnw.cmd dependency-check:check -DfailBuildOnCVSS=7 -DnvdApiKey=***"
    }

    $results.Add((Invoke-OptionalCheckWithTimeout `
        -Name "backend_dependency_check" `
        -WorkingDir $backendDir `
        -Command $backendCommand `
        -ProbeCommand "./mvnw.cmd -version" `
        -TimeoutSeconds $BackendDependencyCheckTimeoutSec `
        -DisplayCommand $backendDisplayCommand `
        -OutputFile (Join-Path $reportDir "backend_dependency_check.txt")))
}

if (Test-Path -LiteralPath $frontendDir) {
    $results.Add((Invoke-OptionalCheckWithTimeout `
        -Name "frontend_npm_audit_prod" `
        -WorkingDir $frontendDir `
        -Command "npm audit --omit=dev --audit-level=high" `
        -ProbeCommand "npm -v" `
        -TimeoutSeconds $ScannerTimeoutSec `
        -OutputFile (Join-Path $reportDir "frontend_npm_audit_prod.txt")))
}

if (Test-Path -LiteralPath $electronDir) {
    # Use modern npm production audit flag to avoid false failures on deprecation warnings.
    $results.Add((Invoke-OptionalCheckWithTimeout `
        -Name "electron_npm_audit_prod" `
        -WorkingDir $electronDir `
        -Command "npm audit --omit=dev --audit-level=high" `
        -ProbeCommand "npm -v" `
        -TimeoutSeconds $ScannerTimeoutSec `
        -OutputFile (Join-Path $reportDir "electron_npm_audit_prod.txt")))
}

if ($hasPython) {
    $pythonDependencyFileForCmd = $pythonDependencyFile -replace '"', '""'
    $pythonProbeCommand = "`$env:PYTHONIOENCODING='utf-8'; python -m pip_audit --version"

    $results.Add((Invoke-OptionalCheckWithTimeout `
        -Name "python_pip_audit" `
        -WorkingDir $RepoRoot `
        -Command ('set PYTHONIOENCODING=utf-8 && python -m pip_audit --desc --format=json -r "{0}"' -f $pythonDependencyFileForCmd) `
        -ProbeCommand $pythonProbeCommand `
        -TimeoutSeconds $ScannerTimeoutSec `
        -DisplayCommand ('python -m pip_audit --desc --format=json -r "{0}"' -f $pythonDependencyFileForCmd) `
        -OutputFile (Join-Path $reportDir "python_pip_audit.txt")))

    $results.Add((Invoke-OptionalCheckWithTimeout `
        -Name "python_safety_check" `
        -WorkingDir $RepoRoot `
        -Command ('set PYTHONIOENCODING=utf-8 && python -m safety check -r "{0}" --json' -f $pythonDependencyFileForCmd) `
        -ProbeCommand "python -m safety --version" `
        -TimeoutSeconds $ScannerTimeoutSec `
        -DisplayCommand ('python -m safety check -r "{0}" --json' -f $pythonDependencyFileForCmd) `
        -OutputFile (Join-Path $reportDir "python_safety_check.txt")))
}

Write-Section "Static pattern scans"

$hardcodedSecretsPattern = '(?i)(password|passwd|secret|api[_-]?key|token|private[_-]?key|jwt[_-]?secret)["'']?\s*[:=]\s*["''][^"'']{6,}["'']'
$weakCryptoPattern = 'MD5|SHA-1|DES/|AES/ECB|ECB/PKCS5Padding|RC4|3DES'
$electronDangerousPattern = 'nodeIntegration\s*:\s*true|contextIsolation\s*:\s*false|sandbox\s*:\s*false|allowRunningInsecureContent\s*:\s*true|enableRemoteModule\s*:\s*true|eval\(|new Function\('
$sqliPattern = 'create(Native)?Query\s*\([^\n]*\+|jdbcTemplate\.(query|update|execute)\s*\([^\n]*\+|Runtime\.getRuntime\(\)\.exec|ProcessBuilder\s*\(\s*(?:\r?\n\s*)*\x22(cmd(?:\.exe)?|powershell(?:\.exe)?|pwsh(?:\.exe)?|sh|/bin/sh)\x22'
$reactXssPattern = 'dangerouslySetInnerHTML|eval\(|new Function\(|javascript:'
$nodeDangerousPattern = 'child_process\.exec\(|eval\(|new Function\(|vm\.runInNewContext\('
$pythonDangerousPattern = 'eval\(|exec\(|pickle\.loads\(|yaml\.load\(|subprocess\..*shell\s*=\s*True|DEBUG\s*=\s*True'

$results.Add((Invoke-CheckWithTimeout `
    -Name "hardcoded_secrets_scan" `
    -WorkingDir $RepoRoot `
    -Command ('rg -n -P -S {0} "{1}" backend/src/main frontend-react/src penztar-client/electron scripts/security' -f $rgExcludes, $hardcodedSecretsPattern) `
    -TimeoutSeconds $ScannerTimeoutSec `
    -Mode "no-match-pass" `
    -OutputFile (Join-Path $reportDir "hardcoded_secrets_scan.txt")))

$results.Add((Invoke-CheckWithTimeout `
    -Name "weak_crypto_scan" `
    -WorkingDir $RepoRoot `
    -Command ('rg -n -S {0} "{1}" backend/src/main frontend-react/src penztar-client/electron' -f $rgExcludes, $weakCryptoPattern) `
    -TimeoutSeconds $ScannerTimeoutSec `
    -Mode "no-match-pass" `
    -OutputFile (Join-Path $reportDir "weak_crypto_scan.txt")))

$results.Add((Invoke-CheckWithTimeout `
    -Name "electron_dangerous_apis_scan" `
    -WorkingDir $RepoRoot `
    -Command ('rg -n -S {0} "{1}" penztar-client/electron frontend-react/src' -f $rgExcludes, $electronDangerousPattern) `
    -TimeoutSeconds $ScannerTimeoutSec `
    -Mode "no-match-pass" `
    -OutputFile (Join-Path $reportDir "electron_dangerous_apis_scan.txt")))

$results.Add((Invoke-CheckWithTimeout `
    -Name "sqli_pattern_scan" `
    -WorkingDir $RepoRoot `
    -Command ('rg -n -U -P -S {0} "{1}" backend/src/main/java' -f $rgExcludes, $sqliPattern) `
    -TimeoutSeconds $ScannerTimeoutSec `
    -Mode "no-match-pass" `
    -OutputFile (Join-Path $reportDir "sqli_and_command_injection_patterns.txt")))

if ($hasReact) {
    $results.Add((Invoke-CheckWithTimeout `
        -Name "react_xss_patterns_scan" `
        -WorkingDir $RepoRoot `
        -Command ('rg -n -S {0} "{1}" frontend-react/src' -f $rgExcludes, $reactXssPattern) `
        -TimeoutSeconds $ScannerTimeoutSec `
        -Mode "no-match-pass" `
        -OutputFile (Join-Path $reportDir "react_xss_patterns_scan.txt")))
}

if ($hasNode) {
    $results.Add((Invoke-CheckWithTimeout `
        -Name "node_dangerous_runtime_scan" `
        -WorkingDir $RepoRoot `
    -Command ('rg -n -S {0} "{1}" backend/src/main frontend-react/src penztar-client/electron' -f $rgExcludes, $nodeDangerousPattern) `
        -TimeoutSeconds $ScannerTimeoutSec `
        -Mode "no-match-pass" `
        -OutputFile (Join-Path $reportDir "node_dangerous_runtime_scan.txt")))
}

if ($hasPython) {
    $results.Add((Invoke-CheckWithTimeout `
        -Name "python_dangerous_api_scan" `
        -WorkingDir $RepoRoot `
    -Command ('rg -n -S {0} "{1}" scripts' -f $rgExcludes, $pythonDangerousPattern) `
        -TimeoutSeconds $ScannerTimeoutSec `
        -Mode "no-match-pass" `
        -OutputFile (Join-Path $reportDir "python_dangerous_api_scan.txt")))
}

Write-Section "Build summary"

$summaryPath = Join-Path $reportDir "summary.json"
$results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$overallStatus = "PASSED"
if ($results | Where-Object { $_.status -eq "FAILED" }) {
    $overallStatus = "FAILED"
}
elseif ($results | Where-Object { $_.status -eq "BLOCKED" }) {
    $overallStatus = "BLOCKED"
}

$gateStatus = [ordered]@{
    timestamp = (Get-Date).ToString("o")
    status = $overallStatus
    stacks = @{
        java = [bool]$hasJava
        node = [bool]$hasNode
        react = [bool]$hasReact
        electron = [bool]$hasElectron
        python = [bool]$hasPython
    }
    checks = $results
}
$gateStatus | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $gateStatusPath -Encoding UTF8

if (Test-Path -LiteralPath $latestDir) {
    Remove-Item -LiteralPath $latestDir -Recurse -Force
}
Copy-Item -LiteralPath $reportDir -Destination $latestDir -Recurse -Force

$statusTable = $results | Select-Object check, status, output, note
$statusTable | Format-Table -AutoSize | Out-String | Set-Content -LiteralPath (Join-Path $reportDir "summary.txt") -Encoding UTF8
$statusTable | Format-Table -AutoSize

Write-Host ""
Write-Host "Security gate reports generated:"
Write-Host " - $reportDir"
Write-Host " - $latestDir"
Write-Host ("Overall gate status: " + $overallStatus)

if ($overallStatus -eq "PASSED") { exit 0 }
if ($overallStatus -eq "FAILED") { exit 1 }
exit 2
