; =============================================================================
; Valutaváltó Pénztár — Egyfájlos Windows Telepítő v7.0
; NSIS 3.x Script — Production Quality
; =============================================================================
; v7.0: S6-04 PostgreSQL trust→scram-sha-256 hardening for ALL users including postgres.
;       postgres superuser gets random password (generate-secrets.ps1 5th output line).
;       .pgpass created at $DATA_DIR\config\.pgpass for service/maintenance access.
;       Upgrade path: passwords set while PG running (trust), then pg_hba hardened after stop.
; v6.1: Eszter review fixes: E6-01 IfSilent +2→+1 (fatal abort in silent mode),
;       E6-02 config dir ACL hardening (inheritance removed, explicit grants),
;       E6-03 uninstaller process-death wait loop, E6-04 firewall remoteip=127.0.0.1,
;       S6-01 default password warning, S6-05 backend dir RX+logs F,
;       S6-06 silent uninstall secrets cleanup, S6-07 CORS localhost:3000 removed,
;       S6-10 secure wipe before SQL/PS1 temp file deletion (forensic prevention)
; v6: Nóra dependency research alapján:
;     - PostgreSQL 16 → 17 upgrade
;     - Windows Firewall szabályok (8080, 54320)
;     - Firewall cleanup uninstall-nál
;     - Dependency report: shared/valuta-installer-dependency-report.md
; v5.1: Gábor review fixes: G2-01 port check after cleanup, G2-04 service wait,
;       G2-05 icacls RX, G2-06 abort cleanup callback
; v5: Eszter review fixes: F-N-01 cmd.exe port check, F-N-02 silent uninstall,
;     F-N-03 vc_redist bundled, F-N-04 stack leak fix, F-N-06 db_exists upgrade,
;     F-N-07 ReadRegDWORD, F-N-08 2>nul removal, F-N-09 quoted NSSM values,
;     F-N-14 LockedList SilentSearch fix
; v4: F3-A random DB jelszó, SI-A silent port abort, F4-A scram-sha-256,
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

; --- Projekt-saját pluginok (nsProcess, LockedList) ---
!addplugindir /x86-unicode "plugins\x86-unicode"
!addincludedir "include"

; --- Paraméterek ---
!ifndef VERSION
  !define VERSION "1.7.0"
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

; --- Windows EXE Version Info (Properties → Részletek) ---
VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey /LANG=1038 "ProductName" "Valutaváltó Pénztár"
VIAddVersionKey /LANG=1038 "CompanyName" "Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "LegalCopyright" "© 2026 Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "FileDescription" "Valutaváltó Pénztár Telepítő"
VIAddVersionKey /LANG=1038 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1038 "ProductVersion" "${VERSION} (${BUILD_DATE})"
VIAddVersionKey /LANG=1038 "OriginalFilename" "Penztar-Setup-${VERSION}.exe"
VIAddVersionKey /LANG=1038 "InternalName" "PenztarSetup"

; --- Alapbeállítások ---
Name "Valutaváltó Pénztár ${VERSION}"
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
!define MUI_WELCOMEPAGE_TITLE "Valutaváltó Pénztár ${VERSION}"
!define MUI_WELCOMEPAGE_TEXT "Ez a varázsló telepíti a Valutaváltó Pénztár alkalmazást.$\r$\n$\r$\nA telepítő automatikusan beállítja:$\r$\n  - Adatbázis szerver (PostgreSQL)$\r$\n  - Backend szerver$\r$\n  - Pénztár alkalmazás$\r$\n$\r$\nTelepítés előtt zárjon be minden futó Pénztár alkalmazást.$\r$\n$\r$\nKattintson a Következő gombra a folytatáshoz."
!define MUI_FINISHPAGE_RUN "$INSTDIR\Penztar.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Pénztár alkalmazás indítása"

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

; --- Változók ---
Var DATA_DIR
Var DB_ALREADY_EXISTS

