param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$clients = @(
  [pscustomobject]@{ directory = 'penztar-client'; artifact = 'Penztar-Setup-2.27.96.exe' },
  [pscustomobject]@{ directory = 'kozponti-client'; artifact = 'Kozponti-Munkaallomas-Setup-2.27.96.exe' }
)

$created = [System.Collections.Generic.List[string]]::new()
try {
  foreach ($client in $clients) {
    $releaseDir = Join-Path $WorkspaceRoot "$($client.directory)\release"
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
    $artifactPath = Join-Path $releaseDir $client.artifact
    if (Test-Path -LiteralPath $artifactPath) {
      throw "Refusing to overwrite existing installer artifact: $artifactPath. Run npm run installer:smoke:signed for real artifacts."
    }

    "synthetic installer artifact for $($client.directory) generated at $((Get-Date).ToString('o'))" |
      Set-Content -LiteralPath $artifactPath -Encoding ASCII
    $created.Add($artifactPath)
  }

  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $WorkspaceRoot 'scripts\installer-smoke-preflight.ps1') `
    -WorkspaceRoot $WorkspaceRoot `
    -CheckArtifacts `
    -MaxArtifactAgeHours 1

  if ($LASTEXITCODE -ne 0) {
    throw "installer-smoke-preflight.ps1 failed with exit code $LASTEXITCODE"
  }
} finally {
  foreach ($path in $created) {
    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  }
}
