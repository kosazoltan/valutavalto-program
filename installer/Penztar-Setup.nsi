; =============================================================================
; Valutavalto Penztar � Egyfajlos Windows Telepito v7.0
; NSIS 3.x Script � Production Quality
; =============================================================================
; v7.0: S6-04 PostgreSQL trust?scram-sha-256 hardening for ALL users including postgres.
;       postgres superuser gets random password (generate-secrets.ps1 5th output line).
;       .pgpass created at $DATA_DIR\config\.pgpass for service/maintenance access.
;       Upgrade path: passwords set while PG running (trust), then pg_hba hardened after stop.
; v6.1: Eszter review fixes: E6-01 IfSilent +2?+1 (fatal abort in silent mode),
;       E6-02 config dir ACL hardening (inheritance removed, explicit grants),
;       E6-03 uninstaller process-death wait loop, E6-04 firewall remoteip=127.0.0.1,
;       S6-01 default password warning, S6-05 backend dir RX+logs F,
;       S6-06 silent uninstall secrets cleanup, S6-07 CORS localhost:3000 removed,
;       S6-10 secure wipe before SQL/PS1 temp file deletion (forensic prevention)
; v6: Nora dependency research alapjan:
;     - PostgreSQL 16 ? 17 upgrade
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

; --- Windows EXE Version Info (Properties ? Reszletek) ---
VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey /LANG=1038 "ProductName" "Valutavalto Penztar"
VIAddVersionKey /LANG=1038 "CompanyName" "Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "LegalCopyright" "� 2026 Exclusive Best Change Zrt."
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

