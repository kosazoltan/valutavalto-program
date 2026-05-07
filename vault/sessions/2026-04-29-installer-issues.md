---
date: 2026-04-29
session_type: installer-debugging
context: v2.3.7 reinstall — felhasználói teszt indítás Track 4 SB4 sprint után
---

# 2026-04-29 v2.3.7 Installer issues — debugging notes

## Workflow context
17 PR mergelve a sessionben (#254-270), v2.3.7 installer kész:
- `Penztar-Setup-2.3.7-20260429.exe` (280 MB, SHA-256 `230a4c54...e7c1f74dcecbf`)
- User-direktíva: "Indítsd az újratelepítést... ellenőrizd a régi telepítést. Töröld úgy, hogy az adatbázisok ne sérüljenek..."

## Sikeres lépések
1. ✅ **Pre-uninstall audit**: install dir `C:\Program Files\Valutavalto Penztar\` v2.3.6 azonosítva, `%APPDATA%\Valutavalto Penztar\` userData NEM létezik (Electron-app még nem futott), PostgreSQL service `postgresql-x64-17` külön mappában (`C:\Program Files\PostgreSQL\17\data\`).
2. ✅ **Eltavolito-2.3.7**: install dir + Start Menu cleanup OK. PostgreSQL data **érintetlen**.

## Hibák a Setup futtatása alatt

### Hiba #1 (Setup #1): NSIS PowerShell `-like` parser error
A `Penztar-Setup.nsi` "scoped postgres.exe kill" része hibás:
```
You must provide a value expression following the '-like' operator.
    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : ExpectedValueExpression
```
A változó-substitúció **üresre fut** a `-like` operator előtt. Ez a NSIS install-cleanup-fázisban (`Penztar-Cleanup.nsi:81-99` környékén) van a `nsExec::ExecToLog 'powershell ... -like $Path*' ...` mintában.

### Hiba #2 (mindkét Setup): `libwinpthread-1.dll` Nem írható (file lock)
A `Penztar-Setup-2.3.7-20260429.exe` **nem tudja kibontani** a `C:\ProgramData\BestChange\pgsql\bin\libwinpthread-1.dll`-t (és 6 másik fájlt: `libcrypto-3-x64.dll`, `libiconv-2.dll`, `libintl-9.dll`, `libpq.dll`, `libssl-3-x64.dll`, `psql.exe`).

**Diagnosztika lépések:**
1. system PostgreSQL service stop (`sc stop postgresql-x64-17`) — ✅ stopped, **nem segít**
2. `tasklist | grep postgres` — 0 process, **nem segít**
3. ESET realtime scan pause 10 minutes — **nem segít**
4. Setup process kill (PID 28560 + 52428) — **nem segít**
5. `takeown /F /R` — ✅ ownership transferred, **nem segít**
6. `icacls /grant:r Administrators:(F)` — Hungarian locale issue: "Administrators: A fióknevek és a biztonsági azonosítók között nem jött létre egymáshoz rendelés." (kell a magyar `Rendszergazdák` név)
7. `cmd.exe del /F /Q` — "A hozzáférés megtagadva"
8. `cmd.exe rmdir /S /Q` — ugyanaz

**Konklúzió:** valami láthatatlan process **memória-mappolja** ezeket a fájlokat (LoadLibrary vagy MapViewOfFile). Windows nem engedi a törlést amíg a handle nyitva van.

**Lehetséges process-ek (REBOOT előtt nem azonosítva):**
- ESET background scan job (a pause **NEM** állítja le az aktív scan-jobokat, csak a real-time figyelést)
- Windows Search Indexer (`SearchProtocolHost.exe`)
- Egy korábbi orphan NSIS extract-process
- Antimalware Service Executable (`MsMpEng.exe`)
- Windows Defender SmartScreen scan

**A REBOOT a leghatékonyabb fix** — minden user-mode handle felszabadul, és a Setup tisztán futhat.

## NSIS script-bug fix tervezett (v2.3.8)

### Bug 1: PowerShell `-like` parser error
**Forrás**: `installer/Penztar-Cleanup.nsi` valahol a `nsExec::ExecToLog` parancsban, ahol PowerShell-t hív scoped postgres.exe kill-hez. A változó-substitúció üresre fut.

**Fix**: a NSIS `$VAR` substitúciót **egyetlen idézőjelek** közé kell tenni a PowerShell parancsban, vagy `-replace` előfordulás-eszi escape-elése. Példa:
```nsis
; ROSSZ:
nsExec::ExecToLog 'powershell -Command "Get-Process | Where-Object { $_.Path -like ''$INSTDIR\*'' }"'

; HELYES:
ReadEnvStr $0 "INSTDIR"
nsExec::ExecToLog 'powershell -Command "Get-Process | Where-Object { $_.Path -like ''$0\*'' }"'
```

### Bug 2: ICACLS Hungarian locale
**Forrás**: a NSIS install vagy cleanup script-ben az `icacls` parancs `Administrators` névvel hívódik, ami English-locale-en működik, magyaron nem.

**Fix**: használjuk a SID-et `S-1-5-32-544` (Administrators built-in group SID) ami language-independent:
```cmd
icacls "C:\ProgramData\BestChange" /grant:r *S-1-5-32-544:(F) /T /C
```

### Bug 3: ESET pause nem elég, kill scenarios
A NSIS install-cleanup-flow valószínűleg több ponton open-tartja a fájlokat (NSIS extract → a fájl önmagát tölti, aztán bezárt handle, de NTFS handle cache miatt késik a release).

**Fix**: a NSIS install-end-en kötelező `Sleep 5000` (5 sec) + `IfFileExists $TARGET 0 +2 / Delete $TARGET` retry-loop a problematic DLL-ekre. Vagy: kibontás előtt **reboot detection** ("ha létezik partial install, javasoljon REBOOT-ot").

## Következő session-feladatok

1. **REBOOT** és Setup #3 futás (azonnal a reboot után)
2. **Ha sikerül**: SetupWizard 5 lépés (Iroda → Program típus → Szerver + Kapcsolat tesztelése → Admin jelszó → Telepítés) + Bootstrap login + VÉTEL teszt
3. **Ha újra fail**: NSIS script-bug-fix + új v2.3.8 build:
   - PowerShell `-like` parser bug
   - ICACLS Hungarian locale (SID használata)
   - Reboot detection + 5-sec sleep retry-loop
4. **Új PR**: `fix(installer): NSIS scoped kill PowerShell + Hungarian locale + retry-loop`

## Verifikációs parancsok REBOOT után

```bash
# Maradt-e a partial install?
ls "C:/ProgramData/BestChange" 2>&1
# Cél: NEM létezik (REBOOT után a NTFS handle-cache lejár)

# Setup futtatás
PowerShell: Start-Process -FilePath "$env:USERPROFILE\Downloads\Penztar-Setup-2.3.7-20260429.exe" -Verb RunAs -Wait
```

## ✅ POST-REBOOT SUCCESS (2026-04-29 13:42 CEST)

### Setup #3 SIKERESEN végigfutott
- ✅ PostgreSQL 17.5 telepítve `C:\ProgramData\BestChange\pgsql\`
- ✅ Embedded JRE telepítve `C:\ProgramData\BestChange\jre\`
- ✅ Backend `valuta-backend.jar` (Spring Boot 4.0.6) telepítve
- ✅ NSSM tools + VC++ Runtime
- ✅ Penztar Electron app `C:\Program Files\Valutavalto Penztar\`
- ✅ **BestChange-PostgreSQL** + **BestChange-Backend** Windows services regisztrálva
- ✅ Firewall szabályok beállítva
- ✅ initdb + valuta_user + pg_hba.conf scram-sha-256

### Spring Boot 4 backend RUNNING (production-stable)
```
13:38:14.098 INFO Started ValutaBackendApplication in 14.465 seconds
- Tomcat 10.1.54 on port 8080 + 9090 (actuator)
- Hibernate ORM 7.2.12
- PostgreSQL 17.5 @ jdbc:postgresql://localhost:54320/valuta
- Flyway: 165 migrations applied (V1..V167) — V166 0 rows, V167 0 rows (V166 already fixed)
- NavClosingService VAT rate coverage validated: 4 codes OK
- HUF currency ID cached: 1
```

### Smoke test PASS
- `curl http://localhost:8080/api/v1/auth/bootstrap-status` → **HTTP 200** (6-29ms)
- Backend → DB connection ESTABLISHED (51460→54320)

### A Setup wizard "Elakad" üzenet pesszimista volt
A "Varakozas a Backend szerverre (ez 30-60 masodpercig tarthat)..." üzenet után a wizard **úgy tűnt mintha** elakadt volna, **DE** a backend valójában feláll (~14.5 sec). A wizard timeout-ja lehet, hogy túl rövid (NSIS `nsExec::ExecToLog` várakozás), vagy a wizard nem észleli a `200 OK` választ az `/auth/bootstrap-status` endpointról.

**v2.3.8 NSIS fix**: a backend wait timeout-ot 60s → 90s, és HTTP 200 polling 5-sec-enként ahelyett hogy fix wait.

### Megnyitott followup-ok (NSIS v2.3.8 build)

1. **PowerShell `-like` parser bug** a `Penztar-Cleanup.nsi`-ben (a Setup #1 + #2 logokban látható)
2. **ICACLS Hungarian locale**: `Administrators` → SID `*S-1-5-32-544`
3. **Backend startup wait** túl rövid timeout (a "Elakad" üzenet)
4. **DLL memory-lock detection**: a Setup-elindítás ELŐTT egy `Get-Process | Where-Object {$_.Modules ...}` check, ami detektálja a lock-okat és ESET-pause-t / REBOOT-ot ajánl.
