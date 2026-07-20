function Get-CurrentOwnerName {
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

function Get-ProcessOwnerName {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Process
    )

    $Owner = Invoke-CimMethod -InputObject $Process -MethodName GetOwner
    if ($Owner.ReturnValue -ne 0 -or [string]::IsNullOrWhiteSpace($Owner.User)) {
        throw "Nem allapithato meg a(z) $($Process.ProcessId) PID tulajdonosa."
    }

    if ([string]::IsNullOrWhiteSpace($Owner.Domain)) {
        return $Owner.User
    }
    return "$($Owner.Domain)\$($Owner.User)"
}

function Get-ProcessSnapshot {
    return @(Get-CimInstance -ClassName Win32_Process)
}

function Get-ProcessById {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    return Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $ProcessId"
}

function Test-SameProcessIdentity {
    param(
        [Parameter(Mandatory = $true)]
        [object]$SnapshotProcess,

        [Parameter(Mandatory = $true)]
        [object]$CurrentProcess
    )

    foreach ($PropertyName in @('CreationDate', 'ExecutablePath', 'ParentProcessId')) {
        $SnapshotProperty = $SnapshotProcess.PSObject.Properties[$PropertyName]
        $CurrentProperty = $CurrentProcess.PSObject.Properties[$PropertyName]
        if ($null -eq $SnapshotProperty -and $null -eq $CurrentProperty) {
            continue
        }
        if ($null -eq $SnapshotProperty -or $null -eq $CurrentProperty) {
            return $false
        }

        if ($PropertyName -eq 'ExecutablePath') {
            if (-not [string]::Equals(
                [string]$SnapshotProperty.Value,
                [string]$CurrentProperty.Value,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                return $false
            }
            continue
        }

        if ($SnapshotProperty.Value -ne $CurrentProperty.Value) {
            return $false
        }
    }

    return $true
}

function Assert-SafeRootProcessId {
    param(
        [Parameter(Mandatory = $true)]
        [int]$RootProcessId,

        [Parameter(Mandatory = $true)]
        [object[]]$ProcessSnapshot
    )

    if ($RootProcessId -le 4 -or $RootProcessId -eq $PID) {
        throw "Tiltott vagy veszelyes processzazonosito: $RootProcessId."
    }

    $Cursor = $ProcessSnapshot |
        Where-Object { [int]$_.ProcessId -eq $PID } |
        Select-Object -First 1
    if ($null -eq $Cursor) {
        throw "A cleanup processz sajat PID-je hianyzik a CIM snapshotbol: $PID."
    }

    $AncestorIds = [System.Collections.Generic.HashSet[int]]::new()
    $ResolvedAncestorCount = 0
    while ([int]$Cursor.ParentProcessId -gt 0) {
        $ParentId = [int]$Cursor.ParentProcessId
        if (-not $AncestorIds.Add($ParentId)) {
            throw "Ciklikus hivo-oslanc eszlelve a CIM snapshotban: $ParentId."
        }
        $Parent = $ProcessSnapshot |
            Where-Object { [int]$_.ProcessId -eq $ParentId } |
            Select-Object -First 1
        if ($null -eq $Parent) {
            if ($ResolvedAncestorCount -gt 0) {
                break
            }
            throw "A hivo processz oslanca nem ellenorizheto: a(z) $ParentId PID hianyzik a CIM snapshotbol."
        }
        $Cursor = $Parent
        $ResolvedAncestorCount++
    }

    if ($AncestorIds.Contains($RootProcessId)) {
        throw "A hivo processz ose nem allithato le: $RootProcessId."
    }
}

function Get-ExplicitProcessTree {
    param(
        [Parameter(Mandatory = $true)]
        [int[]]$RootProcessId,

        [Parameter(Mandatory = $true)]
        [object[]]$ProcessSnapshot
    )

    $Selected = @{}
    $Queue = [System.Collections.Generic.Queue[object]]::new()

    foreach ($RootId in $RootProcessId) {
        Assert-SafeRootProcessId -RootProcessId $RootId -ProcessSnapshot $ProcessSnapshot
        $Root = $ProcessSnapshot |
            Where-Object { [int]$_.ProcessId -eq $RootId } |
            Select-Object -First 1
        if ($null -eq $Root) {
            Write-Warning "A megadott processz mar nem letezik, kihagyva: $RootId."
            continue
        }
        $Queue.Enqueue([pscustomobject]@{ Process = $Root; Depth = 0 })
    }

    while ($Queue.Count -gt 0) {
        $Item = $Queue.Dequeue()
        $ItemProcessId = [int]$Item.Process.ProcessId
        if ($Selected.ContainsKey($ItemProcessId)) {
            continue
        }
        $Selected[$ItemProcessId] = $Item

        foreach ($Child in $ProcessSnapshot | Where-Object {
            [int]$_.ParentProcessId -eq $ItemProcessId
        }) {
            $Queue.Enqueue([pscustomobject]@{ Process = $Child; Depth = $Item.Depth + 1 })
        }
    }

    return @($Selected.Values)
}

function Get-NewDescendantProcessTree {
    param(
        [Parameter(Mandatory = $true)]
        [int[]]$RootProcessId,

        [Parameter(Mandatory = $true)]
        [object[]]$ProcessSnapshot,

        [Parameter(Mandatory = $true)]
        [hashtable]$KnownProcessCreationDate
    )

    foreach ($RootId in $RootProcessId) {
        Assert-SafeRootProcessId -RootProcessId $RootId -ProcessSnapshot $ProcessSnapshot
    }

    $ReachableDepth = @{}
    foreach ($KnownId in $KnownProcessCreationDate.Keys) {
        $CurrentKnownProcess = $ProcessSnapshot |
            Where-Object { [int]$_.ProcessId -eq [int]$KnownId } |
            Select-Object -First 1
        if ($null -eq $CurrentKnownProcess -or
            $CurrentKnownProcess.CreationDate -eq $KnownProcessCreationDate[$KnownId]) {
            $ReachableDepth[[int]$KnownId] = -1
        }
    }

    $Selected = @{}
    $AddedProcess = $true
    while ($AddedProcess) {
        $AddedProcess = $false
        foreach ($Candidate in $ProcessSnapshot) {
            $CandidateId = [int]$Candidate.ProcessId
            $ParentId = [int]$Candidate.ParentProcessId
            if ($KnownProcessCreationDate.ContainsKey($CandidateId) -or
                $Selected.ContainsKey($CandidateId) -or
                -not $ReachableDepth.ContainsKey($ParentId)) {
                continue
            }

            $Depth = [int]$ReachableDepth[$ParentId] + 1
            $Selected[$CandidateId] = [pscustomobject]@{ Process = $Candidate; Depth = $Depth }
            $ReachableDepth[$CandidateId] = $Depth
            $AddedProcess = $true
        }
    }

    return @($Selected.Values)
}

function Invoke-NetstatCommand {
    $Lines = @(& netstat.exe -ano -p TCP)
    return [pscustomobject]@{
        Lines = $Lines
        ExitCode = [int]$LASTEXITCODE
    }
}

function Get-NetstatLines {
    $Result = Invoke-NetstatCommand
    if ($Result.ExitCode -ne 0) {
        throw "A netstat.exe hibaval tert vissza (exit code: $($Result.ExitCode)); a portbizonyitas sikertelen."
    }
    return @($Result.Lines)
}

function Get-ListeningProcessIds {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$NetstatLines,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [int]$Port
    )

    $ProcessIds = [System.Collections.Generic.HashSet[int]]::new()
    $ListeningPattern = "^\s*TCP\s+\S+:$Port\s+\S+\s+LISTENING\s+(\d+)\s*$"
    foreach ($Line in $NetstatLines) {
        if ($Line -match $ListeningPattern) {
            [void]$ProcessIds.Add([int]$Matches[1])
        }
    }
    return @($ProcessIds)
}

