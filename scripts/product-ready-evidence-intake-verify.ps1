param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-evidence-intake-verify'),
  [string]$IntakePath = ''
)

$ErrorActionPreference = 'Stop'

$timestamp = "$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')-$PID"
$runDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
  param(
    [string]$Name,
    [bool]$Passed,
    [string]$Evidence,
    [string]$Expected
  )

  $checks.Add([pscustomobject]@{
      name = $Name
      status = if ($Passed) { 'PASS' } else { 'FAIL' }
      evidence = $Evidence
      expected = $Expected
    })
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

function Convert-ToRelativePath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return ''
  }

  $root = [System.IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('\', '/')
  $full = [System.IO.Path]::GetFullPath($Path)
  if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
  }
  return $full
}

function Resolve-RepoPath {
  param([object]$Value)
  if (-not (Test-TextPresent $Value)) { return '' }
  $text = [string]$Value
  if ([System.IO.Path]::IsPathRooted($text)) { return $text }
  return Join-Path $WorkspaceRoot $text
}

function Test-RepoPath {
  param([object]$Value)
  $path = Resolve-RepoPath $Value
  return ((Test-TextPresent $path) -and (Test-Path -LiteralPath $path))
}

function Get-LatestIntakePath {
  $root = Join-Path $WorkspaceRoot 'security-reports\product-ready-evidence-intake'
  if (-not (Test-Path -LiteralPath $root)) {
    return ''
  }

  $candidates = [System.Collections.Generic.List[object]]::new()
  foreach ($directory in (Get-ChildItem -LiteralPath $root -Directory)) {
    $candidate = Join-Path $directory.FullName 'evidence-intake.json'
    if (Test-Path -LiteralPath $candidate) {
      $file = Get-Item -LiteralPath $candidate
      $candidates.Add([pscustomobject]@{
          path = $candidate
          lastWriteTimeUtc = $file.LastWriteTimeUtc
        })
    }
  }

  $latest = $candidates | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
  if ($null -eq $latest) {
    return ''
  }
  return [string]$latest.path
}

function Get-SourceSectionMap {
  param([object]$Manifest)

  $map = @{}
  foreach ($section in @(Get-PropertyValue $Manifest 'sections')) {
    $sectionName = [string](Get-PropertyValue $section 'section')
    if (-not (Test-TextPresent $sectionName)) {
      continue
    }
    $checkMap = @{}
    foreach ($check in @(Get-PropertyValue $section 'checks')) {
      $checkName = [string](Get-PropertyValue $check 'name')
      if (Test-TextPresent $checkName) {
        $checkMap[$checkName] = $check
      }
    }
    $map[$sectionName] = [pscustomobject]@{
      section = $section
      checks = $checkMap
    }
  }
  return $map
}

