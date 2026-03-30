; =========================================================================
; Valutaváltó Pénztár — Standalone Cleanup/Eltávolító
; Régi telepítések maradékainak teljes eltávolítása
; =========================================================================

!include "MUI2.nsh"

!ifndef VERSION
  !define VERSION "1.4.0"
!endif
!ifndef BUILD_DATE
  !define BUILD_DATE "dev"
!endif

; --- Windows EXE Version Info ---
VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey /LANG=1038 "ProductName" "Valutaváltó Pénztár Eltávolító"
VIAddVersionKey /LANG=1038 "CompanyName" "Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "LegalCopyright" "© 2026 Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "FileDescription" "Valutaváltó Pénztár — Teljes Eltávolító"
VIAddVersionKey /LANG=1038 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1038 "ProductVersion" "${VERSION} (${BUILD_DATE})"

Name "Valutaváltó Pénztár - Eltávolító ${VERSION}"
OutFile "build\Penztar-Eltavolito-${VERSION}-${BUILD_DATE}.exe"
RequestExecutionLevel admin
Unicode true

; --- UI ---
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Hungarian"

Section "Eltávolítás"
    SetDetailsView show

    DetailPrint "============================================"
    DetailPrint "Valutaváltó Pénztár — Teljes Eltávolítás"
    DetailPrint "============================================"
    DetailPrint ""

    ; --- 1. STOP services (NSSM + net stop fallback) ---
    DetailPrint "1/5 — Szolgáltatások leállítása..."
    IfFileExists "C:\ProgramData\BestChange\tools\nssm.exe" 0 cleanup_netstop
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" stop BestChange-Backend 2>nul'
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" stop BestChange-PostgreSQL 2>nul'
    cleanup_netstop:
    nsExec::ExecToLog 'net stop BestChange-Backend 2>nul'
    nsExec::ExecToLog 'net stop BestChange-PostgreSQL 2>nul'
    Sleep 3000

    ; pg_ctl graceful stop
    IfFileExists "C:\ProgramData\BestChange\pgsql\bin\pg_ctl.exe" 0 cleanup_skip_pgctl
        nsExec::ExecToLog '"C:\ProgramData\BestChange\pgsql\bin\pg_ctl.exe" stop -D "C:\ProgramData\BestChange\pgsql\data" -m fast -w -t 30'
    cleanup_skip_pgctl:
    Sleep 2000

    ; --- 2. KILL leftover processes (scoped!) ---
    DetailPrint "2/5 — Futó folyamatok leállítása..."
    nsExec::ExecToLog 'taskkill /F /IM Penztar.exe 2>nul'
    nsExec::ExecToLog 'taskkill /F /IM "Valutavalto Penztar.exe" 2>nul'
    ; Scoped kill: only BestChange-path postgres/java (nem globális!)
    nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    Sleep 2000

    ; --- 3. REMOVE services (only after processes are dead!) ---
    DetailPrint "3/5 — Szolgáltatások eltávolítása..."
    IfFileExists "C:\ProgramData\BestChange\tools\nssm.exe" 0 cleanup_scdelete
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" remove BestChange-Backend confirm'
        nsExec::ExecToLog '"C:\ProgramData\BestChange\tools\nssm.exe" remove BestChange-PostgreSQL confirm'
    cleanup_scdelete:
    nsExec::ExecToLog 'sc.exe delete BestChange-Backend 2>nul'
    nsExec::ExecToLog 'sc.exe delete BestChange-PostgreSQL 2>nul'
    Sleep 1000

    ; --- 4. Remove directories ---
    DetailPrint "4/5 — Fájlok és mappák törlése (5 lépéses: STOP→KILL→REMOVE→DELETE→REGISTRY)..."

    ; Program Files locations
    RMDir /r "$PROGRAMFILES\Valutavalto Penztar"
    RMDir /r "$PROGRAMFILES\ValutavaltoPenztar"
    RMDir /r "$PROGRAMFILES\Penztar"

    ; ProgramData
    RMDir /r "C:\ProgramData\BestChange"

    ; Desktop shortcuts
    Delete "$DESKTOP\Valutaváltó Pénztár.lnk"
    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    Delete "$DESKTOP\Penztar.lnk"

    ; Start menu
    RMDir /r "$SMPROGRAMS\Valutaváltó Pénztár"
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"

    ; --- 5. Registry cleanup ---
    DetailPrint "5/5 — Registry bejegyzések törlése..."
    DeleteRegKey HKLM "Software\BestChange"
    DeleteRegKey HKLM "Software\BestChange\ValutavaltoPenztar"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar"

    DetailPrint ""
    DetailPrint "============================================"
    DetailPrint "KÉSZ! A régi telepítés teljesen eltávolítva."
    DetailPrint "Most futtathatod a Penztar-Setup-1.1.0.exe fájlt."
    DetailPrint "============================================"

    MessageBox MB_OK|MB_ICONINFORMATION "Eltávolítás kész!$\r$\n$\r$\nMost telepítheted az új verziót:$\r$\nPenztar-Setup-1.1.0.exe (rendszergazdaként)"
SectionEnd