function Get-DevProjectRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}

function Test-ExpectedViteProcess {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Process,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $ExecutablePath = [string]$Process.ExecutablePath
    $CommandLine = [string]$Process.CommandLine
    if ([string]::IsNullOrWhiteSpace($ExecutablePath) -or
        [string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    if (-not [string]::Equals(
        [System.IO.Path]::GetFileName($ExecutablePath),
        'node.exe',
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        return $false
    }

    $NormalizedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
    $ProjectRootPrefix = "$NormalizedProjectRoot\"
    $CommandLineTokens = [regex]::Matches($CommandLine, '(?:"([^"]*)"|''([^'']*)''|(\S+))')
    foreach ($TokenMatch in $CommandLineTokens) {
        $Token = if ($TokenMatch.Groups[1].Success) {
            $TokenMatch.Groups[1].Value
        }
        elseif ($TokenMatch.Groups[2].Success) {
            $TokenMatch.Groups[2].Value
        }
        else {
            $TokenMatch.Groups[3].Value
        }
        if ($Token -notmatch '[\\/]node_modules[\\/](?:\.bin[\\/]\.\.[\\/])?vite[\\/]bin[\\/]vite\.js$') {
            continue
        }

        try {
            $ResolvedViteEntryPoint = [System.IO.Path]::GetFullPath($Token)
        }
        catch {
            continue
        }
        if ($ResolvedViteEntryPoint.StartsWith(
            $ProjectRootPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            return $true
        }
    }

    return $false
}

function Stop-ProvenDevPortListeners {
    param(
        [int[]]$Port = @(),

        [Parameter(Mandatory = $true)]
        [string]$ExpectedOwner,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    if ($Port.Count -eq 0) {
        return $false
    }

    $RequiresFinalProof = $false
    $Lines = @(Get-NetstatLines)
    foreach ($CurrentPort in $Port) {
        $ListenerProcessIds = @(Get-ListeningProcessIds -NetstatLines $Lines -Port $CurrentPort)
        if ($ListenerProcessIds.Count -eq 0) {
            Write-Host "netstat proof: TCP $CurrentPort porton nincs LISTENING folyamat."
            continue
        }
        $RequiresFinalProof = $true
        foreach ($ListenerProcessId in $ListenerProcessIds) {
            $Snapshot = @(Get-ProcessSnapshot)
            Assert-SafeRootProcessId `
                -RootProcessId $ListenerProcessId `
                -ProcessSnapshot $Snapshot
            $ListenerProcess = $Snapshot |
                Where-Object { [int]$_.ProcessId -eq $ListenerProcessId } |
                Select-Object -First 1
            if ($null -eq $ListenerProcess) {
                continue
            }

            try {
                $ActualOwner = Get-ProcessOwnerName -Process $ListenerProcess
            }
            catch {
                throw "A(z) $CurrentPort TCP port tovabbra is LISTENING allapotu: PID $ListenerProcessId; a tulajdonos nem bizonyithato."
            }
            $OwnerMatches = [string]::Equals(
                $ActualOwner,
                $ExpectedOwner,
                [System.StringComparison]::OrdinalIgnoreCase
            )
            $ExpectedViteProcess = Test-ExpectedViteProcess `
                -Process $ListenerProcess `
                -ProjectRoot $ProjectRoot
            if (-not $OwnerMatches -or -not $ExpectedViteProcess) {
                Write-Warning "A(z) $CurrentPort port $ListenerProcessId PID-je nem bizonyitott sajat worktree Vite processz; nem lesz leallitva."
                throw "A(z) $CurrentPort TCP port tovabbra is LISTENING allapotu: PID $ListenerProcessId."
            }

            $ListenerTree = @([pscustomobject]@{
                Process = $ListenerProcess
                Depth = 0
            })
            try {
                Stop-OwnedProcessTree `
                    -ProcessTree $ListenerTree `
                    -ExpectedOwner $ExpectedOwner
            }
            catch {
                throw "A(z) $CurrentPort TCP port tovabbra is LISTENING allapotu: PID $ListenerProcessId; a kill-time identitasbizonyitas sikertelen. $($_.Exception.Message)"
            }
        }
    }
    return $RequiresFinalProof
}

function Assert-DevPortsReleased {
    param(
        [int[]]$Port = @()
    )

    if ($Port.Count -eq 0) {
        return
    }

    $Lines = @(Get-NetstatLines)
    foreach ($CurrentPort in $Port) {
        $ListeningPattern = ":$CurrentPort\s+.*\s+LISTENING\s+\d+\s*$"
        $Listener = $Lines | Where-Object { $_ -match $ListeningPattern } | Select-Object -First 1
        if ($null -ne $Listener) {
            throw "A(z) $CurrentPort TCP port tovabbra is LISTENING allapotu: $($Listener.Trim())"
        }
        Write-Host "netstat proof: TCP $CurrentPort porton nincs LISTENING folyamat."
    }
}

function Assert-OwnedProcessTree {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ProcessTree,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedOwner
    )

    $OwnedLiveProcessTree = [System.Collections.Generic.List[object]]::new()
    foreach ($Item in $ProcessTree) {
        try {
            $ActualOwner = Get-ProcessOwnerName -Process $Item.Process
        }
        catch {
            $SnapshotProcess = $Item.Process
            $ProcessId = [int]$SnapshotProcess.ProcessId
            $CurrentProcess = Get-ProcessById -ProcessId $ProcessId
            if ($null -eq $CurrentProcess) {
                continue
            }
            if (-not (Test-SameProcessIdentity `
                -SnapshotProcess $SnapshotProcess `
                -CurrentProcess $CurrentProcess)) {
                throw "PID-identitas valtozott a tulajdonos-ellenorzes kozben, leallitas megtagadva: $ProcessId."
            }
            throw "A(z) $ProcessId PID tulajdonosa nem ellenorizheto; leallitas megtagadva."
        }
        if (-not [string]::Equals(
            $ActualOwner,
            $ExpectedOwner,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Idegen tulajdonu processz a faban: PID $($Item.Process.ProcessId), tulajdonos: $ActualOwner."
        }
        [void]$OwnedLiveProcessTree.Add($Item)
    }

    return @($OwnedLiveProcessTree)
}

function Stop-OwnedProcessTree {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ProcessTree,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedOwner
    )

    $OwnedLiveProcessTree = @(Assert-OwnedProcessTree `
        -ProcessTree $ProcessTree `
        -ExpectedOwner $ExpectedOwner)
    foreach ($Item in @($OwnedLiveProcessTree | Sort-Object -Property Depth -Descending)) {
        $Target = $Item.Process
        $Current = Get-ProcessById -ProcessId ([int]$Target.ProcessId)
        if ($null -eq $Current) {
            continue
        }
        if ($Current.CreationDate -ne $Target.CreationDate) {
            throw "PID ujrahasznositas eszlelve, leallitas megtagadva: $($Target.ProcessId)."
        }
        try {
            $CurrentOwner = Get-ProcessOwnerName -Process $Current
        }
        catch {
            $CurrentAfterOwnerFailure = Get-ProcessById -ProcessId ([int]$Target.ProcessId)
            if ($null -eq $CurrentAfterOwnerFailure) {
                continue
            }
            if (-not (Test-SameProcessIdentity `
                -SnapshotProcess $Current `
                -CurrentProcess $CurrentAfterOwnerFailure)) {
                throw "PID-identitas valtozott a leallitasi tulajdonos-ellenorzes kozben, leallitas megtagadva: $($Target.ProcessId)."
            }
            throw "A(z) $($Target.ProcessId) PID tulajdonosa nem ellenorizheto a leallitas elott; leallitas megtagadva."
        }
        if (-not [string]::Equals(
            $CurrentOwner,
            $ExpectedOwner,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Tulajdonosvaltas eszlelve, leallitas megtagadva: PID $($Target.ProcessId)."
        }
        Stop-Process -Id ([int]$Target.ProcessId) -Force -ErrorAction Stop
        Write-Host "Leallitva: PID $($Target.ProcessId)."
    }
}

function Invoke-OwnedDevProcessCleanup {
    param(
        [Parameter(Mandatory = $true)]
        [int[]]$RootProcessId,

        [int[]]$Port = @(),

        [switch]$WhatIfOnly
    )

    if ($RootProcessId.Count -eq 0) {
        throw 'Legalabb egy explicit ProcessId megadasa kotelezo.'
    }
    foreach ($RootId in $RootProcessId) {
        if ($RootId -le 4 -or $RootId -eq $PID) {
            throw "Tiltott vagy veszelyes processzazonosito: $RootId."
        }
    }

    $Snapshot = @(Get-ProcessSnapshot)
    $Tree = @(Get-ExplicitProcessTree -RootProcessId $RootProcessId -ProcessSnapshot $Snapshot)
    $ExpectedOwner = Get-CurrentOwnerName
    if ($Tree.Count -gt 0) {
        $Tree = @(Assert-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner $ExpectedOwner)
    }

    if ($WhatIfOnly) {
        foreach ($Item in @($Tree | Sort-Object -Property Depth -Descending)) {
            Write-Host "DRY-RUN: sajat processz lenne leallitva: PID $($Item.Process.ProcessId)."
        }
        return
    }

    $KnownProcessCreationDate = @{}
    foreach ($Item in $Tree) {
        $KnownProcessCreationDate[[int]$Item.Process.ProcessId] = $Item.Process.CreationDate
    }
    if ($Tree.Count -gt 0) {
        Stop-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner $ExpectedOwner
    }

    $MaximumRescanCount = 2
    for ($RescanIndex = 0; $RescanIndex -lt $MaximumRescanCount; $RescanIndex++) {
        $RescanSnapshot = @(Get-ProcessSnapshot)
        $NewTree = @(Get-NewDescendantProcessTree `
            -RootProcessId $RootProcessId `
            -ProcessSnapshot $RescanSnapshot `
            -KnownProcessCreationDate $KnownProcessCreationDate)
        if ($NewTree.Count -eq 0) {
            break
        }

        $NewTree = @(Assert-OwnedProcessTree `
            -ProcessTree $NewTree `
            -ExpectedOwner $ExpectedOwner)
        foreach ($Item in $NewTree) {
            $KnownProcessCreationDate[[int]$Item.Process.ProcessId] = $Item.Process.CreationDate
        }
        Stop-OwnedProcessTree -ProcessTree $NewTree -ExpectedOwner $ExpectedOwner
    }

    $RequiresFinalPortProof = Stop-ProvenDevPortListeners `
        -Port $Port `
        -ExpectedOwner $ExpectedOwner `
        -ProjectRoot (Get-DevProjectRoot)
    if ($RequiresFinalPortProof) {
        Assert-DevPortsReleased -Port $Port
    }
}
