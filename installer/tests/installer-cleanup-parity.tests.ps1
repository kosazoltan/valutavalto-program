#!/usr/bin/env pwsh
# =============================================================================
# FKH-036 — Cleanup-paritas es PRESERVE_DATA szerzodes regresszios teszt
# =============================================================================
# MIERT LETEZIK EZ A TESZT
# ------------------------
# A `Penztar-Setup.nsi` (beepitett uninstaller + FAZIS 1e2 cleanup) es a
# `Penztar-Cleanup.nsi` (onallo Penztar-Eltavolito.exe) UGYANAZT a takaritasi
# logikat KET PELDANYBAN tartalmazza. Ez architekturalis duplikacio: amig
# mindketto ugyanazt csinalja, nincs hiba - de ha az egyiket javitjak es a
# masikat nem, a ket eltavolito viselkedese szetcsuszik (drift).
#
# Pontosan ez tortent az FKH-036 D1 defektnel: a telepito upgrade-agja
# `/PRESERVE_DATA=1`-et adott at "az adatbazis es a beallitasok MEGMARADNAK"
# igerettel, de a userData (`.env` - JWT_SECRET, SQLCIPHER_KEY,
# SETUP_COMPLETED) torlese MINDKET scriptben feltetel nelkul futott.
#
# Ez a teszt nem a torlest tiltja, hanem a KET PELDANY EGYUTTMOZGASAT orzi.
#
# KONVENCIO: PS 5.1-kompatibilis, NINCS Pester fuggoseg - azonos az
# `installer-scripts.tests.ps1` mintajaval (a repo szandekosan kerulí a Pestert).
#
# Futtatas:
#   powershell -NoProfile -ExecutionPolicy Bypass -File installer\tests\installer-cleanup-parity.tests.ps1
# Exit 0 = minden PASS; Exit 1 = van FAIL.
#
# MEGJEGYZES A LEFEDETTSEGROL: ez STATIKUS ellenorzes. Nem futtat telepitot es
# nem bizonyitja a futasidoju viselkedest - azt kezi telepito-teszt igazolja.
# Egyetlen CI-workflow sem futtatja (a windows-signed-release.yml
# workflow_dispatch-only), tehat ez MANUALIS / lokalis kapu.
# =============================================================================
$ErrorActionPreference = 'Stop'
$fail = 0
function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) { Write-Host "[PASS] $name" -ForegroundColor Green }
    else { Write-Host "[FAIL] $name  $detail" -ForegroundColor Red; $script:fail++ }
}

$testsDir     = $PSScriptRoot
$installerDir = Split-Path -Parent $testsDir

$setupPath   = Join-Path $installerDir 'Penztar-Setup.nsi'
$cleanupPath = Join-Path $installerDir 'Penztar-Cleanup.nsi'

Check 'Penztar-Setup.nsi letezik'   (Test-Path $setupPath)   $setupPath
Check 'Penztar-Cleanup.nsi letezik' (Test-Path $cleanupPath) $cleanupPath
if ($fail -gt 0) { Write-Host "`nHianyzo forrasfajl - megszakitva" -ForegroundColor Red; exit 1 }

$setup   = Get-Content $setupPath   -Raw
$cleanup = Get-Content $cleanupPath -Raw

# =============================================================================
# 1. PRESERVE_DATA SZERZODES (FKH-036 D1)
# =============================================================================
# A telepito upgrade-agja atadja a flaget. Ha ezt barmelyik oldal nem parsolja,
# a felhasznaloi igeret ("beallitasok megmaradnak") hamissa valik.

Check 'Setup: az upgrade-ag atadja a /PRESERVE_DATA=1-et' `
    ($setup -match '/S\s+/PRESERVE_DATA=1')

Check 'Setup: az uninstaller PARSOLJA a /PRESERVE_DATA-t (D1 fix)' `
    ($setup -match '\$\{GetOptions\}\s+"\$CMDLINE"\s+"/PRESERVE_DATA="') `
    'un.onInit-ben GetOptions-nek kell parsolnia'

Check 'Cleanup: parsolja a /PRESERVE_DATA-t' `
    ($cleanup -match '\$\{GetOptions\}\s+"\$CMDLINE"\s+"/PRESERVE_DATA="')

