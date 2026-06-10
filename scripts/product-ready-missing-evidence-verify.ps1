param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-missing-evidence'),
  [string]$ManifestPath = '',
  [switch]$RequireClosed
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
  param(
    [string]$Name,
    [string]$Status,
    [string]$Evidence,
    [string]$Expected
  )

  $checks.Add([pscustomobject]@{
      name = $Name
      status = $Status
      evidence = $Evidence
      expected = $Expected
    })
}

function Convert-FailStatus {
  param([bool]$Passed)
  if ($Passed) { return 'PASS' }
  return 'FAIL'
}

function Get-PropertyValue {
  param([object]$Object, [string]$Name)
  if ($null -eq $Object) { return $null }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { return $null }
  return $property.Value
}

function Test-TextPresent {
  param([object]$Value)
  return ($null -ne $Value -and -not [string]::IsNullOrWhiteSpace([string]$Value))
}

function Test-IsoDateLike {
  param([object]$Value)
  if (-not (Test-TextPresent $Value)) { return $false }
  try {
    [datetimeoffset]::Parse([string]$Value) | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Resolve-RepoPath {
  param([object]$Value)
  if (-not (Test-TextPresent $Value)) { return $null }
  $text = [string]$Value
  if ([System.IO.Path]::IsPathRooted($text)) { return $text }
  return Join-Path $WorkspaceRoot $text
}

function Test-RepoPath {
  param([object]$Value)
  $path = Resolve-RepoPath $Value
  return ((Test-TextPresent $path) -and (Test-Path -LiteralPath $path))
}

function Get-LatestManifestPath {
  $roots = @(
    (Join-Path $WorkspaceRoot 'security-reports\product-ready-final-gate'),
    (Join-Path $WorkspaceRoot 'security-reports\product-ready-external-evidence-pack')
  )

  $candidates = [System.Collections.Generic.List[object]]::new()
  foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root)) {
      continue
    }

    foreach ($directory in (Get-ChildItem -LiteralPath $root -Directory)) {
      $candidate = Join-Path $directory.FullName 'missing-evidence.json'
      if (Test-Path -LiteralPath $candidate) {
        $file = Get-Item -LiteralPath $candidate
        $candidates.Add([pscustomobject]@{
            path = $candidate
            lastWriteTimeUtc = $file.LastWriteTimeUtc
          })
      }
    }
  }

  $latest = $candidates | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
  if ($null -eq $latest) {
    return ''
  }

  return [string]$latest.path
}

