# scripts/_production-urls.ps1
#
# Shared PowerShell helper: beolvassa a config/production-urls.json-t es
# exportalja $PRODUCTION_URLS hash-ba. Minden script dot-source-olhatja ezt:
#
#   . (Join-Path $PSScriptRoot '_production-urls.ps1')
#
# utana: $PRODUCTION_URLS.base_url, $PRODUCTION_URLS.health_url, stb.

$ErrorActionPreference = 'Stop'

$script:_prodUrlsConfigPath = Join-Path $PSScriptRoot '..' 'config' 'production-urls.json'
if (-not (Test-Path $script:_prodUrlsConfigPath)) {
    throw "Production URL config nem letezik: $script:_prodUrlsConfigPath. Hivatkozott file: config/production-urls.json"
}

try {
    $global:PRODUCTION_URLS = Get-Content $script:_prodUrlsConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    throw "Production URL config parse hiba: $($_.Exception.Message)"
}

# Sanity check: kotelezo kulcsok meg kell legyenek
$requiredKeys = @('domain', 'base_url', 'api_url', 'health_url', 'www_base_url')
foreach ($k in $requiredKeys) {
    if (-not $global:PRODUCTION_URLS.$k) {
        throw "Production URL config hibas: '$k' kulcs hianyzik vagy ures a config/production-urls.json-ban"
    }
}

# Helper funkciok
function Get-ProductionBaseUrl { return $global:PRODUCTION_URLS.base_url }
function Get-ProductionApiUrl  { return $global:PRODUCTION_URLS.api_url }
function Get-ProductionHealthUrl { return $global:PRODUCTION_URLS.health_url }
function Get-ProductionDomain  { return $global:PRODUCTION_URLS.domain }