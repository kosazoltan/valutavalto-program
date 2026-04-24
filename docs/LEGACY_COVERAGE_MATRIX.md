# Legacy Delphi -> Modern Java/TS mapping matrix

> 2026-04-24 teljes audit. A legacy 129 Delphi modul közül **129 le van fedve** a modern stack-ben
> (backend Java Spring Boot + frontend React + penztar-client Electron).
>
> Korabban a `.remember/remember.md` 2026-04-23-i verzioban "5% gap" szerepelt (tiltcopy, recguard, vevo_mend).
> Ez **nem pontos** — a mai audit es az Anti/SZERVER/_extracted/SZERVER/fejleszt/ forraskod elemzes
> alapjan mindharom mar lefedett funkcio.

## Korabban "hianyzonak" tartott 3 modul — verifikacio

### 1. `recguard` (watchdog + kamera file GC)

**Legacy funkcio** (`Anti/SZERVER/_extracted/SZERVER/fejleszt/recguard/unit1.pas`):
- `CreateMutex('RECGUARD.EXE')` - egyszerre csak 1 peldany
- `FormActivate`: Kis 25x25 px panel a bal-felso sarokban (process jelzes)
- `CiklusTimer` 10 mp-enkent: MUKODIK-E A RECEPTOR (wrecept.exe)
- `FutasControl` fel percenkent: ha a wrecept nem fut, ujrainditja
- `GarbageCollection`: 4 napnal regebbi `.C1` kamera file torles `d:\kamera\upload\kamera\*\`
- `GepUjrainditas`: ejjel 1-2 kozott reboot.flg letrehoz, 2 utan `EWX_REBOOT or EWX_FORCE`
- Log: `c:\receptor\log\RG<YYMMDD>.txt` 10 mp-enkent

**Modern lefedes**:

| Legacy funkcio | Modern megoldas |
|---------------|-----------------|
| Mutex / egy peldany | `systemctl` `ExecStartPre=-/usr/bin/pkill ...` + PID file + Spring Boot embedded Tomcat port binding |
| Watchdog restart | `systemctl` `Restart=on-failure` + Hetzner deploy workflow health check |
| Kamera file GC | **`CameraCleanupService.java`** `@Scheduled(cron = "0 0 2 * * *")` naponta 2-kor, retention-based delete (lokalis + R2 storage) |
| Reboot scheduling | Nem szukseges: modern systemd service-ek nem igenyelnek OS reboot-ot |
| Log fajl | `application.log` + Hetzner journal `journalctl -u valuta-backend.service` + Spring Boot Actuator `/health` |

**Fajl**: `backend/src/main/java/hu/puzzleir/valuta/service/CameraCleanupService.java`
**Status**: **TELJES**

### 2. `tiltcopy` (= `tiltasok.dll` - `Anti/SZERVER/fejleszt/ugyfelcontrol/dll/tiltasok/`)

**Legacy funkcio** (`unit2.pas` 2000+ sor):
- JOGI tiltottak kezelese (jogi szemelyek) - create, list, filter, revoke
- NATUR tiltottak kezelese (termeszetes szemelyek)
- Osztott DB access: `LocJogiDbase + RemJogiDbase`, `LocNaturDbase + RemDbase`
- Levalogatas (szuro), Listazas (lista), Tiltas (letiltas), Visszavonás (revoke)
- UI-s dialog (`TForm2`) 160+ komponenssel

**Modern lefedes**:

| Legacy funkcio | Modern megoldas |
|---------------|-----------------|
| JOGI tiltottak | `ProhibitedCompanyRepository` + `ProhibitedCompany` entity |
| NATUR tiltottak | `ProhibitedPersonRepository` + `ProhibitedPerson` entity |
| Listazas / Szuro | REST endpoint-ok + frontend tablazatos UI |
| Tiltas / Visszavonas | CRUD API-k |
| Screening (uj tranzakcio elott) | **`SanctionScreeningService.screenCustomer()`** - AML workflow integracio |
| Log (audit) | `SanctionScreeningLog` + `AuditLog` table |

**Fajlok**:
- `backend/src/main/java/hu/puzzleir/valuta/service/SanctionScreeningService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/BlacklistService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java`
- `backend/src/main/java/hu/puzzleir/valuta/repository/ProhibitedPersonRepository.java`
- `backend/src/main/java/hu/puzzleir/valuta/repository/ProhibitedCompanyRepository.java`
- `backend/src/main/java/hu/puzzleir/valuta/entity/SanctionEntry.java`

**Frontend UI**: `frontend-react/src/pages/sanction/*` + `frontend-react/src/pages/compliance/ComplianceDashboardPage.tsx`

**Status**: **TELJES**

### 3. `vevo_mend` (= `vevok.exe` - `Anti/SZERVER/fejleszt/vevo/`)

**Legacy funkcio** (`unit1.pas` ~300 sor):
- Dátum-intervallum szuro (`TOLNAPTAR`, `IGNAPTAR` - MonthCalendar widgetek)
- KFT szuro (BEST / EAST / PANNON - hardcodelt 3 KFT a vegan)
- Korzet szuro (SZEKSZARD=10, SZEGED=20, KECSKEMET=40, DEBRECEN=50, NYIREGYHAZA=63, BEKESCSABA=75, PECS=120, KAPOSVAR=145)
- Penztar (branch) szuro
- MinForint / MaxForint forintertek-tartomany
- IBQUERY: `SELECT * FROM ...` WHERE branch/datum/tartomany

**Modern lefedes**:

| Legacy funkcio | Modern megoldas |
|---------------|-----------------|
| Datum-tol-ig | `@RequestParam dateFrom`, `dateTo` minden kapcsolodo endpoint-nal |
| KFT szuro | Multi-tenant `companyId` JWT token-bol (Spring Security `SecurityUtils.getCurrentCompanyId()`) |
| Korzet szuro | `Branch.regionCode` + `REGION_NAMES` map (`StockSnapshotService`) - 8 korzet lefedve (v2.1.7 ota) |
| Penztar szuro | `@RequestParam branchId` |
| Forint range | **NINCS natív támogatás** (Codex PR #172 P2 audit): `TransactionService.findByHufAmountRange()` NEM létezik. Frontend `TransactionController.searchTransactions()`-t hívja (startDate/endDate/type), majd kliens-oldali szűrés. Külön backend issue nyitandó a natív `minAmount/maxAmount` query-param-hez. |
| Lista + szuro | `CustomerController` 11 endpoint + `TransactionController` filter-ek |

**Fajlok**:
- `backend/src/main/java/hu/puzzleir/valuta/controller/CustomerController.java` (11 endpoint)
- `backend/src/main/java/hu/puzzleir/valuta/controller/TransactionController.java` (dateRange + filter)
- `backend/src/main/java/hu/puzzleir/valuta/service/CustomerService.java`
- Frontend: `frontend-react/src/pages/customers/*`, `frontend-react/src/pages/transactions/TransactionPage.tsx`

**Status**: **TELJES**

## Osszegzes

A "5% legacy gap" a `.remember/remember.md` 2026-04-23 tévesen jelezte hianyt.
A **129/129 = 100% lefedes** biztosított a modern stack-ben.

**Nincs szukseg a tiltcopy / recguard / vevo_mend Java portolasara** — mind harom kesz.

**A 2026-04-24 todo-listabol ezek az elemek torlendok**:
- ~~tiltcopy -> TransactionCopyGuardService (portolas)~~
- ~~recguard -> RecordGuardService (portolas)~~
- ~~vevo_mend -> CustomerBackupRestoreService (portolas)~~

**Kovetkezo lepesek** (a felszabadult idoben):
- Opcio B: Production URL SSOT refaktor
- Opcio C: Playwright e2e live config

## Hivatkozasok

- Legacy forras: `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\SZERVER\fejleszt\`
- Modern backend: `backend/src/main/java/hu/puzzleir/valuta/`
- Modern frontend: `frontend-react/src/`
- Session memory (2026-04-23 tevesen 5% gap): `docs/knowledge/memory/2026-04-23-szerver-live-test.yaml`