try {
  if (-not (Test-TextPresent $ManifestPath)) {
    $ManifestPath = Get-LatestManifestPath
  }

  Add-Check -Name 'manifest path resolved' -Status (Convert-FailStatus (Test-TextPresent $ManifestPath)) `
    -Evidence "ManifestPath=$ManifestPath" -Expected 'Explicit manifest path or latest missing-evidence.json exists'

  $manifestExists = (Test-TextPresent $ManifestPath) -and (Test-Path -LiteralPath $ManifestPath)
  Add-Check -Name 'manifest exists' -Status (Convert-FailStatus $manifestExists) `
    -Evidence $ManifestPath -Expected 'missing-evidence.json exists'

  if (-not $manifestExists) {
    throw "Missing evidence manifest is not available: $ManifestPath"
  }

  $raw = Get-Content -LiteralPath $ManifestPath -Raw
  $secretPattern = '(?i)(password|passwd|secret|api[_-]?key|token|private[_-]?key|client[_-]?secret)\s*[:=]\s*["''][^"'']{8,}["'']'
  Add-Check -Name 'manifest secret pattern scan' -Status (Convert-FailStatus ($raw -notmatch $secretPattern)) `
    -Evidence $ManifestPath -Expected 'No high-confidence secret values in missing evidence manifest'

  try {
    $manifest = $raw | ConvertFrom-Json
    Add-Check -Name 'manifest json parse' -Status 'PASS' -Evidence $ManifestPath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'manifest json parse' -Status 'FAIL' -Evidence $_.Exception.Message -Expected 'Valid JSON'
    throw
  }

  $schemaVersion = Get-PropertyValue $manifest 'schemaVersion'
  Add-Check -Name 'schemaVersion' -Status (Convert-FailStatus ($schemaVersion -eq 1)) `
    -Evidence "schemaVersion=$schemaVersion" -Expected '1'

  $generatedAt = Get-PropertyValue $manifest 'generatedAt'
  Add-Check -Name 'generatedAt' -Status (Convert-FailStatus (Test-IsoDateLike $generatedAt)) `
    -Evidence "generatedAt=$generatedAt" -Expected 'ISO-like timestamp'

  $draftEvidencePath = Get-PropertyValue $manifest 'draftEvidencePath'
  $finalGateEvidencePath = Get-PropertyValue $manifest 'finalGateEvidencePath'
  $evidencePath = if (Test-TextPresent $draftEvidencePath) { $draftEvidencePath } else { $finalGateEvidencePath }
  Add-Check -Name 'evidence source path' -Status (Convert-FailStatus (Test-RepoPath $evidencePath)) `
    -Evidence "draftEvidencePath=$draftEvidencePath; finalGateEvidencePath=$finalGateEvidencePath" -Expected 'Existing draft or final-gate evidence JSON path'

  foreach ($name in @('localEvidenceBundleRef', 'verifierReport', 'verifierSummary')) {
    $value = Get-PropertyValue $manifest $name
    Add-Check -Name $name -Status (Convert-FailStatus (Test-RepoPath $value)) `
      -Evidence "$name=$value" -Expected 'Existing repo or absolute path'
  }

  $meaning = [string](Get-PropertyValue $manifest 'productReadyMeaning')
  Add-Check -Name 'productReadyMeaning' -Status (Convert-FailStatus ($meaning -match 'Machine-readable (final-gate )?external evidence gap manifest')) `
    -Evidence $meaning -Expected 'Machine-readable external evidence gap manifest identity'

  $finalCommand = Get-PropertyValue $manifest 'finalCommand'
  Add-Check -Name 'finalCommand' -Status (Convert-FailStatus ([string]$finalCommand -eq 'npm run product-ready:final-gate:complete')) `
    -Evidence "finalCommand=$finalCommand" -Expected 'npm run product-ready:final-gate:complete'

  $sections = @(Get-PropertyValue $manifest 'sections')
  Add-Check -Name 'sections array' -Status (Convert-FailStatus ($sections.Count -gt 0)) `
    -Evidence "sections=$($sections.Count)" -Expected 'At least one missing evidence section'

  $sectionCheckCount = 0
  $sectionMissingTotal = 0
  foreach ($section in $sections) {
    $sectionName = [string](Get-PropertyValue $section 'section')
    Add-Check -Name "section.$sectionName.name" -Status (Convert-FailStatus (Test-TextPresent $sectionName)) `
      -Evidence "section=$sectionName" -Expected 'Section name is present'

    foreach ($name in @('owner', 'template', 'notes')) {
      $value = Get-PropertyValue $section $name
      Add-Check -Name "section.$sectionName.$name" -Status (Convert-FailStatus (Test-TextPresent $value)) `
        -Evidence "$name=$value" -Expected 'Section guidance text is present'
    }

    $commands = @(Get-PropertyValue $section 'commands')
    Add-Check -Name "section.$sectionName.commands" -Status (Convert-FailStatus ($commands.Count -gt 0)) `
      -Evidence "commands=$($commands.Count)" -Expected 'At least one suggested command'
    foreach ($command in $commands) {
      Add-Check -Name "section.$sectionName.command text" -Status (Convert-FailStatus (Test-TextPresent $command)) `
        -Evidence "command=$command" -Expected 'Suggested command text is present'
    }

    $sectionChecks = @(Get-PropertyValue $section 'checks')
    $sectionMissing = Get-PropertyValue $section 'missing'
    $sectionCheckCount += $sectionChecks.Count
    if ($null -ne $sectionMissing) {
      $sectionMissingTotal += [int]$sectionMissing
    }

    Add-Check -Name "section.$sectionName.missing matches checks" `
      -Status (Convert-FailStatus ($null -ne $sectionMissing -and [int]$sectionMissing -eq $sectionChecks.Count)) `
      -Evidence "missing=$sectionMissing; checks=$($sectionChecks.Count)" -Expected 'Section missing count equals check count'

    foreach ($check in $sectionChecks) {
      $checkSection = [string](Get-PropertyValue $check 'section')
      $checkName = Get-PropertyValue $check 'name'
      $checkStatus = [string](Get-PropertyValue $check 'status')
      Add-Check -Name "section.$sectionName.check.section:${checkName}" -Status (Convert-FailStatus ($checkSection -eq $sectionName)) `
        -Evidence "check.section=$checkSection; parent=$sectionName" -Expected 'Nested check carries its parent section name'
      Add-Check -Name "section.$sectionName.check.name" -Status (Convert-FailStatus (Test-TextPresent $checkName)) `
        -Evidence "name=$checkName" -Expected 'Check name is present'
      Add-Check -Name "section.$sectionName.check.status:${checkName}" -Status (Convert-FailStatus ($checkStatus -in @('REVIEW', 'FAIL'))) `
        -Evidence "status=$checkStatus" -Expected 'Missing manifest contains only REVIEW or FAIL checks'
      foreach ($name in @('evidence', 'expected')) {
        $value = Get-PropertyValue $check $name
        Add-Check -Name "section.$sectionName.check.${name}:${checkName}" -Status (Convert-FailStatus ($null -ne $value)) `
          -Evidence "$name=$value" -Expected 'Check evidence metadata is present'
      }
    }
  }

  $missing = Get-PropertyValue $manifest 'missing'
  Add-Check -Name 'missing total matches section missing counts' `
    -Status (Convert-FailStatus ($null -ne $missing -and [int]$missing -eq $sectionMissingTotal)) `
    -Evidence "missing=$missing; sectionMissingTotal=$sectionMissingTotal" -Expected 'Top-level missing equals sum of section missing counts'

  Add-Check -Name 'missing total matches manifest checks' `
    -Status (Convert-FailStatus ($null -ne $missing -and [int]$missing -eq $sectionCheckCount)) `
    -Evidence "missing=$missing; manifestChecks=$sectionCheckCount" -Expected 'Top-level missing equals total listed checks'

  if ($RequireClosed) {
    Add-Check -Name 'requireClosed missing total' -Status (Convert-FailStatus ($null -ne $missing -and [int]$missing -eq 0)) `
      -Evidence "missing=$missing" -Expected '0 missing checks for Product Ready closure'
  }
} catch {
  if (-not ($checks | Where-Object { $_.status -eq 'FAIL' })) {
    Add-Check -Name 'missing evidence manifest verifier exception' -Status 'FAIL' -Evidence $_.Exception.Message `
      -Expected 'Verifier completes without exception'
  }
}