; --- Oldalak ---
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\penztar-client\LICENSE.txt"
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
; v2.3.1 Codex P1 fix: upgrade mode flag — ha "1", a SecInstall NEM torli a ProgramData-t
Var UPGRADE_MODE

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
    ; Helyes sorrend: STOP ? pg_ctl ? KILL ? WAIT ? REMOVE
    ; =====================================================================
    DetailPrint "Korabbi telepites ellenorzese..."

    ; --- 1a. STOP services via NSSM (graceful, keeps service registration) ---
    DetailPrint "  Szolgaltatasok leallitasa..."
    ; F-N-08: nsExec nem shell ? 2>nul eltavolitva
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
        DetailPrint "  postgres.exe meg fut � scoped kill..."
        nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    ${EndIf}
    nsProcess::_FindProcess "java.exe"
    Pop $0
    ${If} $0 == 0
        DetailPrint "  java.exe fut � scoped kill (BestChange)..."
        nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    ${EndIf}
    Sleep 2000

    ; --- 1d. WAIT for file locks (F1-A: fully scoped, F-N-04: stack leak fix) ---
    DetailPrint "  Varakozas a fajlzarak feloldasara..."
    StrCpy $R0 0
    lock_wait_loop:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 15
            DetailPrint "  Idotullepes � folytatas (fajlzar lehetseges)."
            Goto lock_wait_done
        ${EndIf}
        ; F1-A: scoped postgres check, F-N-04: Pop both exit code AND stdout
        nsExec::ExecToStack 'powershell.exe -NoProfile -Command "if(Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' }){exit 1}else{exit 0}"'
        Pop $0  ; exit code
        Pop $1  ; stdout (F-N-04 fix: prevent stack leak)
        ${If} $0 == 0
            ; BestChange postgres dead � check java (scoped)
            nsExec::ExecToStack 'powershell.exe -NoProfile -Command "if(Get-Process java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' }){exit 1}else{exit 0}"'
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
            DetailPrint "  Idotullepes � folytatas (service lehet Marked for deletion)."
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
    ; FAZIS 1f: LockedList � locked fajlok detektalasa
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
    ; FAZIS 1g: Port ellenorzes (G2-01 fix: cleanup UTAN, nem .onInit-ben)
    ; Silent upgrade-nel a regi service-ek mar lealltak a Fazis 1-ben,
    ; tehat a port check itt mar nem ad hamis pozitivot.
    ; =====================================================================
    DetailPrint "Port ellenorzes..."
    nsExec::ExecToStack 'cmd.exe /C netstat -an | findstr ":54320 " | findstr "LISTENING"'
    Pop $0
    Pop $1  ; stdout
    ${If} $0 == 0
        IfSilent +2
        MessageBox MB_YESNO|MB_ICONQUESTION "A 54320-as port meg foglalt a cleanup utan.$\r$\n$\r$\nLehetseges, hogy egy masik PostgreSQL peldany fut.$\r$\n$\r$\nFolytatja?" IDYES +2
        Abort
    ${EndIf}

    nsExec::ExecToStack 'cmd.exe /C netstat -an | findstr ":8080 " | findstr "LISTENING"'
    Pop $0
    Pop $1  ; stdout
    ${If} $0 == 0
        IfSilent +2
        MessageBox MB_YESNO|MB_ICONQUESTION "A 8080-as port meg foglalt a cleanup utan.$\r$\n$\r$\nLehetseges, hogy egy masik alkalmazas hasznalja.$\r$\n$\r$\nFolytatja?" IDYES +2
        Abort
    ${EndIf}

    ; =====================================================================
    ; FAZIS 2: Fajlok masolasa
    ; =====================================================================

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

    ; --- Scripts ---
    SetOutPath "$DATA_DIR\scripts"
    File "${STAGE_DIR}\scripts\*.*"

    ; --- Electron App ---
    DetailPrint "Penztar alkalmazas telepitese..."
    SetOutPath $INSTDIR
    ; RE-hardening: strip source maps, test/dev files, git metadata from Electron bundle
    File /r /x "*.map" /x "*.test.js" /x "*.spec.js" /x "jest.config.*" /x ".gitattributes" /x ".gitignore" /x ".gitmodules" /x "*.test.ts" /x "*.spec.ts" /x "*.stories.*" "${STAGE_DIR}\electron\*.*"

    ; =====================================================================
    ; FAZIS 2B: VC++ Redistributable (2015-2022 x64) � PG17 elofeltetel
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

    ; =====================================================================
    ; FAZIS 3: Konfiguracio generalasa
    ; =====================================================================
    DetailPrint "Konfiguracio generalasa..."
    SetOutPath "$DATA_DIR\config"

    ; =====================================================================
    ; Per-install random secret generalas
    ; Kulon PS1 fajl � NSIS nem tudja a PowerShell {} blokkokat inline kezelni
    ; A script 5 sort ir: JWT_SECRET, ENCRYPTION_SALT, ENCRYPTION_KEY, DB_PASSWORD, PG_ADMIN_PASSWORD
    ; =====================================================================
    SetOutPath "$INSTDIR"
    File "scripts\generate-secrets.ps1"
    nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\generate-secrets.ps1"'
    Pop $1  ; exit code
    Pop $2  ; output = 5 lines

    ; Parse 5 lines � $2=jwt, $4=salt, $6=key, $8=dbpw, $9=pgadminpw
    StrCpy $R0 $2  ; save full output

    ${WordFind} $R0 "$\r$\n" "+1" $2
    ${WordFind} $R0 "$\r$\n" "+2" $4
    ${WordFind} $R0 "$\r$\n" "+3" $6
    ${WordFind} $R0 "$\r$\n" "+4" $8
    ${WordFind} $R0 "$\r$\n" "+5" $9

    ; F3-C: Abort if secret generation failed (no weak fallback)
    ; E6-01 fix: IfSilent +1 (only skip MessageBox, NOT Abort)
    ${If} $1 != 0
    ${OrIf} $2 == ""
    ${OrIf} $4 == ""
    ${OrIf} $6 == ""
    ${OrIf} $8 == ""
    ${OrIf} $9 == ""
        IfSilent +1
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
    FileWrite $0 "server.port=8080$\r$\n"
    FileWrite $0 "spring.datasource.url=jdbc:postgresql://localhost:54320/valuta$\r$\n"
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
    FileWrite $0 "cors.allowed-origins=http://localhost:3000,http://localhost:5173,http://localhost:8080,app://localhost,file://$\r$\n"
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
    FileWrite $0 "penztar.bootstrap.company-code=EBC$\r$\n"
    FileWrite $0 "penztar.bootstrap.worker-code=BORSI$\r$\n"
    FileWrite $0 "penztar.bootstrap.role-code=CASHIER$\r$\n"
    FileClose $0

    ; .env for Electron
    FileOpen $0 "$INSTDIR\.env" w
    FileWrite $0 "VITE_API_URL=http://localhost:8080/api/v1$\r$\n"
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
        ; F4-A: initdb with trust (temporary � hardened after user setup)
        DetailPrint "  initdb futtatasa..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\initdb.exe" -D "$DATA_DIR\pgsql\data" -U postgres -E UTF8 --locale=C --auth=trust'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ; E6-01 fix: IfSilent +1
        ${If} $0 != 0
            IfSilent +1
            MessageBox MB_OK|MB_ICONSTOP "HIBA: Az adatbazis inicializalas sikertelen (initdb).$\r$\nHibakod: $0$\r$\n$\r$\nEllenorizze, hogy van-e eleg hely a lemezen."
            Abort
        ${EndIf}

        ; PostgreSQL port + security config
        FileOpen $0 "$DATA_DIR\pgsql\data\postgresql.conf" a
        FileSeek $0 0 END
        FileWrite $0 "$\r$\n# Penztar installer config$\r$\n"
        FileWrite $0 "port = 54320$\r$\n"
        FileWrite $0 "listen_addresses = 'localhost'$\r$\n"
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
        ; E6-01 fix: IfSilent +1
        ${If} $0 != 0
            IfSilent +1
            MessageBox MB_OK|MB_ICONSTOP "HIBA: PostgreSQL nem indult el.$\r$\nEllenorizze a log fajlt:$\r$\n$DATA_DIR\pgsql\log\postgresql.log"
            Abort
        ${EndIf}

        ; Wait for PG to accept connections
        DetailPrint "  Varakozas az adatbazisra..."
        StrCpy $R0 0
        pg_wait_loop:
            IntOp $R0 $R0 + 1
            ; E6-01 fix: IfSilent +1 (pg_ctl stop + Abort always runs)
            ${If} $R0 > 20
                IfSilent +1
                MessageBox MB_OK|MB_ICONSTOP "HIBA: PostgreSQL nem valaszol 20 masodpercen belul."
                nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 10'
                Abort
            ${EndIf}
            Sleep 1000
            nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -c "SELECT 1" -t -A'
            Pop $0
            Pop $1  ; stdout (stack balance)
            ${If} $0 != 0
                Goto pg_wait_loop
            ${EndIf}
        DetailPrint "  PostgreSQL kesz!"

        ; Create database
        DetailPrint "  Adatbazis letrehozasa: valuta"
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\createdb.exe" -p 54320 -U postgres valuta'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETES: Adatbazis mar letezhet (kod: $0)"
        ${EndIf}

        ; Create user � createuser CLI first, then SQL fallback
        DetailPrint "  Felhasznalo letrehozasa: valuta_user"
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\createuser.exe" -p 54320 -U postgres --no-superuser --no-createdb --no-createrole valuta_user'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  createuser kod: $0 � SQL fallback..."
            ; SQL fallback: CREATE ROLE IF NOT EXISTS (PG 16+: DO block)
            FileOpen $0 "$DATA_DIR\scripts\create-user-fallback.sql" w
            FileWrite $0 "DO $$$$ BEGIN$\r$\n"
            FileWrite $0 "  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'valuta_user') THEN$\r$\n"
            FileWrite $0 "    CREATE ROLE valuta_user LOGIN;$\r$\n"
            FileWrite $0 "  END IF;$\r$\n"
            FileWrite $0 "END $$$$;$\r$\n"
            FileClose $0
            nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -f "$DATA_DIR\scripts\create-user-fallback.sql"'
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

        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -d valuta -f "$DATA_DIR\scripts\setup-user.sql"'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETES: setup-user.sql kod: $0 � folytatas"
        ${EndIf}

        ; S6-10 fix: Secure wipe before delete (NTFS forensic recovery prevention)
        FileOpen $0 "$DATA_DIR\scripts\setup-user.sql" w
        FileWrite $0 "-- WIPED --$\r$\n"
        FileClose $0
        Delete "$DATA_DIR\scripts\setup-user.sql"

        ; Verify user � SQL file only, exact marker check (no inline -c fallback)
        FileOpen $0 "$DATA_DIR\scripts\verify-user.sql" w
        FileWrite $0 "SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_roles WHERE rolname='valuta_user') THEN 'ROLE_OK' ELSE 'ROLE_MISSING' END;$\r$\n"
        FileClose $0
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -t -A -f "$DATA_DIR\scripts\verify-user.sql"'
        Pop $R1
        Pop $R2
        ; S6-10 fix: Secure wipe before delete (uses $0 as file handle � does NOT touch R1/R2)
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

        DetailPrint "  HIBA: valuta_user verify sikertelen � rollback indul"
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
        IfSilent +1
        MessageBox MB_OK|MB_ICONSTOP "HIBA: A valuta_user adatbazis felhasznalo letrehozasa/ellenorzese sikertelen.$\r$\nA telepito rollbackelte a felkesz allapotot.$\r$\n$\r$\nVerify output: [$R2]$\r$\nEllenorizze a PostgreSQL logot:$\r$\n$DATA_DIR\pgsql\log\postgresql.log"
        Abort
        verify_user_ok:
        DetailPrint "  valuta_user letrehozva es ellenorizve!"

        ; Seed data � ATHELYEZVE Fazis 6 backend health check UTAN-ra
        ; (A Flyway migraciok hozzak letre a tablakat a backend indulasakor,
        ;  ezert a seed-data.sql csak a backend health check UTAN futhat le.)
        ;  Lasd: FAZIS 6 vege � "Seed adatok betoltese" blokk

        ; S6-04: Harden pg_hba.conf � scram-sha-256 for ALL users (including postgres)
        DetailPrint "  pg_hba.conf biztonsagi beallitas..."
        FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" w
        FileWrite $0 "# Penztar installer � hardened auth (v1.7.0 S6-04)$\r$\n"
        FileWrite $0 "# TYPE  DATABASE  USER         ADDRESS       METHOD$\r$\n"
        FileWrite $0 "host    all       valuta_user  127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       valuta_user  ::1/128       scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     ::1/128       scram-sha-256$\r$\n"
        FileClose $0
        DetailPrint "  pg_hba.conf kesz (S6-04: minden user scram-sha-256)"

        ; S6-04: Create .pgpass for service/maintenance access
        DetailPrint "  .pgpass letrehozas (postgres admin)..."
        FileOpen $0 "$DATA_DIR\config\.pgpass" w
        FileWrite $0 "localhost:54320:*:postgres:$9$\r$\n"
        FileWrite $0 "127.0.0.1:54320:*:postgres:$9$\r$\n"
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
        ; F-N-06 fix: Upgrade telepites � jelszo frissites a meglevo DB-ben
        DetailPrint "  Meglevo adatbazis � jelszo frissites..."

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

        ; Start PG temporarily (now with trust auth)
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\pg_ctl.exe" start -D "$DATA_DIR\pgsql\data" -l "$DATA_DIR\pgsql\log\postgresql.log" -w -t 30'
        Pop $0
        Pop $1
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETES: PG nem indult el frissiteshez � jelszo kihagyva"
            Goto db_done
        ${EndIf}

        ; Update password to match new config
        ; S6-04: Set BOTH valuta_user AND postgres passwords (PG runs with trust)
        FileOpen $0 "$DATA_DIR\scripts\update-password.sql" w
        FileWrite $0 "ALTER USER valuta_user WITH PASSWORD '$8';$\r$\n"
        FileWrite $0 "ALTER USER postgres WITH PASSWORD '$9';$\r$\n"
        FileClose $0
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -d valuta -f "$DATA_DIR\scripts\update-password.sql"'
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

        ; F-N-10 fix: Upgrade � config fajl frissites az uj jelszavakkal
        ; (a generate-secrets.ps1 uj titkokat generalt, azokat KELL a config-ba irni)
        DetailPrint "  application-local.properties frissites (upgrade)..."
        FileOpen $0 "$DATA_DIR\config\application-local.properties" w
        FileWrite $0 "# Valutavalto Penztar - lokalis konfig$\r$\n"
        FileWrite $0 "# Automatikusan generalta a telepito (upgrade)$\r$\n"
        FileWrite $0 "server.port=8080$\r$\n"
        FileWrite $0 "spring.datasource.url=jdbc:postgresql://localhost:54320/valuta$\r$\n"
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
        FileWrite $0 "cors.allowed-origins=http://localhost:3000,http://localhost:5173,http://localhost:8080,app://localhost,file://$\r$\n"
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
        FileClose $0
        DetailPrint "  Config frissitve az uj jelszavakkal!"

        ; Stop temp PG
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
        Sleep 2000

        ; S6-04: pg_hba.conf hardening az upgrade agban is � scram-sha-256 mindenhol
        DetailPrint "  pg_hba.conf biztonsagi beallitas (upgrade)..."
        FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" w
        FileWrite $0 "# Penztar installer � hardened auth (v1.7.0 S6-04 upgrade)$\r$\n"
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
        FileWrite $0 "localhost:54320:*:postgres:$9$\r$\n"
        FileWrite $0 "127.0.0.1:54320:*:postgres:$9$\r$\n"
        FileClose $0

        ; S6-04: Update PGPASSFILE for installer session (upgrade � new password)
        System::Call 'Kernel32::SetEnvironmentVariable(t "PGPASSFILE", t "$DATA_DIR\config\.pgpass")'

    db_done:

    ; =====================================================================
    ; FAZIS 5: Windows szolgaltatasok
    ; =====================================================================
    DetailPrint "Szolgaltatasok regisztralasa..."

    ; --- PostgreSQL service ---
    ; postgres.exe kozvetlenul (NEM pg_ctl!) � NSSM + pg_ctl = "Paused" bug
    ; NetworkService fiokkal fut � PG17 elutasitja az admin/LocalSystem futast!
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
    ; E6-02 fix: Config dir ACL hardening � locale-independent SIDs + recursive child reset
    ; *S-1-5-18 = SYSTEM, *S-1-5-32-544 = Administrators, *S-1-5-20 = NetworkService
    ; Root folder gets explicit ACLs, existing children are reset to inherit from the hardened root.
    nsExec::ExecToLog 'icacls "$DATA_DIR\config" /inheritance:r /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\config" /grant:r *S-1-5-18:(OI)(CI)F *S-1-5-32-544:(OI)(CI)F *S-1-5-20:(OI)(CI)RX /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\config\*" /reset /T /C /Q'
    ; G2-05 fix: RX (not just R) � Java needs eXecute to traverse directories
    nsExec::ExecToLog 'icacls "$DATA_DIR\jre" /grant *S-1-5-20:(OI)(CI)RX /T /Q'

    ; =====================================================================
    ; FAZIS 5B: Windows Firewall szabalyok (localhost portok)
    ; Corporate VPN/firewall policy blokkolhatja a localhost forgalmat is.
    ; Forras: shared/valuta-installer-dependency-report.md
    ; =====================================================================
    DetailPrint "Windows Firewall szabalyok beallitasa..."
    ; Elobb toroljuk a regieket (idempotens � ha nincs, nem hiba)
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-Backend"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-PostgreSQL"'
    ; E6-04 fix: remoteip=127.0.0.1 � localhost-only portok, ne legyenek network-accessible
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="Valutavalto-Backend" dir=in action=allow protocol=TCP localport=8080 remoteip=127.0.0.1 profile=any'
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="Valutavalto-PostgreSQL" dir=in action=allow protocol=TCP localport=54320 remoteip=127.0.0.1 profile=any'
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
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -c "SELECT 1" -t -A'
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
    DetailPrint "  Varakozas a Backend szerverre (ez 30-60 masodpercig tarthat)..."
    StrCpy $R0 0
    be_svc_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 60
            IfSilent be_svc_done
            MessageBox MB_OK|MB_ICONEXCLAMATION "FIGYELMEZTETES: A Backend szerver nem indult el 120 masodpercen belul.$\r$\n$\r$\nEllenorizze a logot:$\r$\n$DATA_DIR\backend\logs\service-stderr.log$\r$\n$\r$\nA telepites befejezodik, de ujrainditas szukseges lehet."
            Goto be_svc_done
        ${EndIf}
        Sleep 2000
        nsExec::ExecToStack 'powershell -NoProfile -Command "try{(Invoke-WebRequest -Uri http://localhost:8080/actuator/health -UseBasicParsing -TimeoutSec 3).StatusCode}catch{1}"'
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
    nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -h 127.0.0.1 -p 54320 -U postgres -d valuta -f "$DATA_DIR\scripts\seed-data.sql"'
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
    IfSilent +1
    MessageBox MB_OK|MB_ICONEXCLAMATION "FONTOS: A dolgozok alapertelmezett jelszava '1234'.$\r$\n$\r$\nAz elso bejelentkezes utan AZONNAL valtoztassa meg a jelszavakat!$\r$\n$\r$\nErintett felhasznalok: BORSI, BALI, KASZA"

    ; =====================================================================
    ; FAZIS 7: Parancsikonok
    ; =====================================================================
    ; T-02 fix: Regi shortcutok torlese upgrade elott (flat .lnk maradvanyok)
    Delete "$SMPROGRAMS\Valutavalto Penztar.lnk"
    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"

    DetailPrint "Parancsikonok letrehozasa..."
    CreateDirectory "$SMPROGRAMS\Valutavalto Penztar"
    CreateShortcut "$SMPROGRAMS\Valutavalto Penztar\Valutavalto Penztar.lnk" "$INSTDIR\Penztar.exe" "" "$INSTDIR\Penztar.exe" 0
    CreateShortcut "$SMPROGRAMS\Valutavalto Penztar\Szolgaltatasok inditasa.lnk" "$DATA_DIR\scripts\start-services.bat" "" "" 0
    CreateShortcut "$SMPROGRAMS\Valutavalto Penztar\Szolgaltatasok leallitasa.lnk" "$DATA_DIR\scripts\stop-services.bat" "" "" 0
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

    ; Scoped process kill
    nsProcess::_FindProcess "postgres.exe"
    Pop $0
    ${If} $0 == 0
        nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    ${EndIf}
    nsProcess::_FindProcess "java.exe"
    Pop $0
    ${If} $0 == 0
        nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    ${EndIf}

    ; E6-03 fix: Wait for process death before removing services (max 10s)
    DetailPrint "  Varakozas a folyamatok leallasara..."
    StrCpy $R0 0
    un_kill_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 10
            DetailPrint "  Timeout � folytatas"
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

    DetailPrint "Alkalmazas fajlok eltavolitasa..."
    RMDir /r "$INSTDIR"

    ; F-N-02 fix: Silent uninstall ? safe default (keep data)
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
        ; S6-04: .pgpass contains postgres admin password � must be wiped
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

    Delete "$DESKTOP\Valutavalto Penztar.lnk"
    RMDir /r "$SMPROGRAMS\Valutavalto Penztar"

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

    ; =====================================================================
    ; v2.3.0: Egysegest flow — egyetlen telepito kezel minden forgatokonyvet
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
IGEN = FRISSITES (ajanlott)$\r$\n    Az adatbazis es a beallitasok MEGMARADNAK.$\r$\n\
    Csak a program reszei frissulnek.$\r$\n$\r$\n\
NEM = GYARI RESET (teljes wipe)$\r$\n    MINDEN adat TOROLVE lesz (DB, config, tranzakciok).$\r$\n\
    Szuzen indul, mintha elso telepites lenne.$\r$\n$\r$\n\
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
    ; onInit only checks x64 + admin + elozo verzio detect — port check is post-cleanup in SecInstall
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
    IfSilent +3
    MessageBox MB_YESNO|MB_ICONQUESTION "Biztosan eltavolitja a Valutavalto Penztart?" IDYES +2
    Abort
FunctionEnd
