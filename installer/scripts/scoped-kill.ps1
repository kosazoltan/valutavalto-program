# ==============================================================================
# Valutavalto Penztar Installer Helper — scoped-kill.ps1
# ==============================================================================
# Cel: A `-like` operator inline NSIS-be agyazasa toredezett quoting miatt
# Setup #1+#2 sessions soran "ParserError: ExpectedValueExpression" hibat dobott.
# Ez a helper PS1 fajl elkerul minden NSIS escaping problemat: a NSIS sima
# `-File <path> -Name postgres` argumentumokkal hivja, semmilyen single-quote /
# double-quote / dollar-jel konfliktus nincs.
#
# Mukodes: csak a megadott process-name + path-szuro szerinti folyamatokat oli meg.
# Path-szuro alapertelmezett: 'BestChange' (a lokalis ProgramData-szel kezdodo
# Penztar-os PostgreSQL es Backend folyamatokat csak).
#
# 2026-04-29 — bevezetve a v2.3.8 NSIS bug fix-ben.
# ==============================================================================

[CmdletBinding()]
param(
    # Process name (postgres, java, stb.) - .exe NELKUL
    [Parameter(Mandatory = $true)]
    [string]$Name,

    # Path-substring szuro (alapertelmezetten 'BestChange')
    [string]$PathFilter = 'BestChange',

    # Csak ellenorzes (true) vagy oles (false, alapertelmezett)
    [switch]$CheckOnly
)

$ErrorActionPreference = 'SilentlyContinue'

try {
    $procs = Get-Process -Name $Name -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path -like "*$PathFilter*" }

    if (-not $procs -or @($procs).Count -eq 0) {
        Write-Output "scoped-kill: $Name (filter='$PathFilter') - 0 process found"
        exit 0
    }

    if ($CheckOnly) {
        Write-Output "scoped-kill: $Name (filter='$PathFilter') - $(@($procs).Count) process(es) running"
        exit 1
    }

    foreach ($p in $procs) {
        Write-Output "scoped-kill: stopping PID=$($p.Id) Path=$($p.Path)"
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
    exit 0
}
catch {
    Write-Output "scoped-kill: ERROR - $($_.Exception.Message)"
    exit 2
}