# A GetOptions makro tobb tucat utasitasra expandal; az `IfSilent +3` RELATIV
# ugras, ezert a makro NEM allhat az IfSilent es a MessageBox kozott.
$unOnInit = [regex]::Match($setup, '(?ms)Function\s+un\.onInit\b.*?FunctionEnd')
Check 'Setup: van un.onInit' $unOnInit.Success
if ($unOnInit.Success) {
    # FONTOS: a NSIS kommentsorokat (`;`) le kell vagni, kulonben az indoklo
    # komment ("...az IfSilent ELOTT...") hamis talalatot ad, es a teszt a
    # helyes kod mellett is bukik. Csak a VEGREHAJTHATO sorokat vizsgaljuk.
    $codeOnly = ($unOnInit.Value -split "`n" |
        Where-Object { $_ -notmatch '^\s*;' }) -join "`n"
    $idxGetOpt = $codeOnly.IndexOf('GetOptions')
    $idxSilent = $codeOnly.IndexOf('IfSilent')
    Check 'Setup: GetOptions az IfSilent ELOTT (relativ-ugras vedelem)' `
        ($idxGetOpt -ge 0 -and $idxSilent -ge 0 -and $idxGetOpt -lt $idxSilent) `
        "GetOptions@$idxGetOpt IfSilent@$idxSilent - a makro NEM kerulhet az IfSilent moge"
}

# =============================================================================
# 2. userData (.env) TORLES FELTETELESSEGE — a D1 defekt lenyege
# =============================================================================
# Az `%APPDATA%\valuta-penztar\.env` tartalmazza a Setup Wizard altal generalt
# JWT_SECRET + SQLCIPHER_KEY titkokat. Frissiteskor NEM torolheto.

foreach ($pair in @(
    @{ Name = 'Setup';   Text = $setup;   Var = 'UN_PRESERVE_DATA' },
    @{ Name = 'Cleanup'; Text = $cleanup; Var = 'PreserveData'     }
)) {
    $n = $pair.Name; $t = $pair.Text; $v = $pair.Var
    $m = [regex]::Matches($t, '(?m)^\s*RMDir\s+/r\s+"\$APPDATA\\valuta-penztar"')
    Check "${n}: van userData RMDir (a takaritas nem veszett el)" ($m.Count -ge 1)

    # Minden ilyen RMDir-t meg kell elozzon egy PRESERVE_DATA guard 800 karakteren belul.
    $guarded = $true
    foreach ($hit in $m) {
        $from   = [Math]::Max(0, $hit.Index - 800)
        $before = $t.Substring($from, $hit.Index - $from)
        if ($before -notmatch [regex]::Escape($v)) { $guarded = $false }
    }
    Check "${n}: a userData torles PRESERVE_DATA-guard mogott van (D1 fix)" $guarded `
        "minden 'RMDir /r `"`$APPDATA\valuta-penztar`"' ele kell egy `$$v feltetel"
}

# =============================================================================
# 3. CLEANUP-INVARIANSOK PARITASA (drift-detektalas)
# =============================================================================
# Amit az egyik eltavolito takarit, a masiknak is takaritania kell.

$invariants = @(
    @{ Name = 'firewall: Valutavalto-Backend';        Pattern = 'firewall delete rule name="Valutavalto-Backend"' },
    @{ Name = 'firewall: Valutavalto-PostgreSQL';     Pattern = 'firewall delete rule name="Valutavalto-PostgreSQL"' },
    @{ Name = 'firewall: BestChange-Backend (8080)';  Pattern = 'firewall delete rule name="BestChange-Backend \(8080\)"' },
    @{ Name = 'firewall: BestChange-PostgreSQL';      Pattern = 'firewall delete rule name="BestChange-PostgreSQL \(54320\)"' },
    @{ Name = 'PGPASSFILE env torles';                Pattern = '/v PGPASSFILE /f' },
    @{ Name = 'registry: Software\BestChange';        Pattern = 'DeleteRegKey HKLM "Software\\BestChange"' },
    @{ Name = 'registry: Uninstall\ValutavaltoPenztar'; Pattern = 'Uninstall\\ValutavaltoPenztar"' },
    @{ Name = 'PROGRAMFILES64 Valutavalto Penztar';   Pattern = 'RMDir /r "\$PROGRAMFILES64\\Valutavalto Penztar"' },
    @{ Name = 'PROGRAMFILES64 ValutavaltoPenztar';    Pattern = 'RMDir /r "\$PROGRAMFILES64\\ValutavaltoPenztar"' },
    @{ Name = 'PROGRAMFILES (legacy 32-bit)';         Pattern = 'RMDir /r "\$PROGRAMFILES\\Valutavalto Penztar"' },
    @{ Name = 'Start menu torles';                    Pattern = 'RMDir /r "\$SMPROGRAMS\\Valutavalto Penztar"' },
    @{ Name = 'Desktop shortcut torles';              Pattern = 'Delete "\$DESKTOP\\Valutavalto Penztar.lnk"' },
    @{ Name = 'service: BestChange-Backend delete';   Pattern = 'sc.exe delete BestChange-Backend' },
    @{ Name = 'service: BestChange-PostgreSQL delete';Pattern = 'sc.exe delete BestChange-PostgreSQL' }
)

