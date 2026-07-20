#Requires -Version 5.1
<#
.SYNOPSIS
  Explicit, sajat tulajdonu Windows dev processzfak biztonsagos leallitasa.

.DESCRIPTION
  Kizarolag a -ProcessId parameterben megadott gyokerfolyamatokat es azok
  leszarmazottait vizsgalja. Minden folyamatnak a jelenlegi Windows felhasznalo
  tulajdonaban kell lennie; elteresnel a script barminemu leallitas elott hibaval
  kilep. A portok csak utolagos netstat-bizonyitekra szolgalnak, port alapjan a
  script soha nem valaszt ki es nem allit le folyamatot.

.PARAMETER ProcessId
  Egy vagy tobb, a hivo altal explicit megadott processzazonosito.

.PARAMETER DevPort
  A leallitas utan netstat-tal ellenorzendo TCP listen portok.

.PARAMETER DryRun
  Validalja es kiirja a processzfat, de nem allit le folyamatot.

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
    scripts/dev-tools/stop-owned-dev-processes.ps1 -ProcessId 12340 -DevPort 3000,5173 -DryRun

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
    scripts/dev-tools/stop-owned-dev-processes.ps1 -ProcessId 12340 -DevPort 3000,5173
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int[]]$ProcessId,

    [ValidateRange(1, 65535)]
    [int[]]$DevPort = @(),

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$FunctionsPath = Join-Path $PSScriptRoot 'stop-owned-dev-processes.functions.ps1'
. $FunctionsPath

Invoke-OwnedDevProcessCleanup -RootProcessId $ProcessId -Port $DevPort -WhatIfOnly:$DryRun
