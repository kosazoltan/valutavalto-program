; =========================================================================
; Valutavalto Penztar — Standalone Cleanup/Eltavolito
; Regi telepitesek maradekainak teljes eltavolitasa
; =========================================================================

!include "MUI2.nsh"

!ifndef VERSION
  !define VERSION "2.1.8"
!endif
!ifndef BUILD_DATE
  !define BUILD_DATE "dev"
!endif

; --- Windows EXE Version Info ---
VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey /LANG=1038 "ProductName" "Valutavalto Penztar Eltavolito"
VIAddVersionKey /LANG=1038 "CompanyName" "Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "LegalCopyright" "© 2026 Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "FileDescription" "Valutavalto Penztar — Teljes Eltavolito"
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

Section "Eltavolitas"
    SetDetailsView show

    DetailPrint "============================================"
    DetailPrint "Valutavalto Penztar — Teljes Eltavolitas"
    DetailPrint "============================================"
    DetailPrint ""

    ; --- 1. STOP services (NSSM + net stop fallback) ---
    DetailPrint "1/5 — Szolgaltatasok leallitasa..."
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
    DetailPrint "2/5 — Futo folyamatok leallitasa..."
    nsExec::ExecToLog 'taskkill /F /IM Penztar.exe'
    nsExec::ExecToLog 'taskkill /F /IM "Valutavalto Penztar.exe"'
    ; Scoped kill: only BestChange-path postgres/java (nem globalis!)
    nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    Sleep 2000

    ; --- 3. REMOVE services (only after processes are dead!) ---
    DetailPrint "3/5 — Szolgaltatasok eltavolitasa..."
    IfFileExists "C:\ProgramData\BestChange\tools\nssm.exe" 0 cleanup_scdelete
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" remove BestChange-Backend confirm'
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" remove BestChange-PostgreSQL confirm'
    cleanup_scdelete:
    nsExec::ExecToLog 'sc.exe delete BestChange-Backend'
    nsExec::ExecToLog 'sc.exe delete BestChange-PostgreSQL'
    Sleep 1000

    ; --- 4. Remove directories ---
    DetailPrint "4/5 — Fajlok es mappak torlese (5 lepeses: STOP?KILL?REMOVE?DELETE?REGISTRY)..."

    ; Program Files locations (F-N-10: PROGRAMFILES64 for x64 installs)
    RMDir /r "$PROGRAMFILES64\Valutavalto Penztar"
    RMDir /r "$PROGRAMFILES64\ValutavaltoPenztar"
    RMDir /r "$PROGRAMFILES64\Penztar"
    ; Legacy 32-bit leftovers
    RMDir /r "$PROGRAMFILES\Valutavalto Penztar"
    RMDir /r "$PROGRAMFILES\ValutavaltoPenztar"

    ; ProgramData
    RMDir /r "C:\ProgramData\BestChange"

    ; Desktop shortcuts
    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    Delete "$DESKTOP\Penztar.lnk"

    ; Start menu
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"

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
    DetailPrint "5/5 — Registry bejegyzesek torlese..."
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
