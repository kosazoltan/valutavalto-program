param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\product-ready-acceptance-coverage'),
  [string]$CoveragePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'docs\PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json')
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
      passed = $Passed
      evidence = $Evidence
      expected = $Expected
    })
}

function Get-PropertyValue {
  param([object]$Object, [string]$Name)
  if ($null -eq $Object) {
    return $null
  }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }
  return $property.Value
}

function Test-TextPresent {
  param([object]$Value)
  return ($null -ne $Value -and -not [string]::IsNullOrWhiteSpace([string]$Value))
}

try {
  $coverageExists = Test-Path -LiteralPath $CoveragePath
  Add-Check -Name 'coverage file exists' -Passed $coverageExists -Evidence $CoveragePath `
    -Expected 'Product Ready acceptance coverage JSON exists'

  if (-not $coverageExists) {
    throw 'Acceptance coverage JSON is missing.'
  }

  try {
    $coverage = Get-Content -LiteralPath $CoveragePath -Raw | ConvertFrom-Json
    Add-Check -Name 'coverage json parse' -Passed $true -Evidence $CoveragePath -Expected 'Valid JSON'
  } catch {
    Add-Check -Name 'coverage json parse' -Passed $false -Evidence $_.Exception.Message -Expected 'Valid JSON'
    throw
  }

  $schemaVersion = Get-PropertyValue $coverage 'schemaVersion'
  Add-Check -Name 'schemaVersion' -Passed ($schemaVersion -eq 1) -Evidence "schemaVersion=$schemaVersion" -Expected '1'

  $status = Get-PropertyValue $coverage 'status'
  Add-Check -Name 'status' -Passed ([string]$status -eq 'LOCAL_PASS') -Evidence "status=$status" -Expected 'LOCAL_PASS'

  $environment = Get-PropertyValue $coverage 'environment'
  Add-Check -Name 'environment' -Passed ([string]$environment -eq 'local') -Evidence "environment=$environment" -Expected 'local'

  $requiredFlows = @(Get-PropertyValue $coverage 'requiredFlows')
  $flows = @(Get-PropertyValue $coverage 'flows')
  Add-Check -Name 'flows array' -Passed ($flows.Count -gt 0) -Evidence "flows=$($flows.Count)" -Expected 'At least one flow'

  foreach ($requiredFlow in $requiredFlows) {
    $flow = $flows | Where-Object { [string](Get-PropertyValue $_ 'id') -eq [string]$requiredFlow } | Select-Object -First 1
    Add-Check -Name "flow:$requiredFlow exists" -Passed ($null -ne $flow) -Evidence "flow=$requiredFlow" `
      -Expected 'Required critical flow is mapped'

    if ($null -eq $flow) {
      continue
    }

    $commands = @(Get-PropertyValue $flow 'commands')
    Add-Check -Name "flow:$requiredFlow commands" -Passed ($commands.Count -gt 0 -and ($commands | Where-Object { -not (Test-TextPresent $_) }).Count -eq 0) `
      -Evidence "commands=$($commands.Count)" -Expected 'At least one non-empty command'

    $evidenceRefs = @(Get-PropertyValue $flow 'evidenceRefs')
    Add-Check -Name "flow:$requiredFlow evidenceRefs" -Passed ($evidenceRefs.Count -gt 0) `
      -Evidence "evidenceRefs=$($evidenceRefs.Count)" -Expected 'At least one evidence reference'

    foreach ($ref in $evidenceRefs) {
      $relativePath = [string](Get-PropertyValue $ref 'path')
      $pathOk = Test-TextPresent $relativePath
      $fullPath = if ($pathOk) { Join-Path $WorkspaceRoot $relativePath } else { '' }
      $fileExists = ($pathOk -and (Test-Path -LiteralPath $fullPath))
      Add-Check -Name "flow:$requiredFlow file:$relativePath" -Passed $fileExists -Evidence $relativePath `
        -Expected 'Evidence file exists'

      $content = ''
      if ($fileExists) {
        $content = Get-Content -LiteralPath $fullPath -Raw
      }

      $patterns = @(Get-PropertyValue $ref 'patterns')
      Add-Check -Name "flow:$requiredFlow patterns:$relativePath" -Passed ($patterns.Count -gt 0) `
        -Evidence "patterns=$($patterns.Count)" -Expected 'At least one evidence pattern'

      foreach ($pattern in $patterns) {
        $patternText = [string]$pattern
        $patternOk = ($fileExists -and (Test-TextPresent $patternText) -and $content.Contains($patternText))
        Add-Check -Name "flow:$requiredFlow pattern:$patternText" -Passed $patternOk -Evidence $relativePath `
          -Expected 'Pattern is present in evidence file'
      }
    }
  }
} catch {
  if (-not ($checks | Where-Object { -not $_.passed })) {
    Add-Check -Name 'acceptance coverage verifier exception' -Passed $false -Evidence $_.Exception.Message `
      -Expected 'Verifier completes without exception'
  }
}

$passed = @($checks | Where-Object { $_.passed }).Count
$failed = @($checks | Where-Object { -not $_.passed }).Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  coveragePath = $CoveragePath
  passed = $passed
  failed = $failed
  checks = $checks
  productReadyMeaning = 'Local critical-flow coverage map. Product Ready still requires staging or production execution evidence.'
}

$summaryPath = Join-Path $runDir 'summary.json'
$reportPath = Join-Path $runDir 'report.md'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Product Ready acceptance coverage verification')
$lines.Add('')
$lines.Add("- Generated at: $($summary.generatedAt)")
$lines.Add("- Coverage path: $CoveragePath")
$lines.Add("- Passed: $passed")
$lines.Add("- Failed: $failed")
$lines.Add('')
$lines.Add('| Result | Check | Evidence | Expected |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($check in $checks) {
  $result = if ($check.passed) { 'PASS' } else { 'FAIL' }
  $evidenceText = ([string]$check.evidence).Replace('|', '\|')
  $expectedText = ([string]$check.expected).Replace('|', '\|')
  $lines.Add("| $result | $($check.name) | $evidenceText | $expectedText |")
}
$lines.Add('')
$lines.Add($summary.productReadyMeaning)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[product-ready-acceptance-coverage] checks: $passed passed, $failed failed"
Write-Host "[product-ready-acceptance-coverage] report: $reportPath"
Write-Host "[product-ready-acceptance-coverage] summary: $summaryPath"

if ($failed -gt 0) {
  exit 1
}
