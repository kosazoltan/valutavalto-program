#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$ChildMode,

    [ValidateRange(1, 65535)]
    [int]$Port,

    [string]$EvidencePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$ViteEntryPoint = Join-Path $ProjectRoot 'frontend-react\node_modules\vite\bin\vite.js'
$FrontendRoot = Join-Path $ProjectRoot 'frontend-react'

if ($ChildMode) {
    if ($Port -le 0 -or [string]::IsNullOrWhiteSpace($EvidencePath)) {
        throw 'ChildMode eseten a Port es EvidencePath parameter kotelezo.'
    }
    if (-not (Test-Path -LiteralPath $ViteEntryPoint -PathType Leaf)) {
        throw "A Vite entrypoint nem talalhato: $ViteEntryPoint"
    }

    $NodeExecutable = (Get-Command node.exe -ErrorAction Stop).Source
    $ViteProcess = Start-Process `
        -FilePath $NodeExecutable `
        -ArgumentList @(
            $ViteEntryPoint,
            '--host',
            '127.0.0.1',
            '--port',
            [string]$Port,
            '--strictPort'
        ) `
        -WorkingDirectory $FrontendRoot `
        -WindowStyle Hidden `
        -PassThru
    try {
        $ViteIdentity = Get-CimInstance `
            -ClassName Win32_Process `
            -Filter "ProcessId = $($ViteProcess.Id)"
    }
    catch {
        if (-not $ViteProcess.HasExited) {
            $ViteProcess.Kill($true)
            $ViteProcess.WaitForExit()
        }
        throw
    }
    [pscustomobject]@{
        RootProcessId = $PID
        ViteProcessId = $ViteProcess.Id
        ViteCreationDate = [string]$ViteIdentity.CreationDate
        Port = $Port
    } | ConvertTo-Json -Compress | Set-Content -LiteralPath $EvidencePath -Encoding utf8
    exit 0
}

$FunctionsPath = Join-Path $PSScriptRoot 'stop-owned-dev-processes.functions.ps1'
. $FunctionsPath

try {
    $null = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $PID"
}
catch {
    throw "A runtime regresszio biztonsagos futtatasa nem lehetseges, mert a Win32_Process CIM lekerdezes nem elerheto: $($_.Exception.Message)"
}

$PortProbe = [System.Net.Sockets.TcpListener]::new(
    [System.Net.IPAddress]::Loopback,
    0
)
$PortProbe.Start()
$RuntimePort = ([System.Net.IPEndPoint]$PortProbe.LocalEndpoint).Port
$PortProbe.Stop()

$EvidenceFile = Join-Path `
    ([System.IO.Path]::GetTempPath()) `
    "s4a-vite-runtime-$([guid]::NewGuid().ToString('N')).json"
$RootProcess = $null
$RuntimeEvidence = $null

try {
    $RootStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $RootStartInfo.FileName = (Get-Command pwsh.exe -ErrorAction Stop).Source
    $RootStartInfo.UseShellExecute = $false
    $RootStartInfo.CreateNoWindow = $true
    foreach ($Argument in @(
        '-NoProfile',
        '-File',
        $PSCommandPath,
        '-ChildMode',
        '-Port',
        [string]$RuntimePort,
        '-EvidencePath',
        $EvidenceFile
    )) {
        [void]$RootStartInfo.ArgumentList.Add($Argument)
    }
    $RootProcess = [System.Diagnostics.Process]::Start($RootStartInfo)
    if (-not $RootProcess.WaitForExit(15000)) {
        throw "A disposable root processz nem lepett ki idoben: $($RootProcess.Id)."
    }
    if ($RootProcess.ExitCode -ne 0) {
        throw "A disposable root processz hibaval tert vissza: $($RootProcess.ExitCode)."
    }
    if (-not (Test-Path -LiteralPath $EvidenceFile -PathType Leaf)) {
        throw 'A disposable root processz nem irt runtime evidenciat.'
    }
    $RuntimeEvidence = Get-Content -Raw -LiteralPath $EvidenceFile | ConvertFrom-Json

    $ListenerSeen = $false
    for ($Attempt = 0; $Attempt -lt 50; $Attempt++) {
        $ListenerIds = @(Get-ListeningProcessIds `
            -NetstatLines @(Get-NetstatLines) `
            -Port $RuntimePort)
        if ($ListenerIds -contains [int]$RuntimeEvidence.ViteProcessId) {
            $ListenerSeen = $true
            break
        }
        Start-Sleep -Milliseconds 100
    }
    if (-not $ListenerSeen) {
        throw "A disposable Vite processz nem kezdett LISTENING allapotba: PID $($RuntimeEvidence.ViteProcessId), port $RuntimePort."
    }

    Invoke-OwnedDevProcessCleanup `
        -RootProcessId ([int]$RuntimeEvidence.RootProcessId) `
        -Port $RuntimePort

    $RemainingListenerIds = @(Get-ListeningProcessIds `
        -NetstatLines @(Get-NetstatLines) `
        -Port $RuntimePort)
    if ($RemainingListenerIds.Count -ne 0) {
        throw "A runtime regresszio utan a disposable port LISTENING maradt: $RuntimePort."
    }

    [pscustomobject]@{
        Result = 'PASS'
        DeadRootProcessId = [int]$RuntimeEvidence.RootProcessId
        ReparentedViteProcessId = [int]$RuntimeEvidence.ViteProcessId
        Port = $RuntimePort
        PortReleased = $true
    } | ConvertTo-Json -Compress
}
finally {
    if ($null -ne $RuntimeEvidence) {
        $RemainingVite = Get-ProcessById -ProcessId ([int]$RuntimeEvidence.ViteProcessId)
        if ($null -ne $RemainingVite -and
            [string]$RemainingVite.CreationDate -eq [string]$RuntimeEvidence.ViteCreationDate) {
            Stop-Process -Id ([int]$RuntimeEvidence.ViteProcessId) -Force -ErrorAction Stop
        }
    }
    if (Test-Path -LiteralPath $EvidenceFile -PathType Leaf) {
        Remove-Item -LiteralPath $EvidenceFile -Force
    }
}