$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$failed = @($checks | Where-Object { $_.status -eq 'FAIL' }).Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  manifestPath = $ManifestPath
  requireClosed = [bool]$RequireClosed
  status = if ($failed -eq 0) { 'PASS' } else { 'FAIL' }
  passed = $passed
  failed = $failed
  checks = $checks
  productReadyMeaning = if ($RequireClosed) {
    'Fail-closed missing evidence manifest verifier. Product Ready requires zero missing checks.'
  } else {
    'Missing evidence manifest structural verifier. This does not prove Product Ready while missing checks remain.'
  }
}

$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready missing evidence manifest verification')
$lines.Add('')
$lines.Add("- Generated at: $($summary.generatedAt)")
$lines.Add("- Manifest path: $ManifestPath")
$lines.Add("- Require closed: $([bool]$RequireClosed)")
$lines.Add("- Status: $($summary.status)")
$lines.Add("- Passed: $passed")
$lines.Add("- Failed: $failed")
$lines.Add('')
$lines.Add('## Checks')
$lines.Add('')
$lines.Add('| Result | Check | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($check in $checks) {
  $evidenceText = ([string]$check.evidence).Replace('|', '\|')
  $expectedText = ([string]$check.expected).Replace('|', '\|')
  $lines.Add("| $($check.status) | $($check.name) | $evidenceText | $expectedText |")
}
$lines.Add('')
$lines.Add('## Product Ready meaning')
$lines.Add('')
$lines.Add($summary.productReadyMeaning)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-missing-evidence] status: $($summary.status)"
Write-Host "[product-ready-missing-evidence] checks: $passed passed, $failed failed"
Write-Host "[product-ready-missing-evidence] report: $reportPath"
Write-Host "[product-ready-missing-evidence] summary: $summaryPath"

if ($failed -gt 0) {
  exit 1
}
exit 0
