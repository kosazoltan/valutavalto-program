; =========================================================================
; Valutavalto Penztar - Standalone Cleanup/Eltavolito
; Regi telepitesek maradekainak teljes eltavolitasa
; =========================================================================

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

!ifndef VERSION
  !define VERSION "2.1.8"
!endif
!ifndef BUILD_DATE
  !define BUILD_DATE "dev"
!endif

; =============================================================================
; v2.3.8 BUG FIX: PowerShell -EncodedCommand b64 strings (l. Penztar-Setup.nsi)
; =============================================================================
; A korabbi inline `Where-Object { $$_.Path -like ''*BestChange*'' }` minta
; "ParserError: ExpectedValueExpression" hibat dobott NSIS+PowerShell quote-
; szetesese miatt. Az -EncodedCommand UTF-16LE base64 quote-mentesen mukodik.
; =============================================================================
!define PS_KILL_PG_B64    "RwBlAHQALQBQAHIAbwBjAGUAcwBzACAAcABvAHMAdABnAHIAZQBzACAALQBFAHIAcgBvAHIAQQBjAHQAaQBvAG4AIABTAGkAbABlAG4AdABsAHkAQwBvAG4AdABpAG4AdQBlACAAfAAgAFcAaABlAHIAZQAtAE8AYgBqAGUAYwB0ACAAewAgACQAXwAuAFAAYQB0AGgAIAAtAGwAaQBrAGUAIAAnACoAQgBlAHMAdABDAGgAYQBuAGcAZQAqACcAIAB9ACAAfAAgAFMAdABvAHAALQBQAHIAbwBjAGUAcwBzACAALQBGAG8AcgBjAGUAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAFMAaQBsAGUAbgB0AGwAeQBDAG8AbgB0AGkAbgB1AGUA"
!define PS_KILL_JAVA_B64  "RwBlAHQALQBQAHIAbwBjAGUAcwBzACAAagBhAHYAYQAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQAgAHwAIABXAGgAZQByAGUALQBPAGIAagBlAGMAdAAgAHsAIAAkAF8ALgBQAGEAdABoACAALQBsAGkAawBlACAAJwAqAEIAZQBzAHQAQwBoAGEAbgBnAGUAKgAnACAAfQAgAHwAIABTAHQAbwBwAC0AUAByAG8AYwBlAHMAcwAgAC0ARgBvAHIAYwBlACAALQBFAHIAcgBvAHIAQQBjAHQAaQBvAG4AIABTAGkAbABlAG4AdABsAHkAQwBvAG4AdABpAG4AdQBlAA=="

; --- Windows EXE Version Info ---
VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey /LANG=1038 "ProductName" "Valutavalto Penztar Eltavolito"
VIAddVersionKey /LANG=1038 "CompanyName" "Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "LegalCopyright" "- 2026 Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "FileDescription" "Valutavalto Penztar - Teljes Eltavolito"
VIAddVersionKey /LANG=1038 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1038 "ProductVersion" "${VERSION} (${BUILD_DATE})"

Name "Valutavalto Penztar - Eltavolito ${VERSION}"
OutFile "build\Penztar-Eltavolito-${VERSION}-${BUILD_DATE}.exe"
RequestExecutionLevel admin
Unicode true

; --- UI ---
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Hungarian"

; v2.3.0: adat-megorzes flag upgrade soran
Var PreserveData

Function .onInit
    ; Parameter parsolas: /PRESERVE_DATA=1 (Setup.exe-bol hivva upgrade-hez)
    ; vagy ures (manualis futtatas -> teljes eltavolitas)
    ${GetOptions} "$CMDLINE" "/PRESERVE_DATA=" $PreserveData
    ${If} $PreserveData == ""
        StrCpy $PreserveData "0"
    ${EndIf}

    ; v2.3.0: Ha a user manualisan futtatta a Cleanup-ot (non-silent, PreserveData=0),
    ; figyelmeztetjuk az adatveszelesrol. Silent mode-ban (Setup-bol hivva) kimarad.
    ; v2.3.0 NSIS fix: az MessageBox a Cleanup.nsi tobb cleanup-version mellett
    ; az NSIS ACP parserrel valamiert hibazott. A confirm-dialog elhagyva, mert
    ; (1) silent mode-ban (PRESERVE_DATA=1, Setup-bol hivva) kimarad,
    ; (2) manualisan futtatva a user mar a Tulajdonsagok+UAC promptolnal
    ;     megerositette a teljes eltavolitas szandekat.
    DetailPrint "Penztar Cleanup indul (PreserveData=$PreserveData)"
    IfSilent skip_confirm

    skip_confirm:
    ${If} $PreserveData == "1"
        DetailPrint "Cleanup: PRESERVE_DATA=1 mod - C:\ProgramData\BestChange MEGTARTVA"
    ${EndIf}