try {
  if (-not (Test-TextPresent $IntakePath)) {
    $IntakePath = Get-LatestIntakePath
  }

  Add-Check -Name 'intake path resolved' -Passed (Test-TextPresent $IntakePath) `
    -Evidence "IntakePath=$IntakePath" -Expected 'Explicit intake path or latest evidence-intake.json exists'

  $intakeExists = (Test-TextPresent $IntakePath) -and (Test-Path -LiteralPath $IntakePath)
  Add-Check -Name 'intake exists' -Passed $intakeExists `
    -Evidence $IntakePath -Expected 'evidence-intake.json exists'

  if (-not $intakeExists) {
    throw "Evidence intake JSON is not available: $IntakePath"
  }

  $raw = Get-Content -LiteralPath $IntakePath -Raw
  $secretPattern = '(?i)(password|passwd|secret|api[_-]?key|token|private[_-]?key|client[_-]?secret)\s*[:=]\s*["''][^"'']{8,}["'']'
  Add-Check -Name 'intake secret pattern scan' -Passed ($raw -notmatch $secretPattern) `
    -Evidence $IntakePath -Expected 'No high-confidence secret values in evidence intake JSON'

  try {
    $intake = $raw | ConvertFrom-Json
    Add-Check -Name 'intake json parse' -Passed $true -Evidence $IntakePath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'intake json parse' -Passed $false -Evidence $_.Exception.Message -Expected 'Valid JSON'
    throw
  }

  $schemaVersion = Get-PropertyValue $intake 'schemaVersion'
  Add-Check -Name 'schemaVersion' -Passed ($schemaVersion -eq 1) `
    -Evidence "schemaVersion=$schemaVersion" -Expected '1'

  $meaning = [string](Get-PropertyValue $intake 'productReadyMeaning')
  Add-Check -Name 'productReadyMeaning' -Passed ($meaning -match 'Operator intake checklist') `
    -Evidence $meaning -Expected 'Operator intake checklist identity; not Product Ready proof'

  foreach ($name in @('sourceManifestPath', 'sourceEvidencePath', 'localEvidenceBundleRef', 'localCoverageReportRef', 'verifierSummary')) {
    $value = Get-PropertyValue $intake $name
    Add-Check -Name $name -Passed (Test-RepoPath $value) `
      -Evidence "$name=$value" -Expected 'Existing repo or absolute path'
  }

  $sourceManifestPath = Resolve-RepoPath (Get-PropertyValue $intake 'sourceManifestPath')
  $sourceRaw = Get-Content -LiteralPath $sourceManifestPath -Raw
  $sourceManifest = $sourceRaw | ConvertFrom-Json
  Add-Check -Name 'source manifest json parse' -Passed $true `
    -Evidence (Convert-ToRelativePath $sourceManifestPath) -Expected 'Valid source missing-evidence.json'

  $sourceMap = Get-SourceSectionMap -Manifest $sourceManifest
  $intakeSections = @(Get-PropertyValue $intake 'sections')
  $sourceSections = @(Get-PropertyValue $sourceManifest 'sections')
  Add-Check -Name 'section count matches source manifest' -Passed ($intakeSections.Count -eq $sourceSections.Count) `
    -Evidence "intakeSections=$($intakeSections.Count); sourceSections=$($sourceSections.Count)" `
    -Expected 'Evidence intake section count equals source missing manifest section count'

  $intakeCheckTotal = 0
  $sourceCheckTotal = 0
  foreach ($sourceSection in $sourceSections) {
    $sourceCheckTotal += @(Get-PropertyValue $sourceSection 'checks').Count
  }

  foreach ($section in $intakeSections) {
    $sectionName = [string](Get-PropertyValue $section 'section')
    $sourceSectionEntry = $sourceMap[$sectionName]
    Add-Check -Name "section.$sectionName.exists in source" -Passed ($null -ne $sourceSectionEntry) `
      -Evidence "section=$sectionName" -Expected 'Intake section exists in source missing manifest'

    if ($null -eq $sourceSectionEntry) {
      continue
    }

    foreach ($name in @('owner', 'template', 'notes')) {
      $intakeValue = [string](Get-PropertyValue $section $name)
      $sourceValue = [string](Get-PropertyValue $sourceSectionEntry.section $name)
      Add-Check -Name "section.$sectionName.$name matches source" -Passed ($intakeValue -eq $sourceValue) `
        -Evidence "intake=$intakeValue; source=$sourceValue" -Expected 'Intake section guidance preserves source manifest value'
    }

    $intakeMissing = Get-PropertyValue $section 'missing'
    $sourceMissing = Get-PropertyValue $sourceSectionEntry.section 'missing'
    Add-Check -Name "section.$sectionName.missing matches source" -Passed ([int]$intakeMissing -eq [int]$sourceMissing) `
      -Evidence "intake=$intakeMissing; source=$sourceMissing" -Expected 'Intake section missing count preserves source manifest value'

    $checksInSection = @(Get-PropertyValue $section 'checks')
    $intakeCheckTotal += $checksInSection.Count
    foreach ($check in $checksInSection) {
      $checkName = [string](Get-PropertyValue $check 'name')
      $sourceCheck = $sourceSectionEntry.checks[$checkName]
      Add-Check -Name "section.$sectionName.check.$checkName.exists in source" -Passed ($null -ne $sourceCheck) `
        -Evidence "check=$checkName" -Expected 'Intake check exists in source missing manifest section'

      if ($null -eq $sourceCheck) {
        continue
      }

      $checkSection = [string](Get-PropertyValue $check 'section')
      Add-Check -Name "section.$sectionName.check.$checkName.section" -Passed ($checkSection -eq $sectionName) `
        -Evidence "check.section=$checkSection; parent=$sectionName" -Expected 'Intake check repeats parent section'

      $sourceCheckName = [string](Get-PropertyValue $check 'sourceCheckName')
      Add-Check -Name "section.$sectionName.check.$checkName.sourceCheckName" -Passed ($sourceCheckName -eq $checkName) `
        -Evidence "sourceCheckName=$sourceCheckName; name=$checkName" -Expected 'Intake check preserves source check name'

      $sourceStatus = [string](Get-PropertyValue $sourceCheck 'status')
      $intakeSourceStatus = [string](Get-PropertyValue $check 'sourceStatus')
      $intakeStatus = [string](Get-PropertyValue $check 'status')
      Add-Check -Name "section.$sectionName.check.$checkName.sourceStatus" -Passed ($intakeSourceStatus -eq $sourceStatus) `
        -Evidence "sourceStatus=$intakeSourceStatus; source=$sourceStatus" -Expected 'Intake sourceStatus mirrors source manifest check status'
      Add-Check -Name "section.$sectionName.check.$checkName.status" -Passed ($intakeStatus -eq $sourceStatus) `
        -Evidence "status=$intakeStatus; source=$sourceStatus" -Expected 'Intake status mirrors source manifest check status'

      foreach ($pair in @(
          @{ intake = 'currentEvidence'; source = 'evidence' },
          @{ intake = 'expected'; source = 'expected' }
        )) {
        $intakeValue = [string](Get-PropertyValue $check $pair.intake)
        $sourceValue = [string](Get-PropertyValue $sourceCheck $pair.source)
        Add-Check -Name "section.$sectionName.check.$checkName.$($pair.intake) matches source" `
          -Passed ($intakeValue -eq $sourceValue) `
          -Evidence "intake=$intakeValue; source=$sourceValue" -Expected 'Intake check preserves source check metadata'
      }

      foreach ($name in @('jsonPointer', 'requiredValue', 'operatorAction', 'evidenceRef', 'completedBy', 'completedAt')) {
        $value = Get-PropertyValue $check $name
        Add-Check -Name "section.$sectionName.check.$checkName.$name present" -Passed ($null -ne $value) `
          -Evidence "$name=$value" -Expected 'Operator intake fillable/check metadata field is present'
      }
    }
  }

  $intakeMissing = Get-PropertyValue $intake 'missing'
  $sourceMissing = Get-PropertyValue $sourceManifest 'missing'
  Add-Check -Name 'missing total matches source manifest' -Passed ([int]$intakeMissing -eq [int]$sourceMissing) `
    -Evidence "intake=$intakeMissing; source=$sourceMissing" -Expected 'Top-level missing count preserves source manifest'
  Add-Check -Name 'check total matches source manifest' -Passed ($intakeCheckTotal -eq $sourceCheckTotal) `
    -Evidence "intakeChecks=$intakeCheckTotal; sourceChecks=$sourceCheckTotal" -Expected 'Total intake checks equals source manifest checks'
} catch {
  if (-not ($checks | Where-Object { $_.status -eq 'FAIL' })) {
    Add-Check -Name 'evidence intake verifier exception' -Passed $false -Evidence $_.Exception.Message `
      -Expected 'Verifier completes without exception'
  }
}

$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$failed = @($checks | Where-Object { $_.status -eq 'FAIL' }).Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  intakePath = Convert-ToRelativePath $IntakePath
  status = if ($failed -eq 0) { 'PASS' } else { 'FAIL' }
  passed = $passed
  failed = $failed
  checks = $checks
  productReadyMeaning = 'Evidence intake structural verifier. This verifies operator intake traceability, not Product Ready evidence completion.'
}

$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready evidence intake verification')
$lines.Add('')
$lines.Add("- Generated at: $($summary.generatedAt)")
$lines.Add("- Intake path: $($summary.intakePath)")
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

Write-Host "[product-ready-evidence-intake-verify] status: $($summary.status)"
Write-Host "[product-ready-evidence-intake-verify] checks: $passed passed, $failed failed"
Write-Host "[product-ready-evidence-intake-verify] report: $reportPath"
Write-Host "[product-ready-evidence-intake-verify] summary: $summaryPath"

if ($failed -gt 0) {
  exit 1
}
exit 0
