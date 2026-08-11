param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\installer-clean-vm-smoke'),
  [switch]$ExecuteInstall,
  [switch]$AcceptVmMutation,
  [switch]$ConfirmDisposableCleanVm,
  [switch]$AllowExistingInstall,
  [switch]$SkipUninstall,
  [int]$LaunchSeconds = 10,
  [int]$MaxArtifactAgeHours = 72
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
  param(
    [string]$Area,
    [string]$Name,
    [string]$Status,
    [string]$Evidence,
    [string]$Expected
  )

  $checks.Add([pscustomobject]@{
      area = $Area
      name = $Name
      status = $Status
      evidence = $Evidence
      expected = $Expected
    })
}

function Get-Sha256Hash {
  param([string]$Path)
  $cmd = Get-Command Get-FileHash -ErrorAction SilentlyContinue
  if ($cmd) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
  }

  $stream = [System.IO.File]::OpenRead($Path)
  try {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
      $bytes = $sha.ComputeHash($stream)
      return (($bytes | ForEach-Object { $_.ToString('x2') }) -join '').ToUpperInvariant()
    } finally {
      $sha.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

function Test-TextLikeFile {
  param([string]$Path)
  $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
  return @(
    '.config', '.css', '.env', '.html', '.ini', '.js', '.json',
    '.log', '.md', '.properties', '.txt', '.xml', '.yaml', '.yml'
  ).Contains($extension)
}

function Get-SecretPatternFindings {
  param(
    [string]$Root,
    [int]$MaxFileBytes = 1048576
  )

  $findings = [System.Collections.Generic.List[string]]::new()
  if (-not (Test-Path -LiteralPath $Root)) {
    return $findings
  }

  $forbiddenNameRegex = '(?i)(^|[\\/])(\.env($|\.)|.*secret.*\.(json|txt|env|properties|yml|yaml|pem|key|p12|pfx)$|id_rsa$|.*private.*key.*)'
  $patterns = @(
    [pscustomobject]@{ name = 'private-key'; pattern = '-----BEGIN [A-Z ]*PRIVATE KEY-----' },
    [pscustomobject]@{ name = 'aws-access-key'; pattern = 'AKIA[0-9A-Z]{16}' },
    [pscustomobject]@{ name = 'hard-coded-secret-value'; pattern = '(?i)(jwt[_-]?secret|db[_-]?password|database[_-]?password|client[_-]?secret|api[_-]?key|access[_-]?token|refresh[_-]?token)\s*[:=]\s*["''][A-Za-z0-9_./+=:@-]{16,}["'']' }
  )

  foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue) {
    $relative = $file.FullName.Substring($Root.Length).TrimStart('\', '/')
    if ($relative -match $forbiddenNameRegex) {
      $findings.Add("$relative::forbidden-filename")
    }

    if ((Test-TextLikeFile $file.FullName) -and $file.Length -le $MaxFileBytes) {
      $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
      foreach ($pattern in $patterns) {
        if ($content -match $pattern.pattern) {
          $findings.Add("$relative::$($pattern.name)")
        }
      }
    }
  }

  return $findings
}

function Get-InstallCandidates {
  param([string]$ProductName)
  return @(
    (Join-Path $env:LOCALAPPDATA "Programs\$ProductName"),
    (Join-Path $env:ProgramFiles $ProductName),
    (Join-Path ${env:ProgramFiles(x86)} $ProductName)
  ) | Where-Object { $_ -and $_.Trim().Length -gt 0 }
}

function Find-InstalledExe {
  param(
    [string]$ProductName,
    [string]$ExpectedExe
  )

  foreach ($candidate in (Get-InstallCandidates -ProductName $ProductName)) {
    $exePath = Join-Path $candidate $ExpectedExe
    if (Test-Path -LiteralPath $exePath) {
      return $exePath
    }
  }

  return $null
}

function Find-Uninstaller {
  param([string]$ProductName)
  foreach ($candidate in (Get-InstallCandidates -ProductName $ProductName)) {
    if (Test-Path -LiteralPath $candidate) {
      $uninstaller = Get-ChildItem -LiteralPath $candidate -Filter 'Uninstall*.exe' -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
      if ($uninstaller) {
        return $uninstaller.FullName
      }
    }
  }
  return $null
}

$clients = @(
  [pscustomobject]@{
    name = 'penztar-client'
    productName = 'Valutavalto Penztar'
    artifact = Join-Path $WorkspaceRoot 'penztar-client\release\Penztar-Setup-2.27.96.exe'
    expectedExe = 'Valutavalto Penztar.exe'
    processName = 'Valutavalto Penztar'
    userData = Join-Path $env:APPDATA 'Valutavalto Penztar'
  },
  [pscustomobject]@{
    name = 'kozponti-client'
    productName = 'Valutavalto Kozponti Munkaallomas'
    artifact = Join-Path $WorkspaceRoot 'kozponti-client\release\Kozponti-Munkaallomas-Setup-2.27.96.exe'
    expectedExe = 'Valutavalto Kozponti Munkaallomas.exe'
    processName = 'Valutavalto Kozponti Munkaallomas'
    userData = Join-Path $env:APPDATA 'Valutavalto Kozponti Munkaallomas'
  }
)

foreach ($client in $clients) {
  if (Test-Path -LiteralPath $client.artifact) {
    $artifact = Get-Item -LiteralPath $client.artifact
    $ageHours = [math]::Round(((Get-Date) - $artifact.LastWriteTime).TotalHours, 2)
    Add-Check -Area $client.name -Name 'installer artifact exists' -Status 'PASS' `
      -Evidence "$($artifact.FullName); size=$($artifact.Length); ageHours=$ageHours" -Expected 'Installer EXE exists'
    Add-Check -Area $client.name -Name 'installer artifact age' -Status ($(if ($ageHours -le $MaxArtifactAgeHours) { 'PASS' } else { 'FAIL' })) `
      -Evidence "ageHours=$ageHours" -Expected "<= $MaxArtifactAgeHours"
    $hashPath = Join-Path $runDir "$($client.name).sha256"
    "$(Get-Sha256Hash -Path $artifact.FullName) *$($artifact.Name)" | Set-Content -LiteralPath $hashPath -Encoding ASCII
    Add-Check -Area $client.name -Name 'installer artifact sha256' -Status 'PASS' -Evidence $hashPath -Expected 'SHA-256 generated'
  } else {
    Add-Check -Area $client.name -Name 'installer artifact exists' -Status 'FAIL' -Evidence $client.artifact -Expected 'Installer EXE exists'
  }
}

if (-not $ExecuteInstall) {
  foreach ($client in $clients) {
    Add-Check -Area $client.name -Name 'clean VM install execution' -Status 'SKIP' `
      -Evidence 'Run with -ExecuteInstall -AcceptVmMutation -ConfirmDisposableCleanVm on a disposable clean Windows VM' `
      -Expected 'Silent install, launch, log/config scan, uninstall'
  }
} else {
  Add-Check -Area 'environment' -Name 'vm mutation acknowledgement' -Status ($(if ($AcceptVmMutation) { 'PASS' } else { 'FAIL' })) `
    -Evidence "AcceptVmMutation=$([bool]$AcceptVmMutation)" -Expected 'Explicit mutation acknowledgement on a disposable VM'
  Add-Check -Area 'environment' -Name 'disposable clean VM confirmation' -Status ($(if ($ConfirmDisposableCleanVm) { 'PASS' } else { 'FAIL' })) `
    -Evidence "ConfirmDisposableCleanVm=$([bool]$ConfirmDisposableCleanVm)" -Expected 'Operator confirms this is a disposable clean Windows VM'

  if (-not $AcceptVmMutation -or -not $ConfirmDisposableCleanVm) {
    foreach ($client in $clients) {
      Add-Check -Area $client.name -Name 'clean VM install execution' -Status 'FAIL' `
        -Evidence 'Missing -AcceptVmMutation or -ConfirmDisposableCleanVm; refusing install/launch/uninstall mutation' `
        -Expected 'Both environment confirmations are present before installer mutation'
    }
  } else {

    foreach ($client in $clients) {
      $existingExe = Find-InstalledExe -ProductName $client.productName -ExpectedExe $client.expectedExe
      if ($existingExe -and -not $AllowExistingInstall) {
        Add-Check -Area $client.name -Name 'clean VM guard' -Status 'FAIL' `
          -Evidence $existingExe -Expected 'No existing install before clean VM smoke'
        continue
      }

      $installStdout = Join-Path $runDir "$($client.name)-install.stdout.log"
      $installStderr = Join-Path $runDir "$($client.name)-install.stderr.log"
      $installProc = Start-Process -FilePath $client.artifact -ArgumentList @('/S') -Wait -PassThru `
        -RedirectStandardOutput $installStdout -RedirectStandardError $installStderr
      Add-Check -Area $client.name -Name 'silent installer exit code' -Status ($(if ($installProc.ExitCode -eq 0) { 'PASS' } else { 'FAIL' })) `
        -Evidence "exit=$($installProc.ExitCode); stdout=$installStdout; stderr=$installStderr" -Expected 'exit code 0'

      $installedExe = Find-InstalledExe -ProductName $client.productName -ExpectedExe $client.expectedExe
      Add-Check -Area $client.name -Name 'installed executable exists' -Status ($(if ($installedExe) { 'PASS' } else { 'FAIL' })) `
        -Evidence "$(if ($installedExe) { $installedExe } else { $client.expectedExe })" -Expected 'Installed executable is present'

      if ($installedExe) {
        $launchProc = Start-Process -FilePath $installedExe -PassThru
        Start-Sleep -Seconds $LaunchSeconds
        $stillRunning = -not $launchProc.HasExited
        Add-Check -Area $client.name -Name 'launch smoke' -Status ($(if ($stillRunning) { 'PASS' } else { 'FAIL' })) `
          -Evidence "pid=$($launchProc.Id); exited=$($launchProc.HasExited)" -Expected "Process remains alive for $LaunchSeconds seconds"
        if ($stillRunning) {
          Stop-Process -Id $launchProc.Id -Force -ErrorAction SilentlyContinue
        }

        foreach ($scanRoot in @((Split-Path -Parent $installedExe), $client.userData)) {
          $findings = Get-SecretPatternFindings -Root $scanRoot
          Add-Check -Area $client.name -Name "runtime secret scan: $scanRoot" -Status ($(if ($findings.Count -eq 0) { 'PASS' } else { 'FAIL' })) `
            -Evidence "$(if ($findings.Count -eq 0) { $scanRoot } else { ($findings | Select-Object -First 20) -join '; ' })" `
            -Expected 'No high-confidence secret leak in installed files/logs/userData'
        }
      }

      if ($SkipUninstall) {
        Add-Check -Area $client.name -Name 'uninstall smoke' -Status 'SKIP' -Evidence '-SkipUninstall was supplied' -Expected 'Uninstall normally verified'
        continue
      }

      $uninstaller = Find-Uninstaller -ProductName $client.productName
      if (-not $uninstaller) {
        Add-Check -Area $client.name -Name 'uninstaller exists' -Status 'FAIL' -Evidence $client.productName -Expected 'Uninstall*.exe exists'
        continue
      }

      Add-Check -Area $client.name -Name 'uninstaller exists' -Status 'PASS' -Evidence $uninstaller -Expected 'Uninstall*.exe exists'
      $uninstallStdout = Join-Path $runDir "$($client.name)-uninstall.stdout.log"
      $uninstallStderr = Join-Path $runDir "$($client.name)-uninstall.stderr.log"
      $uninstallProc = Start-Process -FilePath $uninstaller -ArgumentList @('/S') -Wait -PassThru `
        -RedirectStandardOutput $uninstallStdout -RedirectStandardError $uninstallStderr
      Add-Check -Area $client.name -Name 'silent uninstall exit code' -Status ($(if ($uninstallProc.ExitCode -eq 0) { 'PASS' } else { 'FAIL' })) `
        -Evidence "exit=$($uninstallProc.ExitCode); stdout=$uninstallStdout; stderr=$uninstallStderr" -Expected 'exit code 0'

      $postUninstallExe = Find-InstalledExe -ProductName $client.productName -ExpectedExe $client.expectedExe
      Add-Check -Area $client.name -Name 'executable removed after uninstall' -Status ($(if (-not $postUninstallExe) { 'PASS' } else { 'FAIL' })) `
        -Evidence "$(if ($postUninstallExe) { $postUninstallExe } else { 'not found' })" -Expected 'Installed executable removed'
    }
  }
}

$failed = @($checks | Where-Object { $_.status -eq 'FAIL' })
$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$skipped = @($checks | Where-Object { $_.status -eq 'SKIP' }).Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  executeInstall = [bool]$ExecuteInstall
  acceptVmMutation = [bool]$AcceptVmMutation
  confirmDisposableCleanVm = [bool]$ConfirmDisposableCleanVm
  skipUninstall = [bool]$SkipUninstall
  passed = $passed
  failed = $failed.Count
  skipped = $skipped
  checks = $checks
  productReadyMeaning = if ($ExecuteInstall) {
    'Clean Windows VM installer smoke evidence, with explicit disposable clean VM confirmation.'
  } else {
    'Preflight only. Re-run with -ExecuteInstall -AcceptVmMutation -ConfirmDisposableCleanVm on a disposable clean Windows VM for Product Ready installer evidence.'
  }
}

$summaryPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Installer clean Windows VM smoke')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Workspace: $WorkspaceRoot")
$lines.Add("- Execute install: $([bool]$ExecuteInstall)")
$lines.Add("- Accept VM mutation: $([bool]$AcceptVmMutation)")
$lines.Add("- Confirm disposable clean VM: $([bool]$ConfirmDisposableCleanVm)")
$lines.Add("- Checks: $passed passed, $($failed.Count) failed, $skipped skipped")
$lines.Add('')
$lines.Add('## Checks')
$lines.Add('')
$lines.Add('| Area | Check | Status | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- | --- |')
foreach ($check in $checks) {
  $evidence = ($check.evidence -replace '\|', '/')
  $expected = ($check.expected -replace '\|', '/')
  $lines.Add("| $($check.area) | $($check.name) | $($check.status) | $evidence | $expected |")
}
$lines.Add('')
$lines.Add('## Product Ready Meaning')
$lines.Add('')
$lines.Add($summary.productReadyMeaning)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[installer-clean-vm-smoke] checks: $passed passed, $($failed.Count) failed, $skipped skipped"
Write-Host "[installer-clean-vm-smoke] report: $reportPath"
Write-Host "[installer-clean-vm-smoke] summary: $summaryPath"

if ($failed.Count -gt 0) {
  exit 1
}
exit 0