foreach ($inv in $invariants) {
    $inSetup   = $setup   -match $inv.Pattern
    $inCleanup = $cleanup -match $inv.Pattern
    Check ("paritas: " + $inv.Name) ($inSetup -and $inCleanup) `
        "Setup=$inSetup Cleanup=$inCleanup - a ket eltavolito szetcsuszott"
}

# =============================================================================
# 4. ADAT-MEGORZESI GUARD (ProgramData)
# =============================================================================
# A `C:\ProgramData\BestChange` a PostgreSQL adatkonyvtar. Feltetel nelkuli
# torlese frissiteskor = teljes adatbazis-vesztes.

Check 'Setup: ProgramData torles UPGRADE_MODE-guard mogott' `
    ($setup -match '(?ms)\$\{If\}\s+\$UPGRADE_MODE\s*==\s*"1".{0,400}RMDir /r "C:\\ProgramData\\BestChange"')

Check 'Cleanup: ProgramData torles PreserveData-guard mogott' `
    ($cleanup -match '(?ms)\$\{If\}\s+\$PreserveData\s*==\s*"1".{0,400}RMDir /r "C:\\ProgramData\\BestChange"')

# =============================================================================
# 5. ISMERT, NYITOTT HIANY — dokumentacios assert (FKH-036 D2)
# =============================================================================
# A pénztaros offline SQLite DB-je (`~/.valuta/local.db`, l. sqlite.ts
# resolveDatabasePath isPackaged-ag) SZINKRONIZALATLAN penzugyi tranzakciokat
# tarthat (`pending_transactions WHERE synced = 0`), es EGYETLEN telepito-script
# sem ismeri. Ez tudatosan NINCS javitva: a mentes/torles admin-kontextusban a
# ROSSZ felhasznaloi profilra oldodna fel ($PROFILE = a telepito admin, nem a
# penztaros), tehat hamis biztonsagot adna.
#
# Ez az assert AKKOR BUKIK, ha valaki `~/.valuta` kezelest vezet be a
# telepitobe - ilyenkor a D2 kockazatot (profil-feloldas, wipe-konzisztencia,
# hibakezeles, rotacio) ujra kell ertekelni, es ezt a tesztet frissiteni.
#
# 2026-08-11 D2-UJRAERTEKELES (kiterjesztes, NEM gyengites):
# A guard eddig CSAK a ket .nsi-t szkennelte, a ket electron-builder .nsh-t nem -
# pedig azok is futtatnak torlest (pl. installer-cleanup.nsh: $LOCALAPPDATA).
# Egy .nsh-ba rejtett `~/.valuta` kezeles igy eszrevetlen maradt volna.
# A D2 ujraertekelese megtortent (.hermes/tickets/2026-08-11-d2-penztaros-profil-terv.md):
# a telepito-oldali profil-azonositas ELVETVE; a helyes megoldas app-oldali,
# sync-gate-elt (`getPendingTransactionCount() == 0`) gyari reset. A telepito
# tovabbra sem nyulhat a `~/.valuta`-hoz - ezt most MIND A NEGY fajlra orizzuk.
$penztarNshPath  = Join-Path (Split-Path -Parent $installerDir) 'penztar-client\build\installer-cleanup.nsh'
$kozpontiNshPath = Join-Path (Split-Path -Parent $installerDir) 'kozponti-client\build\installer-cleanup.nsh'
$penztarNshRaw   = if (Test-Path $penztarNshPath)  { Get-Content $penztarNshPath  -Raw } else { '' }
$kozpontiNshRaw  = if (Test-Path $kozpontiNshPath) { Get-Content $kozpontiNshPath -Raw } else { '' }

$setupHasValuta   = $setup   -match '\\\.valuta\\'
$cleanupHasValuta = $cleanup -match '\\\.valuta\\'
$pNshHasValuta    = $penztarNshRaw  -match '\\\.valuta\\'
$kNshHasValuta    = $kozpontiNshRaw -match '\\\.valuta\\'
Check 'D2 dokumentalt allapot: a telepito NEM nyul a ~/.valuta-hoz' `
    (-not $setupHasValuta -and -not $cleanupHasValuta) `
    'Ha ez FAIL, valaki bevezette a ~/.valuta kezelest -> ertekeld ujra a D2 kockazatot es frissitsd a tesztet'

Check 'D2 kiterjesztes: az electron-builder .nsh-k SEM nyulnak a ~/.valuta-hoz' `
    (-not $pNshHasValuta -and -not $kNshHasValuta) `
    'Egy .nsh-ba rejtett ~/.valuta kezeles ugyanaz a D2 kockazat, mint a .nsi-ben'

# =============================================================================
# 6. ELECTRON-BUILDER .nsh PARITAS (platform-refaktor, 2026-08-10)
# =============================================================================
# A `penztar-client/build/installer-cleanup.nsh` es a
# `kozponti-client/build/installer-cleanup.nsh` KET makrot BITRE AZONOSAN
# tartalmaz:
#   - `preInit`               (5 sor)  — #1428 R2 System.dll crash-fix friss telepitesnel
#   - `customCheckAppRunning` (73 sor) — #1428 silent-mod System.dll process-enum kihagyasa
# A `customInit` LEGITIMEN elter (kliens-specifikus utvonalak/GUID-ok), ezert azt
# NEM hasonlitjuk.
#
# MIERT NEM KOZOS !include-DAL OLDJUK MEG (empirikusan igazolt, 2026-08-10):
# az NSIS `!include` relativ utvonala a MAKENSIS CWD-jehez oldodik fel, NEM a
# beagyazo fajlhoz. Az electron-builder a makensis-t sajat temp konyvtarabol
# futtatja, ezert egy `!include "../../packages/..."` NEM talalna meg a fajlt
# (a reprodukciot lefuttattuk: "!include: could not find"). A #1428 crash-fix
# terulete draga aron lett stabil, ezert itt a DUPLIKACIOT MEGTARTJUK, es
# helyette GEPPEL ORIZZUK, hogy a ket peldany ne csuszhasson el.
$penztarNsh  = Join-Path (Split-Path -Parent $installerDir) 'penztar-client\build\installer-cleanup.nsh'
$kozpontiNsh = Join-Path (Split-Path -Parent $installerDir) 'kozponti-client\build\installer-cleanup.nsh'

Check 'penztar installer-cleanup.nsh letezik'  (Test-Path $penztarNsh)  $penztarNsh
Check 'kozponti installer-cleanup.nsh letezik' (Test-Path $kozpontiNsh) $kozpontiNsh

if ((Test-Path $penztarNsh) -and (Test-Path $kozpontiNsh)) {
    $pNsh = Get-Content $penztarNsh  -Raw
    $kNsh = Get-Content $kozpontiNsh -Raw

    function Get-NsisMacro([string]$text, [string]$name) {
        $m = [regex]::Match($text, "(?ms)!macro\s+$name\b(.*?)!macroend")
        if (-not $m.Success) { return $null }
        # whitespace-normalizalas: a formazasi elteres nem drift
        return ($m.Groups[1].Value -replace '\s+', ' ').Trim()
    }

    foreach ($macro in @('preInit', 'customCheckAppRunning')) {
        $a = Get-NsisMacro $pNsh $macro
        $b = Get-NsisMacro $kNsh $macro
        Check "nsh: mindket kliensben van '$macro' makro" ($null -ne $a -and $null -ne $b)
        if ($null -ne $a -and $null -ne $b) {
            Check "nsh paritas: '$macro' azonos (#1428 crash-fix drift-vedelem)" ($a -eq $b) `
                "a ket installer-cleanup.nsh '$macro' makroja szetcsuszott - a #1428 System.dll fix serulhetett"
        }
    }
}

if ($fail -gt 0) { Write-Host "`n$fail teszt FAIL" -ForegroundColor Red; exit 1 }
Write-Host "`nMinden teszt PASS" -ForegroundColor Green; exit 0