FunctionEnd

Section "Eltavolitas"
    SetDetailsView show

    DetailPrint "============================================"
    DetailPrint "Valutavalto Penztar - Teljes Eltavolitas"
    DetailPrint "============================================"
    DetailPrint ""

    ; --- 1. STOP services (NSSM + net stop fallback) ---
    DetailPrint "1/5 - Szolgaltatasok leallitasa..."
    IfFileExists "C:\ProgramData\BestChange\tools\nssm.exe" 0 cleanup_netstop
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" stop BestChange-Backend'
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" stop BestChange-PostgreSQL'
    cleanup_netstop:
    nsExec::ExecToLog 'net stop BestChange-Backend'
    nsExec::ExecToLog 'net stop BestChange-PostgreSQL'
    Sleep 3000

    ; pg_ctl graceful stop
    IfFileExists "C:\ProgramData\BestChange\pgsql\bin\pg_ctl.exe" 0 cleanup_skip_pgctl
        nsExec::ExecToLog '"C:\ProgramData\BestChange\pgsql\bin\pg_ctl.exe" stop -D "C:\ProgramData\BestChange\pgsql\data" -m fast -w -t 30'
    cleanup_skip_pgctl:
    Sleep 2000

    ; --- 2. KILL leftover processes (scoped!) ---
    DetailPrint "2/5 - Futo folyamatok leallitasa..."
    nsExec::ExecToLog 'taskkill /F /IM Penztar.exe'
    nsExec::ExecToLog 'taskkill /F /IM "Valutavalto Penztar.exe"'
    ; Scoped kill: only BestChange-path postgres/java (nem globalis!)
    ; v2.3.8: -EncodedCommand a -like quote-szetesese-bug elkerulesere
    nsExec::ExecToLog 'powershell.exe -NoProfile -EncodedCommand ${PS_KILL_PG_B64}'
    nsExec::ExecToLog 'powershell.exe -NoProfile -EncodedCommand ${PS_KILL_JAVA_B64}'
    Sleep 2000

    ; --- 3. REMOVE services (only after processes are dead!) ---
    DetailPrint "3/5 - Szolgaltatasok eltavolitasa..."
    IfFileExists "C:\ProgramData\BestChange\tools\nssm.exe" 0 cleanup_scdelete
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" remove BestChange-Backend confirm'
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" remove BestChange-PostgreSQL confirm'
    cleanup_scdelete:
    nsExec::ExecToLog 'sc.exe delete BestChange-Backend'
    nsExec::ExecToLog 'sc.exe delete BestChange-PostgreSQL'
    Sleep 1000

    ; --- 4. Remove directories ---
    DetailPrint "4/5 - Fajlok es mappak torlese (5 lepeses: STOP->KILL->REMOVE->DELETE->REGISTRY)..."

    ; Program Files locations (F-N-10: PROGRAMFILES64 for x64 installs)
    RMDir /r "$PROGRAMFILES64\Valutavalto Penztar"
    RMDir /r "$PROGRAMFILES64\ValutavaltoPenztar"
    RMDir /r "$PROGRAMFILES64\Penztar"
    ; Legacy 32-bit leftovers
    RMDir /r "$PROGRAMFILES\Valutavalto Penztar"
    RMDir /r "$PROGRAMFILES\ValutavaltoPenztar"

    ; ProgramData - v2.3.0: upgrade mode-ban NEM toroljuk (adat-megorzes)
    ${If} $PreserveData == "1"
        DetailPrint "  Upgrade mode: C:\ProgramData\BestChange adatmappa MEGTARTVA (DB + config)."
    ${Else}
        RMDir /r "C:\ProgramData\BestChange"
    ${EndIf}

    ; Desktop shortcuts
    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    Delete "$DESKTOP\Penztar.lnk"

    ; Start menu
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"

    ; --- 4a. Electron userData cleanup (Setup Wizard fix) ---
    ; Az %APPDATA%\valuta-penztar\ mappaban van a .env (SETUP_COMPLETED flag).
    ; Ha nem toroljuk, ujratelepites utan a Setup Wizard NEM indul automatikusan.
    ; FIGYELEM (D2, 2026-08-11 meressel igazolva): a `SetShellVarContext current`
    ; a FUTO PROCESS TOKENJENEK felhasznalojara oldodik fel, NEM automatikusan a
    ; penztarosera. Onelevacional ("Futtatas rendszergazdakent" a bejelentkezett
    ; user altal) ez a penztaros profilja, DE kulon admin-fiokkal (runas,
    ; domain-admin) az ADMIN-e, `/S` SCCM/GPO alatt pedig a LocalSystem
    ; systemprofile-ja. Ilyenkor az alabbi torles NEM a penztaros userData-jat
    ; erinti. A `~/.valuta` offline penzugyi DB-t ezert a telepito TUDATOSAN nem
    ; kezeli (l. installer-cleanup-parity.tests.ps1 5. szekcio).
    ;
    ; ==== FKH-036 (D1 fix): PRESERVE_DATA=1 eseten NEM TOROLJUK ====
    ; Ez a script mar a .onInit-ben parsolja a /PRESERVE_DATA= flaget (l. fent),
    ; de eddig CSAK a ProgramData-t vedte vele (4. lepes) - a userData torlese
    ; feltetel nelkul futott. Igy frissitesi (adat-megorzo) modban is elveszett a
    ; `.env`, benne a Setup Wizard altal generalt JWT_SECRET + SQLCIPHER_KEY
    ; titkokkal es a SETUP_COMPLETED markerrel.
    ; A Helga-tunet (2026-05-04) ellen ma mar runtime-vedelem van:
    ; `main.ts` userData `.env` migration + `first-run.ts` ujra-wizard.
    DetailPrint "4a/5 - Electron userData (.env, config) torlese..."
    SetShellVarContext current
    ${If} $PreserveData == "1"
        DetailPrint "  PRESERVE_DATA=1: userData MEGTARTVA - $APPDATA\valuta-penztar"
    ${Else}
        RMDir /r "$APPDATA\valuta-penztar"
    ${EndIf}
    SetShellVarContext all

    ; --- 4b. Firewall rules cleanup (BUG-03 fix) ---
    DetailPrint "4b/5 - Tuzfalszabalyok torlese..."
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-Backend"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-PostgreSQL"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="BestChange-Backend (8080)"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="BestChange-PostgreSQL (54320)"'

    ; --- 4c. PGPASSFILE environment variable cleanup (BUG-04 fix) ---
    DetailPrint "4c/5 - PGPASSFILE kornyezeti valtozo torlese..."
    nsExec::ExecToLog 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PGPASSFILE /f'

        ; --- 5. Registry cleanup ---
    DetailPrint "5/5 - Registry bejegyzesek torlese..."
    DeleteRegKey HKLM "Software\BestChange"
    DeleteRegKey HKLM "Software\BestChange\ValutavaltoPenztar"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar"

    DetailPrint ""
    DetailPrint "============================================"
    DetailPrint "KESZ! A regi telepites teljesen eltavolitva."
    DetailPrint "Most futtathatod a Penztar-Setup-${VERSION}.exe fajlt."
    DetailPrint "============================================"

    MessageBox MB_OK|MB_ICONINFORMATION "Eltavolitas kesz!$\r$\n$\r$\nMost telepitheted az uj verziot:$\r$\nPenztar-Setup-${VERSION}.exe (rendszergazdakent)"
SectionEnd