; =============================================================================
; Telepítés
; =============================================================================
Section "Telepítés" SecInstall
    SetOutPath $INSTDIR

    ; Data directory: C:\ProgramData\BestChange (nincs szóköz!)
    ExpandEnvStrings $DATA_DIR "%PROGRAMDATA%\BestChange"
    CreateDirectory $DATA_DIR

    ; =====================================================================
    ; FÁZIS 1: Régi telepítés cleanup (ha van)
    ; Helyes sorrend: STOP → pg_ctl → KILL → WAIT → REMOVE
    ; =====================================================================
    DetailPrint "Korábbi telepítés ellenőrzése..."

    ; --- 1a. STOP services via NSSM (graceful, keeps service registration) ---
    DetailPrint "  Szolgáltatások leállítása..."
    ; F-N-08: nsExec nem shell → 2>nul eltávolítva
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
    DetailPrint "  Maradék folyamatok leállítása..."
    nsProcess::_FindProcess "postgres.exe"
    Pop $0
    ${If} $0 == 0
        DetailPrint "  postgres.exe még fut — scoped kill..."
        nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    ${EndIf}
    nsProcess::_FindProcess "java.exe"
    Pop $0
    ${If} $0 == 0
        DetailPrint "  java.exe fut — scoped kill (BestChange)..."
        nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    ${EndIf}
    Sleep 2000

    ; --- 1d. WAIT for file locks (F1-A: fully scoped, F-N-04: stack leak fix) ---
    DetailPrint "  Várakozás a fájlzárak feloldására..."
    StrCpy $R0 0
    lock_wait_loop:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 15
            DetailPrint "  Időtúllépés — folytatás (fájlzár lehetséges)."
            Goto lock_wait_done
        ${EndIf}
        ; F1-A: scoped postgres check, F-N-04: Pop both exit code AND stdout
        nsExec::ExecToStack 'powershell.exe -NoProfile -Command "if(Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' }){exit 1}else{exit 0}"'
        Pop $0  ; exit code
        Pop $1  ; stdout (F-N-04 fix: prevent stack leak)
        ${If} $0 == 0
            ; BestChange postgres dead — check java (scoped)
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

    ; --- 1e. REMOVE service registration (CSAK miután a process halott!) ---
    DetailPrint "  Régi szolgáltatások eltávolítása..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-Backend confirm'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-PostgreSQL confirm'
    ; Fallback: sc delete
    nsExec::ExecToLog 'cmd.exe /C sc.exe delete BestChange-Backend'
    nsExec::ExecToLog 'cmd.exe /C sc.exe delete BestChange-PostgreSQL'

    ; G2-04 fix: Wait for services to actually disappear (avoid "Marked for deletion")
    DetailPrint "  Várakozás a szolgáltatások törlésére..."
    StrCpy $R0 0
    svc_delete_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 20
            DetailPrint "  Időtúllépés — folytatás (service lehet Marked for deletion)."
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
    ; FÁZIS 1f: LockedList — locked fájlok detektálása
    ; =====================================================================
    IfFileExists "$DATA_DIR\pgsql\bin\postgres.exe" 0 skip_lockedlist
        DetailPrint "  Fájlzárak ellenőrzése (LockedList)..."
        LockedList::AddFolder "$DATA_DIR\pgsql\bin"
        LockedList::AddFolder "$DATA_DIR\jre\bin"
        LockedList::AddFolder "$DATA_DIR\backend"
        LockedList::SilentSearch
        ; F-N-14 fix: LockedList::SilentSearch nem tér vissza count-tal
        ; Konzervatív megoldás: egyszerű sleep a biztonság kedvéért
        Sleep 2000
    skip_lockedlist:

    ; =====================================================================
    ; FÁZIS 1g: Port ellenőrzés (G2-01 fix: cleanup UTÁN, nem .onInit-ben)
    ; Silent upgrade-nél a régi service-ek már leálltak a Fázis 1-ben,
    ; tehát a port check itt már nem ad hamis pozitívot.
    ; =====================================================================
    DetailPrint "Port ellenőrzés..."
    nsExec::ExecToStack 'cmd.exe /C netstat -an | findstr ":54320 " | findstr "LISTENING"'
    Pop $0
    Pop $1  ; stdout
    ${If} $0 == 0
        IfSilent +2
        MessageBox MB_YESNO|MB_ICONQUESTION "A 54320-as port még foglalt a cleanup után.$\r$\n$\r$\nLehetséges, hogy egy másik PostgreSQL példány fut.$\r$\n$\r$\nFolytatja?" IDYES +2
        Abort
    ${EndIf}

    nsExec::ExecToStack 'cmd.exe /C netstat -an | findstr ":8080 " | findstr "LISTENING"'
    Pop $0
    Pop $1  ; stdout
    ${If} $0 == 0
        IfSilent +2
        MessageBox MB_YESNO|MB_ICONQUESTION "A 8080-as port még foglalt a cleanup után.$\r$\n$\r$\nLehetséges, hogy egy másik alkalmazás használja.$\r$\n$\r$\nFolytatja?" IDYES +2
        Abort
    ${EndIf}

    ; =====================================================================
    ; FÁZIS 2: Fájlok másolása
    ; =====================================================================

    ; --- PostgreSQL ---
    DetailPrint "PostgreSQL 17 telepítése..."
    SetOutPath "$DATA_DIR\pgsql"
    ; RE-hardening: strip source maps, test files, git metadata from pgAdmin bundle
    File /r /x "*.map" /x "*.test.js" /x "*.spec.js" /x "jest.config.*" /x ".gitattributes" /x ".gitignore" /x ".gitmodules" "${STAGE_DIR}\pgsql\*.*"
    CreateDirectory "$DATA_DIR\pgsql\data"
    CreateDirectory "$DATA_DIR\pgsql\log"

    ; --- Java Runtime ---
    DetailPrint "Java Runtime telepítése..."
    SetOutPath "$DATA_DIR\jre"
    File /r "${STAGE_DIR}\jre\*.*"

    ; --- Backend ---
    DetailPrint "Backend szerver telepítése..."
    SetOutPath "$DATA_DIR\backend"
    File "${STAGE_DIR}\backend\valuta-backend.jar"
    CreateDirectory "$DATA_DIR\backend\logs"

    ; --- NSSM + VC++ Redistributable (F-N-03 fix: vc_redist is bundled) ---
    DetailPrint "Service Manager + VC++ Runtime telepítése..."
    SetOutPath "$DATA_DIR\tools"
    File "${STAGE_DIR}\tools\nssm.exe"
    File "${STAGE_DIR}\tools\vc_redist.x64.exe"

    ; --- Scripts ---
    SetOutPath "$DATA_DIR\scripts"
    File "${STAGE_DIR}\scripts\*.*"

    ; --- Electron App ---
    DetailPrint "Pénztár alkalmazás telepítése..."
    SetOutPath $INSTDIR
    ; RE-hardening: strip source maps, test/dev files, git metadata from Electron bundle
    File /r /x "*.map" /x "*.test.js" /x "*.spec.js" /x "jest.config.*" /x ".gitattributes" /x ".gitignore" /x ".gitmodules" /x "*.test.ts" /x "*.spec.ts" /x "*.stories.*" "${STAGE_DIR}\electron\*.*"

    ; =====================================================================
    ; FÁZIS 2B: VC++ Redistributable (2015-2022 x64) — PG17 előfeltétel
    ; =====================================================================
    DetailPrint "Visual C++ Runtime ellenőrzés..."
    ; F-N-07 fix: ReadRegDWORD for DWORD registry value
    ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" "Installed"
    ${If} $0 != 1
        DetailPrint "  VC++ 2015-2022 Redistributable telepítése..."
        nsExec::ExecToStack '"$DATA_DIR\tools\vc_redist.x64.exe" /install /quiet /norestart'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ${If} $0 != 0
        ${AndIf} $0 != 3010
            DetailPrint "  VC++ Redistributable kód: $0 (folytatás)"
        ${EndIf}
    ${Else}
        DetailPrint "  VC++ Runtime OK (registry verified)"
    ${EndIf}

    ; =====================================================================
    ; FÁZIS 3: Konfiguráció generálása
    ; =====================================================================
    DetailPrint "Konfiguráció generálása..."
    SetOutPath "$DATA_DIR\config"

    ; =====================================================================
    ; Per-install random secret generálás
    ; Külön PS1 fájl — NSIS nem tudja a PowerShell {} blokkokat inline kezelni
    ; A script 5 sort ír: JWT_SECRET, ENCRYPTION_SALT, ENCRYPTION_KEY, DB_PASSWORD, PG_ADMIN_PASSWORD
    ; =====================================================================
    SetOutPath "$INSTDIR"
    File "scripts\generate-secrets.ps1"
    nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\generate-secrets.ps1"'
    Pop $1  ; exit code
    Pop $2  ; output = 5 lines

    ; Parse 5 lines — $2=jwt, $4=salt, $6=key, $8=dbpw, $9=pgadminpw
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
        MessageBox MB_OK|MB_ICONSTOP "HIBA: A biztonsági kulcsok generálása sikertelen (PowerShell).$\r$\nEllenőrizze, hogy a PowerShell elérhető-e.$\r$\nHibakód: $1"
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
    FileWrite $0 "spring.jpa.hibernate.ddl-auto=update$\r$\n"
    FileWrite $0 "spring.jpa.show-sql=false$\r$\n"
    FileWrite $0 "spring.flyway.enabled=false$\r$\n"
    FileWrite $0 "# Flyway disabled: JPA ddl-auto=update manages schema, seed via init-db$\r$\n"
    ; S6-07 fix: dev CORS origin eltávolítva (csak Electron app origin kell)
    FileWrite $0 "cors.allowed-origins=app://localhost$\r$\n"
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
    ; FÁZIS 4: Adatbázis inicializálás
    ; =====================================================================
    DetailPrint "Adatbázis inicializálása..."
    StrCpy $DB_ALREADY_EXISTS 0

    ; Check if DB already initialized
    IfFileExists "$DATA_DIR\pgsql\data\PG_VERSION" db_exists db_init

    db_init:
        ; F4-A: initdb with trust (temporary — hardened after user setup)
        DetailPrint "  initdb futtatása..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\initdb.exe" -D "$DATA_DIR\pgsql\data" -U postgres -E UTF8 --locale=C --auth=trust'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ; E6-01 fix: IfSilent +1
        ${If} $0 != 0
            IfSilent +1
            MessageBox MB_OK|MB_ICONSTOP "HIBA: Az adatbázis inicializálás sikertelen (initdb).$\r$\nHibakód: $0$\r$\n$\r$\nEllenőrizze, hogy van-e elég hely a lemezen."
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
        DetailPrint "  PostgreSQL ideiglenes indítás..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\pg_ctl.exe" start -D "$DATA_DIR\pgsql\data" -l "$DATA_DIR\pgsql\log\postgresql.log" -w -t 30'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ; E6-01 fix: IfSilent +1
        ${If} $0 != 0
            IfSilent +1
            MessageBox MB_OK|MB_ICONSTOP "HIBA: PostgreSQL nem indult el.$\r$\nEllenőrizze a log fájlt:$\r$\n$DATA_DIR\pgsql\log\postgresql.log"
            Abort
        ${EndIf}

        ; Wait for PG to accept connections
        DetailPrint "  Várakozás az adatbázisra..."
        StrCpy $R0 0
        pg_wait_loop:
            IntOp $R0 $R0 + 1
            ; E6-01 fix: IfSilent +1 (pg_ctl stop + Abort always runs)
            ${If} $R0 > 20
                IfSilent +1
                MessageBox MB_OK|MB_ICONSTOP "HIBA: PostgreSQL nem válaszol 20 másodpercen belül."
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
        DetailPrint "  PostgreSQL kész!"

        ; Create database
        DetailPrint "  Adatbázis létrehozása: valuta"
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\createdb.exe" -p 54320 -U postgres valuta'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETÉS: Adatbázis már létezhet (kód: $0)"
        ${EndIf}

        ; Create user — createuser CLI first, then SQL fallback
        DetailPrint "  Felhasználó létrehozása: valuta_user"
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\createuser.exe" -p 54320 -U postgres --no-superuser --no-createdb --no-createrole valuta_user'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  createuser kód: $0 — SQL fallback..."
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
            DetailPrint "  SQL fallback kód: $0"
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
            DetailPrint "  FIGYELMEZTETÉS: setup-user.sql kód: $0 — folytatás"
        ${EndIf}

        ; S6-10 fix: Secure wipe before delete (NTFS forensic recovery prevention)
        FileOpen $0 "$DATA_DIR\scripts\setup-user.sql" w
        FileWrite $0 "-- WIPED --$\r$\n"
        FileClose $0
        Delete "$DATA_DIR\scripts\setup-user.sql"

        ; Verify user — SQL file only, exact marker check (no inline -c fallback)
        FileOpen $0 "$DATA_DIR\scripts\verify-user.sql" w
        FileWrite $0 "SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_roles WHERE rolname='valuta_user') THEN 'ROLE_OK' ELSE 'ROLE_MISSING' END;$\r$\n"
        FileClose $0
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -t -A -f "$DATA_DIR\scripts\verify-user.sql"'
        Pop $R1
        Pop $R2
        ; S6-10 fix: Secure wipe before delete (uses $0 as file handle — does NOT touch R1/R2)
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

        DetailPrint "  HIBA: valuta_user verify sikertelen — rollback indul"
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
        MessageBox MB_OK|MB_ICONSTOP "HIBA: A valuta_user adatbázis felhasználó létrehozása/ellenőrzése sikertelen.$\r$\nA telepítő rollbackelte a félkész állapotot.$\r$\n$\r$\nVerify output: [$R2]$\r$\nEllenőrizze a PostgreSQL logot:$\r$\n$DATA_DIR\pgsql\log\postgresql.log"
        Abort
        verify_user_ok:
        DetailPrint "  valuta_user létrehozva és ellenőrizve!"

        ; Seed data
        DetailPrint "  Seed adatok betöltése..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -d valuta -f "$DATA_DIR\scripts\seed-data.sql"'
        Pop $0
        Pop $1  ; stdout
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETÉS: Seed script kód: $0 (lehet hogy az adatok már léteznek)"
        ${Else}
            DetailPrint "  Seed adatok betöltve!"
        ${EndIf}

        ; S6-01 fix: Figyelmeztetés az alapértelmezett jelszavakra
        IfSilent +1
        MessageBox MB_OK|MB_ICONEXCLAMATION "FONTOS: A dolgozók alapértelmezett jelszava '1234'.$\r$\n$\r$\nAz első bejelentkezés után AZONNAL változtassa meg a jelszavakat!$\r$\n$\r$\nÉrintett felhasználók: BORSI, BALI, KASZA"

        ; S6-04: Harden pg_hba.conf — scram-sha-256 for ALL users (including postgres)
        DetailPrint "  pg_hba.conf biztonsági beállítás..."
        FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" w
        FileWrite $0 "# Penztar installer — hardened auth (v1.7.0 S6-04)$\r$\n"
        FileWrite $0 "# TYPE  DATABASE  USER         ADDRESS       METHOD$\r$\n"
        FileWrite $0 "host    all       valuta_user  127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       valuta_user  ::1/128       scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     ::1/128       scram-sha-256$\r$\n"
        FileClose $0
        DetailPrint "  pg_hba.conf kész (S6-04: minden user scram-sha-256)"

        ; S6-04: Create .pgpass for service/maintenance access
        DetailPrint "  .pgpass létrehozás (postgres admin)..."
        FileOpen $0 "$DATA_DIR\config\.pgpass" w
        FileWrite $0 "localhost:54320:*:postgres:$9$\r$\n"
        FileWrite $0 "127.0.0.1:54320:*:postgres:$9$\r$\n"
        FileClose $0

        ; S6-04: Set PGPASSFILE for installer session (health check needs it)
        System::Call 'Kernel32::SetEnvironmentVariable(t "PGPASSFILE", t "$DATA_DIR\config\.pgpass")'

        ; Stop temp PG
        DetailPrint "  Ideiglenes PostgreSQL leállítás..."
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
        Sleep 2000
        Goto db_done

    db_exists:
        StrCpy $DB_ALREADY_EXISTS 1
        ; F-N-06 fix: Upgrade telepítés — jelszó frissítés a meglévő DB-ben
        DetailPrint "  Meglévő adatbázis — jelszó frissítés..."

        ; S6-04: Set PGPASSFILE if .pgpass exists from previous v7.0+ install
        ; This is needed because pg_hba may already be scram-sha-256 (re-upgrade scenario)
        IfFileExists "$DATA_DIR\config\.pgpass" 0 +2
            System::Call 'Kernel32::SetEnvironmentVariable(t "PGPASSFILE", t "$DATA_DIR\config\.pgpass")'

        ; Start PG temporarily
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\pg_ctl.exe" start -D "$DATA_DIR\pgsql\data" -l "$DATA_DIR\pgsql\log\postgresql.log" -w -t 30'
        Pop $0
        Pop $1
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETÉS: PG nem indult el frissítéshez — jelszó kihagyva"
            Goto db_done
        ${EndIf}

        ; Update password to match new config
        ; S6-04: Set BOTH valuta_user AND postgres passwords while PG still runs with trust
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
            DetailPrint "  DB jelszavak frissítve (valuta_user + postgres)!"
        ${Else}
            DetailPrint "  FIGYELMEZTETÉS: Jelszó frissítés sikertelen (kód: $0)"
        ${EndIf}

        ; F-N-10 fix: Upgrade — config fájl frissítés az új jelszavakkal
        ; (a generate-secrets.ps1 új titkokat generált, azokat KELL a config-ba írni)
        DetailPrint "  application-local.properties frissítés (upgrade)..."
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
        FileWrite $0 "spring.jpa.hibernate.ddl-auto=update$\r$\n"
        FileWrite $0 "spring.jpa.show-sql=false$\r$\n"
        FileWrite $0 "spring.flyway.enabled=false$\r$\n"
        FileWrite $0 "# Flyway disabled: JPA ddl-auto=update manages schema, seed via init-db$\r$\n"
        FileWrite $0 "cors.allowed-origins=app://localhost$\r$\n"
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
        DetailPrint "  Config frissítve az új jelszavakkal!"

        ; Stop temp PG
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
        Sleep 2000

        ; S6-04: pg_hba.conf hardening az upgrade ágban is — scram-sha-256 mindenhol
        DetailPrint "  pg_hba.conf biztonsági beállítás (upgrade)..."
        FileOpen $0 "$DATA_DIR\pgsql\data\pg_hba.conf" w
        FileWrite $0 "# Penztar installer — hardened auth (v1.7.0 S6-04 upgrade)$\r$\n"
        FileWrite $0 "# TYPE  DATABASE  USER         ADDRESS       METHOD$\r$\n"
        FileWrite $0 "host    all       valuta_user  127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       valuta_user  ::1/128       scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     127.0.0.1/32  scram-sha-256$\r$\n"
        FileWrite $0 "host    all       postgres     ::1/128       scram-sha-256$\r$\n"
        FileClose $0
        DetailPrint "  pg_hba.conf kész (S6-04 upgrade path)"

        ; S6-04: Create .pgpass for maintenance access (upgrade)
        DetailPrint "  .pgpass frissítés (postgres admin - upgrade)..."
        FileOpen $0 "$DATA_DIR\config\.pgpass" w
        FileWrite $0 "localhost:54320:*:postgres:$9$\r$\n"
        FileWrite $0 "127.0.0.1:54320:*:postgres:$9$\r$\n"
        FileClose $0

        ; S6-04: Update PGPASSFILE for installer session (upgrade — new password)
        System::Call 'Kernel32::SetEnvironmentVariable(t "PGPASSFILE", t "$DATA_DIR\config\.pgpass")'

    db_done:

    ; =====================================================================
    ; FÁZIS 5: Windows szolgáltatások
    ; =====================================================================
    DetailPrint "Szolgáltatások regisztrálása..."

    ; --- PostgreSQL service ---
    ; postgres.exe közvetlenül (NEM pg_ctl!) — NSSM + pg_ctl = "Paused" bug
    ; NetworkService fiókkal fut — PG17 elutasítja az admin/LocalSystem futást!
    DetailPrint "  BestChange-PostgreSQL szolgáltatás..."
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
    DetailPrint "  BestChange-Backend szolgáltatás..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" install BestChange-Backend "$DATA_DIR\jre\bin\java.exe"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppDirectory "$DATA_DIR\backend"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppParameters "-jar" "valuta-backend.jar" "--spring.config.additional-location=file:../config/" "--spring.profiles.active=local"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend DisplayName "BestChange Backend"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend Description "Valutavalto Penztar szerver"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend ObjectName "NT AUTHORITY\NetworkService" ""'
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
    ; E6-02 fix: Config dir ACL hardening — locale-independent SIDs + recursive child reset
    ; *S-1-5-18 = SYSTEM, *S-1-5-32-544 = Administrators, *S-1-5-20 = NetworkService
    ; Root folder gets explicit ACLs, existing children are reset to inherit from the hardened root.
    nsExec::ExecToLog 'icacls "$DATA_DIR\config" /inheritance:r /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\config" /grant:r *S-1-5-18:(OI)(CI)F *S-1-5-32-544:(OI)(CI)F *S-1-5-20:(OI)(CI)RX /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\config\*" /reset /T /C /Q'
    ; G2-05 fix: RX (not just R) — Java needs eXecute to traverse directories
    nsExec::ExecToLog 'icacls "$DATA_DIR\jre" /grant *S-1-5-20:(OI)(CI)RX /T /Q'

    ; =====================================================================
    ; FÁZIS 5B: Windows Firewall szabályok (localhost portok)
    ; Corporate VPN/firewall policy blokkolhatja a localhost forgalmat is.
    ; Forrás: shared/valuta-installer-dependency-report.md
    ; =====================================================================
    DetailPrint "Windows Firewall szabályok beállítása..."
    ; Előbb töröljük a régieket (idempotens — ha nincs, nem hiba)
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-Backend"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-PostgreSQL"'
    ; E6-04 fix: remoteip=127.0.0.1 — localhost-only portok, ne legyenek network-accessible
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="Valutavalto-Backend" dir=in action=allow protocol=TCP localport=8080 remoteip=127.0.0.1 profile=any'
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="Valutavalto-PostgreSQL" dir=in action=allow protocol=TCP localport=54320 remoteip=127.0.0.1 profile=any'
    DetailPrint "  Firewall szabályok OK"

    ; =====================================================================
    ; FÁZIS 6: Szolgáltatások indítása + health check
    ; =====================================================================
    DetailPrint "Szolgáltatások indítása..."

    ; Race fix: only after ACL/config hardening flip services to AUTO_START, then start them.
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL Start SERVICE_AUTO_START'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend Start SERVICE_AUTO_START'

    ; --- PostgreSQL indítás (F5-A: nssm start) ---
    DetailPrint "  PostgreSQL indítása..."
    nsExec::ExecToStack '"$DATA_DIR\tools\nssm.exe" start BestChange-PostgreSQL'
    Pop $0
    Pop $1  ; stdout
    ${If} $0 != 0
        DetailPrint "  FIGYELMEZTETÉS: PostgreSQL service start kód: $0"
    ${EndIf}

    ; Health check: PostgreSQL
    DetailPrint "  Várakozás a PostgreSQL-re..."
    StrCpy $R0 0
    pg_svc_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 30
            IfSilent pg_svc_done
            MessageBox MB_OK|MB_ICONEXCLAMATION "FIGYELMEZTETÉS: A PostgreSQL nem válaszol 30 másodpercen belül.$\r$\nA telepítés folytatódik, de lehetséges, hogy manuális beavatkozás szükséges."
            Goto pg_svc_done
        ${EndIf}
        Sleep 1000
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -c "SELECT 1" -t -A'
        Pop $0
        Pop $1  ; stdout (stack balance)
        ${If} $0 != 0
            Goto pg_svc_wait
        ${EndIf}
    DetailPrint "  PostgreSQL kész! ($R0 mp)"
    pg_svc_done:

    ; --- Backend indítás (F5-A: nssm start) ---
    DetailPrint "  Backend szerver indítása..."
    nsExec::ExecToStack '"$DATA_DIR\tools\nssm.exe" start BestChange-Backend'
    Pop $0
    Pop $1  ; stdout
    ${If} $0 != 0
        DetailPrint "  FIGYELMEZTETÉS: Backend service start kód: $0"
    ${EndIf}

    ; Health check: Backend
    DetailPrint "  Várakozás a Backend szerverre (ez 30-60 másodpercig tarthat)..."
    StrCpy $R0 0
    be_svc_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 60
            IfSilent be_svc_done
            MessageBox MB_OK|MB_ICONEXCLAMATION "FIGYELMEZTETÉS: A Backend szerver nem indult el 120 másodpercen belül.$\r$\n$\r$\nEllenőrizze a logot:$\r$\n$DATA_DIR\backend\logs\service-stderr.log$\r$\n$\r$\nA telepítés befejeződik, de újraindítás szükséges lehet."
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
        DetailPrint "  Backend szerver kész! ($R1 mp)"
    be_svc_done:

    ; =====================================================================
    ; FÁZIS 7: Parancsikonok
    ; =====================================================================
    ; T-02 fix: Régi shortcutok törlése upgrade előtt (flat .lnk maradványok)
    Delete "$SMPROGRAMS\Valutaváltó Pénztár.lnk"
    Delete "$DESKTOP\Valutaváltó Pénztár.lnk"
    RMDir /r "$SMPROGRAMS\Valutaváltó Pénztár"

    DetailPrint "Parancsikonok létrehozása..."
    CreateDirectory "$SMPROGRAMS\Valutaváltó Pénztár"
    CreateShortcut "$SMPROGRAMS\Valutaváltó Pénztár\Valutaváltó Pénztár.lnk" "$INSTDIR\Penztar.exe" "" "$INSTDIR\Penztar.exe" 0
    CreateShortcut "$SMPROGRAMS\Valutaváltó Pénztár\Szolgáltatások indítása.lnk" "$DATA_DIR\scripts\start-services.bat" "" "" 0
    CreateShortcut "$SMPROGRAMS\Valutaváltó Pénztár\Szolgáltatások leállítása.lnk" "$DATA_DIR\scripts\stop-services.bat" "" "" 0
    CreateShortcut "$SMPROGRAMS\Valutaváltó Pénztár\Eltávolítás.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
    CreateShortcut "$DESKTOP\Valutaváltó Pénztár.lnk" "$INSTDIR\Penztar.exe" "" "$INSTDIR\Penztar.exe" 0

    ; =====================================================================
    ; FÁZIS 8: Registry
    ; =====================================================================
    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "InstallDir" $INSTDIR
    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "DataDir" $DATA_DIR
    WriteRegStr HKLM "Software\BestChange\ValutavaltoPenztar" "Version" "${VERSION}"

    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayName" "Valutaváltó Pénztár ${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayIcon" "$INSTDIR\Penztar.exe,0"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "Publisher" "Exclusive Best Change Zrt."
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "URLInfoAbout" "https://excbest.com"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "InstallDate" "${BUILD_DATE}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "VersionMajor" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "VersionMinor" 6
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "NoRepair" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "EstimatedSize" 430080

    WriteUninstaller "$INSTDIR\uninstall.exe"

    DetailPrint ""
    DetailPrint "========================================="
    DetailPrint "  Telepítés sikeresen befejeződött!"
    DetailPrint "========================================="
SectionEnd

; =============================================================================
; Eltávolítás
; =============================================================================
Section "un.Eltávolítás"
    ReadRegStr $DATA_DIR HKLM "Software\BestChange\ValutavaltoPenztar" "DataDir"
    ${If} $DATA_DIR == ""
        ExpandEnvStrings $DATA_DIR "%PROGRAMDATA%\BestChange"
    ${EndIf}

    DetailPrint "Szolgáltatások leállítása..."
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
    DetailPrint "  Várakozás a folyamatok leállására..."
    StrCpy $R0 0
    un_kill_wait:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 10
            DetailPrint "  Timeout — folytatás"
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

    DetailPrint "Szolgáltatások eltávolítása..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-Backend confirm'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-PostgreSQL confirm'
    nsExec::ExecToLog 'cmd.exe /C sc.exe delete BestChange-Backend'
    nsExec::ExecToLog 'cmd.exe /C sc.exe delete BestChange-PostgreSQL'
    Sleep 1000

    ; Firewall szabályok eltávolítása
    DetailPrint "Firewall szabályok eltávolítása..."
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-Backend"'
    nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="Valutavalto-PostgreSQL"'

    DetailPrint "Alkalmazás fájlok eltávolítása..."
    RMDir /r "$INSTDIR"

    ; F-N-02 fix: Silent uninstall → safe default (keep data)
    IfSilent un_keepData
    MessageBox MB_YESNO "Töröljem az adatbázist és a konfigurációt is?$\r$\n$\r$\nHa NEM-et választ, az adatok megmaradnak egy későbbi újratelepítéshez.$\r$\n$\r$\n($DATA_DIR)" IDYES un_deleteData IDNO un_keepData

    un_deleteData:
        DetailPrint "Adatok törlése..."
        RMDir /r "$DATA_DIR"
        Goto un_doneData

    un_keepData:
        DetailPrint "Binárisok törlése (adatok megmaradnak)..."
        ; S6-06 fix: Secrets törlése még keep-data módban is
        Delete "$DATA_DIR\config\application-local.properties"
        ; S6-04: .pgpass contains postgres admin password — must be wiped
        FileOpen $0 "$DATA_DIR\config\.pgpass" w
        FileWrite $0 "# WIPED"
        FileClose $0
        Delete "$DATA_DIR\config\.pgpass"
        DetailPrint "  Konfigurációs fájlok törölve (titkos kulcsok eltávolítva)"
        RMDir /r "$DATA_DIR\jre"
        RMDir /r "$DATA_DIR\tools"
        RMDir /r "$DATA_DIR\scripts"
        Delete "$DATA_DIR\backend\valuta-backend.jar"

    un_doneData:

    Delete "$DESKTOP\Valutaváltó Pénztár.lnk"
    RMDir /r "$SMPROGRAMS\Valutaváltó Pénztár"

    DeleteRegKey HKLM "Software\BestChange\ValutavaltoPenztar"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar"

    DetailPrint ""
    DetailPrint "Eltávolítás kész!"
SectionEnd

; =============================================================================
; Indítási ellenőrzések
; =============================================================================
Function .onInit
    ${IfNot} ${RunningX64}
        MessageBox MB_OK|MB_ICONSTOP "Ez az alkalmazás csak 64 bites Windows rendszeren fut."
        Abort
    ${EndIf}

    UserInfo::GetAccountType
    Pop $0
    ${If} $0 != "admin"
        MessageBox MB_OK|MB_ICONSTOP "A telepítéshez rendszergazdai jogosultság szükséges.$\r$\n$\r$\nKattintson jobb gombbal a telepítőre, majd válassza a$\r$\n'Futtatás rendszergazdaként' lehetőséget."
        Abort
    ${EndIf}

    ; G2-01 fix: Port check MOVED to Section (after Fázis 1 cleanup)
    ; onInit only checks x64 + admin — port check is post-cleanup in SecInstall
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
    MessageBox MB_YESNO|MB_ICONQUESTION "Biztosan eltávolítja a Valutaváltó Pénztárt?" IDYES +2
    Abort
FunctionEnd
