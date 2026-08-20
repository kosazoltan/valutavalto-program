#!/usr/bin/env pwsh
# pick-local-ports.ps1 — FULL installer local bindable port picker (called by NSIS)
#
# Windows Hyper-V / Docker / WSL WinNAT reserves TCP excludedportrange blocks.
# netstat LISTENING is NOT enough: bind to 54320 can fail with WSAEACCES
# (Permission denied) even when nothing is listening. PostgreSQL then FATAL-s
# with "could not bind IPv4 address 127.0.0.1: Permission denied".
#
# Output (one line, NSIS WordFind):  PGPORT,HTTPPORT
# Compatible with Windows PowerShell 5.1 (no pwsh required).
#
# -DefineOnly: dot-source for tests (no stdout, no exit).

param(
    [switch]$DefineOnly,
    [int]$PreferredPgPort = 54320,
    [int]$PreferredHttpPort = 8080
)

$ErrorActionPreference = 'Stop'

function Get-TcpExcludedPortRangesFromText {
    param([string]$Text)
    $ranges = @()
    if ([string]::IsNullOrEmpty($Text)) { return $ranges }
    foreach ($line in ($Text -split "`r?`n")) {
        if ($line -match '^\s*(\d+)\s+(\d+)\s*\*?') {
            $start = [int]$Matches[1]
            $end = [int]$Matches[2]
            if ($end -ge $start -and $start -gt 0 -and $end -le 65535) {
                $ranges += ,[pscustomobject]@{ Start = $start; End = $end }
            }
        }
    }
    return $ranges
}

function Get-TcpExcludedPortRanges {
    $text = & netsh.exe interface ipv4 show excludedportrange protocol=tcp 2>$null | Out-String
    return Get-TcpExcludedPortRangesFromText -Text $text
}

function Test-PortInExcludedRange {
    param(
        [int]$Port,
        [object[]]$Ranges
    )
    foreach ($r in $Ranges) {
        if ($Port -ge $r.Start -and $Port -le $r.End) { return $true }
    }
    return $false
}

function Test-TcpLoopbackBind {
    param([int]$Port)
    $listener = $null
    try {
        $listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        if ($null -ne $listener) {
            try { $listener.Stop() } catch { }
        }
    }
}

function Select-LocalListenPort {
    param(
        [int]$Preferred,
        [int[]]$Fallbacks,
        [object[]]$ExcludedRanges,
        [scriptblock]$BindProbe = $null
    )
    if ($null -eq $BindProbe) {
        $BindProbe = { param($p) Test-TcpLoopbackBind -Port $p }
    }
    $candidates = @($Preferred)
    if ($null -ne $Fallbacks) { $candidates += $Fallbacks }

    $tryPort = {
        param([int]$port)
        if ($port -lt 1 -or $port -gt 65535) { return $null }
        if (Test-PortInExcludedRange -Port $port -Ranges $ExcludedRanges) { return $null }
        if (& $BindProbe $port) { return [int]$port }
        return $null
    }

    foreach ($port in $candidates) {
        $hit = & $tryPort $port
        if ($null -ne $hit) { return $hit }
    }
    for ($p = 55000; $p -le 55999; $p++) {
        $hit = & $tryPort $p
        if ($null -ne $hit) { return $hit }
    }
    return $null
}

if ($DefineOnly) { return }

$ranges = Get-TcpExcludedPortRanges
$pg = Select-LocalListenPort -Preferred $PreferredPgPort -Fallbacks @(55432, 55532, 64320, 45432) -ExcludedRanges $ranges
$http = Select-LocalListenPort -Preferred $PreferredHttpPort -Fallbacks @(18080, 8081, 8888, 9080) -ExcludedRanges $ranges

if ($null -eq $pg -or $null -eq $http) {
    Write-Error "No bindable loopback port for PostgreSQL/backend (WinNAT excludedportrange)."
    exit 1
}

Write-Output ("{0},{1}" -f $pg, $http)
exit 0
