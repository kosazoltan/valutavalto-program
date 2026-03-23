param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path,
    [string]$LocalConnectionString,
    [string]$RemoteConnectionString,
    [string]$MigrationTable = "flyway_schema_history"
)
# Távoli Flyway paritás:
#   strict (alap) — kötelező a public.flyway_schema_history + egyezés a lokállal
#   optional      — ha a távoli DB elérhető, de nincs Flyway tábla (üres Neon stb.),
#                   csak a lokális vs repo egyezést nézzük; WARN + kilépés 0
# Állítható: $env:DB_PREFLIGHT_REMOTE_MODE = "optional"

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-PsqlAvailable {
    if (Get-Command psql -ErrorAction SilentlyContinue) {
        return $true
    }

    $postgresRoot = 'C:\Program Files\PostgreSQL'
    if (Test-Path -LiteralPath $postgresRoot) {
        $binCandidates = Get-ChildItem -LiteralPath $postgresRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName 'bin' }

        foreach ($binPath in $binCandidates) {
            if (Test-Path -LiteralPath (Join-Path $binPath 'psql.exe')) {
                $env:Path = "$env:Path;$binPath"
                if (Get-Command psql -ErrorAction SilentlyContinue) {
                    return $true
                }
            }
        }
    }

    return $false
}

function Write-Status {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    switch ($Level) {
        "OK" { Write-Host "[DB-PREFLIGHT] $Message" -ForegroundColor Green }
        "WARN" { Write-Host "[DB-PREFLIGHT] $Message" -ForegroundColor Yellow }
        "ERR" { Write-Host "[DB-PREFLIGHT] $Message" -ForegroundColor Red }
        default { Write-Host "[DB-PREFLIGHT] $Message" -ForegroundColor Cyan }
    }
}

function Import-DotEnv {
    param([string]$EnvFile)

    if (!(Test-Path -LiteralPath $EnvFile)) {
        return
    }

    foreach ($line in Get-Content -LiteralPath $EnvFile -ErrorAction Stop) {
        if ($line -match '^\s*#') { continue }
        if ($line -match '^\s*$') { continue }
        if ($line -match '^\s*([^=]+?)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            if ($value.StartsWith('"') -and $value.EndsWith('"') -and $value.Length -ge 2) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($key, "Process"))) {
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
    }
}

function Convert-JdbcToPostgresUri {
    param([string]$JdbcUrl)

    if ([string]::IsNullOrWhiteSpace($JdbcUrl)) {
        return $null
    }

    if (-not $JdbcUrl.StartsWith("jdbc:postgresql://")) {
        return $JdbcUrl
    }

    $withoutPrefix = $JdbcUrl.Substring("jdbc:".Length)
    if ($withoutPrefix -notmatch '\?') {
        return $withoutPrefix
    }

    return $withoutPrefix
}

function Build-PostgresUri {
    param(
        [string]$DbHost,
        [string]$Port,
        [string]$Database,
        [string]$Username,
        [string]$Password,
        [string]$SslMode = "disable"
    )

    if ([string]::IsNullOrWhiteSpace($DbHost) -or
        [string]::IsNullOrWhiteSpace($Database) -or
        [string]::IsNullOrWhiteSpace($Username)) {
        return $null
    }

    $safePort = if ([string]::IsNullOrWhiteSpace($Port)) { "5432" } else { $Port }
    $safePassword = if ($null -eq $Password) { "" } else { $Password }

    return "postgresql://${Username}`:${safePassword}@${DbHost}`:${safePort}/${Database}?sslmode=${SslMode}"
}

function Resolve-LocalConnection {
    param([string]$ExplicitValue)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitValue)) {
        return Convert-JdbcToPostgresUri -JdbcUrl $ExplicitValue
    }

    if (-not [string]::IsNullOrWhiteSpace($env:LOCAL_DATABASE_URL)) {
        return Convert-JdbcToPostgresUri -JdbcUrl $env:LOCAL_DATABASE_URL
    }

    if (-not [string]::IsNullOrWhiteSpace($env:DATABASE_URL_LOCAL)) {
        return Convert-JdbcToPostgresUri -JdbcUrl $env:DATABASE_URL_LOCAL
    }

    $localDbHost = if ($env:LOCAL_DB_HOST) { $env:LOCAL_DB_HOST } else { "localhost" }
    $localDbPort = if ($env:LOCAL_DB_PORT) { $env:LOCAL_DB_PORT } else { "5432" }
    $localDatabase = if ($env:LOCAL_DB_NAME) { $env:LOCAL_DB_NAME } else { "valuta" }
    $localUsername = if ($env:LOCAL_DB_USERNAME) { $env:LOCAL_DB_USERNAME } else { "valuta_user" }
    $localPassword = if ($env:LOCAL_DB_PASSWORD) { $env:LOCAL_DB_PASSWORD } else { "valuta_pass" }

    return Build-PostgresUri -DbHost $localDbHost -Port $localDbPort -Database $localDatabase -Username $localUsername -Password $localPassword -SslMode "disable"
}

