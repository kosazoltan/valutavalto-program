Describe 'stop-owned-dev-processes contract' {
    BeforeAll {
        $FunctionsPath = Join-Path $PSScriptRoot 'stop-owned-dev-processes.functions.ps1'
        . $FunctionsPath

        function New-TestSelfProcess {
            return [pscustomobject]@{
                ProcessId = $PID
                ParentProcessId = 0
                CreationDate = '20260719175900.000000+120'
                TestOwner = 'Developer'
            }
        }
    }

    BeforeEach {
        Mock Get-CurrentOwnerName { 'TEST\Developer' }
        Mock Get-ProcessOwnerName { "TEST\$($Process.TestOwner)" }
        Mock Stop-Process {}
        Mock Get-NetstatLines { @() }
    }

    It 'dry-runban validalja a sajat explicit processzfat, de nem allit le processzt' {
        $Root = [pscustomobject]@{
            ProcessId = 500
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $Child = [pscustomobject]@{
            ProcessId = 501
            ParentProcessId = 500
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }
        $Self = New-TestSelfProcess
        Mock Get-ProcessSnapshot { @($Self, $Root, $Child) }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 500 -Port 3000 -WhatIfOnly } | Should -Not -Throw
        Assert-MockCalled Stop-Process -Times 0
        Assert-MockCalled Get-NetstatLines -Times 0
    }

    It 'idegen tulajdonu leszarmazottnal fail-closed es semmit nem allit le' {
        $Root = [pscustomobject]@{
            ProcessId = 600
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $ForeignChild = [pscustomobject]@{
            ProcessId = 601
            ParentProcessId = 600
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'OtherUser'
        }
        $Self = New-TestSelfProcess
        Mock Get-ProcessSnapshot { @($Self, $Root, $ForeignChild) }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 600 } | Should -Throw
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'tiltott PID-et fail-closed elutasit' {
        Mock Get-ProcessSnapshot { @() }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 4 } | Should -Throw
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'ures PID-listat fail-closed elutasit' {
        Mock Get-ProcessSnapshot { @() }

        { Invoke-OwnedDevProcessCleanup -RootProcessId @() } | Should -Throw
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'leallitas utan netstat proofot futtat a megadott dev portokra' {
        $Root = [pscustomobject]@{
            ProcessId = 700
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $Child = [pscustomobject]@{
            ProcessId = 701
            ParentProcessId = 700
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }
        $Self = New-TestSelfProcess
        Mock Get-ProcessSnapshot { @($Self, $Root, $Child) }
        Mock Get-ProcessById {
            return @($Root, $Child) | Where-Object { $_.ProcessId -eq $ProcessId }
        }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 700 -Port 3000, 5173 } | Should -Not -Throw
        Assert-MockCalled Stop-Process -Times 2
        Assert-MockCalled Get-NetstatLines -Times 1
    }

    It 'LISTENING dev port eseten a netstat proof fail-closed' {
        Mock Get-NetstatLines {
            '  TCP    0.0.0.0:3000    0.0.0.0:0    LISTENING    9999'
        }

        { Assert-DevPortsReleased -Port 3000 } | Should -Throw
    }

    It 'fail-closed ha a CIM snapshotbol hianyzik a cleanup sajat PID-je' {
        $Root = [pscustomobject]@{
            ProcessId = 710
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }

        { Assert-SafeRootProcessId -RootProcessId 710 -ProcessSnapshot @($Root) } | Should -Throw
    }

    It 'blokkolja a snapshotban igazolt hivo-ost' {
        $Ancestor = [pscustomobject]@{
            ProcessId = 720
            ParentProcessId = 0
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $Self = [pscustomobject]@{
            ProcessId = $PID
            ParentProcessId = 720
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }

        { Assert-SafeRootProcessId -RootProcessId 720 -ProcessSnapshot @($Ancestor, $Self) } |
            Should -Throw
    }

    It 'biztonsagosan lezarja a bejarast ha egy tavoli szulo mar nincs a snapshotban' {
        $LiveParent = [pscustomobject]@{
            ProcessId = 721
            ParentProcessId = 722
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $Self = [pscustomobject]@{
            ProcessId = $PID
            ParentProcessId = $LiveParent.ProcessId
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }

        { Assert-SafeRootProcessId -RootProcessId 799 -ProcessSnapshot @($LiveParent, $Self) } |
            Should -Not -Throw
    }

    It 'a snapshotbol mar hianyzo, de az elerheto oslancban latott PID-et is blokkolja' {
        $LiveParent = [pscustomobject]@{
            ProcessId = 723
            ParentProcessId = 724
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $Self = [pscustomobject]@{
            ProcessId = $PID
            ParentProcessId = $LiveParent.ProcessId
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }

        { Assert-SafeRootProcessId -RootProcessId 724 -ProcessSnapshot @($LiveParent, $Self) } |
            Should -Throw
    }

    It 'fail-closed ha a hivo oslancabol hianyzik egy nem nulla koztes szulo' {
        $HigherRoot = [pscustomobject]@{
            ProcessId = 725
            ParentProcessId = 0
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $MissingIntermediate = [pscustomobject]@{
            ProcessId = 724
            ParentProcessId = $HigherRoot.ProcessId
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }
        $Self = [pscustomobject]@{
            ProcessId = $PID
            ParentProcessId = $MissingIntermediate.ProcessId
            CreationDate = '20260719180002.000000+120'
            TestOwner = 'Developer'
        }

        { Assert-SafeRootProcessId -RootProcessId 725 -ProcessSnapshot @($HigherRoot, $Self) } |
            Should -Throw '*724 PID hianyzik a CIM snapshotbol*'
    }

    It 'a sajat PID-et explicit gyokerkent is fail-closed elutasitja' {
        $Self = New-TestSelfProcess

        { Assert-SafeRootProcessId -RootProcessId $PID -ProcessSnapshot @($Self) } |
            Should -Throw
    }

    It 'engedelyezi a sajat tulajdonu nem-os explicit gyokeret' {
        $Root = [pscustomobject]@{
            ProcessId = 730
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $Self = New-TestSelfProcess
        Mock Get-ProcessSnapshot { @($Self, $Root) }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 730 -WhatIfOnly } | Should -Not -Throw
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'az ujraszkenneleskor megjeleno sajat gyermeket is leallitja, de az idegen agat nem' {
        $Root = [pscustomobject]@{
            ProcessId = 800
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $NewChild = [pscustomobject]@{
            ProcessId = 801
            ParentProcessId = 800
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }
        $Unrelated = [pscustomobject]@{
            ProcessId = 899
            ParentProcessId = 42
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }
        $Self = New-TestSelfProcess
        $script:SnapshotCall = 0
        $script:Events = @()
        Mock Get-ProcessSnapshot {
            $script:SnapshotCall++
            if ($script:SnapshotCall -eq 1) {
                return @($Self, $Root)
            }
            return @($Self, $NewChild, $Unrelated)
        }
        Mock Get-ProcessById {
            return @($Root, $NewChild, $Unrelated) |
                Where-Object { $_.ProcessId -eq $ProcessId }
        }
        Mock Stop-Process { $script:Events += "stop:$Id" }
        Mock Get-NetstatLines {
            $script:Events += 'port-proof'
            return @()
        }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 800 -Port 3000 } | Should -Not -Throw
        Assert-MockCalled Stop-Process -Times 1 -ParameterFilter { $Id -eq 801 }
        Assert-MockCalled Stop-Process -Times 0 -ParameterFilter { $Id -eq 899 }
        $script:Events[-1] | Should -Be 'port-proof'
    }

    It 'legfeljebb ket ujraszkenneles utan determinisztikusan befejezodik' {
        $Root = [pscustomobject]@{
            ProcessId = 900
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            TestOwner = 'Developer'
        }
        $FirstLateChild = [pscustomobject]@{
            ProcessId = 901
            ParentProcessId = 900
            CreationDate = '20260719180001.000000+120'
            TestOwner = 'Developer'
        }
        $SecondLateChild = [pscustomobject]@{
            ProcessId = 902
            ParentProcessId = 901
            CreationDate = '20260719180002.000000+120'
            TestOwner = 'Developer'
        }
        $Self = New-TestSelfProcess
        $script:SnapshotCall = 0
        Mock Get-ProcessSnapshot {
            $script:SnapshotCall++
            switch ($script:SnapshotCall) {
                1 { return @($Self, $Root) }
                2 { return @($Self, $FirstLateChild) }
                default { return @($Self, $SecondLateChild) }
            }
        }
        Mock Get-ProcessById {
            return @($Root, $FirstLateChild, $SecondLateChild) |
                Where-Object { $_.ProcessId -eq $ProcessId }
        }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 900 -Port 3000 } | Should -Not -Throw
        Assert-MockCalled Get-ProcessSnapshot -Times 3
        Assert-MockCalled Stop-Process -Times 3
        Assert-MockCalled Get-NetstatLines -Times 1
    }

    It 'kihagyja a snapshot es a GetOwner kozott eltunt processzt' {
        $Vanished = [pscustomobject]@{
            ProcessId = 1000
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            ExecutablePath = 'C:\dev\vanished.exe'
            TestOwner = 'Developer'
        }
        $Tree = @([pscustomobject]@{ Process = $Vanished; Depth = 0 })
        Mock Get-ProcessOwnerName { throw 'HRESULT 0x80041002 Not found' }
        Mock Get-ProcessById { return $null }

        { Stop-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner 'TEST\Developer' } |
            Should -Not -Throw
        Assert-MockCalled Get-ProcessById -Times 1 -Exactly
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'fail-closed ha a GetOwner hibazik, de ugyanaz a processz meg el' {
        $Live = [pscustomobject]@{
            ProcessId = 1001
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            ExecutablePath = 'C:\dev\live.exe'
            TestOwner = 'Developer'
        }
        $Tree = @([pscustomobject]@{ Process = $Live; Depth = 0 })
        Mock Get-ProcessOwnerName { throw 'GetOwner failed' }
        Mock Get-ProcessById { return $Live }

        { Stop-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner 'TEST\Developer' } |
            Should -Throw '*tulajdonosa nem ellenorizheto*'
        Assert-MockCalled Get-ProcessById -Times 1 -Exactly
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'fail-closed ha a GetOwner hiba utan a PID identitasa megvaltozott' {
        $Snapshot = [pscustomobject]@{
            ProcessId = 1002
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            ExecutablePath = 'C:\dev\original.exe'
            TestOwner = 'Developer'
        }
        $Reused = [pscustomobject]@{
            ProcessId = 1002
            ParentProcessId = 200
            CreationDate = '20260719180000.000000+120'
            ExecutablePath = 'C:\Windows\reused.exe'
            TestOwner = 'Developer'
        }
        $Tree = @([pscustomobject]@{ Process = $Snapshot; Depth = 0 })
        Mock Get-ProcessOwnerName { throw 'HRESULT 0x80041002 Not found' }
        Mock Get-ProcessById { return $Reused }

        { Stop-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner 'TEST\Developer' } |
            Should -Throw '*PID-identitas valtozott*'
        Assert-MockCalled Get-ProcessById -Times 1 -Exactly
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'a tulajdonos-elteres tovabbra is fail-closed marad' {
        $Foreign = [pscustomobject]@{
            ProcessId = 1003
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            ExecutablePath = 'C:\dev\foreign.exe'
            TestOwner = 'OtherUser'
        }
        $Tree = @([pscustomobject]@{ Process = $Foreign; Depth = 0 })
        Mock Get-ProcessById { throw 'Get-ProcessById must not be called' }

        { Stop-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner 'TEST\Developer' } |
            Should -Throw '*Idegen tulajdonu processz*'
        Assert-MockCalled Get-ProcessById -Times 0
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'kihagyja a kill-time GetOwner kozben eltunt processzt' {
        $Target = [pscustomobject]@{
            ProcessId = 1004
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            ExecutablePath = 'C:\dev\kill-time-vanished.exe'
            TestOwner = 'Developer'
        }
        $Tree = @([pscustomobject]@{ Process = $Target; Depth = 0 })
        $script:OwnerCall = 0
        $script:LookupCall = 0
        Mock Get-ProcessOwnerName {
            $script:OwnerCall++
            if ($script:OwnerCall -eq 1) {
                return 'TEST\Developer'
            }
            throw 'HRESULT 0x80041002 Not found'
        }
        Mock Get-ProcessById {
            $script:LookupCall++
            if ($script:LookupCall -eq 1) {
                return $Target
            }
            return $null
        }

        { Stop-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner 'TEST\Developer' } |
            Should -Not -Throw
        Assert-MockCalled Get-ProcessOwnerName -Times 2 -Exactly
        Assert-MockCalled Get-ProcessById -Times 2 -Exactly
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'fail-closed ha a kill-time GetOwner hiba utan ugyanaz a processz meg el' {
        $Live = [pscustomobject]@{
            ProcessId = 1005
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            ExecutablePath = 'C:\dev\kill-time-live.exe'
            TestOwner = 'Developer'
        }
        $Tree = @([pscustomobject]@{ Process = $Live; Depth = 0 })
        $script:OwnerCall = 0
        Mock Get-ProcessOwnerName {
            $script:OwnerCall++
            if ($script:OwnerCall -eq 1) {
                return 'TEST\Developer'
            }
            throw 'GetOwner failed'
        }
        Mock Get-ProcessById { return $Live }

        { Stop-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner 'TEST\Developer' } |
            Should -Throw '*tulajdonosa nem ellenorizheto a leallitas elott*'
        Assert-MockCalled Get-ProcessOwnerName -Times 2 -Exactly
        Assert-MockCalled Get-ProcessById -Times 2 -Exactly
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'fail-closed ha a PID a kill-time GetOwner hiba kozben ujrahasznosult' {
        $Target = [pscustomobject]@{
            ProcessId = 1006
            ParentProcessId = 100
            CreationDate = '20260719180000.000000+120'
            ExecutablePath = 'C:\dev\kill-time-original.exe'
            TestOwner = 'Developer'
        }
        $Reused = [pscustomobject]@{
            ProcessId = 1006
            ParentProcessId = 200
            CreationDate = '20260719180001.000000+120'
            ExecutablePath = 'C:\Windows\kill-time-reused.exe'
            TestOwner = 'Developer'
        }
        $Tree = @([pscustomobject]@{ Process = $Target; Depth = 0 })
        $script:OwnerCall = 0
        $script:LookupCall = 0
        Mock Get-ProcessOwnerName {
            $script:OwnerCall++
            if ($script:OwnerCall -eq 1) {
                return 'TEST\Developer'
            }
            throw 'HRESULT 0x80041002 Not found'
        }
        Mock Get-ProcessById {
            $script:LookupCall++
            if ($script:LookupCall -eq 1) {
                return $Target
            }
            return $Reused
        }

        { Stop-OwnedProcessTree -ProcessTree $Tree -ExpectedOwner 'TEST\Developer' } |
            Should -Throw '*PID-identitas valtozott a leallitasi tulajdonos-ellenorzes kozben*'
        Assert-MockCalled Get-ProcessOwnerName -Times 2 -Exactly
        Assert-MockCalled Get-ProcessById -Times 2 -Exactly
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'mar eltunt rootnal is ujraszkennel es kotelezo portbizonyitast futtat' {
        $Self = New-TestSelfProcess
        Mock Get-ProcessSnapshot { @($Self) }
        Mock Get-NewDescendantProcessTree { @() }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 1100 -Port 3000 } |
            Should -Not -Throw

        Assert-MockCalled Get-NewDescendantProcessTree -Times 1 -Exactly
        Assert-MockCalled Get-NetstatLines -Times 1 -Exactly
        Assert-MockCalled Stop-Process -Times 0
    }

    It 'csak a sajat worktree-bol bizonyitott reparentelt Vite listenert allitja le' {
        $Self = New-TestSelfProcess
        $Vite = [pscustomobject]@{
            ProcessId = 1201
            ParentProcessId = 44
            CreationDate = '20260719181000.000000+120'
            ExecutablePath = 'C:\Program Files\nodejs\node.exe'
            CommandLine = '"C:\Program Files\nodejs\node.exe" "D:\repo\worktree\frontend-react\node_modules\vite\bin\vite.js" --port 3000'
            TestOwner = 'Developer'
        }
        $script:SnapshotCall = 0
        $script:NetstatCall = 0
        Mock Get-DevProjectRoot { 'D:\repo\worktree' }
        Mock Get-ProcessSnapshot {
            $script:SnapshotCall++
            if ($script:SnapshotCall -lt 3) {
                return @($Self)
            }
            return @($Self, $Vite)
        }
        Mock Get-ProcessById { $Vite }
        Mock Get-NetstatLines {
            $script:NetstatCall++
            if ($script:NetstatCall -eq 1) {
                return '  TCP    127.0.0.1:3000    0.0.0.0:0    LISTENING    1201'
            }
            return @()
        }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 1200 -Port 3000 } |
            Should -Not -Throw

        Assert-MockCalled Stop-Process -Times 1 -Exactly -ParameterFilter { $Id -eq 1201 }
        Assert-MockCalled Get-NetstatLines -Times 2 -Exactly
    }

    It 'bizonyitatlan port-owner processzt eletben hagy es LISTENING hibaval zar' {
        $Self = New-TestSelfProcess
        $UnprovenListener = [pscustomobject]@{
            ProcessId = 1301
            ParentProcessId = 44
            CreationDate = '20260719181100.000000+120'
            ExecutablePath = 'C:\Program Files\nodejs\node.exe'
            CommandLine = '"C:\Program Files\nodejs\node.exe" "D:\foreign\node_modules\vite\bin\vite.js" --port 3000'
            TestOwner = 'Developer'
        }
        $script:SnapshotCall = 0
        Mock Get-DevProjectRoot { 'D:\repo\worktree' }
        Mock Get-ProcessSnapshot {
            $script:SnapshotCall++
            if ($script:SnapshotCall -lt 3) {
                return @($Self)
            }
            return @($Self, $UnprovenListener)
        }
        Mock Get-NetstatLines {
            '  TCP    127.0.0.1:3000    0.0.0.0:0    LISTENING    1301'
        }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 1300 -Port 3000 } |
            Should -Throw '*LISTENING*'

        Assert-MockCalled Stop-Process -Times 0
    }

    It 'idegen tulajdonu, egyebkent Vite-szeru orphan listenert sem allit le' {
        $Self = New-TestSelfProcess
        $ForeignListener = [pscustomobject]@{
            ProcessId = 1351
            ParentProcessId = 44
            CreationDate = '20260719181130.000000+120'
            ExecutablePath = 'C:\Program Files\nodejs\node.exe'
            CommandLine = '"C:\Program Files\nodejs\node.exe" "D:\repo\worktree\frontend-react\node_modules\vite\bin\vite.js" --port 3000'
            TestOwner = 'OtherUser'
        }
        $script:SnapshotCall = 0
        Mock Get-DevProjectRoot { 'D:\repo\worktree' }
        Mock Get-ProcessSnapshot {
            $script:SnapshotCall++
            if ($script:SnapshotCall -lt 3) {
                return @($Self)
            }
            return @($Self, $ForeignListener)
        }
        Mock Get-NetstatLines {
            '  TCP    127.0.0.1:3000    0.0.0.0:0    LISTENING    1351'
        }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 1350 -Port 3000 } |
            Should -Throw '*LISTENING*'

        Assert-MockCalled Stop-Process -Times 0
    }

    It 'nem bizonyithato orphan owner eseten is LISTENING hibaval zar es nem allit le' {
        $Self = New-TestSelfProcess
        $UnknownOwnerListener = [pscustomobject]@{
            ProcessId = 1371
            ParentProcessId = 44
            CreationDate = '20260719181145.000000+120'
            ExecutablePath = 'C:\Program Files\nodejs\node.exe'
            CommandLine = '"C:\Program Files\nodejs\node.exe" "D:\repo\worktree\frontend-react\node_modules\vite\bin\vite.js" --port 3000'
            TestOwner = 'Developer'
        }
        $script:SnapshotCall = 0
        Mock Get-DevProjectRoot { 'D:\repo\worktree' }
        Mock Get-ProcessSnapshot {
            $script:SnapshotCall++
            if ($script:SnapshotCall -lt 3) {
                return @($Self)
            }
            return @($Self, $UnknownOwnerListener)
        }
        Mock Get-NetstatLines {
            '  TCP    127.0.0.1:3000    0.0.0.0:0    LISTENING    1371'
        }
        Mock Get-ProcessOwnerName { throw 'GetOwner access denied' }

        { Invoke-OwnedDevProcessCleanup -RootProcessId 1370 -Port 3000 } |
            Should -Throw '*LISTENING*'

        Assert-MockCalled Stop-Process -Times 0
    }

    It 'nem fogad el kulon argumentumban worktree-pathot es idegen Vite entrypointot' {
        $Decoy = [pscustomobject]@{
            ExecutablePath = 'C:\Program Files\nodejs\node.exe'
            CommandLine = '"C:\Program Files\nodejs\node.exe" "D:\foreign\node_modules\vite\bin\vite.js" --config "D:\repo\worktree\vite.config.ts"'
        }

        Test-ExpectedViteProcess -Process $Decoy -ProjectRoot 'D:\repo\worktree' |
            Should -BeFalse
    }

    It 'ciklikus hivo-oslancnal determinisztikusan fail-closed hibazik' {
        $FirstAncestor = [pscustomobject]@{
            ProcessId = 1401
            ParentProcessId = 1402
            CreationDate = '20260719181200.000000+120'
            TestOwner = 'Developer'
        }
        $SecondAncestor = [pscustomobject]@{
            ProcessId = 1402
            ParentProcessId = 1401
            CreationDate = '20260719181201.000000+120'
            TestOwner = 'Developer'
        }
        $Self = [pscustomobject]@{
            ProcessId = $PID
            ParentProcessId = 1401
            CreationDate = '20260719181202.000000+120'
            TestOwner = 'Developer'
        }

        { Assert-SafeRootProcessId -RootProcessId 1499 -ProcessSnapshot @(
            $Self,
            $FirstAncestor,
            $SecondAncestor
        ) } | Should -Throw '*Ciklikus*'
    }
}

Describe 'Get-NetstatLines fail-closed contract' {
    BeforeAll {
        $FunctionsPath = Join-Path $PSScriptRoot 'stop-owned-dev-processes.functions.ps1'
        . $FunctionsPath
    }

    It 'nem nulla netstat exit code eseten nem enged hamis portbizonyitast' {
        Mock Invoke-NetstatCommand {
            [pscustomobject]@{
                Lines = @()
                ExitCode = 1
            }
        }

        { Get-NetstatLines } | Should -Throw '*exit code: 1*'
    }

    It 'ures string alaku netstat snapshotot ures listener-listakent kezel' {
        $ListenerProcessIds = @(Get-ListeningProcessIds `
            -NetstatLines @('') `
            -Port 3000)

        $ListenerProcessIds.Count | Should -Be 0
    }
}
