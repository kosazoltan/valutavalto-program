; =============================================================================
; Valutavalto Penztar - Egyfajlos Windows Telepito v7.0
; NSIS 3.x Script - Production Quality
; =============================================================================
; v7.0: S6-04 PostgreSQL trust->scram-sha-256 hardening for ALL users including postgres.
;       postgres superuser gets random password (generate-secrets.ps1 5th output line).
;       .pgpass created at $DATA_DIR\config\.pgpass for service/maintenance access.
;       Upgrade path: passwords set while PG running (trust), then pg_hba hardened after stop.
; v6.1: Eszter review fixes: E6-01 fatal abort in silent mode (a +2->+1 valtoztatas
;     v2.28.79-ben VISSZAJAVITVA +2 0-ra: a +1 nem ugrott semmit, igy a MessageBox
;     /S modban is megjelent es a nema telepito blokkolt — empirikusan mérve),
;       E6-02 config dir ACL hardening (inheritance removed, explicit grants),
;       E6-03 uninstaller process-death wait loop, E6-04 firewall remoteip=127.0.0.1,
;       S6-01 default password warning, S6-05 backend dir RX+logs F,
;       S6-06 silent uninstall secrets cleanup, S6-07 CORS localhost:3000 removed,
;       S6-10 secure wipe before SQL/PS1 temp file deletion (forensic prevention)
; v6: Nora dependency research alapjan:
;     - PostgreSQL 16 -> 17 upgrade
;     - Windows Firewall szabalyok (8080, 54320)
;     - Firewall cleanup uninstall-nal
;     - Dependency report: shared/valuta-installer-dependency-report.md
; v5.1: Gabor review fixes: G2-01 port check after cleanup, G2-04 service wait,
;       G2-05 icacls RX, G2-06 abort cleanup callback
; v5: Eszter review fixes: F-N-01 cmd.exe port check, F-N-02 silent uninstall,
;     F-N-03 vc_redist bundled, F-N-04 stack leak fix, F-N-06 db_exists upgrade,
;     F-N-07 ReadRegDWORD, F-N-08 2>nul removal, F-N-09 quoted NSSM values,
;     F-N-14 LockedList SilentSearch fix
; v4: F3-A random DB jelszo, SI-A silent port abort, F4-A scram-sha-256,
;     F1-A scoped lock_wait, F5-A nssm start, F3-C no weak fallback
; v3: nsProcess + LockedList pluginok, helyes service stop sorrend,
;     pg_ctl graceful shutdown, scoped process kill
; =============================================================================

!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"
!include "WordFunc.nsh"

; --- Projekt-sajat pluginok (nsProcess, LockedList) ---
!addplugindir /x86-unicode "plugins\x86-unicode"
!addincludedir "include"

; --- Parameterek ---
!ifndef VERSION
  !define VERSION "2.1.8"
!endif
!ifndef BUILD_DATE
  !define BUILD_DATE "dev"
!endif
!ifndef STAGE_DIR
  !define STAGE_DIR "build\stage"
!endif
!ifndef OUTPUT_DIR
  !define OUTPUT_DIR "build"