function Resolve-RemoteConnection {
    param([string]$ExplicitValue)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitValue)) {
        return Convert-JdbcToPostgresUri -JdbcUrl $ExplicitValue
    }

    if (-not [string]::IsNullOrWhiteSpace($env:NEON_DATABASE_URL)) {
        return Convert-JdbcToPostgresUri -JdbcUrl $env:NEON_DATABASE_URL
    }

    if (-not [string]::IsNullOrWhiteSpace($env:RENDER_DB_URL_EXTERNAL)) {
        return Convert-JdbcToPostgresUri -JdbcUrl $env:RENDER_DB_URL_EXTERNAL
    }

    if (-not [string]::IsNullOrWhiteSpace($env:DATABASE_URL) -and -not ($env:DATABASE_URL -match 'localhost|127\.0\.0\.1')) {
        return Convert-JdbcToPostgresUri -JdbcUrl $env:DATABASE_URL
    }

    if (-not [string]::IsNullOrWhiteSpace($env:DB_HOST) -and
        -not [string]::IsNullOrWhiteSpace($env:DB_NAME) -and
        -not [string]::IsNullOrWhiteSpace($env:DB_USERNAME)) {
        $remotePort = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
        $remoteSsl = if ($env:DB_SSLMODE) { $env:DB_SSLMODE } else { "require" }
        return Build-PostgresUri -DbHost $env:DB_HOST -Port $remotePort -Database $env:DB_NAME -Username $env:DB_USERNAME -Password $env:DB_PASSWORD -SslMode $remoteSsl
    }

    return $null
}

function Invoke-PsqlLines {
    param(
        [string]$ConnectionString,
        [string]$Sql
    )

    $output = psql "$ConnectionString" -v ON_ERROR_STOP=1 -X -t -A -c "$Sql" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "psql failed: $output"
    }

    $lines = @()
    foreach ($line in ($output -split "`r?`n")) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -gt 0) {
            $lines += $trimmed
        }
    }

    return $lines
}

function Get-VersionedMigrationFiles {
    param([string]$MigrationDir)

    if (!(Test-Path -LiteralPath $MigrationDir)) {
        throw "Migration directory not found: $MigrationDir"
    }

    $versions = New-Object System.Collections.Generic.HashSet[string]

    foreach ($file in (Get-ChildItem -LiteralPath $MigrationDir -File -Filter "V*.sql")) {
        if ($file.Name -match '^V([^_]+(?:_[^_]+)*)__') {
            $version = $matches[1] -replace '_', '.'
            $null = $versions.Add($version)
            continue
        }

        if ($file.Name -match '^V([^.]*)\.sql$') {
            $version = $matches[1] -replace '_', '.'
            $null = $versions.Add($version)
        }
    }

    if ($versions.Count -eq 0) {
        throw "No versioned Flyway migrations found under: $MigrationDir"
    }

    return @($versions)
}

function Get-AppliedVersions {
    param(
        [string]$ConnectionString,
        [string]$TableName,
        [string]$Label
    )

    $existsSql = "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$TableName');"
    $existsLines = Invoke-PsqlLines -ConnectionString $ConnectionString -Sql $existsSql
    $exists = ($existsLines | Select-Object -Last 1)
    if ($exists -ne "t") {
        throw "${Label}: migration table 'public.$TableName' does not exist"
    }

    $failedSql = "SELECT COUNT(*) FROM public.$TableName WHERE success = false;"
    $failedCount = [int](Invoke-PsqlLines -ConnectionString $ConnectionString -Sql $failedSql | Select-Object -Last 1)
    if ($failedCount -gt 0) {
        throw "${Label}: found $failedCount failed migration record(s) in public.$TableName"
    }

    $versionSql = "SELECT version FROM public.$TableName WHERE success = true AND version IS NOT NULL ORDER BY installed_rank;"
    $versionLines = Invoke-PsqlLines -ConnectionString $ConnectionString -Sql $versionSql

    return @($versionLines)
}

Write-Status "Mandatory DB preflight started"

if (-not (Ensure-PsqlAvailable)) {
    Write-Status "psql client not found. Install PostgreSQL client tools first." "ERR"
    exit 1
}

$envPath = Join-Path $RepoRoot ".env"
Import-DotEnv -EnvFile $envPath

$localConn = Resolve-LocalConnection -ExplicitValue $LocalConnectionString
$remoteConn = Resolve-RemoteConnection -ExplicitValue $RemoteConnectionString

if ([string]::IsNullOrWhiteSpace($localConn)) {
    Write-Status "Local DB connection string could not be resolved." "ERR"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($remoteConn)) {
    Write-Status "Remote/Neon DB connection string could not be resolved." "ERR"
    exit 1
}

