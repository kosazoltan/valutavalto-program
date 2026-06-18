param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'security-reports\installer-smoke'),
  [switch]$CheckArtifacts,
  [switch]$RequireSignature,
  [int]$MaxArtifactAgeHours = 72
)

$ErrorActionPreference = 'Stop'
if ($RequireSignature -and -not $CheckArtifacts) {
  $CheckArtifacts = $true
}

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

function Get-RepoPath {
  param([string]$RelativePath)
  return Join-Path $WorkspaceRoot $RelativePath
}

function Test-RepoPath {
  param([string]$RelativePath)
  return Test-Path -LiteralPath (Get-RepoPath $RelativePath)
}

function Get-RepoContent {
  param([string]$RelativePath)
  $path = Get-RepoPath $RelativePath
  if (-not (Test-Path -LiteralPath $path)) { return '' }
  return Get-Content -LiteralPath $path -Raw
}

function Get-RepoJson {
  param([string]$RelativePath)
  return Get-Content -LiteralPath (Get-RepoPath $RelativePath) -Raw | ConvertFrom-Json
}

function Add-PathCheck {
  param([string]$Area, [string]$RelativePath, [string]$Expected)
  Add-Check -Area $Area -Name $RelativePath -Status ($(if (Test-RepoPath $RelativePath) { 'PASS' } else { 'FAIL' })) `
    -Evidence $RelativePath -Expected $Expected
}

function Add-ContentCheck {
  param([string]$Area, [string]$RelativePath, [string]$Pattern, [string]$Expected)
  $content = Get-RepoContent $RelativePath
  Add-Check -Area $Area -Name "$RelativePath contains $Pattern" -Status ($(if ($content -match [regex]::Escape($Pattern)) { 'PASS' } else { 'FAIL' })) `
    -Evidence $RelativePath -Expected $Expected
}

