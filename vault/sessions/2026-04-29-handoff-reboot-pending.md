---
date: 2026-04-29
time: 23:00 CEST
session_type: handoff-reboot-pending
context: v2.3.7 reinstall fail (DLL memory-lock), REBOOT scheduled
priority: P0 — éles pénztár tesztelése
---

# 2026-04-29 Handoff — REBOOT pending

## Mi történt eddig

A user a 17 PR mergelése + v2.3.7 installer build után indítani akarta a v2.3.7 reinstall + tesztelési flow-t:
1. ✅ Penztar-Eltavolito-2.3.7-20260429.exe (admin) — install dir cleanup OK, **adatbázis sértetlen** (PostgreSQL külön mappa)
2. ❌ **Penztar-Setup-2.3.7-20260429.exe** (admin) — **2× FAIL** ugyanazon a hibán

## A hiba pontos forrása

### A NSIS script belső bug
`Penztar-Cleanup.nsi`-ben a "scoped postgres.exe kill" rész PowerShell-t hív, és a változó-substitúció üresre fut:
```
You must provide a value expression following the '-like' operator.
```

### A főhiba: 7 PostgreSQL DLL nem írható
```
Nem írható: C:\ProgramData\BestChange\pgsql\bin\libwinpthread-1.dll
```
Plusz: `libcrypto-3-x64.dll`, `libiconv-2.dll`, `libintl-9.dll`, `libpq.dll`, `libssl-3-x64.dll`, `psql.exe`.

## Diagnosztika

- system PostgreSQL leállítva (`sc stop postgresql-x64-17`) — **nem segít**
- 0 postgres.exe process — **nem segít**
- ESET realtime scan pause 10 minutes — **nem segít**
- Setup process kill (PID 28560 + 52428) — **nem segít**
- `takeown /F /R` — ✅ ownership transferred — **nem segít**
- `icacls /grant:r Administrators:(F)` — ❌ Hungarian locale issue ("A fióknevek és a biztonsági azonosítók között nem jött létre egymáshoz rendelés")
- `cmd.exe del /F /Q` — ❌ "A hozzáférés megtagadva"

**Konklúzió**: egy láthatatlan process MapViewOfFile-en keresztül map-eli a DLL-eket (Windows defender? ESET scan job? Windows Search Indexer?). Windows nem engedi a deletion-t amíg a memory-mapping aktív. **REBOOT egyetlen megoldás**.

## Reboot előtti state

- `C:\ProgramData\BestChange\pgsql\bin\` — 7 lock-olt fájl
- `C:\Program Files\Valutavalto Penztar\` — NEM létezik (Setup #1 NSIS rollback törölte)
- system PostgreSQL service `postgresql-x64-17` **STOPPED**
- ESET realtime: paused (de a service `ekrn` RUNNING, NOT_STOPPABLE)
- Registry: Valutavalto Penztar 2.3.6 entry **TÖRÖLVE** (cleanup #1)

## Reboot UTÁN — agent feladat

```powershell
# 1. Verifikáld, hogy a lock-olt fájlok eltűntek (NTFS handle cache lejár reboot-tal)
Test-Path "C:\ProgramData\BestChange\pgsql\bin\libwinpthread-1.dll"
# Várt: False (vagy True, de már törölhető)

# 2. Maradék cleanup ha kell (most már sikerülni fog)
Remove-Item -Path "C:\ProgramData\BestChange" -Recurse -Force -ErrorAction Continue

# 3. Setup azonnal indít (mielőtt ESET vagy Windows Search lock-olná)
Start-Process -FilePath "$env:USERPROFILE\Downloads\Penztar-Setup-2.3.7-20260429.exe" -Verb RunAs -Wait
```

## Reboot UTÁN — user feladat (SetupWizard 5 lépés)

| Lépés | Mező | Érték |
|---|---|---|
| 1. Iroda | Iroda kiválasztása | `BR017` (vagy másik valós) |
| 2. Program típus | Online/Offline | **Online** |
| 3. Szerver | API URL | `https://excvaluta.com/api/v1` (default) |
| 3. Szerver | **🔴 KÖTELEZŐ: Kapcsolat tesztelése gomb** | várj zöld pipa (`connectionTest.state=ok`) |
| 4. Admin jelszó | Bootstrap admin user/pass | (1Password-ből) |
| 5. Telepítés | Befejezés | OK |

Aztán: bootstrap admin login + új VÉTEL teszt → bizonylat formátum `V<3-jegy>000001` (BR017-en `V017000001`).

## Backend stack (production)
- Spring Boot 4.0.6 + Tomcat 11.0.21 (Servlet 6.1)
- Jackson 2 stop-gap + JacksonConfig.java programmatic ObjectMapper
- springdoc 3.0.3 + flyway-database-postgresql 12.4.0
- HTTP 200 stabil (Hetzner monitor 3× SUCCESS a 04-29-i sessionben)

## Maradt P0/P1/P2 a következő session-be

- **P0**: Setup #3 sikeresen lefuttatása (REBOOT után)
- **P0**: SetupWizard + Bootstrap login + VÉTEL teszt (user-akció)
- **P1**: NSIS script bug-fix → v2.3.8 build
  - PowerShell `-like` parser error (`Penztar-Cleanup.nsi` scoped postgres kill)
  - ICACLS Hungarian locale → SID `*S-1-5-32-544`
  - Reboot detection + 5-sec sleep retry-loop a problematic DLL-eken
- **P2**: CodeQL Actions hardening (9 medium, korábban már TODO)
- **P2 long-term**: teljes Jackson 3 migráció (39 fájl `tools.jackson.*`)

## Workflow-state

- 17 PR mergelve a 04-29-i sessionben (#254-270)
- Main HEAD: `70e4a4cd`
- 0 open PR
- Production HTTP 200 stabil