$migrationDir = Join-Path $RepoRoot "backend\src\main\resources\db\migration"
$expectedVersions = Get-VersionedMigrationFiles -MigrationDir $migrationDir
$expectedVersionSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($v in $expectedVersions) { $null = $expectedVersionSet.Add($v) }

Write-Status "Checking DB reachability and migration history"

try {
    $null = Invoke-PsqlLines -ConnectionString $localConn -Sql "SELECT 1;"
    Write-Status "Local DB connection OK" "OK"
}
catch {
    Write-Status "Local DB connection failed: $($_.Exception.Message)" "ERR"
    exit 1
}

try {
    $null = Invoke-PsqlLines -ConnectionString $remoteConn -Sql "SELECT 1;"
    Write-Status "Remote/Neon DB connection OK" "OK"
}
catch {
    Write-Status "Remote/Neon DB connection failed: $($_.Exception.Message)" "ERR"
    exit 1
}

try {
    $localApplied = Get-AppliedVersions -ConnectionString $localConn -TableName $MigrationTable -Label "Local DB"
    Write-Status "Local DB migration table check OK" "OK"
}
catch {
    Write-Status $_.Exception.Message "ERR"
    exit 1
}

$remoteMode = if ($env:DB_PREFLIGHT_REMOTE_MODE) { $env:DB_PREFLIGHT_REMOTE_MODE.Trim().ToLowerInvariant() } else { "strict" }
$skipRemoteParity = $false
$remoteApplied = @()

try {
    $remoteApplied = Get-AppliedVersions -ConnectionString $remoteConn -TableName $MigrationTable -Label "Remote/Neon DB"
    Write-Status "Remote/Neon DB migration table check OK" "OK"
}
catch {
    $msg = $_.Exception.Message
    if ($remoteMode -eq "optional" -and $msg -match "does not exist") {
        Write-Status "Remote/Neon: nincs Flyway tábla (flyway_schema_history) — optional mód: távoli paritás kihagyva. Éles előtt: flyway migrate + strict mód." "WARN"
        $skipRemoteParity = $true
    }
    else {
        Write-Status $msg "ERR"
        exit 1
    }
}

$localSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($v in $localApplied) { $null = $localSet.Add($v) }

$remoteSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($v in $remoteApplied) { $null = $remoteSet.Add($v) }

$missingInLocal = New-Object System.Collections.Generic.List[string]
$missingInRemote = New-Object System.Collections.Generic.List[string]
$driftOnlyLocal = New-Object System.Collections.Generic.List[string]
$driftOnlyRemote = New-Object System.Collections.Generic.List[string]

foreach ($v in $expectedVersionSet) {
    if (-not $localSet.Contains($v)) { $missingInLocal.Add($v) }
    if (-not $skipRemoteParity) {
        if (-not $remoteSet.Contains($v)) { $missingInRemote.Add($v) }
    }
}

if (-not $skipRemoteParity) {
    foreach ($v in $localSet) {
        if (-not $remoteSet.Contains($v)) { $driftOnlyLocal.Add($v) }
    }

    foreach ($v in $remoteSet) {
        if (-not $localSet.Contains($v)) { $driftOnlyRemote.Add($v) }
    }
}

$hasMismatch = ($missingInLocal.Count -gt 0) -or ($missingInRemote.Count -gt 0) -or ($driftOnlyLocal.Count -gt 0) -or ($driftOnlyRemote.Count -gt 0)

if ($hasMismatch) {
    Write-Status "DB migration parity mismatch detected. Mandatory reconciliation required." "ERR"

    if ($missingInLocal.Count -gt 0) {
        Write-Status ("Missing in local DB: " + (($missingInLocal | Sort-Object) -join ', ')) "ERR"
    }

    if ($missingInRemote.Count -gt 0) {
        Write-Status ("Missing in remote/Neon DB: " + (($missingInRemote | Sort-Object) -join ', ')) "ERR"
    }

    if ($driftOnlyLocal.Count -gt 0) {
        Write-Status ("Present only in local DB history: " + (($driftOnlyLocal | Sort-Object) -join ', ')) "ERR"
    }

    if ($driftOnlyRemote.Count -gt 0) {
        Write-Status ("Present only in remote/Neon DB history: " + (($driftOnlyRemote | Sort-Object) -join ', ')) "ERR"
    }

    Write-Status "Run mandatory migration reconciliation before build/deploy. Example: backend/mvnw flyway:migrate against both DB targets." "WARN"
    exit 1
}

Write-Status ("Versioned migrations in repo: " + $expectedVersionSet.Count) "OK"
Write-Status ("Applied migrations (local): " + $localSet.Count) "OK"
if ($skipRemoteParity) {
    Write-Status "Applied migrations (remote/Neon): (nem ellenőrizve — optional mód)" "WARN"
}
else {
    Write-Status ("Applied migrations (remote/Neon): " + $remoteSet.Count) "OK"
}
Write-Status "Mandatory DB preflight PASSED" "OK"
exit 0