function Test-ExtraResourceProductionUrls {
  param([object]$Builder)
  if (-not ($Builder.extraResources -is [array])) { return $false }
  foreach ($resource in $Builder.extraResources) {
    $from = "$($resource.from)".Replace('\', '/')
    if ($from.EndsWith('config/production-urls.json') -and "$($resource.to)" -eq 'production-urls.json') {
      return $true
    }
  }
  return $false
}

function Get-TargetArchSummary {
  param([object]$Builder)
  if (-not $Builder.win -or -not ($Builder.win.target -is [array])) { return '' }
  $parts = @()
  foreach ($target in $Builder.win.target) {
    $arch = if ($target.arch -is [array]) { ($target.arch -join ',') } else { "$($target.arch)" }
    $parts += "$($target.target):$arch"
  }
  return ($parts -join ';')
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

function Add-AuthenticodeSignatureCheck {
  param(
    [string]$Name,
    [string]$ArtifactPath
  )

  $signatureShell = Get-Command pwsh -ErrorAction SilentlyContinue
  if (-not $signatureShell) {
    $signatureShell = Get-Command powershell.exe -ErrorAction SilentlyContinue
  }
  if (-not $signatureShell) {
    Add-Check -Area $Name -Name 'installer artifact authenticode signature' `
      -Status ($(if ($RequireSignature) { 'FAIL' } else { 'SKIP' })) `
      -Evidence 'Neither pwsh nor powershell.exe is available for Authenticode signature inspection' `
      -Expected 'Authenticode signature can be inspected'
    return
  }

  $escapedArtifactPath = $ArtifactPath.Replace("'", "''")
  $probeScript = @"
`$ErrorActionPreference = 'Stop'
`$signature = Get-AuthenticodeSignature -FilePath '$escapedArtifactPath' -ErrorAction Stop
`$certificate = `$signature.SignerCertificate
[pscustomobject]@{
  Status = `$signature.Status.ToString()
  StatusMessage = "`$(`$signature.StatusMessage)"
  Subject = if (`$certificate) { "`$(`$certificate.Subject)" } else { "" }
  Thumbprint = if (`$certificate) { "`$(`$certificate.Thumbprint)" } else { "" }
} | ConvertTo-Json -Depth 4
"@
  $encodedProbe = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($probeScript))
  $stdoutPath = Join-Path $runDir "$Name-authenticode.stdout.json"
  $stderrPath = Join-Path $runDir "$Name-authenticode.stderr.log"
  $proc = Start-Process -FilePath $signatureShell.Source `
    -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encodedProbe) `
    -WorkingDirectory $WorkspaceRoot -NoNewWindow -Wait -PassThru `
    -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
  if ($proc.ExitCode -ne 0) {
    Add-Check -Area $Name -Name 'installer artifact authenticode signature' `
      -Status ($(if ($RequireSignature) { 'FAIL' } else { 'SKIP' })) `
      -Evidence "exit=$($proc.ExitCode); stdout=$stdoutPath; stderr=$stderrPath" `
      -Expected 'Authenticode signature can be inspected'
    return
  }

  try {
    $signature = Get-Content -LiteralPath $stdoutPath -Raw | ConvertFrom-Json
  } catch {
    Add-Check -Area $Name -Name 'installer artifact authenticode signature' `
      -Status ($(if ($RequireSignature) { 'FAIL' } else { 'SKIP' })) `
      -Evidence "Authenticode signature JSON could not be parsed: $($_.Exception.Message); stdout=$stdoutPath; stderr=$stderrPath" `
      -Expected 'Authenticode signature can be inspected'
    return
  }

  $evidence = "status=$($signature.Status); subject=$($signature.Subject); thumbprint=$($signature.Thumbprint); message=$($signature.StatusMessage); report=$stdoutPath"
  $status = if ($signature.Status -eq 'Valid') {
    'PASS'
  } elseif ($RequireSignature) {
    'FAIL'
  } else {
    'SKIP'
  }

  Add-Check -Area $Name -Name 'installer artifact authenticode signature' -Status $status `
    -Evidence $evidence -Expected 'Valid Authenticode signature for signed production release artifacts'
}

function Test-TextLikeFile {
  param([string]$Path)
  $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
  return @(
    '.css', '.html', '.js', '.json', '.map', '.md', '.properties',
    '.txt', '.xml', '.yaml', '.yml', '.env', '.config'
  ).Contains($extension)
}

function Get-SecretPatternFindings {
  param(
    [string]$Content,
    [string]$Source
  )

  $findings = [System.Collections.Generic.List[string]]::new()
  $patterns = @(
    [pscustomobject]@{ name = 'private-key'; pattern = '-----BEGIN [A-Z ]*PRIVATE KEY-----' },
    [pscustomobject]@{ name = 'aws-access-key'; pattern = 'AKIA[0-9A-Z]{16}' },
    [pscustomobject]@{ name = 'hard-coded-secret-value'; pattern = '(?i)(jwt[_-]?secret|db[_-]?password|database[_-]?password|client[_-]?secret|api[_-]?key|access[_-]?token|refresh[_-]?token)\s*[:=]\s*["''][A-Za-z0-9_./+=:@-]{16,}["'']' }
  )

  foreach ($item in $patterns) {
    if ($Content -match $item.pattern) {
      $findings.Add("$Source::$($item.name)")
    }
  }

  return $findings
}

function Add-PackagedSecretLeakChecks {
  param(
    [string]$Name,
    [string]$Directory
  )

  $resourcesDir = Get-RepoPath "$Directory\release\win-unpacked\resources"
  if (-not (Test-Path -LiteralPath $resourcesDir)) {
    Add-Check -Area $Name -Name 'packaged secret scan' -Status ($(if ($CheckArtifacts) { 'FAIL' } else { 'SKIP' })) `
      -Evidence $resourcesDir -Expected 'win-unpacked resources exist after installer package build'
    return
  }

  $forbiddenNameRegex = '(?i)(^|[\\/])(\.env($|\.)|.*secret.*\.(json|txt|env|properties|yml|yaml|pem|key|p12|pfx)$|id_rsa$|.*private.*key.*)'
  $badNames = [System.Collections.Generic.List[string]]::new()
  $secretFindings = [System.Collections.Generic.List[string]]::new()

  foreach ($file in Get-ChildItem -LiteralPath $resourcesDir -Recurse -File -ErrorAction SilentlyContinue) {
    $relative = $file.FullName.Substring($resourcesDir.Length).TrimStart('\', '/')
    if ($relative -match $forbiddenNameRegex) {
      $badNames.Add($relative)
    }

    if ((Test-TextLikeFile $file.FullName) -and $file.Length -le 1048576) {
      $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
      foreach ($finding in (Get-SecretPatternFindings -Content $content -Source $relative)) {
        $secretFindings.Add($finding)
      }
    }
  }

  Add-Check -Area $Name -Name 'packaged forbidden secret filenames' -Status ($(if ($badNames.Count -eq 0) { 'PASS' } else { 'FAIL' })) `
    -Evidence ($(if ($badNames.Count -eq 0) { $resourcesDir } else { ($badNames | Select-Object -First 20) -join '; ' })) `
    -Expected 'No .env/private-key/secret credential files in packaged resources'
  Add-Check -Area $Name -Name 'packaged text secret patterns' -Status ($(if ($secretFindings.Count -eq 0) { 'PASS' } else { 'FAIL' })) `
    -Evidence ($(if ($secretFindings.Count -eq 0) { $resourcesDir } else { ($secretFindings | Select-Object -First 20) -join '; ' })) `
    -Expected 'No high-confidence hard-coded secret values in packaged text resources'

  $asarPath = Join-Path $resourcesDir 'app.asar'
  if (-not (Test-Path -LiteralPath $asarPath)) {
    Add-Check -Area $Name -Name 'asar secret scan' -Status 'FAIL' -Evidence $asarPath -Expected 'app.asar exists'
    return
  }

  $asarModule = Get-RepoPath "$Directory\node_modules\@electron\asar"
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node -or -not (Test-Path -LiteralPath $asarModule)) {
    Add-Check -Area $Name -Name 'asar secret scan' -Status 'SKIP' -Evidence "node=$($node.Source); module=$asarModule" -Expected 'node and @electron/asar available'
    return
  }

  $scannerPath = Join-Path $runDir "$Name-asar-secret-scan.cjs"
  @'
const asar = require(process.argv[2]);
const archive = process.argv[3];
const forbiddenName = /(^|[\\/])(\.env($|\.)|.*secret.*\.(json|txt|env|properties|yml|yaml|pem|key|p12|pfx)$|id_rsa$|.*private.*key.*)/i;
const textExt = new Set(['.css', '.html', '.js', '.json', '.map', '.md', '.properties', '.txt', '.xml', '.yaml', '.yml', '.env', '.config']);
const secretPatterns = [
  { name: 'private-key', re: /-----BEGIN [A-Z ]*PRIVATE KEY-----/ },
  { name: 'aws-access-key', re: /AKIA[0-9A-Z]{16}/ },
  { name: 'hard-coded-secret-value', re: /(jwt[_-]?secret|db[_-]?password|database[_-]?password|client[_-]?secret|api[_-]?key|access[_-]?token|refresh[_-]?token)\s*[:=]\s*["'][A-Za-z0-9_./+=:@-]{16,}["']/i },
];

function extname(path) {
  const index = path.lastIndexOf('.');
  return index >= 0 ? path.slice(index).toLowerCase() : '';
}

const entries = asar.listPackage(archive).map((entry) => entry.replace(/^\/+/, ''));
const badNames = entries.filter((entry) => forbiddenName.test(entry));
const secretFindings = [];

for (const entry of entries) {
  if (!textExt.has(extname(entry))) continue;
  let buffer;
  try {
    buffer = asar.extractFile(archive, entry);
  } catch {
    continue;
  }
  if (!buffer || buffer.length > 1024 * 1024) continue;
  const text = buffer.toString('utf8');
  for (const pattern of secretPatterns) {
    if (pattern.re.test(text)) {
      secretFindings.push(`${entry}::${pattern.name}`);
    }
  }
}

console.log(JSON.stringify({
  entries: entries.length,
  badNames: badNames.slice(0, 20),
  secretFindings: secretFindings.slice(0, 20),
}));
'@ | Set-Content -LiteralPath $scannerPath -Encoding UTF8

  $asarStdout = Join-Path $runDir "$Name-asar-secret-scan.stdout.json"
  $asarStderr = Join-Path $runDir "$Name-asar-secret-scan.stderr.log"
  $proc = Start-Process -FilePath $node.Source -ArgumentList @($scannerPath, $asarModule, $asarPath) `
    -WorkingDirectory $WorkspaceRoot -NoNewWindow -Wait -PassThru `
    -RedirectStandardOutput $asarStdout -RedirectStandardError $asarStderr
  if ($proc.ExitCode -ne 0) {
    Add-Check -Area $Name -Name 'asar secret scan' -Status 'FAIL' `
      -Evidence "exit=$($proc.ExitCode); stdout=$asarStdout; stderr=$asarStderr" -Expected 'ASAR scan exits with 0'
    return
  }

  $asarResult = Get-Content -LiteralPath $asarStdout -Raw | ConvertFrom-Json
  Add-Check -Area $Name -Name 'asar forbidden secret filenames' -Status ($(if ($asarResult.badNames.Count -eq 0) { 'PASS' } else { 'FAIL' })) `
    -Evidence ($(if ($asarResult.badNames.Count -eq 0) { "entries=$($asarResult.entries); report=$asarStdout" } else { ($asarResult.badNames -join '; ') })) `
    -Expected 'No .env/private-key/secret credential files inside app.asar'
  Add-Check -Area $Name -Name 'asar text secret patterns' -Status ($(if ($asarResult.secretFindings.Count -eq 0) { 'PASS' } else { 'FAIL' })) `
    -Evidence ($(if ($asarResult.secretFindings.Count -eq 0) { "entries=$($asarResult.entries); report=$asarStdout" } else { ($asarResult.secretFindings -join '; ') })) `
    -Expected 'No high-confidence hard-coded secret values inside app.asar text files'
}

function Add-ClientChecks {
  param(
    [string]$Name,
    [string]$Directory,
    [string]$ExpectedAppId,
    [string]$ExpectedProductName,
    [string]$ExpectedArtifactName,
    [string]$ArtifactRelativeDirectory,
    [string]$ArtifactNamePattern
  )

  $packagePath = "$Directory\package.json"
  $builderPath = "$Directory\electron-builder.json"
  $mainPath = "$Directory\electron\main.ts"

  Add-PathCheck -Area $Name -RelativePath $packagePath -Expected 'Client package.json exists'
  Add-PathCheck -Area $Name -RelativePath $builderPath -Expected 'electron-builder config exists'
  Add-PathCheck -Area $Name -RelativePath $mainPath -Expected 'Electron main process exists'

  if (-not (Test-RepoPath $packagePath) -or -not (Test-RepoPath $builderPath)) {
    return
  }

  $pkg = Get-RepoJson $packagePath
  $builder = Get-RepoJson $builderPath
  $packageScript = "$($pkg.scripts.package)"
  $unsignedScript = "$($pkg.scripts.'package:unsigned')"
  $targetSummary = Get-TargetArchSummary $builder

  Add-Check -Area $Name -Name 'package script alignment gate' -Status ($(if ($packageScript.Contains('check-four-area-alignment.mjs')) { 'PASS' } else { 'FAIL' })) `
    -Evidence $packageScript -Expected 'package runs four-area alignment gate before electron-builder'
  Add-Check -Area $Name -Name 'package script electron-builder win target' -Status ($(if ($packageScript.Contains('electron-builder --win')) { 'PASS' } else { 'FAIL' })) `
    -Evidence $packageScript -Expected 'package builds Windows installer'
  Add-Check -Area $Name -Name 'unsigned package explicit opt-in' -Status ($(if ($unsignedScript.Contains('ALLOW_UNSIGNED_BUILD=1') -and $unsignedScript.Contains('electron-builder --win')) { 'PASS' } else { 'FAIL' })) `
    -Evidence $unsignedScript -Expected 'unsigned package requires explicit ALLOW_UNSIGNED_BUILD=1'
  Add-Check -Area $Name -Name 'appId' -Status ($(if ($builder.appId -eq $ExpectedAppId) { 'PASS' } else { 'FAIL' })) `
    -Evidence "$($builder.appId)" -Expected $ExpectedAppId
  Add-Check -Area $Name -Name 'productName' -Status ($(if ($builder.productName -eq $ExpectedProductName) { 'PASS' } else { 'FAIL' })) `
    -Evidence "$($builder.productName)" -Expected $ExpectedProductName
  Add-Check -Area $Name -Name 'artifactName' -Status ($(if ($builder.win.artifactName -eq $ExpectedArtifactName) { 'PASS' } else { 'FAIL' })) `
    -Evidence "$($builder.win.artifactName)" -Expected $ExpectedArtifactName
  Add-Check -Area $Name -Name 'NSIS x64 target' -Status ($(if ($targetSummary -match 'nsis:.*x64') { 'PASS' } else { 'FAIL' })) `
    -Evidence $targetSummary -Expected 'nsis target for x64'
  Add-Check -Area $Name -Name 'NSIS guided install' -Status ($(if ($builder.nsis.oneClick -eq $false -and $builder.nsis.allowToChangeInstallationDirectory -eq $true) { 'PASS' } else { 'FAIL' })) `
    -Evidence "oneClick=$($builder.nsis.oneClick); allowToChangeInstallationDirectory=$($builder.nsis.allowToChangeInstallationDirectory)" `
    -Expected 'oneClick=false and allowToChangeInstallationDirectory=true'
  Add-Check -Area $Name -Name 'production URLs extraResource' -Status ($(if (Test-ExtraResourceProductionUrls $builder) { 'PASS' } else { 'FAIL' })) `
    -Evidence $builderPath -Expected 'config/production-urls.json is packaged as production-urls.json'
  Add-ContentCheck -Area $Name -RelativePath $mainPath -Pattern 'production-urls.json' -Expected 'Main process reads packaged production URLs'

  if ($CheckArtifacts) {
    $artifactPatternTemplate = if ($ArtifactNamePattern) { $ArtifactNamePattern } else { $ExpectedArtifactName }
    $artifactPattern = $artifactPatternTemplate.Replace('${version}', $pkg.version)
    $artifactDirRelative = if ($ArtifactRelativeDirectory) { $ArtifactRelativeDirectory } else { "$Directory\release" }
    $releaseDir = Get-RepoPath $artifactDirRelative
    $artifact = if (Test-Path -LiteralPath $releaseDir) {
      Get-ChildItem -LiteralPath $releaseDir -Filter $artifactPattern -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    } else {
      $null
    }
    if ($artifact) {
      $ageHours = [Math]::Round(((Get-Date) - $artifact.LastWriteTime).TotalHours, 2)
      Add-Check -Area $Name -Name 'installer artifact exists' -Status 'PASS' `
        -Evidence "$($artifact.FullName); size=$($artifact.Length); ageHours=$ageHours" -Expected $artifactPattern
      Add-Check -Area $Name -Name 'installer artifact age' -Status ($(if ($ageHours -le $MaxArtifactAgeHours) { 'PASS' } else { 'FAIL' })) `
        -Evidence "ageHours=$ageHours" -Expected "<= $MaxArtifactAgeHours"
      $hash = Get-Sha256Hash -Path $artifact.FullName
      $hashPath = Join-Path $runDir "$Name.sha256"
      "$hash *$($artifact.Name)" | Set-Content -LiteralPath $hashPath -Encoding ASCII
      Add-Check -Area $Name -Name 'installer artifact sha256' -Status 'PASS' -Evidence $hashPath -Expected 'SHA-256 generated'
      Add-AuthenticodeSignatureCheck -Name $Name -ArtifactPath $artifact.FullName
    } else {
      Add-Check -Area $Name -Name 'installer artifact exists' -Status 'FAIL' -Evidence "$releaseDir\$artifactPattern" -Expected 'Artifact exists'
    }
  } else {
    Add-Check -Area $Name -Name 'installer artifact check' -Status 'SKIP' -Evidence 'Run with -CheckArtifacts after package:unsigned/package' -Expected 'Optional local artifact verification'
  }

  Add-PackagedSecretLeakChecks -Name $Name -Directory $Directory
}

function Add-NsisArtifactCheck {
  param(
    [string]$Name,
    [string]$RelativeDirectory,
    [string]$ArtifactPattern
  )

  if (-not $CheckArtifacts) {
    Add-Check -Area $Name -Name 'installer artifact check' -Status 'SKIP' `
      -Evidence 'Run with -CheckArtifacts after installer build' -Expected $ArtifactPattern
    return
  }

  $artifactDir = Get-RepoPath $RelativeDirectory
  $artifact = if (Test-Path -LiteralPath $artifactDir) {
    Get-ChildItem -LiteralPath $artifactDir -Filter $ArtifactPattern -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  } else {
    $null
  }

  if ($artifact) {
    $ageHours = [Math]::Round(((Get-Date) - $artifact.LastWriteTime).TotalHours, 2)
    Add-Check -Area $Name -Name 'installer artifact exists' -Status 'PASS' `
      -Evidence "$($artifact.FullName); size=$($artifact.Length); ageHours=$ageHours" -Expected $ArtifactPattern
    Add-Check -Area $Name -Name 'installer artifact age' -Status ($(if ($ageHours -le $MaxArtifactAgeHours) { 'PASS' } else { 'FAIL' })) `
      -Evidence "ageHours=$ageHours" -Expected "<= $MaxArtifactAgeHours"
    $hash = Get-Sha256Hash -Path $artifact.FullName
    $hashPath = Join-Path $runDir "$Name.sha256"
    "$hash *$($artifact.Name)" | Set-Content -LiteralPath $hashPath -Encoding ASCII
    Add-Check -Area $Name -Name 'installer artifact sha256' -Status 'PASS' -Evidence $hashPath -Expected 'SHA-256 generated'
    Add-AuthenticodeSignatureCheck -Name $Name -ArtifactPath $artifact.FullName
  } else {
    Add-Check -Area $Name -Name 'installer artifact exists' -Status 'FAIL' -Evidence "$artifactDir\$ArtifactPattern" -Expected 'Artifact exists'
  }
}

Add-PathCheck -Area 'docs' -RelativePath 'docs\INSTALLER_DOCS_INDEX.md' -Expected 'Installer documentation index exists'
Add-PathCheck -Area 'docs' -RelativePath 'docs\BUILD_WINDOWS.md' -Expected 'Windows build documentation exists'
Add-PathCheck -Area 'docs' -RelativePath 'docs\INSTALL_WINDOWS.md' -Expected 'Windows install documentation exists'
Add-PathCheck -Area 'docs' -RelativePath 'docs\UPDATE_WINDOWS.md' -Expected 'Windows update/rollback documentation exists'
Add-PathCheck -Area 'docs' -RelativePath 'docs\SECURITY_INSTALLER_CHECKLIST.md' -Expected 'Installer security checklist exists'
Add-PathCheck -Area 'docs' -RelativePath 'docs\ELECTRON_CASHIER_SMOKE_CHECKLIST.md' -Expected 'Electron cashier smoke checklist exists'

Add-ContentCheck -Area 'root' -RelativePath 'package.json' -Pattern '"package:penztar"' -Expected 'Root penztar packaging script is wired'
Add-ContentCheck -Area 'root' -RelativePath 'package.json' -Pattern '"package:kozponti"' -Expected 'Root kozponti packaging script is wired'
Add-ContentCheck -Area 'root' -RelativePath 'package.json' -Pattern '"installer:smoke:preflight"' -Expected 'Root installer smoke preflight script is wired'
Add-ContentCheck -Area 'root' -RelativePath 'package.json' -Pattern '"installer:smoke:artifacts"' -Expected 'Root installer artifact verification script is wired'
Add-PathCheck -Area 'root' -RelativePath 'installer\build-installer.ps1' -Expected 'Penztar setup NSIS build script exists'
Add-PathCheck -Area 'root' -RelativePath 'installer\build-cleanup.ps1' -Expected 'Penztar standalone uninstaller build script exists'

Add-ClientChecks -Name 'penztar-client' -Directory 'penztar-client' `
  -ExpectedAppId 'com.bestchange.penztar' `
  -ExpectedProductName 'Valutavalto Penztar' `
  -ExpectedArtifactName 'Penztar-Setup-${version}.exe' `
  -ArtifactRelativeDirectory 'installer\build' `
  -ArtifactNamePattern 'Penztar-Setup-${version}-*.exe'
Add-NsisArtifactCheck -Name 'penztar-eltavolito' -RelativeDirectory 'installer\build' -ArtifactPattern "Penztar-Eltavolito-$((Get-RepoJson 'package.json').version)-*.exe"
Add-ClientChecks -Name 'kozponti-client' -Directory 'kozponti-client' `
  -ExpectedAppId 'com.bestchange.munkaallomas' `
  -ExpectedProductName 'Valutavalto Kozponti Munkaallomas' `
  -ExpectedArtifactName 'Kozponti-Munkaallomas-Setup-${version}.exe'

$alignmentStdout = Join-Path $runDir 'four-area-alignment.stdout.log'
$alignmentStderr = Join-Path $runDir 'four-area-alignment.stderr.log'
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
  $proc = Start-Process -FilePath $node.Source -ArgumentList @('scripts/check-four-area-alignment.mjs') `
    -WorkingDirectory $WorkspaceRoot -NoNewWindow -Wait -PassThru `
    -RedirectStandardOutput $alignmentStdout -RedirectStandardError $alignmentStderr
  Add-Check -Area 'alignment' -Name 'check-four-area-alignment' -Status ($(if ($proc.ExitCode -eq 0) { 'PASS' } else { 'FAIL' })) `
    -Evidence "exit=$($proc.ExitCode); stdout=$alignmentStdout; stderr=$alignmentStderr" -Expected 'exit code 0'
} else {
  Add-Check -Area 'alignment' -Name 'tool:node' -Status 'FAIL' -Evidence 'node not found on PATH' -Expected 'node available'
}

$failed = @($checks | Where-Object { $_.status -eq 'FAIL' })
$passed = @($checks | Where-Object { $_.status -eq 'PASS' }).Count
$skipped = @($checks | Where-Object { $_.status -eq 'SKIP' }).Count

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  workspaceRoot = $WorkspaceRoot
  checkArtifacts = [bool]$CheckArtifacts
  requireSignature = [bool]$RequireSignature
  maxArtifactAgeHours = $MaxArtifactAgeHours
  passed = $passed
  failed = $failed.Count
  skipped = $skipped
  checks = $checks
  pendingExternalEvidence = @(
    'Run the three expected Windows artifacts on a trusted Windows build machine: Penztar Setup, Penztar Eltavolito, Kozponti Munkaallomas',
    'Run this script with -CheckArtifacts and attach generated SHA-256 files',
    'For production release artifacts, run this script with -RequireSignature and attach Authenticode certificate evidence',
    'Install each generated installer on a clean Windows VM',
    'Verify launch, first-run/config path, backend URL, update/rollback notes, uninstall, and no secret leakage',
    'Attach signed release artifact/code-signing evidence when signed production releases are required'
  )
}

$summaryPath = Join-Path $runDir 'summary.json'
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportPath = Join-Path $runDir 'report.md'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Installer smoke preflight')
$lines.Add('')
$lines.Add("- Generated: $($summary.generatedAt)")
$lines.Add("- Workspace: $WorkspaceRoot")
$lines.Add("- Check artifacts: $([bool]$CheckArtifacts)")
$lines.Add("- Require signature: $([bool]$RequireSignature)")
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
$lines.Add('## Pending External Evidence')
$lines.Add('')
foreach ($item in $summary.pendingExternalEvidence) {
  $lines.Add("- $item")
}
$lines.Add('')
$lines.Add('## Product Ready Meaning')
$lines.Add('')
if ($CheckArtifacts) {
  if ($RequireSignature) {
    $lines.Add('This report verifies installer configuration, artifact hashes, and Authenticode signatures. Product Ready still requires clean Windows VM install/smoke evidence.')
  } else {
    $lines.Add('This report verifies installer configuration and locally built artifacts. Unsigned artifacts are acceptable only for local development evidence; Product Ready release evidence requires -RequireSignature plus clean Windows VM install/smoke evidence.')
  }
} else {
  $lines.Add('This preflight verifies installer configuration and smoke evidence paths. Product Ready still requires generated artifacts and clean Windows VM install/smoke evidence.')
}

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "[installer-smoke] checks: $passed passed, $($failed.Count) failed, $skipped skipped"
Write-Host "[installer-smoke] report: $reportPath"
Write-Host "[installer-smoke] summary: $summaryPath"

if ($failed.Count -gt 0) {
  exit 1
}
exit 0
