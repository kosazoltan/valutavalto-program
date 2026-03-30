; =============================================================================
; Valutaváltó Pénztár — Egyfájlos Windows Telepítő v2
; NSIS 3.x Script — Production Quality
; =============================================================================
; Javítva: NSSM quoting, EXE név, health check, hibakezelés, re-install
; =============================================================================

!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"

; --- Paraméterek ---
!ifndef VERSION
  !define VERSION "1.1.0"
!endif
!ifndef STAGE_DIR
  !define STAGE_DIR "build\stage"
!endif
!ifndef OUTPUT_DIR
  !define OUTPUT_DIR "build"
!endif

; --- Alapbeállítások ---
Name "Valutaváltó Pénztár ${VERSION}"
OutFile "${OUTPUT_DIR}\Penztar-Setup-${VERSION}.exe"
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
    ; (F-08 fix: sc delete ELŐTT kell killt csinálni, nem utána)
    ; =====================================================================
    DetailPrint "Korábbi telepítés ellenőrzése..."

    ; --- 1a. STOP services via NSSM (graceful, keeps service registration) ---
    DetailPrint "  Szolgáltatások leállítása..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" stop BestChange-Backend 2>nul'
    Sleep 3000
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" stop BestChange-PostgreSQL 2>nul'
    Sleep 3000
    ; Fallback: net stop (ha NSSM nincs a data dir-ben, pl. első telepítés régi maradvánnyal)
    nsExec::ExecToLog 'net stop BestChange-Backend 2>nul'
    nsExec::ExecToLog 'net stop BestChange-PostgreSQL 2>nul'
    Sleep 2000

    ; --- 1b. pg_ctl stop -m fast (PostgreSQL-specifikus graceful shutdown) ---
    DetailPrint "  PostgreSQL graceful stop..."
    IfFileExists "$DATA_DIR\pgsql\bin\pg_ctl.exe" 0 skip_pgctl
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
    skip_pgctl:
    Sleep 2000

    ; --- 1c. KILL remaining BestChange processes (scoped, F-06+F-07) ---
    DetailPrint "  Maradék folyamatok leállítása..."
    nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    Sleep 1000

    ; --- 1d. WAIT for file locks (postgres + java) ---
    DetailPrint "  Várakozás a fájlzárak feloldására..."
    StrCpy $R0 0
    lock_wait_loop:
        IntOp $R0 $R0 + 1
        ${If} $R0 > 15
            DetailPrint "  Időtúllépés — folytatás (fájlzár lehetséges)."
            Goto lock_wait_done
        ${EndIf}
        nsExec::ExecToStack 'powershell.exe -NoProfile -Command "if(Get-Process postgres,java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' }){exit 1}else{exit 0}"'
        Pop $0
        ${If} $0 == 0
            Goto lock_wait_done
        ${EndIf}
        Sleep 1000
        Goto lock_wait_loop
    lock_wait_done:
    Sleep 1000

    ; --- 1e. REMOVE service registration (CSAK miután a process halott!) ---
    DetailPrint "  Régi szolgáltatások eltávolítása..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-Backend confirm 2>nul'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-PostgreSQL confirm 2>nul'
    ; Fallback: sc delete (ha NSSM nem elérhető)
    nsExec::ExecToLog 'sc.exe delete BestChange-Backend 2>nul'
    nsExec::ExecToLog 'sc.exe delete BestChange-PostgreSQL 2>nul'
    Sleep 1000

    ; =====================================================================
    ; FÁZIS 2: Fájlok másolása
    ; =====================================================================

    ; --- PostgreSQL ---
    DetailPrint "PostgreSQL 16 telepítése..."
    SetOutPath "$DATA_DIR\pgsql"
    File /r "${STAGE_DIR}\pgsql\*.*"
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

    ; --- NSSM ---
    DetailPrint "Service Manager telepítése..."
    SetOutPath "$DATA_DIR\tools"
    File "${STAGE_DIR}\tools\nssm.exe"

    ; --- Scripts ---
    SetOutPath "$DATA_DIR\scripts"
    File "${STAGE_DIR}\scripts\*.*"

    ; --- Electron App ---
    DetailPrint "Pénztár alkalmazás telepítése..."
    SetOutPath $INSTDIR
    File /r "${STAGE_DIR}\electron\*.*"

    ; =====================================================================
    ; FÁZIS 2B: VC++ Redistributable (2015-2022 x64) — PG16 előfeltétel
    ; =====================================================================
    ; PG 16 EDB binárisok vcruntime140.dll-t igényelnek — sok irodai gépen nincs!
    ; F-08: Registry-based check (megbízhatóbb mint $SYSDIR\vcruntime140.dll)
    DetailPrint "Visual C++ Runtime ellenőrzés..."
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" "Installed"
    ${If} $0 != 1
        DetailPrint "  VC++ 2015-2022 Redistributable telepítése..."
        nsExec::ExecToStack '"$DATA_DIR\tools\vc_redist.x64.exe" /install /quiet /norestart'
        Pop $0
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

    ; Per-install random JWT secret generálás (F-01 security fix)
    nsExec::ExecToStack 'powershell.exe -NoProfile -Command "[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Max 256 }) -as [byte[]])"'
    Pop $1  ; exit code
    Pop $2  ; output = random base64 string (64 char)
    ; Ha PowerShell nem elérhető → cmd.exe %RANDOM% alapú fallback (F-02 fix: nem determinisztikus)
    StrCmp $2 "" 0 +5
        nsExec::ExecToStack 'cmd.exe /c "echo %RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%%RANDOM%JWT%DATE%"'
        Pop $1
        Pop $2
        StrCmp $2 "" 0 +2
            StrCpy $2 "EmergencyJWTKey-$HWNDPARENT-NoRandom"

    ; Per-install random encryption salt generálás
    nsExec::ExecToStack 'powershell.exe -NoProfile -Command "-join ((1..16) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })"'
    Pop $3  ; exit code
    Pop $4  ; output = random hex salt (32 char)
    StrCmp $4 "" 0 +2
        StrCpy $4 "a1b2c3d4e5f6a7b8" ; fallback

    ; Per-install random encryption key generálás (F-03 fix)
    nsExec::ExecToStack 'powershell.exe -NoProfile -Command "[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Max 256 }) -as [byte[]])"'
    Pop $5  ; exit code
    Pop $6  ; output = random base64 encryption key
    StrCmp $6 "" 0 +2
        StrCpy $6 "LocalInstallKey2026BestChange" ; fallback

    ; application-local.properties
    FileOpen $0 "$DATA_DIR\config\application-local.properties" w
    FileWrite $0 "# Valutavalto Penztar - lokalis konfig$\r$\n"
    FileWrite $0 "# Automatikusan generalta a telepito$\r$\n"
    FileWrite $0 "server.port=8080$\r$\n"
    FileWrite $0 "spring.datasource.url=jdbc:postgresql://localhost:54320/valuta$\r$\n"
    FileWrite $0 "spring.datasource.username=valuta_user$\r$\n"
    FileWrite $0 "spring.datasource.password=BestChange2026Local$\r$\n"
    FileWrite $0 "spring.datasource.driver-class-name=org.postgresql.Driver$\r$\n"
    FileWrite $0 "spring.datasource.hikari.maximum-pool-size=10$\r$\n"
    FileWrite $0 "spring.datasource.hikari.minimum-idle=2$\r$\n"
    FileWrite $0 "spring.jpa.hibernate.ddl-auto=update$\r$\n"
    FileWrite $0 "spring.jpa.show-sql=false$\r$\n"
    FileWrite $0 "spring.flyway.enabled=false$\r$\n"
    FileWrite $0 "# Flyway disabled: JPA ddl-auto=update manages schema, seed via init-db$\r$\n"
    FileWrite $0 "cors.allowed-origins=app://localhost,http://localhost:3000$\r$\n"
    FileWrite $0 "logging.level.root=INFO$\r$\n"
    FileWrite $0 "logging.level.hu.puzzleir.valuta=INFO$\r$\n"
    FileWrite $0 "springdoc.api-docs.enabled=true$\r$\n"
    FileWrite $0 "springdoc.swagger-ui.enabled=true$\r$\n"
    FileWrite $0 "camera.enabled=false$\r$\n"
    FileWrite $0 "jwt.secret=$2$\r$\n"
    FileWrite $0 "jwt.expiration=86400000$\r$\n"
    FileWrite $0 "google.client.id=none$\r$\n"
    FileWrite $0 "google.client.secret=none$\r$\n"
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

    ; Check if DB already initialized
    IfFileExists "$DATA_DIR\pgsql\data\PG_VERSION" db_exists db_init

    db_init:
        ; initdb
        DetailPrint "  initdb futtatása..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\initdb.exe" -D "$DATA_DIR\pgsql\data" -U postgres -E UTF8 --locale=C --auth=trust'
        Pop $0
        ${If} $0 != 0
            IfSilent +2
            MessageBox MB_OK|MB_ICONSTOP "HIBA: Az adatbázis inicializálás sikertelen (initdb).$\r$\nHibakód: $0$\r$\n$\r$\nEllenőrizze, hogy van-e elég hely a lemezen."
            Abort
        ${EndIf}

        ; PostgreSQL port config
        FileOpen $0 "$DATA_DIR\pgsql\data\postgresql.conf" a
        FileSeek $0 0 END
        FileWrite $0 "$\r$\n# Penztar installer config$\r$\n"
        FileWrite $0 "port = 54320$\r$\n"
        FileWrite $0 "listen_addresses = 'localhost'$\r$\n"
        FileWrite $0 "log_destination = 'stderr'$\r$\n"
        FileWrite $0 "logging_collector = on$\r$\n"
        FileWrite $0 "log_directory = 'log'$\r$\n"
        FileClose $0

        ; Start PG temporarily for DB setup
        DetailPrint "  PostgreSQL ideiglenes indítás..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\pg_ctl.exe" start -D "$DATA_DIR\pgsql\data" -l "$DATA_DIR\pgsql\log\postgresql.log" -w -t 30'
        Pop $0
        ${If} $0 != 0
            IfSilent +2
            MessageBox MB_OK|MB_ICONSTOP "HIBA: PostgreSQL nem indult el.$\r$\nEllenőrizze a log fájlt:$\r$\n$DATA_DIR\pgsql\log\postgresql.log"
            Abort
        ${EndIf}

        ; Wait for PG to accept connections
        DetailPrint "  Várakozás az adatbázisra..."
        StrCpy $R0 0
        pg_wait_loop:
            IntOp $R0 $R0 + 1
            ${If} $R0 > 20
                IfSilent +3
                MessageBox MB_OK|MB_ICONSTOP "HIBA: PostgreSQL nem válaszol 20 másodpercen belül."
                nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 10'
                Abort
            ${EndIf}
            Sleep 1000
            nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -c "SELECT 1" -t -A'
            Pop $0
            ${If} $0 != 0
                Goto pg_wait_loop
            ${EndIf}
        DetailPrint "  PostgreSQL kész!"

        ; Create database
        DetailPrint "  Adatbázis létrehozása: valuta"
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\createdb.exe" -p 54320 -U postgres valuta'
        Pop $0
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETÉS: Adatbázis már létezhet (kód: $0)"
        ${EndIf}

        ; Create user via createuser.exe (no SQL escaping issues at all)
        DetailPrint "  Felhasználó létrehozása: valuta_user"

        ; Step 1: createuser (idempotent — fails silently if user exists)
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\createuser.exe" -p 54320 -U postgres --no-superuser --no-createdb --no-createrole valuta_user'
        Pop $0
        ${If} $0 != 0
            DetailPrint "  createuser kód: $0 (user már létezhet — OK)"
        ${EndIf}

        ; Step 2: Set password + grants via SQL file (no dollar-quoting needed)
        FileOpen $0 "$DATA_DIR\scripts\setup-user.sql" w
        FileWrite $0 "ALTER USER valuta_user WITH PASSWORD 'BestChange2026Local';$\r$\n"
        FileWrite $0 "GRANT ALL PRIVILEGES ON DATABASE valuta TO valuta_user;$\r$\n"
        FileWrite $0 "GRANT ALL ON SCHEMA public TO valuta_user;$\r$\n"
        FileWrite $0 "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO valuta_user;$\r$\n"
        FileClose $0

        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -d valuta -f "$DATA_DIR\scripts\setup-user.sql"'
        Pop $0
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETÉS: setup-user.sql kód: $0 — folytatás"
        ${EndIf}

        ; Cleanup temp SQL file
        Delete "$DATA_DIR\scripts\setup-user.sql"

        ; Verify user exists (SQL file to avoid NSIS $$ quoting issues)
        FileOpen $0 "$DATA_DIR\scripts\verify-user.sql" w
        FileWrite $0 "SELECT count(*) FROM pg_roles WHERE rolname='valuta_user';$\r$\n"
        FileClose $0
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -t -A -f "$DATA_DIR\scripts\verify-user.sql"'
        Pop $0
        Pop $1
        Delete "$DATA_DIR\scripts\verify-user.sql"
        StrCpy $2 $1 1
        ${If} $2 != "1"
            IfSilent +2
            MessageBox MB_OK|MB_ICONSTOP "HIBA: A valuta_user adatbázis felhasználó létrehozása sikertelen.$\r$\nA backend szerver nem fog tudni csatlakozni.$\r$\n$\r$\nEllenőrizze a PostgreSQL logot:$\r$\n$DATA_DIR\pgsql\log\postgresql.log"
            Abort
        ${EndIf}
        DetailPrint "  valuta_user létrehozva és ellenőrizve!"

        ; Run seed data SQL (company, branch, workers, currencies)
        DetailPrint "  Seed adatok betöltése..."
        nsExec::ExecToStack '"$DATA_DIR\pgsql\bin\psql.exe" -p 54320 -U postgres -d valuta -f "$DATA_DIR\scripts\seed-data.sql"'
        Pop $0
        ${If} $0 != 0
            DetailPrint "  FIGYELMEZTETÉS: Seed script kód: $0 (lehet hogy az adatok már léteznek)"
        ${Else}
            DetailPrint "  Seed adatok betöltve!"
        ${EndIf}

        ; Stop temp PG (service will manage it)
        DetailPrint "  Ideiglenes PostgreSQL leállítás..."
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
        Sleep 2000
        Goto db_done

    db_exists:
        DetailPrint "  Meglévő adatbázis megtalálva, kihagyás."

    db_done:

    ; =====================================================================
    ; FÁZIS 5: Windows szolgáltatások
    ; =====================================================================
    DetailPrint "Szolgáltatások regisztrálása..."

    ; --- PostgreSQL service ---
    ; postgres.exe közvetlenül (NEM pg_ctl!) — NSSM + pg_ctl = "Paused" bug
    ; NetworkService fiókkal fut — PG16 elutasítja az admin/LocalSystem futást!
    DetailPrint "  BestChange-PostgreSQL szolgáltatás..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" install BestChange-PostgreSQL "$DATA_DIR\pgsql\bin\postgres.exe"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppDirectory $DATA_DIR\pgsql'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppParameters "-D" "$DATA_DIR\pgsql\data"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL DisplayName "BestChange PostgreSQL"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL Description "Valutavalto Penztar adatbazis szerver"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL ObjectName "NT AUTHORITY\NetworkService" ""'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL Start SERVICE_AUTO_START'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppStdout $DATA_DIR\pgsql\log\service-stdout.log'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppStderr $DATA_DIR\pgsql\log\service-stderr.log'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppThrottle 30000'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppExit Default Restart'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppRestartDelay 3000'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppRotateFiles 1'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-PostgreSQL AppRotateBytes 10485760'

    ; Grant NetworkService full control on pgsql data/log dirs
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\data" /grant "NT AUTHORITY\NetworkService":(OI)(CI)F /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\log" /grant "NT AUTHORITY\NetworkService":(OI)(CI)F /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\bin" /grant "NT AUTHORITY\NetworkService":(OI)(CI)RX /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\lib" /grant "NT AUTHORITY\NetworkService":(OI)(CI)RX /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\pgsql\share" /grant "NT AUTHORITY\NetworkService":(OI)(CI)RX /T /Q'

    ; --- Backend service ---
    ; NetworkService fiókkal fut — security best practice
    ; AppThrottle 120s: Spring Boot 162 entity + Flyway = lassú startup!
    DetailPrint "  BestChange-Backend szolgáltatás..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" install BestChange-Backend "$DATA_DIR\jre\bin\java.exe"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppDirectory $DATA_DIR\backend'
    ; DB jelszó CSAK config fájlból (application-local.properties), nem parancssorból — F-04 security fix
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppParameters "-jar" "valuta-backend.jar" "--spring.config.additional-location=file:../config/" "--spring.profiles.active=local"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend DisplayName "BestChange Backend"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend Description "Valutavalto Penztar szerver"'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend ObjectName "NT AUTHORITY\NetworkService" ""'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend DependOnService BestChange-PostgreSQL'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend Start SERVICE_AUTO_START'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppThrottle 120000'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppExit Default Restart'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppRestartDelay 5000'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppStdout $DATA_DIR\backend\logs\service-stdout.log'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppStderr $DATA_DIR\backend\logs\service-stderr.log'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppRotateFiles 1'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" set BestChange-Backend AppRotateBytes 10485760'

    ; Grant NetworkService access to backend/config/jre dirs
    nsExec::ExecToLog 'icacls "$DATA_DIR\backend" /grant "NT AUTHORITY\NetworkService":(OI)(CI)F /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\config" /grant "NT AUTHORITY\NetworkService":(OI)(CI)R /T /Q'
    nsExec::ExecToLog 'icacls "$DATA_DIR\jre" /grant "NT AUTHORITY\NetworkService":(OI)(CI)RX /T /Q'

    ; =====================================================================
    ; FÁZIS 6: Szolgáltatások indítása + health check
    ; =====================================================================
    DetailPrint "Szolgáltatások indítása..."

    ; --- PostgreSQL indítás ---
    DetailPrint "  PostgreSQL indítása..."
    nsExec::ExecToStack 'net start BestChange-PostgreSQL'
    Pop $0
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
        ${If} $0 != 0
            Goto pg_svc_wait
        ${EndIf}
    DetailPrint "  PostgreSQL kész! ($R0 mp)"
    pg_svc_done:

    ; --- Backend indítás ---
    DetailPrint "  Backend szerver indítása..."
    nsExec::ExecToStack 'net start BestChange-Backend'
    Pop $0
    ${If} $0 != 0
        DetailPrint "  FIGYELMEZTETÉS: Backend service start kód: $0"
    ${EndIf}

    ; Health check: Backend (port 8080 listening)
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
        ; $1 contains "200" if success
        StrCpy $2 $1 3  ; first 3 chars
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

    ; Programs and Features
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayName" "Valutaváltó Pénztár ${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayIcon" "$INSTDIR\Penztar.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "Publisher" "Exclusive Best Change Zrt."
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "InstallLocation" "$INSTDIR"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar" "NoRepair" 1

    ; Uninstaller
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
    ; Read data dir from registry
    ReadRegStr $DATA_DIR HKLM "Software\BestChange\ValutavaltoPenztar" "DataDir"
    ${If} $DATA_DIR == ""
        ExpandEnvStrings $DATA_DIR "%PROGRAMDATA%\BestChange"
    ${EndIf}

    ; F-08: Helyes sorrend — STOP → pg_ctl → KILL → WAIT → REMOVE
    DetailPrint "Szolgáltatások leállítása..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" stop BestChange-Backend 2>nul'
    Sleep 3000
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" stop BestChange-PostgreSQL 2>nul'
    Sleep 3000
    nsExec::ExecToLog 'net stop BestChange-Backend 2>nul'
    nsExec::ExecToLog 'net stop BestChange-PostgreSQL 2>nul'
    Sleep 2000

    ; pg_ctl graceful stop
    IfFileExists "$DATA_DIR\pgsql\bin\pg_ctl.exe" 0 un_skip_pgctl
        nsExec::ExecToLog '"$DATA_DIR\pgsql\bin\pg_ctl.exe" stop -D "$DATA_DIR\pgsql\data" -m fast -w -t 30'
    un_skip_pgctl:
    Sleep 2000

    ; Scoped process kill (F-06+F-07)
    nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process postgres -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    nsExec::ExecToLog 'powershell.exe -NoProfile -Command "Get-Process java -ErrorAction SilentlyContinue | Where-Object { $$_.Path -like ''*BestChange*'' } | Stop-Process -Force -ErrorAction SilentlyContinue"'
    Sleep 2000

    ; REMOVE service (csak miután a process halott)
    DetailPrint "Szolgáltatások eltávolítása..."
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-Backend confirm'
    nsExec::ExecToLog '"$DATA_DIR\tools\nssm.exe" remove BestChange-PostgreSQL confirm'
    nsExec::ExecToLog 'sc.exe delete BestChange-Backend 2>nul'
    nsExec::ExecToLog 'sc.exe delete BestChange-PostgreSQL 2>nul'
    Sleep 1000

    ; Remove program files
    DetailPrint "Alkalmazás fájlok eltávolítása..."
    RMDir /r "$INSTDIR"

    ; Ask about data
    MessageBox MB_YESNO "Töröljem az adatbázist és a konfigurációt is?$\r$\n$\r$\nHa NEM-et választ, az adatok megmaradnak egy későbbi újratelepítéshez.$\r$\n$\r$\n($DATA_DIR)" IDYES un_deleteData IDNO un_keepData

    un_deleteData:
        DetailPrint "Adatok törlése..."
        RMDir /r "$DATA_DIR"
        Goto un_doneData

    un_keepData:
        ; Remove binaries but keep data/config
        DetailPrint "Binárisok törlése (adatok megmaradnak)..."
        RMDir /r "$DATA_DIR\jre"
        RMDir /r "$DATA_DIR\tools"
        RMDir /r "$DATA_DIR\scripts"
        Delete "$DATA_DIR\backend\valuta-backend.jar"

    un_doneData:

    ; Shortcuts
    Delete "$DESKTOP\Valutaváltó Pénztár.lnk"
    RMDir /r "$SMPROGRAMS\Valutaváltó Pénztár"

    ; Registry
    DeleteRegKey HKLM "Software\BestChange\ValutavaltoPenztar"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ValutavaltoPenztar"

    DetailPrint ""
    DetailPrint "Eltávolítás kész!"
SectionEnd

; =============================================================================
; Indítási ellenőrzések
; =============================================================================
Function .onInit
    ; 64-bit check
    ${IfNot} ${RunningX64}
        MessageBox MB_OK|MB_ICONSTOP "Ez az alkalmazás csak 64 bites Windows rendszeren fut."
        Abort
    ${EndIf}

    ; Admin check
    UserInfo::GetAccountType
    Pop $0
    ${If} $0 != "admin"
        MessageBox MB_OK|MB_ICONSTOP "A telepítéshez rendszergazdai jogosultság szükséges.$\r$\n$\r$\nKattintson jobb gombbal a telepítőre, majd válassza a$\r$\n'Futtatás rendszergazdaként' lehetőséget."
        Abort
    ${EndIf}

    ; Port check: 54320
    nsExec::ExecToStack 'netstat -an | findstr ":54320 " | findstr "LISTENING"'
    Pop $0
    ${If} $0 == 0
        IfSilent +3
        MessageBox MB_YESNO|MB_ICONQUESTION "A 54320-as port foglalt.$\r$\n$\r$\nLehetséges, hogy egy korábbi telepítés fut.$\r$\nA telepítő megpróbálja leállítani.$\r$\n$\r$\nFolytatja?" IDYES +2
        Abort
    ${EndIf}

    ; Port check: 8080
    nsExec::ExecToStack 'netstat -an | findstr ":8080 " | findstr "LISTENING"'
    Pop $0
    ${If} $0 == 0
        IfSilent +3
        MessageBox MB_YESNO|MB_ICONQUESTION "A 8080-as port foglalt.$\r$\n$\r$\nLehetséges, hogy egy másik alkalmazás használja.$\r$\n$\r$\nFolytatja?" IDYES +2
        Abort
    ${EndIf}
FunctionEnd

Function un.onInit
    MessageBox MB_YESNO|MB_ICONQUESTION "Biztosan eltávolítja a Valutaváltó Pénztárt?" IDYES +2
    Abort
FunctionEnd
