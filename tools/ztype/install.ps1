#Requires -Version 5.1
<#
.SYNOPSIS
    ZType egykattintásos telepítő (felhasználói mappa, venv, parancsikonok).

.DESCRIPTION
    - Másolás: %LOCALAPPDATA%\ZType
    - venv + pip install
    - Start menü parancsikon
    - Automatikus indulás: Startup mappa parancsikon

    Futtatás: jobb klikk → Futtatás PowerShell-lel, vagy dupla klikk Install-ZType.cmd
#>

$ErrorActionPreference = "Stop"
$Dest = Join-Path $env:LOCALAPPDATA "ZType"
$Root = $PSScriptRoot

Write-Host "ZType telepítés ide: $Dest" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$files = @(
    "ztype.py",
    "api_key_dialog.py",
    "secrets_store.py",
    "win_vk_hotkey.py",
    "requirements.txt",
    "ZType-debug.cmd"
)
foreach ($f in $files) {
    $src = Join-Path $Root $f
    if (-not (Test-Path -LiteralPath $src)) {
        throw "Hiányzik: $src"
    }
    Copy-Item -LiteralPath $src -Destination (Join-Path $Dest $f) -Force
}

function Find-PythonExe {
    $trials = @(
        @("py", @("-3.12")),
        @("py", @("-3.11")),
        @("py", @("-3.10")),
        @("py", @("-3")),
        @("python", @())
    )
    foreach ($t in $trials) {
        $cmd = $t[0]
        $extra = $t[1]
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { continue }
        try {
            if ($extra.Count -gt 0) {
                $exe = & $cmd @($extra + @("-c", "import sys; print(sys.executable)")) 2>$null
            } else {
                $exe = & $cmd -c "import sys; print(sys.executable)" 2>$null
            }
            $exe = ($exe | Out-String).Trim()
            if ($exe -and (Test-Path -LiteralPath $exe)) { return $exe }
        } catch { }
    }
    return $null
}

$pyExe = Find-PythonExe
if (-not $pyExe) {
    throw "Nem található Python 3.10+ (PATH / py launcher). Telepítsd: https://www.python.org/downloads/"
}

Write-Host "Python: $pyExe" -ForegroundColor Green

$venvPy = Join-Path $Dest ".venv\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $venvPy)) {
    & $pyExe -m venv (Join-Path $Dest ".venv")
    if ($LASTEXITCODE -ne 0) { throw "venv létrehozás sikertelen" }
}

$venvPython = Join-Path $Dest ".venv\Scripts\python.exe"
& $venvPython -m pip install --upgrade pip 2>$null
& $venvPython -m pip install -r (Join-Path $Dest "requirements.txt")
if ($LASTEXITCODE -ne 0) { throw "pip install sikertelen" }

$pythonw = Join-Path $Dest ".venv\Scripts\pythonw.exe"
$script = Join-Path $Dest "ztype.py"

$Wsh = New-Object -ComObject WScript.Shell

$startMenu = [Environment]::GetFolderPath("Programs")
$smFolder = Join-Path $startMenu "ZType"
New-Item -ItemType Directory -Force -Path $smFolder | Out-Null
$lnkMain = Join-Path $smFolder "ZType.lnk"
$sc = $Wsh.CreateShortcut($lnkMain)
$sc.TargetPath = $pythonw
$sc.Arguments = "`"$script`""
$sc.WorkingDirectory = $Dest
$sc.Description = "ZType diktálás (Whisper, magyar)"
$sc.Save()

$debugCmd = Join-Path $Dest "ZType-debug.cmd"
if (Test-Path -LiteralPath $debugCmd) {
    $lnkDbg = Join-Path $smFolder "ZType (hibakeresés).lnk"
    $sd = $Wsh.CreateShortcut($lnkDbg)
    $sd.TargetPath = $debugCmd
    $sd.WorkingDirectory = $Dest
    $sd.Description = "ZType konzol — látod a hibát, ha nem indul el"
    $sd.Save()
}

$startup = [Environment]::GetFolderPath("Startup")
$lnkStart = Join-Path $startup "ZType.lnk"
$sc2 = $Wsh.CreateShortcut($lnkStart)
$sc2.TargetPath = $pythonw
$sc2.Arguments = "`"$script`""
$sc2.WorkingDirectory = $Dest
$sc2.Description = "ZType automatikus indulás"
$sc2.Save()

Write-Host ""
Write-Host "Kész. ZType:" -ForegroundColor Green
Write-Host "  Start menü → ZType → ZType"
Write-Host "  Hibakeresés: Start menü → ZType → ZType (hibakeresés)"
Write-Host "  Automatikus indulás: Startup mappában parancsikon"
Write-Host "  Első futtatáskor maszkolt ablakban add meg az OpenAI API kulcsot."
Write-Host "  Napló: $env:LOCALAPPDATA\ZType\ztype.log"
Write-Host ""