!endif
; Audit TOP15 #3 (2026-07-04 incidens): kritikus Electron runtime-fajl
; post-copy verifikacio. Silent (/S) modban a MessageBox kimarad, az Abort NEM
; (ugyanaz a minta, mint a Penztar.exe-check, PR #698).
!macro VerifyElectronFile RELPATH
    ; v2.28.28 fix: relativ ugras named label helyett. A korabbi
    ; `electron_file_ok_${__LINE__}` label az NSIS 3.x-ben tobbszoros
    ; `!insertmacro` beszurasnal `.N` uniquifiert kapott a JUMP-oldalon, de a
    ; label-definicio nem — igy `could not resolve label "electron_file_ok_443.1"`
    ; compile-hibaval elszallt a release-build. A +4 relativ ugras insertion-safe.
    ; Utasitas-szamlalas: 0=IfFileExists, +1=IfSilent, +2=MessageBox, +3=Abort,
    ; +4=elso utasitas a makro UTAN.
    IfFileExists "$INSTDIR\${RELPATH}" +4 0
        IfSilent +2 0
        MessageBox MB_OK|MB_ICONSTOP "TELEPITÉS SIKERTELEN!$\r$\n$\r$\nEgy kritikus programfájl hiányzik a következő helyről:$\r$\n$INSTDIR\${RELPATH}$\r$\n$\r$\nValószínű ok: az AV (ESET, Windows Defender) blokkolta a fájl másolását. Megoldás:$\r$\n1. Kapcsolja ki az ESET-et 10 percre (Setup > Pause protection)$\r$\n2. Indítsa újra a telepítőt ($EXEFILE)$\r$\n3. Indítsa újra az ESET-et$\r$\n$\r$\nKérem jelezze a fejlesztőnek (Kósa Zoltán)."
        Abort "Electron resource file missing: ${RELPATH} — install aborted"
!macroend

; =============================================================================
; v2.3.8 BUG FIX: PowerShell -EncodedCommand b64 strings
; =============================================================================
; A korabbi inline `Where-Object { $$_.Path -like ''*BestChange*'' }` minta
; v2.3.7 Setup #1+#2 sessions soran "ParserError: ExpectedValueExpression"
; hibat dobott NSIS+PowerShell quote-szetesese miatt. Az -EncodedCommand
; UTF-16LE base64 kodolt formatot fogad el quote-mentesen.
;
; Generator: installer/scripts/compute-b64.ps1 (es scoped-kill.ps1 mint forras)
; UTF-16LE bazis-szoveg:
;   KILL_PG:    Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*BestChange*' } | Stop-Process -Force -ErrorAction SilentlyContinue
;   KILL_JAVA:  Get-Process java     -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*BestChange*' } | Stop-Process -Force -ErrorAction SilentlyContinue
;   CHECK_PG:   if (Get-Process postgres -EA 0 | Where-Object { $_.Path -like '*BestChange*' }) { exit 1 } else { exit 0 }
;   CHECK_JAVA: if (Get-Process java     -EA 0 | Where-Object { $_.Path -like '*BestChange*' }) { exit 1 } else { exit 0 }
; =============================================================================
!define PS_KILL_PG_B64    "RwBlAHQALQBQAHIAbwBjAGUAcwBzACAAcABvAHMAdABnAHIAZQBzACAALQBFAHIAcgBvAHIAQQBjAHQAaQBvAG4AIABTAGkAbABlAG4AdABsAHkAQwBvAG4AdABpAG4AdQBlACAAfAAgAFcAaABlAHIAZQAtAE8AYgBqAGUAYwB0ACAAewAgACQAXwAuAFAAYQB0AGgAIAAtAGwAaQBrAGUAIAAnACoAQgBlAHMAdABDAGgAYQBuAGcAZQAqACcAIAB9ACAAfAAgAFMAdABvAHAALQBQAHIAbwBjAGUAcwBzACAALQBGAG8AcgBjAGUAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAFMAaQBsAGUAbgB0AGwAeQBDAG8AbgB0AGkAbgB1AGUA"
!define PS_KILL_JAVA_B64  "RwBlAHQALQBQAHIAbwBjAGUAcwBzACAAagBhAHYAYQAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQAgAHwAIABXAGgAZQByAGUALQBPAGIAagBlAGMAdAAgAHsAIAAkAF8ALgBQAGEAdABoACAALQBsAGkAawBlACAAJwAqAEIAZQBzAHQAQwBoAGEAbgBnAGUAKgAnACAAfQAgAHwAIABTAHQAbwBwAC0AUAByAG8AYwBlAHMAcwAgAC0ARgBvAHIAYwBlACAALQBFAHIAcgBvAHIAQQBjAHQAaQBvAG4AIABTAGkAbABlAG4AdABsAHkAQwBvAG4AdABpAG4AdQBlAA=="
!define PS_CHECK_PG_B64   "aQBmACAAKABHAGUAdAAtAFAAcgBvAGMAZQBzAHMAIABwAG8AcwB0AGcAcgBlAHMAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAFMAaQBsAGUAbgB0AGwAeQBDAG8AbgB0AGkAbgB1AGUAIAB8ACAAVwBoAGUAcgBlAC0ATwBiAGoAZQBjAHQAIAB7ACAAJABfAC4AUABhAHQAaAAgAC0AbABpAGsAZQAgACcAKgBCAGUAcwB0AEMAaABhAG4AZwBlACoAJwAgAH0AKQAgAHsAIABlAHgAaQB0ACAAMQAgAH0AIABlAGwAcwBlACAAewAgAGUAeABpAHQAIAAwACAAfQA="
!define PS_CHECK_JAVA_B64 "aQBmACAAKABHAGUAdAAtAFAAcgBvAGMAZQBzAHMAIABqAGEAdgBhACAALQBFAHIAcgBvAHIAQQBjAHQAaQBvAG4AIABTAGkAbABlAG4AdABsAHkAQwBvAG4AdABpAG4AdQBlACAAfAAgAFcAaABlAHIAZQAtAE8AYgBqAGUAYwB0ACAAewAgACQAXwAuAFAAYQB0AGgAIAAtAGwAaQBrAGUAIAAnACoAQgBlAHMAdABDAGgAYQBuAGcAZQAqACcAIAB9ACkAIAB7ACAAZQB4AGkAdAAgADEAIAB9ACAAZQBsAHMAZQAgAHsAIABlAHgAaQB0ACAAMAAgAH0A"

; --- Windows EXE Version Info (Properties -> Reszletek) ---
VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey /LANG=1038 "ProductName" "Valutavalto Penztar"
VIAddVersionKey /LANG=1038 "CompanyName" "Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "LegalCopyright" "- 2026 Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "FileDescription" "Valutavalto Penztar Telepito"
VIAddVersionKey /LANG=1038 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1038 "ProductVersion" "${VERSION} (${BUILD_DATE})"
VIAddVersionKey /LANG=1038 "OriginalFilename" "Penztar-Setup-${VERSION}.exe"
VIAddVersionKey /LANG=1038 "InternalName" "PenztarSetup"

; --- Alapbeallitasok ---
Name "Valutavalto Penztar ${VERSION}"
OutFile "${OUTPUT_DIR}\Penztar-Setup-${VERSION}-${BUILD_DATE}.exe"
InstallDir "$PROGRAMFILES64\Valutavalto Penztar"
InstallDirRegKey HKLM "Software\BestChange\ValutavaltoPenztar" "InstallDir"
RequestExecutionLevel admin
Unicode true
SetCompressor /SOLID lzma
SetCompressorDictSize 64

; --- Branding ---
!define MUI_ICON "..\penztar-client\build\icons\app-icon-bestchange.ico"
!define MUI_UNICON "..\penztar-client\build\icons\app-icon-bestchange.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Valutavalto Penztar ${VERSION}"
!define MUI_WELCOMEPAGE_TEXT "Ez a varazslo telepiti a Valutavalto Penztar alkalmazast.$\r$\n$\r$\nA telepito automatikusan beallitja:$\r$\n  - Adatbazis szerver (PostgreSQL)$\r$\n  - Backend szerver$\r$\n  - Penztar alkalmazas$\r$\n$\r$\nTelepites elott zarjon be minden futo Penztar alkalmazast.$\r$\n$\r$\nKattintson a Kovetkezo gombra a folytatashoz."
!define MUI_FINISHPAGE_RUN "$INSTDIR\Penztar.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Penztar alkalmazas inditasa"

; --- nsDialogs (custom InstallMode page-hez) ---
!include "nsDialogs.nsh"

; --- Oldalak ---
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\penztar-client\LICENSE.txt"
; v2.5.9 Egyseges telepito: a user valassza ki a telepites tipusat
Page custom InstallModePage InstallModePageLeave
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; --- Uninstaller oldalak ---
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; --- Nyelv ---
!insertmacro MUI_LANGUAGE "Hungarian"

; --- Valtozok ---
Var DATA_DIR
Var DB_ALREADY_EXISTS
; v2.3.1 Codex P1 fix: upgrade mode flag - ha "1", a SecInstall NEM torli a ProgramData-t
Var UPGRADE_MODE
; v2.5.9 Egyseges telepito: "THIN" (csak Electron) vagy "FULL" (lokalis backend is)
Var INSTALL_MODE
Var DLG_RB_THIN
Var DLG_RB_FULL
; FULL mod: helyi PG/backend port. Alap 54320/8080, de WinNAT excludedportrange
; (Hyper-V/Docker/WSL) eseten a pick-local-ports.ps1 mas, kotheto portot valaszt.
Var PG_PORT
Var HTTP_PORT
; FKH-036 (D1 fix): az UNINSTALLER oldali /PRESERVE_DATA= flag.
; A telepito upgrade-agban mar ma is atadja (`ExecWait '$R0 /S /PRESERVE_DATA=1'`),
; de az uninstaller eddig NEM parsolta -> a userData (`.env`: JWT_SECRET,
; SQLCIPHER_KEY, SETUP_COMPLETED) a "beallitasok MEGMARADNAK" igeret ellenere
; feltetel nelkul torlodott. "1" = frissites (userData megorzes), "0" = teljes wipe.
Var UN_PRESERVE_DATA

; =============================================================================
; v2.5.9 Egyseges telepito - InstallMode valaszto custom page (nsDialogs)
; =============================================================================
Function InstallModePage
    !insertmacro MUI_HEADER_TEXT "Telepites tipusa" "Valassza ki, milyen modon szeretne hasznalni a Penztar alkalmazast."

    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 24u "A Penztar alkalmazas ket modban hasznalhato. A legtobb felhasznalonak az 'Online penztar' (alapertelmezett) elegendo - a backend szerver a Hetzner felhoben fut (excvaluta.com), igy nem kell helyi PostgreSQL/Java telepitese."
    Pop $0

    ${NSD_CreateRadioButton} 0 30u 100% 12u "Online penztar (ajanlott) - csak Penztar alkalmazas, ~90 MB"
    Pop $DLG_RB_THIN
    ${NSD_OnClick} $DLG_RB_THIN OnSelectThin

    ${NSD_CreateLabel} 16u 42u 90% 16u "A Penztar alkalmazas a Hetzner backend-re (excvaluta.com) csatlakozik. Internet kapcsolat szukseges."
    Pop $0

    ${NSD_CreateRadioButton} 0 62u 100% 12u "Offline-kepes penztar - lokalis PostgreSQL + Java backend telepitese (~280 MB)"
    Pop $DLG_RB_FULL
    ${NSD_OnClick} $DLG_RB_FULL OnSelectFull

    ${NSD_CreateLabel} 16u 74u 90% 16u "A Penztar alkalmazas mellett egy lokalis PostgreSQL adatbazis es Java backend is telepitesre kerul. Akkor valassza, ha az iroda interneten akar offline-modban is mukodjon."
    Pop $0

    ; Default: Thin (online mode)
    ${NSD_SetState} $DLG_RB_THIN ${BST_CHECKED}
    StrCpy $INSTALL_MODE "THIN"

    nsDialogs::Show
FunctionEnd

Function OnSelectThin
    StrCpy $INSTALL_MODE "THIN"
FunctionEnd

Function OnSelectFull
    StrCpy $INSTALL_MODE "FULL"
FunctionEnd

Function InstallModePageLeave
    ; A radio button OnClick handler beallitotta $INSTALL_MODE-ot.
    ; Itt csak fail-safe default-ot biztositunk.
    ${If} $INSTALL_MODE == ""
        StrCpy $INSTALL_MODE "THIN"
    ${EndIf}
    DetailPrint "Telepites tipusa: $INSTALL_MODE"
FunctionEnd

; =============================================================================
; Telepites
; =============================================================================
Section "Telepites" SecInstall
    SetOutPath $INSTDIR

    ; Data directory: C:\ProgramData\BestChange (nincs szokoz!)
    ExpandEnvStrings $DATA_DIR "%PROGRAMDATA%\BestChange"
    CreateDirectory $DATA_DIR

    ; =====================================================================
    ; FAZIS 1: Regi telepites cleanup (ha van)
    ; Helyes sorrend: STOP -> pg_ctl -> KILL -> WAIT -> REMOVE
    ; =====================================================================
    DetailPrint "Korabbi telepites ellenorzese..."

    ; --- 1a. STOP services via NSSM (graceful, keeps service registration) ---
    DetailPrint "  Szolgaltatasok leallitasa..."
    ; F-N-08: nsExec nem shell - 2>nul eltavolitva
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" stop BestChange-Backend'
    Sleep 3000
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" stop BestChange-PostgreSQL'
    Sleep 3000
    ; Fallback: net stop (ha NSSM nincs a data dir-ben)
    nsExec::ExecToLog 'net stop BestChange-Backend'
    nsExec::ExecToLog 'net stop BestChange-PostgreSQL'
    Sleep 2000

    ; --- 1b. pg_ctl stop -m fast (PostgreSQL-specifikus graceful shutdown) ---
    DetailPrint "  PostgreSQL graceful stop..."
    IfFileExists "$DATA_DIR\pgsql\bin\pg_ctl.exe" 0 skip_pgctl
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
    skip_pgctl:
    Sleep 2000

    ; --- 1c. KILL remaining BestChange processes (scoped PS) ---
    DetailPrint "  Maradek folyamatok leallitasa..."
    nsProcess::_FindProcess "postgres.exe"
    Pop $0
    ${If} $0 == 0
        DetailPrint "  postgres.exe meg fut - scoped kill..."
        ; v2.3.8: -EncodedCommand a -like quote-szetesese-bug elkerulesere
        nsExec::ExecToLog 'powershell.exe -NoProfile -EncodedCommand ${PS_KILL_PG_B64}'
    ${EndIf}
    nsProcess::_FindProcess "java.exe"
    Pop $0
    ${If} $0 == 0
        DetailPrint "  java.exe fut - scoped kill (BestChange)..."
        ; v2.3.8: -EncodedCommand a -like quote-szetesese-bug elkerulesere
        nsExec::ExecToLog 'powershell.exe -NoProfile -EncodedCommand ${PS_KILL_JAVA_B64}'
    ${EndIf}
    Sleep 2000

    ; --- 1d. WAIT for file locks (F1-A: fully scoped, F-N-04: stack leak fix) ---
    DetailPrint "  Varakozas a fajlzarak feloldasara..."
    StrCpy $R0 0
    lock_wait_loop:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 15
            DetailPrint "  Idotullepes - folytatas (fajlzar lehetseges)."
            Goto lock_wait_done
        ${EndIf}
        ; F1-A: scoped postgres check (v2.3.8: -EncodedCommand quote-bug fix)
        ; F-N-04: Pop both exit code AND stdout (stack-leak prevent)
        nsExec::ExecToStack 'powershell.exe -NoProfile -EncodedCommand ${PS_CHECK_PG_B64}'
        Pop $0  ; exit code
        Pop $1  ; stdout (F-N-04 fix: prevent stack leak)
        ${If} $0 == 0
            ; BestChange postgres dead - check java (scoped, v2.3.8: -EncodedCommand)
            nsExec::ExecToStack 'powershell.exe -NoProfile -EncodedCommand ${PS_CHECK_JAVA_B64}'
            Pop $0  ; exit code
            Pop $1  ; stdout (F-N-04 fix)
            ${If} $0 == 0
                Goto lock_wait_done
            ${EndIf}
        ${EndIf}
        Sleep 1000
        Goto lock_wait_loop
    lock_wait_done:
    Sleep 1000

    ; --- 1e. REMOVE service registration (CSAK miutan a process halott!) ---
    DetailPrint "  Regi szolgaltatasok eltavolitasa..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-Backend confirm'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-PostgreSQL confirm'
    ; Fallback: sc delete
    nsExec::ExecToLog 'cmd.exe /C sc.exe delete BestChange-Backend'
    nsExec::ExecToLog 'cmd.exe /C sc.exe delete BestChange-PostgreSQL'

    ; G2-04 fix: Wait for services to actually disappear (avoid "Marked for deletion")
    DetailPrint "  Varakozas a szolgaltatasok torlesere..."
    StrCpy $R0 0
    svc_delete_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 20
            DetailPrint "  Idotullepes - folytatas (service lehet Marked for deletion)."
            Goto svc_delete_done
        ${EndIf}
        nsExec::ExecToStack 'cmd.exe /C sc.exe query BestChange-Backend'
        Pop $0
        Pop $1
        nsExec::ExecToStack 'cmd.exe /C sc.exe query BestChange-PostgreSQL'
        Pop $2
        Pop $3
        ; sc query returns non-zero if service doesn't exist (= successfully deleted)
        ${If} $0 != 0
        ${AndIf} $2 != 0
            Goto svc_delete_done
        ${EndIf}
        Sleep 1000
        Goto svc_delete_wait
    svc_delete_done:

    ; =====================================================================
    ; FAZIS 1e2: Regi fajlok, registry, tuzfal, shortcutok torlese
    ; (Cleanup.nsi beolvasztva az egyseges telepitobe)
    ; =====================================================================
    DetailPrint "  Regi telepites maradekainak torlese..."

    ; Program Files helyek (x64 + legacy 32-bit)
    RMDir /r "$PROGRAMFILES64\Valutavalto Penztar"
    RMDir /r "$PROGRAMFILES64\ValutavaltoPenztar"
    RMDir /r "$PROGRAMFILES64\Penztar"
    RMDir /r "$PROGRAMFILES\Valutavalto Penztar"
    RMDir /r "$PROGRAMFILES\ValutavaltoPenztar"

    ; ProgramData (regi adatok)
    ; v2.3.1 Codex P1 fix #220: upgrade mode-ban MEGTARTJUK a ProgramData-t (DB + config),
    ; egyebkent (wipe mode / virgin install / legacy flow) toroljuk
    ${If} $UPGRADE_MODE == "1"
        DetailPrint "  Upgrade mode: C:\ProgramData\BestChange adatok MEGTARTVA (DB + config)."
    ${Else}
        RMDir /r "C:\ProgramData\BestChange"
    ${EndIf}

    ; Desktop shortcutok
    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    Delete "$DESKTOP\Penztar.lnk"

    ; Start Menu
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"

    ; Tuzfalszabalyok torlese
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-Backend"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-PostgreSQL"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="BestChange-Backend (8080)"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="BestChange-PostgreSQL (54320)"'

    ; PGPASSFILE kornyezeti valtozo torlese
    nsExec::ExecToLog 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PGPASSFILE /f'

    ; Registry cleanup
    SetRegView 64
    DeleteRegKey HKLM "Software\BestChange"
    DeleteRegKey HKLM "Software\BestChange\ValutavaltoPenztar"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar"

    ; DATA_DIR ujrateremtese (az elozo RMDir torolte)
    ExpandEnvStrings $DATA_DIR "%PROGRAMDATA%\BestChange"
    CreateDirectory $DATA_DIR

    ; =====================================================================
    ; FAZIS 1f: LockedList - locked fajlok detektalasa
    ; =====================================================================
    IfFileExists "$DATA_DIR\pgsql\bin\postgres.exe" 0 skip_lockedlist
        DetailPrint "  Fajlzarak ellenorzese (LockedList)..."
        LockedList::AddFolder "$DATA_DIR\pgsql\bin"
        LockedList::AddFolder "$DATA_DIR\jre\bin"
        LockedList::AddFolder "$DATA_DIR\backend"
        LockedList::SilentSearch
        ; F-N-14 fix: LockedList::SilentSearch nem ter vissza count-tal
        ; Konzervativ megoldas: egyszeru sleep a biztonsag kedveert
        Sleep 2000
    skip_lockedlist:

    ; =====================================================================
    ; FAZIS 1g: Port valasztas (G2-01: cleanup UTAN). CSAK FULL mod.
    ; A netstat LISTENING NEM eleg: Hyper-V/Docker/WSL WinNAT excludedportrange
    ; WSAEACCES-t ad bindre (Permission denied), noha semmi nem LISTENING.
    ; Empiria 2026-08-19: 54320 a 54313-54412 blokkban volt -> PG FATAL, telepites Abort.
    ; =====================================================================
    ${If} $INSTALL_MODE == "FULL"
        DetailPrint "Helyi portok valasztasa (FULL mod, lokalis backend)..."
        StrCpy $PG_PORT "54320"
        StrCpy $HTTP_PORT "8080"
        SetOutPath $DATA_DIR
        File "scripts\pick-local-ports.ps1"
        nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$DATA_DIR\pick-local-ports.ps1"'
        Pop $1  ; exit code
        Pop $2  ; stdout = "PGPORT,HTTPPORT"
        StrCpy $R0 $2
        ${WordFind} $R0 "," "+1" $3
        ${WordFind} $R0 "," "+2" $5
        ${WordFind} $3 "$\r" "+1" $3
        ${WordFind} $5 "$\r" "+1" $5
        ${WordFind} $3 "$\n" "+1" $3
        ${WordFind} $5 "$\n" "+1" $5
        FileOpen $0 "$DATA_DIR\pick-local-ports.ps1" w
        FileWrite $0 "# WIPED"
        FileClose $0
        Delete "$DATA_DIR\pick-local-ports.ps1"
        ${If} $1 != 0
        ${OrIf} $3 == ""
        ${OrIf} $5 == ""
            IfSilent +2 0
            MessageBox MB_OK|MB_ICONSTOP "HIBA: Nem talalhato szabad helyi port a PostgreSQL / backend szamara.$\r$\nA Windows (Hyper-V vagy Docker) lefoglalta a szokasos portokat.$\r$\nHibakod: $1"
            Abort
        ${EndIf}
        StrCpy $PG_PORT $3
        StrCpy $HTTP_PORT $5
        DetailPrint "  PostgreSQL port: $PG_PORT"
        DetailPrint "  Backend port: $HTTP_PORT"
        ${If} $PG_PORT != "54320"
        ${OrIf} $HTTP_PORT != "8080"
            IfSilent +2 0
            MessageBox MB_OK|MB_ICONINFORMATION "A helyi telepites a Windows altal foglalt portok miatt mas portokon indul:$\r$\n$\r$\nAdatbazis: $PG_PORT$\r$\nAlkalmazas-szerver: $HTTP_PORT$\r$\n$\r$\nA telepites folytatodik, nincs teendoje."
        ${EndIf}
    ${EndIf}

    ; =====================================================================
    ; FAZIS 2: Fajlok masolasa
    ; =====================================================================

    ; v2.5.9 EGYSEGES TELEPITO: az Electron alkalmazas MINDIG telepul (THIN + FULL modban is)
    ; --- Electron App (mindenkinek) ---
    DetailPrint "Penztar alkalmazas telepitese..."
    SetOutPath $INSTDIR
    ; RE-hardening: strip source maps, test/dev files, git metadata from Electron bundle.
    ; v2.5.62 hot-fix (Sourcery+Codex P2 PR #698): a Penztar.exe-t is KIZÁRJUK
    ; a rekurzív kibontásból (`/x "Penztar.exe"`), mert lentebb explicit
    ; `File` direktívával külön tesszük be — különben duplikálódna a 212 MB-os
    ; binary az installer data block-ban (~282 MB → ~494 MB lenne).
    File /r /x "*.map" /x "*.test.js" /x "*.spec.js" /x "jest.config.*" /x ".gitattributes" /x ".gitignore" /x ".gitmodules" /x "*.test.ts" /x "*.spec.ts" /x "*.stories.*" /x "Penztar.exe" "${STAGE_DIR}\electron\*.*"

    ; v2.5.62 hot-fix: explicit File direktiva a kritikus Penztar.exe-re
    ; (Kosa Zoltan tesztgepen, 2026-05-19: az ESET ekrn.exe silent-deny-jolta a
    ; 212 MB Electron exe-t a wildcard `*.*` rekurziv masolas soran,
    ; karantenba SEM tette, csak file-write-blokkolta. Az explicit File direktiva
    ; mas execution path-ot hasznal, talan athaladhat a deny-on.)
    ; SZÁNDÉKOS: a Penztar.exe a fenti `File /r` `/x "Penztar.exe"` exclude
    ; miatt CSAK itt kerül az installer data block-ba (egyszer, nem duplikálva).
    File "${STAGE_DIR}\electron\Penztar.exe"

    ; v2.5.62 hot-fix: post-install verify hogy a kritikus Penztar.exe valoban
    ; tenyleg a Program Files-ban van. Ha hianyzik (AV silent-deny, disk-full,
    ; permission stb.), abort+MessageBox a user-nek hogy mit tegyen.
    ; Sourcery P3 PR #698 fix: $EXEFILE-t használunk a hardcoded telepítő-név
    ; helyett, így a v2.5.63+ release-eknél is helyes lesz az utasítás.
    ; Copilot P3 PR #698 fix: a felhasználó-felé MAGÁZÓ hangnem (CLAUDE.md
    ; NULLADIK PRIORITAS: nem-informatikus végfelhasználó alapelv — magázó
    ; kommunikáció, NEM tegezés).
    ; Copilot P2 PR #698 fix: silent install (`/S` flag) esetén NE jelenjen
    ; meg interaktív MessageBox — `IfSilent +2` átugorja a MessageBox-ot,
    ; csak a `Abort` fut le. A script-ben már van minta erre (generate-secrets).
    IfFileExists "$INSTDIR\Penztar.exe" penztar_exe_ok 0
        IfSilent +2 0
        MessageBox MB_OK|MB_ICONSTOP "TELEPITÉS SIKERTELEN!$\r$\n$\r$\nA Penztar.exe (212 MB) hiányzik a következő helyről:$\r$\n$INSTDIR\Penztar.exe$\r$\n$\r$\nValószínű ok: az AV (ESET, Windows Defender) blokkolta. Megoldás:$\r$\n1. Kapcsolja ki az ESET-et 10 percre (Setup > Pause protection)$\r$\n2. Indítsa újra a telepítőt ($EXEFILE)$\r$\n3. Indítsa újra az ESET-et$\r$\n$\r$\nKérem jelezze a fejlesztőnek (Kósa Zoltán)."
        Abort "Penztar.exe missing — install aborted"
    penztar_exe_ok:
        DetailPrint "Penztar.exe verified at $INSTDIR\Penztar.exe"
    ; Kritikus Electron runtime-fajlok verifikacioja (audit TOP15 #3)
    DetailPrint "Electron runtime fajlok ellenorzese..."
    !insertmacro VerifyElectronFile "icudtl.dat"
    !insertmacro VerifyElectronFile "resources.pak"
    !insertmacro VerifyElectronFile "v8_context_snapshot.bin"
    !insertmacro VerifyElectronFile "snapshot_blob.bin"
    !insertmacro VerifyElectronFile "chrome_100_percent.pak"
    !insertmacro VerifyElectronFile "chrome_200_percent.pak"
    !insertmacro VerifyElectronFile "ffmpeg.dll"
    !insertmacro VerifyElectronFile "locales\en-US.pak"
    !insertmacro VerifyElectronFile "locales\hu.pak"
    !insertmacro VerifyElectronFile "resources\app.asar"
    DetailPrint "Electron runtime fajlok rendben (10/10)."

    ; v2.5.9: Diagnosztikai szkript bemasolasa az INSTDIR-be (mindenkinek)
    DetailPrint "Diagnosztikai eszkoz telepitese..."
    SetOutPath $INSTDIR
    File /nonfatal "${STAGE_DIR}\scripts\diagnose-penztar-network.ps1"

    ; v2.5.9: A backend-fugges file-ok CSAK FULL modban telepulnek
    ${If} $INSTALL_MODE == "FULL"
        ; --- PostgreSQL ---
        DetailPrint "PostgreSQL 17 telepitese..."
        SetOutPath "$DATA_DIR\pgsql"
        ; RE-hardening: strip source maps, test files, git metadata from pgAdmin bundle
        File /r /x "*.map" /x "*.test.js" /x "*.spec.js" /x "jest.config.*" /x ".gitattributes" /x ".gitignore" /x ".gitmodules" "${STAGE_DIR}\pgsql\*.*"
        CreateDirectory "$DATA_DIR\pgsql\data"
        CreateDirectory "$DATA_DIR\pgsql\log"

        ; --- Java Runtime ---
        DetailPrint "Java Runtime telepitese..."
        SetOutPath "$DATA_DIR\jre"
        File /r "${STAGE_DIR}\jre\*.*"

        ; --- Backend ---
        DetailPrint "Backend szerver telepitese..."
        SetOutPath "$DATA_DIR\backend"
        File "${STAGE_DIR}\backend\valuta-backend.jar"
        CreateDirectory "$DATA_DIR\backend\logs"

        ; --- NSSM + VC++ Redistributable (F-N-03 fix: vc_redist is bundled) ---
        DetailPrint "Service Manager + VC++ Runtime telepitese..."
        SetOutPath "$DATA_DIR\tools"
        File "${STAGE_DIR}\tools\nssm.exe"
        File "${STAGE_DIR}\tools\vc_redist.x64.exe"

        ; --- Scripts (lokalis backend-hez) ---
        SetOutPath "$DATA_DIR\scripts"
        File "${STAGE_DIR}\scripts\*.*"

        ; =====================================================================
        ; FAZIS 2B: VC++ Redistributable (2015-2022 x64) - PG17 elofeltetel
        ; =====================================================================
        DetailPrint "Visual C++ Runtime ellenorzes..."
        ; F-N-07 fix: ReadRegDWORD for DWORD registry value
        ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" "Installed"
        ${If} $0 != 1
            DetailPrint "  VC++ 2015-2022 Redistributable telepitese..."
            nsExec::ExecToStack '"$DATA_DIR\tools\vc_redist.x64.exe" /install /quiet /norestart'
            Pop $0
            Pop $1  ; stdout (stack balance)
            ${If} $0 != 0
            ${AndIf} $0 != 3010
                DetailPrint "  VC++ Redistributable kod: $0 (folytatas)"
            ${EndIf}
        ${Else}
            DetailPrint "  VC++ Runtime OK (registry verified)"
        ${EndIf}
    ${Else}
        DetailPrint "Online (THIN) mod: lokalis backend NEM telepul - a Penztar a Hetzner backend-re csatlakozik (excvaluta.com)."
    ${EndIf}

    ; v2.5.9: A backend-orientalt fazisok (config-gen, DB-init, service-register, firewall,
    ; service-start, seed) CSAK FULL modban futnak. THIN modban a Penztar a Hetzner-re megy.
    ${If} $INSTALL_MODE == "FULL"

    ; =====================================================================
    ; FAZIS 3: Konfiguracio generalasa
    ; =====================================================================
    DetailPrint "Konfiguracio generalasa..."
    SetOutPath "$DATA_DIR\config"

    ; =====================================================================
    ; Per-install random secret generalas
    ; Kulon PS1 fajl - NSIS nem tudja a PowerShell {} blokkokat inline kezelni
    ; A script 5 sort ir: JWT_SECRET, ENCRYPTION_SALT, ENCRYPTION_KEY, DB_PASSWORD, PG_ADMIN_PASSWORD
    ; =====================================================================
    SetOutPath "$INSTDIR"
    File "scripts\generate-secrets.ps1"
    nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\generate-secrets.ps1"'
    Pop $1  ; exit code
    Pop $2  ; output = 5 lines

    ; Parse 5 lines - $2=jwt, $4=salt, $6=key, $8=dbpw, $9=pgadminpw
    StrCpy $R0 $2  ; save full output

    ${WordFind} $R0 "$\r$\n" "+1" $2
    ${WordFind} $R0 "$\r$\n" "+2" $4
    ${WordFind} $R0 "$\r$\n" "+3" $6
    ${WordFind} $R0 "$\r$\n" "+4" $8
    ${WordFind} $R0 "$\r$\n" "+5" $9

    ; F3-C: Abort if secret generation failed (no weak fallback)
    ; E6-01 fix (v2.28.79): IfSilent +2 0 — a MessageBox kimarad, az Abort lefut.
    ; A korabbi `IfSilent +1` HIBAS volt: NSIS-ben a +1 a KOVETKEZO utasitas,
    ; azaz nem ugrik semmit, igy a MessageBox /S modban IS megjelent es a nema
    ; telepito orokre blokkolt rajta. Empirikus meres: .hermes/tmp/ifsilent-probe.nsi
    ${If} $1 != 0
    ${OrIf} $2 == ""
    ${OrIf} $4 == ""
    ${OrIf} $6 == ""
    ${OrIf} $8 == ""
    ${OrIf} $9 == ""
        IfSilent +2 0
        MessageBox MB_OK|MB_ICONSTOP "HIBA: A biztonsagi kulcsok generalasa sikertelen (PowerShell).$\r$\nEllenorizze, hogy a PowerShell elerheto-e.$\r$\nHibakod: $1"
        Abort
    ${EndIf}

    ; S6-10 fix: Secure wipe before delete (contains secret generation logic)
    FileOpen $0 "$INSTDIR\generate-secrets.ps1" w
    FileWrite $0 "# WIPED"
    FileClose $0
    Delete "$INSTDIR\generate-secrets.ps1"

    ; application-local.properties (F3-A: random DB password from $8)
    FileOpen $0 "$DATA_DIR\config\application-local.properties" w
    FileWrite $0 "# Valutavalto Penztar - lokalis konfig$\r$\n"
    FileWrite $0 "# Automatikusan generalta a telepito$\r$\n"
    FileWrite $0 "server.port=$HTTP_PORT$\r$\n"
    FileWrite $0 "spring.datasource.url=jdbc:postgresql://localhost:$PG_PORT/valuta$\r$\n"
    FileWrite $0 "spring.datasource.username=valuta_user$\r$\n"
    FileWrite $0 "spring.datasource.password=$8$\r$\n"
    FileWrite $0 "spring.datasource.driver-class-name=org.postgresql.Driver$\r$\n"
    FileWrite $0 "spring.datasource.hikari.maximum-pool-size=10$\r$\n"
    FileWrite $0 "spring.datasource.hikari.minimum-idle=2$\r$\n"
    FileWrite $0 "spring.jpa.hibernate.ddl-auto=none$\r$\n"
    FileWrite $0 "spring.jpa.show-sql=false$\r$\n"
    FileWrite $0 "spring.flyway.enabled=true$\r$\n"
    FileWrite $0 "spring.flyway.locations=classpath:db/migration$\r$\n"
    FileWrite $0 "spring.flyway.baseline-on-migrate=true$\r$\n"
    FileWrite $0 "spring.flyway.validate-on-migrate=true$\r$\n"
    FileWrite $0 "spring.flyway.out-of-order=true$\r$\n"
    FileWrite $0 "# Flyway kezeli a schemat: V0_1..V144 auto-lefutnak, seed-data.sql kiegeszit$\r$\n"
    ; S6-07 fix: dev CORS origin eltavolitva (csak Electron app origin kell)
    FileWrite $0 "cors.allowed-origins=http://localhost:3000,http://localhost:5173,http://localhost:$HTTP_PORT,app://localhost,file://$\r$\n"
    FileWrite $0 "logging.level.root=INFO$\r$\n"
    FileWrite $0 "logging.level.hu.puzzleir.valuta=INFO$\r$\n"
    FileWrite $0 "springdoc.api-docs.enabled=false$\r$\n"
    FileWrite $0 "springdoc.swagger-ui.enabled=false$\r$\n"
    FileWrite $0 "camera.enabled=false$\r$\n"
    FileWrite $0 "jwt.secret=$2$\r$\n"
    FileWrite $0 "jwt.expiration=86400000$\r$\n"
    FileWrite $0 "app.encryption.key=$6$\r$\n"
    FileWrite $0 "app.encryption.salt=$4$\r$\n"
    FileWrite $0 "management.endpoints.web.exposure.include=health,info$\r$\n"
        FileWrite $0 "management.endpoint.health.show-details=never$\r$\n"
        FileWrite $0 "management.health.mail.enabled=false$\r$\n"
        FileWrite $0 "evening.closing.artifact-success-enabled=true$\r$\n"
        FileWrite $0 "penztar.bootstrap.company-code=EBC$\r$\n"
    FileWrite $0 "penztar.bootstrap.worker-code=BORSI$\r$\n"
    FileWrite $0 "penztar.bootstrap.role-code=CASHIER$\r$\n"
    FileClose $0

    ; .env for Electron
    FileOpen $0 "$INSTDIR\.env" w
    FileWrite $0 "VITE_API_URL=http://localhost:$HTTP_PORT/api/v1$\r$\n"
    FileWrite $0 "VITE_BRANCH_CODE=EBC$\r$\n"
    FileWrite $0 "VITE_COMPANY_ID=1$\r$\n"
    FileClose $0

    ; =====================================================================
    ; FAZIS 4: Adatbazis inicializalas
    ; =====================================================================
    DetailPrint "Adatbazis inicializalasa..."
    StrCpy $DB_ALREADY_EXISTS 0

    ; Check if DB already initialized
    IfFileExists "$DATA_DIR\pgsql\data\PG_VERSION" db_exists db_init

    db_init:
        ; F4-A: initdb with trust (temporary - hardened after user setup)
        DetailPrint "  initdb futtatasa..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\initdb.exe" -D "$DATA_DIR\pgsql\data" -U postgres -E UTF8 --locale=C --auth=trust'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ; E6-01 fix (v2.28.79): IfSilent +2 0 (a +1 nem ugrott semmit -> /S blokkolt)
        ${If} $0 != 0
            IfSilent +2 0
            MessageBox MB_OK|MB_ICONSTOP "HIBA: Az adatbazis inicializalas sikertelen (initdb).$\r$\nHibakod: $0$\r$\n$\r$\nEllenorizze, hogy van-e eleg hely a lemezen."
            Abort
        ${EndIf}

        ; PostgreSQL port + security config
        FileOpen $0 "$DATA_DIR\pgsql\data\postgresql.conf" a
        FileSeek $0 0 END
        FileWrite $0 "$\r$\n# Penztar installer config$\r$\n"
        FileWrite $0 "port = $PG_PORT$\r$\n"
        FileWrite $0 "listen_addresses = '127.0.0.1'$\r$\n"
        FileWrite $0 "log_destination = 'stderr'$\r$\n"
        FileWrite $0 "logging_collector = on$\r$\n"
        FileWrite $0 "log_directory = 'log'$\r$\n"
        FileWrite $0 "password_encryption = 'scram-sha-256'$\r$\n"
        FileClose $0

        ; Start PG temporarily for DB setup
        DetailPrint "  PostgreSQL ideiglenes inditas..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\pg_ctl.exe" start -D "$DATA_DIR\pgsql\data" -l "$DATA_DIR\pgsql\log\postgresql.log" -w -t 30'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ; E6-01 fix (v2.28.79): IfSilent +2 0 (a +1 nem ugrott semmit -> /S blokkolt)
        ${If} $0 != 0
            IfSilent +2 0
            MessageBox MB_OK|MB_ICONSTOP "HIBA: PostgreSQL nem indult el (port $PG_PORT).$\r$\n$\r$\nGyakori ok: a Windows (Hyper-V/Docker) nem engedelyezi a port koteset.$\r$\nLog konyvtar: $DATA_DIR\pgsql\data\log$\r$\n(es $DATA_DIR\pgsql\log\postgresql.log)"
            Abort
        ${EndIf}

        ; Wait for PG to accept connections
        DetailPrint "  Varakozas az adatbazisra..."
        StrCpy $R0 0
        pg_wait_loop:
            IntOp $R0 $R0 + 1
            ; E6-01 fix (v2.28.79): IfSilent +2 0 — a MessageBox kimarad, a pg_ctl stop
            ; ES az Abort is lefut (a +2 a MessageBox UTANI utasitasra ugrik).
            ${If} $R0 > 20
                IfSilent +2 0
                MessageBox MB_OK|MB_ICONSTOP "HIBA: PostgreSQL nem valaszol 20 masodpercen belul (port $PG_PORT).$\r$\nLog: $DATA_DIR\pgsql\data\log"
                nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 10'
                Abort
            ${EndIf}
            Sleep 1000
            nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p $PG_PORT -U postgres -c "SELECT 1" -t -A'
            Pop $0
            Pop $1  ; stdout (stack balance)
            ${If} $0 != 0
                Goto pg_wait_loop
            ${EndIf}
        DetailPrint "  PostgreSQL kesz!"

        ; Create database
        DetailPrint "  Adatbazis letrehozasa: valuta"
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\createdb.exe" -p $PG_PORT -U postgres valuta'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETES: Adatbazis mar letezhet (kod: $0)"
        ${EndIf}

        ; Create user - createuser CLI first, then SQL fallback
        DetailPrint "  Felhasznalo letrehozasa: valuta_user"
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\createuser.exe" -p $PG_PORT -U postgres --no-superuser --no-createdb --no-createrole valuta_user'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  createuser kod: $0 - SQL fallback..."
            ; SQL fallback: CREATE ROLE IF NOT EXISTS (PG 16+: DO block)
            FileOpen $0 "$DATA_DIR\scripts\create-user-fallback.sql" w
            FileWrite $0 "DO $$$$ BEGIN$\r$\n"
            FileWrite $0 "  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'valuta_user') THEN$\r$\n"
            FileWrite $0 "    CREATE ROLE valuta_user LOGIN;$\r$\n"
            FileWrite $0 "  END IF;$\r$\n"
            FileWrite $0 "END $$$$;$\r$\n"
            FileClose $0
            nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p $PG_PORT -U postgres -f "$DATA_DIR\scripts\create-user-fallback.sql"'
            Pop $0
            Pop $1
            DetailPrint "  SQL fallback kod: $0"
            ; S6-10: secure wipe
            FileOpen $0 "$DATA_DIR\scripts\create-user-fallback.sql" w
            FileWrite $0 "-- WIPED --$\r$\n"
            FileClose $0
            Delete "$DATA_DIR\scripts\create-user-fallback.sql"
        ${EndIf}

        ; Set password + grants (F3-A: random password from $8)
        ; S6-04: Also set postgres superuser password (from $9) to eliminate trust auth
        FileOpen $0 "$DATA_DIR\scripts\setup-user.sql" w
        FileWrite $0 "ALTER USER valuta_user WITH PASSWORD '$8';$\r$\n"
        FileWrite $0 "ALTER USER postgres WITH PASSWORD '$9';$\r$\n"
        FileWrite $0 "GRANT ALL PRIVILEGES ON DATABASE valuta TO valuta_user;$\r$\n"
        FileWrite $0 "GRANT ALL ON SCHEMA public TO valuta_user;$\r$\n"
        FileWrite $0 "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO valuta_user;$\r$\n"
        FileClose $0

        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p $PG_PORT -U postgres -d valuta -f "$DATA_DIR\scripts\setup-user.sql"'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETES: setup-user.sql kod: $0 - folytatas"
        ${EndIf}

        ; S6-10 fix: Secure wipe before delete (NTFS forensic recovery prevention)
        FileOpen $0 "$DATA_DIR\scripts\setup-user.sql" w
        FileWrite $0 "-- WIPED --$\r$\n"
        FileClose $0
        Delete "$DATA_DIR\scripts\setup-user.sql"

        ; Verify user - SQL file only, exact marker check (no inline -c fallback)
        FileOpen $0 "$DATA_DIR\scripts\verify-user.sql" w
        FileWrite $0 "SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_roles WHERE rolname='valuta_user') THEN 'ROLE_OK' ELSE 'ROLE_MISSING' END;$\r$\n"
        FileClose $0
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p $PG_PORT -U postgres -t -A -f "$DATA_DIR\scripts\verify-user.sql"'
        Pop $R1
        Pop $R2
        ; S6-10 fix: Secure wipe before delete (uses $0 as file handle - does NOT touch R1/R2)
        FileOpen $0 "$DATA_DIR\scripts\verify-user.sql" w
        FileWrite $0 "-- WIPED --$\r$\n"
        FileClose $0
        Delete "$DATA_DIR\scripts\verify-user.sql"

        DetailPrint "  Verify raw output: [$R2], exit code: $R1"
        ${If} $R1 == 0
            ${If} $R2 == "ROLE_OK"
                Goto verify_user_ok
            ${EndIf}
            StrCpy $2 $R2 7
            ${If} $2 == "ROLE_OK"
                Goto verify_user_ok
            ${EndIf}
            StrCpy $2 $R2 7 1
            ${If} $2 == "ROLE_OK"
                Goto verify_user_ok
            ${EndIf}
        ${EndIf}

        DetailPrint "  HIBA: valuta_user verify sikertelen - rollback indul"
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 10'
        ${If} $DB_ALREADY_EXISTS == 0
            RMDir /r "$DATA_DIR\pgsql"
            RMDir /r "$DATA_DIR\backend"
            RMDir /r "$DATA_DIR\config"
            RMDir /r "$DATA_DIR\jre"
            RMDir /r "$DATA_DIR\tools"
            RMDir /r "$DATA_DIR\scripts"
            RMDir /r "$INSTDIR"
        ${EndIf}
        IfSilent +2 0
        MessageBox MB_OK|MB_ICONSTOP "HIBA: A valuta_user adatbazis felhasznalo letrehozasa/ellenorzese sikertelen.$\r$\nA telepito rollbackelte a felkesz allapotot.$\r$\n$\r$\nVerify output: [$R2]$\r$\nEllenorizze a PostgreSQL logot:$\r$\n$DATA_DIR\pgsql\log\postgresql.log"
        Abort
        verify_user_ok:
        DetailPrint "  valuta_user letrehozva es ellenorizve!"

        ; Seed data - ATHELYEZVE Fazis 6 backend health check UTAN-ra
        ; (A Flyway migraciok hozzak letre a tablakat a backend indulasakor,
        ;  ezert a seed-data.sql csak a backend health check UTAN futhat le.)
        ;  Lasd: FAZIS 6 vege - "Seed adatok betoltese" blokk

        ; S6-04: Harden pg_hba.conf - scram-sha-256 for ALL users (including postgres)
        DetailPrint "  pg_hba.conf biztonsagi beallitas..."
        FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" w
        FileWrite $0 "# Penztar installer - hardened auth (v1.7.0 S6-04)$\r$\n"
        FileWrite $0 "# TYPE  DATABASE  USER         ADDRESS       METHOD$\r$\n"
        FileWrite $0 "host    all       valuta_user  127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       valuta_user  ::1/128       scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     ::1/128       scram-sha-256$\r$\n"
        FileClose $0
        DetailPrint "  pg_hba.conf kesz (S6-04: minden user scram-sha-256)"

        ; F-007 (audit 2026-05-29): post-hardening validacio — a pg_hba.conf NEM tartalmazhat
        ; 'trust' auth sort. Ha az initdb ideiglenes trust-modja valamiert bennmaradt (hiba a
        ; hardening-irasban), a telepito itt HANGOSAN elbukik a PG leallitasaval — igy a penztari
        ; gepen nem maradhat hitelesites-nelkuli (trust) DB-ablak.
        ; FAIL-CLOSED (Codex P2): findstr exit-kodjai — 0 = talalt 'trust' sort; 1 = NINCS talalat
        ; (a fajl olvashato, tiszta); >=2 = HIBA (fajl nem nyithato/olvashato vagy parancs-hiba).
        ; CSAK az explicit "nincs talalat" (exit 1) szamit sikernek — minden mas (trust talalat
        ; VAGY olvasasi/parancs-hiba) biztonsagi okbol abortal, hogy egy nem-ellenorizheto
        ; pg_hba.conf se csusszon at a kapun.
        nsExec::ExecToStack 'cmd /c findstr /I /R /C:"^[^#].*trust" "$DATA_DIR\pgsql\data\pg_hba.conf"'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ${If} $0 != 1
            ${If} $0 == 0
                DetailPrint "  HIBA: pg_hba.conf meg tartalmaz 'trust' auth-ot a hardening utan!"
            ${Else}
                DetailPrint "  HIBA: pg_hba.conf trust-validacio nem futtathato (findstr kod: $0) — fail-closed!"
            ${EndIf}
            nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 10'
            IfSilent +2 0
            MessageBox MB_OK|MB_ICONSTOP "HIBA: Az adatbazis-hitelesites nem ellenorizheto biztonsagosan (pg_hba.conf trust-ellenorzes kod: $0).$\r$\nA telepito biztonsagi okbol leallt."
            Abort
        ${EndIf}
        DetailPrint "  pg_hba.conf validacio OK (nincs trust auth)"

        ; S6-04: Create .pgpass for service/maintenance access
        DetailPrint "  .pgpass letrehozas (postgres admin)..."
        FileOpen $0 "$DATA_DIR\config\.pgpass" w
        FileWrite $0 "localhost:$PG_PORT:*:postgres:$9$\r$\n"
        FileWrite $0 "127.0.0.1:$PG_PORT:*:postgres:$9$\r$\n"
        FileClose $0

        ; S6-04: Set PGPASSFILE for installer session (health check needs it)
        System::Call 'Kernel32::SetEnvironmentVariable(t "PGPASSFILE", t "$DATA_DIR\config\.pgpass")'

        ; Stop temp PG
        DetailPrint "  Ideiglenes PostgreSQL leallitas..."
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
        Sleep 2000
        Goto db_done

    db_exists:
        StrCpy $DB_ALREADY_EXISTS 1
        ; F-N-06 fix: Upgrade telepites - jelszo frissites a meglevo DB-ben
        DetailPrint "  Meglevo adatbazis - jelszo frissites..."

        ; S6-04: Set PGPASSFILE if .pgpass exists from previous v7.0+ install
        ; This is needed because pg_hba may already be scram-sha-256 (re-upgrade scenario)
        IfFileExists "$DATA_DIR\config\.pgpass" 0 +2
            System::Call 'Kernel32::SetEnvironmentVariable(t "PGPASSFILE", t "$DATA_DIR\config\.pgpass")'

        ; F-N-11 fix: Temp trust pg_hba BEFORE starting PG (upgrade path)
        ; The existing pg_hba may be scram-sha-256 from a prior install, and the
        ; .pgpass may have an outdated postgres password. Trust mode ensures psql
        ; can connect to update passwords, then we re-harden afterwards.
        IfFileExists "$DATA_DIR\pgsql\data\pg_hba.conf" 0 +6
            FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" w
            FileWrite $0 "# Temporary trust for upgrade password rotation$\r$\n"
            FileWrite $0 "host    all       all          127.0.0.1/32  trust$\r$\n"
            FileWrite $0 "host    all       all          ::1/128       trust$\r$\n"
            FileClose $0

        ; WinNAT: a regi postgresql.conf port=54320 lehet excluded range-ben
        FileOpen $0 "$DATA_DIR\pgsql\data\postgresql.conf" a
        FileSeek $0 0 END
        FileWrite $0 "$\r$\n# Penztar installer port (upgrade)$\r$\n"
        FileWrite $0 "port = $PG_PORT$\r$\n"
        FileWrite $0 "listen_addresses = '127.0.0.1'$\r$\n"
        FileClose $0

        ; Start PG temporarily (now with trust auth)
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\pg_ctl.exe" start -D "$DATA_DIR\pgsql\data" -l "$DATA_DIR\pgsql\log\postgresql.log" -w -t 30'
        Pop $0
        Pop $1
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETES: PG nem indult el frissiteshez - jelszo kihagyva"
            Goto db_done
        ${EndIf}

        ; Update password to match new config
        ; S6-04: Set BOTH valuta_user AND postgres passwords (PG runs with trust)
        FileOpen $0 "$DATA_DIR\scripts\update-password.sql" w
        FileWrite $0 "ALTER USER valuta_user WITH PASSWORD '$8';$\r$\n"
        FileWrite $0 "ALTER USER postgres WITH PASSWORD '$9';$\r$\n"
        FileClose $0
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p $PG_PORT -U postgres -d valuta -f "$DATA_DIR\scripts\update-password.sql"'
        Pop $0
        Pop $1
        ; S6-10 fix: Secure wipe before delete
        FileOpen $0 "$DATA_DIR\scripts\update-password.sql" w
        FileWrite $0 "-- WIPED --$\r$\n"
        FileClose $0
        Delete "$DATA_DIR\scripts\update-password.sql"
        ${If} $0 == 0
            DetailPrint "  DB jelszavak frissitve (valuta_user + postgres)!"
        ${Else}
            DetailPrint "  FIGYELMEZTETES: Jelszo frissites sikertelen (kod: $0)"
        ${EndIf}

        ; F-N-10 fix: Upgrade - config fajl frissites az uj jelszavakkal
        ; (a generate-secrets.ps1 uj titkokat generalt, azokat KELL a config-ba irni)
        DetailPrint "  application-local.properties frissites (upgrade)..."
        FileOpen $0 "$DATA_DIR\config\application-local.properties" w
        FileWrite $0 "# Valutavalto Penztar - lokalis konfig$\r$\n"
        FileWrite $0 "# Automatikusan generalta a telepito (upgrade)$\r$\n"
        FileWrite $0 "server.port=$HTTP_PORT$\r$\n"
        FileWrite $0 "spring.datasource.url=jdbc:postgresql://localhost:$PG_PORT/valuta$\r$\n"
        FileWrite $0 "spring.datasource.username=valuta_user$\r$\n"
        FileWrite $0 "spring.datasource.password=$8$\r$\n"
        FileWrite $0 "spring.datasource.driver-class-name=org.postgresql.Driver$\r$\n"
        FileWrite $0 "spring.datasource.hikari.maximum-pool-size=10$\r$\n"
        FileWrite $0 "spring.datasource.hikari.minimum-idle=2$\r$\n"
        FileWrite $0 "spring.jpa.hibernate.ddl-auto=none$\r$\n"
        FileWrite $0 "spring.jpa.show-sql=false$\r$\n"
        FileWrite $0 "spring.flyway.enabled=true$\r$\n"
        FileWrite $0 "spring.flyway.locations=classpath:db/migration$\r$\n"
        FileWrite $0 "spring.flyway.baseline-on-migrate=true$\r$\n"
        FileWrite $0 "spring.flyway.validate-on-migrate=true$\r$\n"
        FileWrite $0 "spring.flyway.out-of-order=true$\r$\n"
        FileWrite $0 "# Flyway kezeli a schemat: V0_1..V144 auto-lefutnak, seed-data.sql kiegeszit$\r$\n"
        FileWrite $0 "cors.allowed-origins=http://localhost:3000,http://localhost:5173,http://localhost:$HTTP_PORT,app://localhost,file://$\r$\n"
        FileWrite $0 "logging.level.root=INFO$\r$\n"
        FileWrite $0 "logging.level.hu.puzzleir.valuta=INFO$\r$\n"
        FileWrite $0 "springdoc.api-docs.enabled=false$\r$\n"
        FileWrite $0 "springdoc.swagger-ui.enabled=false$\r$\n"
        FileWrite $0 "camera.enabled=false$\r$\n"
        FileWrite $0 "jwt.secret=$2$\r$\n"
        FileWrite $0 "jwt.expiration=86400000$\r$\n"
        FileWrite $0 "app.encryption.key=$6$\r$\n"
        FileWrite $0 "app.encryption.salt=$4$\r$\n"
        FileWrite $0 "management.endpoints.web.exposure.include=health,info$\r$\n"
        FileWrite $0 "management.endpoint.health.show-details=never$\r$\n"
        FileWrite $0 "management.health.mail.enabled=false$\r$\n"
        FileWrite $0 "evening.closing.artifact-success-enabled=true$\r$\n"
        FileClose $0
        DetailPrint "  Config frissitve az uj jelszavakkal!"

        ; Stop temp PG
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
        Sleep 2000

        ; S6-04: pg_hba.conf hardening az upgrade agban is - scram-sha-256 mindenhol
        DetailPrint "  pg_hba.conf biztonsagi beallitas (upgrade)..."
        FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" w
        FileWrite $0 "# Penztar installer - hardened auth (v1.7.0 S6-04 upgrade)$\r$\n"
        FileWrite $0 "# TYPE  DATABASE  USER         ADDRESS       METHOD$\r$\n"
        FileWrite $0 "host    all       valuta_user  127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       valuta_user  ::1/128       scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     ::1/128       scram-sha-256$\r$\n"
        FileClose $0
        DetailPrint "  pg_hba.conf kesz (S6-04 upgrade path)"

        ; S6-04: Create .pgpass for maintenance access (upgrade)
        DetailPrint "  .pgpass frissites (postgres admin - upgrade)..."
        FileOpen $0 "$DATA_DIR\config\.pgpass" w
        FileWrite $0 "localhost:$PG_PORT:*:postgres:$9$\r$\n"
        FileWrite $0 "127.0.0.1:$PG_PORT:*:postgres:$9$\r$\n"
        FileClose $0

        ; S6-04: Update PGPASSFILE for installer session (upgrade - new password)
        System::Call 'Kernel32::SetEnvironmentVariable(t "PGPASSFILE", t "$DATA_DIR\config\.pgpass")'

    db_done:

    ; =====================================================================
    ; FAZIS 5: Windows szolgaltatasok
    ; =====================================================================
    DetailPrint "Szolgaltatasok regisztralasa..."

    ; --- PostgreSQL service ---
    ; postgres.exe kozvetlenul (NEM pg_ctl!) - NSSM + pg_ctl = "Paused" bug
    ; NetworkService fiokkal fut - PG17 elutasitja az admin/LocalSystem futast!
    DetailPrint "  BestChange-PostgreSQL szolgaltatas..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" install BestChange-PostgreSQL "$DATA_DIR\pgsql\bin\postgres.exe"'
    ; F-N-09 fix: quoted values for safety
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppDirectory "$DATA_DIR\pgsql"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppParameters "-D" "$DATA_DIR\pgsql\data"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL DisplayName "BestChange PostgreSQL"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL Description "Valutavalto Penztar adatbazis szerver"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL ObjectName "NT AUTHORITY\NetworkService" ""'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL Start SERVICE_DEMAND_START'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppStdout "$DATA_DIR\pgsql\log\service-stdout.log"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppStderr "$DATA_DIR\pgsql\log\service-stderr.log"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppThrottle 30000'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppExit Default Restart'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppRestartDelay 3000'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppRotateFiles 1'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppRotateBytes 10485760'

    ; Grant NetworkService (*S-1-5-20 = locale-independent SID)
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\data" /grant *S-1-5-20:(OI)(CI)F /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\log" /grant *S-1-5-20:(OI)(CI)F /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\bin" /grant *S-1-5-20:(OI)(CI)RX /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\lib" /grant *S-1-5-20:(OI)(CI)RX /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\share" /grant *S-1-5-20:(OI)(CI)RX /T /Q'

    ; --- Backend service ---
    DetailPrint "  BestChange-Backend szolgaltatas..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" install BestChange-Backend "$DATA_DIR\jre\bin\java.exe"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppDirectory "$DATA_DIR\backend"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppParameters "-jar" "valuta-backend.jar" "--spring.config.additional-location=file:../config/" "--spring.profiles.active=local"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend DisplayName "BestChange Backend"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend Description "Valutavalto Penztar szerver"'
    ; F-N-12 fix: Backend runs as LocalSystem (not NetworkService)
    ; NetworkService lacks writable temp dir for Java; config ACL (E6-02) still restricts file access.
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend ObjectName LocalSystem'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend DependOnService BestChange-PostgreSQL'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend Start SERVICE_DEMAND_START'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppThrottle 120000'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppExit Default Restart'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppRestartDelay 5000'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppStdout "$DATA_DIR\backend\logs\service-stdout.log"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppStderr "$DATA_DIR\backend\logs\service-stderr.log"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppRotateFiles 1'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppRotateBytes 10485760'

    ; S6-05 fix: Backend dir RX only (JAR overwrite prevention), logs dir F (write needed)
    CreateDirectory "$DATA_DIR\backend\logs"
    nsExec::ExecToLog 'icacls "$DATA_DIR\backend" /grant *S-1-5-20:(OI)(CI)RX /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\backend\logs" /grant *S-1-5-20:(OI)(CI)F /T /Q'
    ; E6-02 fix: Config dir ACL hardening - locale-independent SIDs + recursive child reset
    ; *S-1-5-18 = SYSTEM, *S-1-5-32-544 = Administrators, *S-1-5-20 = NetworkService
    ; Root folder gets explicit ACLs, existing children are reset to inherit from the hardened root.
    nsExec::ExecToLog 'icacls "$DATA_DIR\config" /inheritance:r /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\config" /grant:r *S-1-5-18:(OI)(CI)F *S-1-5-32-544:(OI)(CI)F *S-1-5-20:(OI)(CI)RX /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\config\*" /reset /T /C /Q'
    ; G2-05 fix: RX (not just R) - Java needs eXecute to traverse directories
    nsExec::ExecToLog 'icacls "$DATA_DIR\jre" /grant *S-1-5-20:(OI)(CI)RX /T /Q'

    ; =====================================================================
    ; FAZIS 5B: Windows Firewall szabalyok (localhost portok)
    ; Corporate VPN/firewall policy blokkolhatja a localhost forgalmat is.
    ; Forras: shared/valuta-installer-dependency-report.md
    ; =====================================================================
    DetailPrint "Windows Firewall szabalyok beallitasa..."
    ; Elobb toroljuk a regieket (idempotens - ha nincs, nem hiba)
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-Backend"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-PostgreSQL"'
    ; E6-04 fix: remoteip=127.0.0.1 - localhost-only portok, ne legyenek network-accessible
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="Valutavalto-Backend" dir=in action=allow protocol=TCP localport=$HTTP_PORT remoteip=127.0.0.1 profile=any'
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="Valutavalto-PostgreSQL" dir=in action=allow protocol=TCP localport=$PG_PORT remoteip=127.0.0.1 profile=any'
    DetailPrint "  Firewall szabalyok OK"

    ; =====================================================================
    ; FAZIS 6: Szolgaltatasok inditasa + health check
    ; =====================================================================
    DetailPrint "Szolgaltatasok inditasa..."

    ; Race fix: only after ACL/config hardening flip services to AUTO_START, then start them.
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL Start SERVICE_AUTO_START'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend Start SERVICE_AUTO_START'

    ; --- PostgreSQL inditas (F5-A: nssm start) ---
    DetailPrint "  PostgreSQL inditasa..."
    nsExec::ExecToStack '"$DATA_DIR\tools\nssm.exe" start BestChange-PostgreSQL'
    Pop $0
    Pop $1  ; stdout
    ${If} $0 != 0
        DetailPrint "  FIGYELMEZTETES: PostgreSQL service start kod: $0"
    ${EndIf}

    ; Health check: PostgreSQL
    DetailPrint "  Varakozas a PostgreSQL-re..."
    StrCpy $R0 0
    pg_svc_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 30
            IfSilent pg_svc_done
            MessageBox MB_OK|MB_ICONEXCLAMATION "FIGYELMEZTETES: A PostgreSQL nem valaszol 30 masodpercen belul.$\r$\nA telepites folytatodik, de lehetseges, hogy manualis beavatkozas szukseges."
            Goto pg_svc_done
        ${EndIf}
        Sleep 1000
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p $PG_PORT -U postgres -c "SELECT 1" -t -A'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ${If} $0 != 0
            Goto pg_svc_wait
        ${EndIf}
    DetailPrint "  PostgreSQL kesz! ($R0 mp)"
    pg_svc_done:

    ; --- Backend inditas (F5-A: nssm start) ---
    DetailPrint "  Backend szerver inditasa..."
    nsExec::ExecToStack '"$DATA_DIR\tools\nssm.exe" start BestChange-Backend'
    Pop $0
    Pop $1  ; stdout
    ${If} $0 != 0
        DetailPrint "  FIGYELMEZTETES: Backend service start kod: $0"
    ${EndIf}

    ; Health check: Backend
    ; v2.3.8: timeout 60 iter (120s) -> 90 iter (180s), uzenet "30-60 mp" -> "30-90 mp"
    ; Indok: a 04-29 SetupWizard "Elakad" panaszra a backend valoban 14.5 sec alatt
    ; feljon, de ESET realtime / lassu HDD eseten 60-90 mp-be is telhet. A tobblet
    ; varakozas ingyenes (a be_svc_ready: a 200 OK-ra azonnal kilep).
    DetailPrint "  Varakozas a Backend szerverre (ez 30-90 masodpercig tarthat, lassu rendszeren akar 180 mp-ig)..."
    StrCpy $R0 0
    be_svc_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 90
            IfSilent be_svc_done
            MessageBox MB_OK|MB_ICONEXCLAMATION "FIGYELMEZTETES: A Backend szerver nem indult el 180 masodpercen belul.$\r$\n$\r$\nEllenorizze a logot:$\r$\n$DATA_DIR\backend\logs\service-stderr.log$\r$\n$\r$\nA telepites befejezodik, de ujrainditas szukseges lehet."
            Goto be_svc_done
        ${EndIf}
        Sleep 2000
        nsExec::ExecToStack 'powershell -NoProfile -Command "try{(Invoke-WebRequest -Uri http://localhost:$HTTP_PORT/actuator/health -UseBasicParsing -TimeoutSec 3).StatusCode}catch{1}"'
        Pop $0
        Pop $1
        StrCpy $2 $1 3
        ${If} $2 == "200"
            Goto be_svc_ready
        ${EndIf}
        Goto be_svc_wait

    be_svc_ready:
        IntOp $R1 $R0 * 2
        DetailPrint "  Backend szerver kesz! ($R1 mp)"
    be_svc_done:

    ; --- Seed adatok (a backend MUST be running -> Flyway migrations create tables) ---
    DetailPrint "  Seed adatok betoltese (tablak mar leteznek)..."
    ; Temp trust for psql seed (pg_hba is scram-sha-256 by now)
    FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" r
    FileRead $0 $R3
    FileClose $0
    ; Backup current pg_hba
    CopyFiles /SILENT "$DATA_DIR\pgsql\data\pg_hba.conf" "$DATA_DIR\pgsql\data\pg_hba.conf.bak"
    ; Set trust temporarily
    FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" w
    FileWrite $0 "# TEMP trust for seed$\r$\n"
    FileWrite $0 "host    all       all          127.0.0.1/32  trust$\r$\n"
    FileWrite $0 "host    all       all          ::1/128       trust$\r$\n"
    FileClose $0
    nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\pg_ctl.exe" reload -D "$DATA_DIR\pgsql\data"'
    Pop $0
    Pop $1
    Sleep 2000
    ; Run seed
    nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -h 127.0.0.1 -p $PG_PORT -U postgres -d valuta -f "$DATA_DIR\scripts\seed-data.sql"'
    Pop $0
    Pop $1
    ${If} $0 != 0
        DetailPrint "  FIGYELMEZTETES: Seed script kod: $0 (lehet hogy az adatok mar leteznek)"
    ${Else}
        DetailPrint "  Seed adatok betoltve!"
    ${EndIf}
    ; Restore hardened pg_hba
    CopyFiles /SILENT "$DATA_DIR\pgsql\data\pg_hba.conf.bak" "$DATA_DIR\pgsql\data\pg_hba.conf"
    Delete "$DATA_DIR\pgsql\data\pg_hba.conf.bak"
    nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\pg_ctl.exe" reload -D "$DATA_DIR\pgsql\data"'
    Pop $0
    Pop $1
    DetailPrint "  pg_hba.conf visszaallitva (hardened)"

    ; S6-01 fix: Figyelmeztetes az alapertelmezett jelszavakra
    IfSilent +2 0
    MessageBox MB_OK|MB_ICONEXCLAMATION "FONTOS: A dolgozok alapertelmezett jelszava '1234'.$\r$\n$\r$\nAz elso bejelentkezes utan AZONNAL valtoztassa meg a jelszavakat!$\r$\n$\r$\nErintett felhasznalok: BORSI, BALI, KASZA"

    ${EndIf} ; <-- v2.5.9: VEGE a FULL-only blokknak (FAZIS 3-6: config + DB init + service + firewall + seed)

    ; =====================================================================
    ; FAZIS 7: Parancsikonok (mindenkinek - THIN + FULL is)
    ; =====================================================================
    ; T-02 fix: Regi shortcutok torlese upgrade elott (flat .lnk maradvanyok)
    Delete "$SMPROGRAMS\Valutavalto Penztar.lnk"
    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"

    DetailPrint "Parancsikonok letrehozasa..."
    CreateDirectory "$SMPROGRAMS\Valutavalto Penztar"
    CreateShortcut "$SMPROGRAMS\Valutavalto Penztar\Valutavalto Penztar.lnk" "$INSTDIR\Penztar.exe" "" "$INSTDIR\Penztar.exe" 0
    ${If} $INSTALL_MODE == "FULL"
        ; Service-vezerlo bat-ok csak FULL modban (lokalis backend)
        CreateShortcut "$SMPROGRAMS\Valutavalto Penztar\Szolgaltatasok inditasa.lnk" "$DATA_DIR\scripts\start-services.bat" "" "" 0
        CreateShortcut "$SMPROGRAMS\Valutavalto Penztar\Szolgaltatasok leallitasa.lnk" "$DATA_DIR\scripts\stop-services.bat" "" "" 0
    ${EndIf}
    ; v2.5.9: Diagnosztikai parancsikon (mindenkinek)
    CreateShortcut "$SMPROGRAMS\Valutavalto Penztar\Halozati diagnosztika.lnk" "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File $\"$INSTDIR\diagnose-penztar-network.ps1$\"" "$INSTDIR\Penztar.exe" 0
    CreateShortcut "$SMPROGRAMS\Valutavalto Penztar\Eltavolitas.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
    CreateShortcut "$DESKTOP\Valutavalto Penztar.lnk" "$INSTDIR\Penztar.exe" "" "$INSTDIR\Penztar.exe" 0

    ; =====================================================================
    ; FAZIS 8: Registry
    ; =====================================================================
    ; BUG-07 fix: Explicit 64-bit registry view for x64 Windows
    SetRegView 64

    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "InstallDir" $INSTDIR
    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "DataDir" $DATA_DIR
    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "Version" "${VERSION}"
    ; v2.5.9: az uninstaller olvassa hogy melyik service-eket kell stoppolni/eltavolitani
    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "InstallMode" $INSTALL_MODE
    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "PgPort" $PG_PORT
    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "HttpPort" $HTTP_PORT

    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayName" "Valutavalto Penztar ${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayIcon" "$INSTDIR\Penztar.exe,0"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "Publisher" "Exclusive Best Change Zrt."
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "URLInfoAbout" "https://excbest.com"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "InstallDate" "${BUILD_DATE}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "VersionMajor" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "VersionMinor" 9
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "NoRepair" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "EstimatedSize" 430080

    WriteUninstaller "$INSTDIR\uninstall.exe"

    ; v2.5.13 NEM-INFORMATIKUS-FELHASZNALO: DNS cache flush AUTOMATIKUSAN.
    ; Ha valamelyik felhasznalo gepen IPv6 cache stale, a flush utan a friss DNS valasz
    ; megerkezik (csak A rekordok, mert a Cloudflare IPv6 OFF szerver-oldalrol).
    ; Korabban a felhasznaloknak kezzel kellett `ipconfig /flushdns`-t futtatniuk - ez TILOS.
    DetailPrint "DNS cache frissites (automatikus)..."
    nsExec::ExecToLog 'ipconfig /flushdns'

    ; v2.5.13: regi userData mappak (mojibake .env, stale config) torlese.
    ; SetShellVarContext current: a $APPDATA a current-user `Roaming\` mappajara mutat.
    ; A SetupWizard bekorul ujra futni az elso indulasnal -> tiszta start.
    ; FONTOS: ezt CSAK akkor csinaljuk, ha a userData `.env` regi/serult formatumban van.
    SetShellVarContext current
    ${If} ${FileExists} "$APPDATA\valuta-penztar\.env"
        ; A v2.5.13 Electron `main.ts` migration-je IS automatikusan javitja a hibas
        ; `VITE_API_URL="https://"` (ures URL) erteket. Itt NEM toroljuk el az egeszet,
        ; hogy a JWT_SECRET/SQLCIPHER_KEY-ek megmaradjanak a `Setup-Wizard befejezve`
        ; markeret megorzo formatum melle.
        DetailPrint "userData kompatibilitas-ellenorzes (Electron app inditasakor migracio)..."
    ${EndIf}
    SetShellVarContext all

    DetailPrint ""
    DetailPrint "========================================="
    DetailPrint "  Telepites sikeresen befejezodott!"
    DetailPrint "========================================="
SectionEnd

; =============================================================================
; Eltavolitas
; =============================================================================
Section "un.Eltavolitas"
    ReadRegStr $DATA_DIR HKLM "Software\BestChange\ValutavaltoPenztar" "DataDir"
    ${If} $DATA_DIR == ""
        ExpandEnvStrings $DATA_DIR "%PROGRAMDATA%\BestChange"
    ${EndIf}
    ; v2.5.9: olvassuk hogy melyik mode-ban telepult, hogy csak a relevans cleanup-okat csinaljuk
    ReadRegStr $INSTALL_MODE HKLM "Software\BestChange\ValutavaltoPenztar" "InstallMode"
    ${If} $INSTALL_MODE == ""
        ; Backward-compat: regi (v2.5.8 elotti) telepitesek mind FULL modban voltak
        StrCpy $INSTALL_MODE "FULL"
    ${EndIf}
    DetailPrint "Eltavolitasi mode: $INSTALL_MODE"

    ${If} $INSTALL_MODE == "FULL"
        DetailPrint "Szolgaltatasok leallitasa..."
        nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" stop BestChange-Backend'
        Sleep 3000
        nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" stop BestChange-PostgreSQL'
        Sleep 3000
        nsExec::ExecToLog 'net stop BestChange-Backend'
        nsExec::ExecToLog 'net stop BestChange-PostgreSQL'
        Sleep 2000

        IfFileExists "$DATA_DIR\pgsql\bin\pg_ctl.exe" 0 un_skip_pgctl
            nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
        un_skip_pgctl:
        Sleep 2000

        ; Scoped process kill (v2.3.8: -EncodedCommand quote-bug fix)
        nsProcess::_FindProcess "postgres.exe"
        Pop $0
        ${If} $0 == 0
            nsExec::ExecToLog 'powershell.exe -NoProfile -EncodedCommand ${PS_KILL_PG_B64}'
        ${EndIf}
        nsProcess::_FindProcess "java.exe"
        Pop $0
        ${If} $0 == 0
            nsExec::ExecToLog 'powershell.exe -NoProfile -EncodedCommand ${PS_KILL_JAVA_B64}'
        ${EndIf}
    ${Else}
        DetailPrint "THIN mode: nincs lokalis backend service eltavolitando."
    ${EndIf}

    ${If} $INSTALL_MODE == "FULL"
        ; E6-03 fix: Wait for process death before removing services (max 10s)
        DetailPrint "  Varakozas a folyamatok leallasara..."
        StrCpy $R0 0
        un_kill_wait:
            IntOp $R0 $R0 + 1
            ${If} $R0 > 10
                DetailPrint "  Timeout - folytatas"
                Goto un_kill_done
            ${EndIf}
            Sleep 1000
            nsProcess::_FindProcess "postgres.exe"
            Pop $0
            ${If} $0 == 0
                Goto un_kill_wait
            ${EndIf}
            nsProcess::_FindProcess "java.exe"
            Pop $0
            ${If} $0 == 0
                Goto un_kill_wait
            ${EndIf}
        un_kill_done:

        DetailPrint "Szolgaltatasok eltavolitasa..."
        nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-Backend confirm'
        nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-PostgreSQL confirm'
        nsExec::ExecToLog 'cmd.exe /C sc.exe delete BestChange-Backend'
        nsExec::ExecToLog 'cmd.exe /C sc.exe delete BestChange-PostgreSQL'
        Sleep 1000

        ; Firewall szabalyok eltavolitasa (F-02 fix: mind a 4 rule torlese)
        DetailPrint "Firewall szabalyok eltavolitasa..."
        nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-Backend"'
        nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-PostgreSQL"'
        nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="BestChange-Backend (8080)"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="BestChange-PostgreSQL (54320)"'

        ; F-01 fix: PGPASSFILE environment variable cleanup az uninstallerben
        nsExec::ExecToLog 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PGPASSFILE /f'
    ${EndIf} ; <-- v2.5.9: VEGE az un. FULL-only blokknak

    DetailPrint "Alkalmazas fajlok eltavolitasa..."
    RMDir /r "$INSTDIR"

    ; F-N-02 fix: Silent uninstall - safe default (keep data)
    IfSilent un_keepData
    MessageBox MB_YESNO "Toroljem az adatbazist es a konfiguraciot is?$\r$\n$\r$\nHa NEM-et valaszt, az adatok megmaradnak egy kesobbi ujratelepiteshez.$\r$\n$\r$\n($DATA_DIR)" IDYES un_deleteData IDNO un_keepData

    un_deleteData:
        DetailPrint "Adatok torlese..."
        RMDir /r "$DATA_DIR"
        Goto un_doneData

    un_keepData:
        DetailPrint "Binarisok torlese (adatok megmaradnak)..."
        ; S6-06 fix: Secrets torlese meg keep-data modban is
        Delete "$DATA_DIR\config\application-local.properties"
        ; S6-04: .pgpass contains postgres admin password - must be wiped
        FileOpen $0 "$DATA_DIR\config\.pgpass" w
        FileWrite $0 "# WIPED"
        FileClose $0
        Delete "$DATA_DIR\config\.pgpass"
        DetailPrint "  Konfiguracios fajlok torolve (titkos kulcsok eltavolitva)"
        RMDir /r "$DATA_DIR\jre"
        RMDir /r "$DATA_DIR\tools"
        RMDir /r "$DATA_DIR\scripts"
        Delete "$DATA_DIR\backend\valuta-backend.jar"

    un_doneData:

    ; v2.5.11 KRITIKUS: a Helga-tunet (2026-05-04) megelozese - torolju a userData
    ; (`%APPDATA%\valuta-penztar`) Setup-Wizard config-jat, hogy a kovetkezo telepitesnel
    ; FRISS SetupWizard induljon. A regi mojibake-os ".env" + "https://" ures URL bug-os
    ; userData NEM tornyosulhat ki a kovetkezo verzionak.
    ;
    ; FIGYELEM (D2, 2026-08-11 meressel igazolva): a `SetShellVarContext current`
    ; a FUTO PROCESS TOKENJENEK felhasznalojara oldodik fel. Ha a telepitest a
    ; bejelentkezett felhasznalo inditja "Futtatas rendszergazdakent"-tel (a
    ; docs/INSTALL_WINDOWS.md:63 szerinti ajanlott ut), akkor ez valoban a
    ; penztaros profilja. DE kulon admin-fiokkal (runas, domain-admin, jelszavas
    ; UAC-prompt) ez az ADMIN profilja, `uninstall.exe /S` SCCM/GPO alatt pedig a
    ; LocalSystem systemprofile-ja. Ezekben az esetekben az alabbi torles NEM a
    ; penztaros userData-jat erinti. Ezert a `~/.valuta` offline penzugyi DB-t a
    ; telepito TUDATOSAN nem kezeli (l. installer-cleanup-parity.tests.ps1 5. sz.).
    ;
    ; ==== FKH-036 (D1 fix): FRISSITESKOR NEM TOROLJUK ====
    ; A telepito upgrade-agja azt igeri, hogy "az adatbazis es a helyi beallitasok
    ; MEGMARADNAK", es `/PRESERVE_DATA=1`-gyel hivja ezt az uninstallert. Ez a blokk
    ; viszont eddig FELTETEL NELKUL futott, azaz torolte a `.env`-et, benne a Setup
    ; Wizard altal generalt JWT_SECRET + SQLCIPHER_KEY titkokkal es a
    ; SETUP_COMPLETED markerrel -> az igeret hamis volt.
    ;
    ; A Helga-tunet (2026-05-04) ellen ma mar KETTOS runtime-vedelem van, ezert a
    ; torles frissiteskor nem szukseges:
    ;   1. `penztar-client/electron/main.ts` userData `.env` migration: a hibas
    ;      `VITE_API_URL="https://"` erteket a titkok MEGORZESE mellett atirja.
    ;   2. `first-run.ts` ervenytelen `.env` eseten ujra futtatja a Setup Wizardot.
    ; Ugyanez az indoklas mar egyszer megjelent a telepito oldalan is (v2.5.13),
    ; ahol az installer-oldali torlest szinten visszavontak.
    ;
    ; Teljes eltavolitas / gyari reset (`PRESERVE_DATA=0`, vagy Add/Remove
    ; Programs-bol inditott manualis uninstall) eseten a torles VALTOZATLAN.
    SetShellVarContext current
    ${If} $UN_PRESERVE_DATA == "1"
        DetailPrint "Frissites (PRESERVE_DATA=1): userData MEGTARTVA - $APPDATA\valuta-penztar"
    ${ElseIf} ${FileExists} "$APPDATA\valuta-penztar\*.*"
        DetailPrint "Felhasznaloi adatok (Setup config + logok) torlese: $APPDATA\valuta-penztar"
        RMDir /r "$APPDATA\valuta-penztar"
    ${EndIf}
    ; A shortcutokat a telepito current-user contextben hozza letre, ezert
    ; az uninstallnak is ugyanabban a shell contextben kell torolnie oket.
    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"
    SetShellVarContext all  ; reset all-users context-re

    ; BUG-07 fix: 64-bit registry view in uninstaller
    SetRegView 64

    DeleteRegKey HKLM "Software\BestChange\ValutavaltoPenztar"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar"

    DetailPrint ""
    DetailPrint "Eltavolitas kesz!"
SectionEnd

; =============================================================================
; Inditasi ellenorzesek
; =============================================================================
Function .onInit
    ${IfNot} ${RunningX64}
        MessageBox MB_OK|MB_ICONSTOP "Ez az alkalmazas csak 64 bites Windows rendszeren fut."
        Abort
    ${EndIf}

    UserInfo::GetAccountType
    Pop $0
    ${If} $0 != "admin"
        MessageBox MB_OK|MB_ICONSTOP "A telepiteshez rendszergazdai jogosultsag szukseges.$\r$\n$\r$\nKattintson jobb gombbal a telepitore, majd valassza a$\r$\n'Futtatas rendszergazdakent' lehetoseget."
        Abort
    ${EndIf}

    ; v2.5.9: Silent install esetén a Custom Page nem fut, így a $INSTALL_MODE üres marad
    ; -> default = "THIN" (online mode, a Penztar a Hetzner-re csatlakozik).
    ; GUI mode: a InstallModePage felülírja a user választása szerint.
    StrCpy $INSTALL_MODE "THIN"
    StrCpy $PG_PORT "54320"
    StrCpy $HTTP_PORT "8080"

    ; =====================================================================
    ; v2.3.0: Egysegest flow - egyetlen telepito kezel minden forgatokonyvet
    ; =====================================================================
    ; 3 eset:
    ;   (1) SZUZ TELEPITES: nincs elozo verzio -> direct telepit
    ;   (2) FRISSITES (ajanlott): van elozo verzio, adat MEGMARAD
    ;   (3) TELJES UJRATELEPITES (gyari reset): adat TOROLVE, szuzen indul
    ;
    ; A felhasznalonak 3-gombos MessageBox: Frissites (Yes) / Gyari reset (No) / Megse (Cancel)
    ;
    ; Silent mode-ban (/S):
    ;   - /WIPE=1 parancssori flag -> gyari reset
    ;   - Egyebkent -> frissites (default, biztonsagos)
    ; v2.3.1 Codex P2 fix #220: 64-bit registry view (SetRegView 64) KOTELEZO,
    ; mert a WriteRegStr alul SetRegView 64-gyel ir, es 64-bit Windows-on a default
    ; olvasas a Wow6432Node-bol hozna az ertekt, igy nem talalja a telepitest.
    SetRegView 64
    StrCpy $UPGRADE_MODE "0"
    ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "UninstallString"
    ${If} $R0 != ""
        ; Silent mode handling (CI / enterprise deploy)
        IfSilent silent_mode_check

        ; Interactive user dialog (3 opcio)
        MessageBox MB_YESNOCANCEL|MB_ICONQUESTION \
            "Mar van egy telepitett Penztar verzio.$\r$\n$\r$\nMit szeretnel tenni?$\r$\n$\r$\n\
IGEN = FRISSITES (ajanlott)$\r$\n    Az adatbazis es a helyi beallitasok MEGMARADNAK.$\r$\n\
    A szerver-kapcsolati configot a telepito ujragenerlja.$\r$\n\
    Csak a program reszei frissulnek.$\r$\n$\r$\n\
NEM = GYARI RESET$\r$\n    A program, a helyi beallitasok es a szerver-oldali adatbazis$\r$\n\
    TOROLVE lesz. FIGYELEM: a penztaros gepen tarolt offline$\r$\n\
    tranzakcios adatbazis (.valuta) NEM torlodik.$\r$\n$\r$\n\
MEGSE = Telepites megszakitasa" \
            /SD IDYES \
            IDYES upgrade_mode \
            IDNO wipe_mode
        ; v2.3.0 NSIS fix: MessageBox max 8 parameter (2 return-check par).
        ; Az IDCANCEL eset fall-through-val kerul az abort_install-hoz alul.
        Goto abort_install

        silent_mode_check:
            ; Silent mode: /WIPE=1 flag dont
            ClearErrors
            ${GetOptions} "$CMDLINE" "/WIPE=" $R2
            ${If} $R2 == "1"
                Goto wipe_mode
            ${Else}
                Goto upgrade_mode
            ${EndIf}

        upgrade_mode:
            DetailPrint "=== FRISSITES MOD ==="
            DetailPrint "Elozo verzio eltavolitasa (silent, PRESERVE_DATA=1)..."
            DetailPrint "Az adatbazis + config MEGMARAD."
            ; v2.3.1 Codex P1 fix #220: UPGRADE_MODE flag jelzi a SecInstall-nak,
            ; hogy NE torolje a ProgramData-t (Fazis 1e2)
            StrCpy $UPGRADE_MODE "1"
            ExecWait '$R0 /S /PRESERVE_DATA=1' $R1
            DetailPrint "Elozo verzio eltavolitva (exit code: $R1). Adatok megorizve."
            Sleep 2000
            Goto continue_install

        wipe_mode:
            ; v2.3.0 NSIS fix: a kiterjedt confirm-MessageBox az NSIS ACP parserrel
            ; valamiert nem fordult le. Helyette: a fo MessageBox-ban az IDNO valasz
            ; mar tudatos, ott a teljes warning szoveg latszik (lasd onInit fent),
            ; igy itt csak silent-mode flow mehet kozvetlenul a wipe-ra.
            ; Ha valamiert mas uton ide kerul - silent mode-szeruen kezeljuk.
            IfSilent wipe_confirm_silent

        wipe_confirm_silent:
            DetailPrint "=== GYARI RESET MOD ==="
            DetailPrint "Elozo verzio TELJES eltavolitasa (silent, PRESERVE_DATA=0)..."
            DetailPrint "MINDEN ADAT TOROLVE LESZ."
            ExecWait '$R0 /S /PRESERVE_DATA=0' $R1
            DetailPrint "Teljes eltavolitva (exit code: $R1). Szuzen indul."
            Sleep 2000
            Goto continue_install

        abort_install:
            DetailPrint "Felhasznalo megszakitotta a telepites."
            Abort

        continue_install:
    ${EndIf}

    ; G2-01 fix: Port check MOVED to Section (after Fazis 1 cleanup)
    ; onInit only checks x64 + admin + elozo verzio detect - port check is post-cleanup in SecInstall
FunctionEnd

; G2-06 fix: Clean up temp files containing secrets on abort/failure
Function .onInstFailed
    ; DATA_DIR may not be set yet if failure is very early
    ExpandEnvStrings $DATA_DIR "%PROGRAMDATA%\BestChange"
    ; S6-10 fix: Secure wipe before delete (forensic recovery prevention)
    FileOpen $0 "$DATA_DIR\scripts\setup-user.sql" w
    FileWrite $0 "-- WIPED --$\r$\n"
    FileClose $0
    Delete "$DATA_DIR\scripts\setup-user.sql"
    FileOpen $0 "$DATA_DIR\scripts\update-password.sql" w
    FileWrite $0 "-- WIPED --$\r$\n"
    FileClose $0
    Delete "$DATA_DIR\scripts\update-password.sql"
    FileOpen $0 "$DATA_DIR\scripts\verify-user.sql" w
    FileWrite $0 "-- WIPED --$\r$\n"
    FileClose $0
    Delete "$DATA_DIR\scripts\verify-user.sql"
    FileOpen $0 "$INSTDIR\generate-secrets.ps1" w
    FileWrite $0 "# WIPED"
    FileClose $0
    Delete "$INSTDIR\generate-secrets.ps1"
    ; S6-04: .pgpass wipe on install failure
    FileOpen $0 "$DATA_DIR\config\.pgpass" w
    FileWrite $0 "# WIPED"
    FileClose $0
    Delete "$DATA_DIR\config\.pgpass"
FunctionEnd

; F-N-02 fix: silent uninstall confirmation skip
Function un.onInit
    ; FKH-036 (D1 fix): a /PRESERVE_DATA= flag parsolasa.
    ;
    ; MIERT ITT, AZ IfSilent ELOTT: a ${GetOptions} makro tobb tucat NSIS-
    ; utasitasra expandal. Az alabbi `IfSilent +3` RELATIV ugras (F-N-02 idioma),
    ; ezert a makro NEM kerulhet az IfSilent es a MessageBox koze - kulonben a +3
    ; a makro kozepere ugrana, es silent modban megjelenne a megerosito dialogus
    ; (vagy Abort futna). A parsolas ezert a fuggveny legelso muvelete.
    ;
    ; Kontraktus: a telepito upgrade-agja `/S /PRESERVE_DATA=1`-et ad at,
    ; wipe-agja `/PRESERVE_DATA=0`-t. Ures/hianyzo ertek (pl. Add/Remove
    ; Programs-bol inditott manualis eltavolitas) = "0" = teljes eltavolitas,
    ; azaz a korabbi viselkedes valtozatlan.
    StrCpy $UN_PRESERVE_DATA "0"
    ClearErrors
    ${GetOptions} "$CMDLINE" "/PRESERVE_DATA=" $UN_PRESERVE_DATA
    ${If} ${Errors}
        StrCpy $UN_PRESERVE_DATA "0"
    ${EndIf}
    ${If} $UN_PRESERVE_DATA != "1"
        StrCpy $UN_PRESERVE_DATA "0"
    ${EndIf}
    DetailPrint "Eltavolitas: PRESERVE_DATA=$UN_PRESERVE_DATA"

    IfSilent +3
    MessageBox MB_YESNO|MB_ICONQUESTION "Biztosan eltavolitja a Valutavalto Penztart?" IDYES +2
    Abort
FunctionEnd
