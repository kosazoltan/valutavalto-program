# Central workstation legacy module inventory

Date: 2026-05-12
Scope: `D:\repo\valutavalto-program\forrasok\SZERVER`

## Summary

The legacy `forrasok\SZERVER` tree is not just a collection of hidden binaries. It contains a sizeable Delphi codebase with source files for most server-side and central-office tools.

Inventory observed:

- 3666 files total under the folder.
- 195 `.exe` files, many of them debug/test launchers named `project1.exe`.
- 99 `.dll` files.
- 482 `.pas`, 482 `.dfm`, 250 `.dpr` source files.
- 28 `.dat`, 5 `.fdb`, 2 `.gdb`, 6 `.dbf`, 87 `.upd`, plus Excel/Word/PDF samples and archives.

Important source layout:

- `fejleszt\server`: old monolithic server UI, `server.exe`, version 7.00.
- `fejleszt\helga\locserver`: later server UI variant, version 8.00.
- `newdll`: released DLL module set, likely deployed under `C:\receptor\newdll`.
- `ujdll`: source tree for the `newdll` modules.
- `fejleszt\recptor`: background receptor process that receives and processes cashier closing packages.
- `fejleszt\arfolyam\verzio22`: latest legacy standalone exchange-rate editor/publisher found in this tree.

Most exact behavior can be read from Delphi source, so for these modules "code-level reversal" means source-level reading rather than blind binary decompilation. Binary string extraction was also run against non-debug EXE/DLL artifacts to confirm hardcoded paths, FTP behavior, database use, and visible form texts.

## Legacy topology

The legacy system has three distinct layers:

1. Interactive server/central-office shell:
   - `fejleszt\server\server.exe`
   - `fejleszt\helga\locserver\locserver.exe`
   - Opens a login form, checks yesterday's closings, then presents a main menu.

2. DLL module library:
   - `newdll\*.dll`
   - Source under `ujdll\<module>\makedll`.
   - The shell and some modules call these DLLs through exported `stdcall` functions.

3. Background receiver/processor:
   - `fejleszt\recptor\wrecept.exe`
   - Watches `C:\RECEPTOR\MAIL\IN\` for marker files.
   - Finds the matching package file, decodes date from the extension, calls `unpackerrutin`, writes into branch monthly Firebird databases, archives the package, and updates `daybook.fdb`.

The modern design should preserve this separation:

- Backend service/API: source of truth, ingest, validation, audit, distribution, scheduled/background jobs.
- Central local workstation Electron app: authenticated operator UI for central office/főértéktár/belső ellenőr workflows.
- Cashier app: remains separate because its operational and offline transaction surface is different.

## Legacy server main menu

`fejleszt\server\unit10.dfm` and `unit1.pas` define these 14 menu entries:

| Menu | Legacy caption | Legacy action | Modern placement |
| --- | --- | --- | --- |
| 1 | Rendszeradatok karbantartása | `Rendszeradatok.ShowModal` | Central workstation admin module, backend validated |
| 2 | Napi árfolyamok karbantartása | `ArfolyamTmk.ShowModal` | Central workstation rate module |
| 3 | Zárások beérkezésének felügyelete | `GetDataDisp` / related forms | Central workstation dashboard, server data |
| 4 | Üzlethelyiségek karbantartása | `IRODATMK.ShowModal` | Central workstation admin, backend validated |
| 5 | Import-file készítése a bank részére | `makeimportrutin` external DLL | Central workstation export UI, backend-generated file |
| 6 | Beérkezett adatok áttekintése | `Attekintes.ShowModal` | Central workstation reporting/dashboard |
| 7 | Adatszolgáltatás az MNB részére | `MnBListak.ShowModal` | Central workstation compliance/reporting |
| 8 | Időszaki átlagárfolyamok | `Atlagarfolyam.ShowModal` | Central workstation reporting |
| 9 | Pénztárosok forgalmi adatai | `Jutszam.ShowModal` | Central workstation payroll/commission/reporting |
| 10 | Árfolyam eltérítések kimutatása | `ArfolyamElterites.ShowModal` | Central workstation audit/reporting |
| 11 | WU és ÁFA adatok ellenőrzése | `WuniWafaControl.ShowModal` | Central workstation audit/reporting |
| 12 | Dolgozói adatkarbantartás | `dolgozoinyilvantartas` external DLL | Central workstation staff admin, backend validated |
| 13 | Tranzakciós díjak jelentése | `tranzakciojelentes` external DLL | Central workstation reporting/export |
| 14 | Jutalék %%% beállítása | `jutalekszorzo` external DLL | Central workstation commission settings |

## Exchange-rate legacy behavior

Two different rate-related tools exist:

1. Full standalone rate editor:
   - `fejleszt\arfolyam\verzio22\arfolyam.exe`
   - Reads/writes `arfdata.dat`.
   - Generates `ujdata.dat`/`NRddhhmm.DAT`.
   - Generates modernized/alternate exchange package `RMddhhmm.ARF`.
   - Uploads to FTP directory `ARFOLYAM`.
   - Deletes previous remote `RM*.ARF` before upload.

2. Server-shell rate maintenance DLL/form:
   - `ujdll\arftmk\makedll\arftmk.dpr`
   - Exports `arfolyamkarbantarto`.
   - Writes settlement/MNB-related files:
     - `C:\receptor\mail\arfolyam\AF100.<kit>`
     - `C:\receptor\mail\exchange\arfMMDD.DAT`

Important binary formats:

- `arfdata.dat`: local editor state. Version byte 16 in `verzio22`, then office data, URL buttons, base rates/formulas/colors, 54 work groups, per-currency work columns, and group limits.
- `NRddhhmm.DAT`: file name comment says version 15/16, 200-byte cashier group mapping, 54 groups, 28 currencies, 9 work columns, 5-byte float encoding, limits, 255-255-255 terminator.
- `RMddhhmm.ARF`: version 111, 54 groups, 23 currencies, 200-byte group mapping, per group/currency encoded currency and 9 rate words, limits, terminator.
- `AF100.<kit>`: settlement/MNB style output, encoded currency plus 5-byte integer rate representation, terminator 255-255.

Modern placement:

- Rate editing and draft workflow belongs in the central local workstation.
- Final publication belongs to the backend API: validate, audit, persist, version, create distribution package, expose to cash desks.
- The workstation may locally prepare the package and show legacy-compatible preview, but it must not be the authority.

## Released DLL catalog

`newdll` appears to be the deployed module library. Source is usually under `ujdll\<module>\makedll`.

| DLL | Legacy source module | Function from captions/source | Modern placement |
| --- | --- | --- | --- |
| `arftmk.dll` | `ujdll\arftmk` | Árfolyamok beállítása, kiküldése | Central workstation rate module + backend publish |
| `atlagarf.dll` | `ujdll\atlagarf` | Időszaki átlagárfolyam számítás, Excel | Central workstation report |
| `bankdisp.dll` | `ujdll\bankforg` | Időszaki banki forgalom | Central workstation report |
| `beerk.dll` | `ujdll\beerkezes` | Beérkezett adatok áttekintése, dispatch to display modules | Central workstation dashboard |
| `datadisp.dll` | `ujdll\datadisp` | Napi/forgalmi data display | Central workstation report |
| `dbctrl.dll` | `ujdll\dbookctrl` | Daybook database control | Backend service/job |
| `dolgjutalek.dll` | `ujdll\jutszamito` | Dolgozói jutalékszámítás | Central workstation reporting; calculation validated server-side |
| `dolgozok.dll` | `ujdll\dolgozok` | Dolgozói nyilvántartás | Central workstation staff admin |
| `forgdisp.dll` | `ujdll\forgalomdisp` | Időszaki forgalom kimutatása | Central workstation report |
| `getdisp.dll` | `ujdll\getdisp` | Report/menu selector | Central workstation navigation concept only |
| `getegyseg.dll` | `ujdll\getuzlet` | Egység/iroda választás | Shared UI picker backed by API |
| `gyujto.dll` | `ujdll\mnbgyujto` | MNB data collection | Backend aggregation + central workstation report UI |
| `hovalasz.dll` | `ujdll\hovalasz` | Hónapválasztó | UI component only |
| `hrk.dll` | `ujdll\hrkserver` | Horvát kuna monthly traffic | Historical/reporting; likely low priority |
| `idoszak.dll` | `ujdll\idoszak` | Időszakválasztó | UI component only |
| `import.dll` | `ujdll\import` | Bank import file generation | Central workstation export UI + backend generation |
| `irtmk.dll` | `ujdll\irtmk` | Irodák/körzetek karbantartása | Central workstation admin |
| `jutszaz.dll` | `ujdll\jutszazalek` | Jutalék százezrelék/szorzó beállítása | Central workstation admin/reporting |
| `kdtrdisp.dll` | `ujdll\kezdtranzdisp` | Kezelési/tranzakciós díjak listája | Central workstation report |
| `keszdisp.dll` | `ujdll\keszletdisp` | Időszaki készletek/címletek | Central workstation report |
| `kezdij.dll` | `ujdll\kezdij` | Havi készpénzes kezelési díj | Central workstation report |
| `legyujto.dll` | `ujdll\adatgyujto` | Adatok legyűjtése | Backend aggregation job, UI trigger/status in workstation |
| `missctrl.dll` | `ujdll\beerkctrl` | Hiányzó zárások ellenőrzése | Backend check + workstation dashboard |
| `mnbhibak.dll` | `ujdll\mnbhibak` | MNB listák/hibák | Central workstation compliance report |
| `ptkdisp.dll` | `ujdll\ptarkozott` | Pénztárak közötti mozgások | Central workstation report |
| `stornodisp.dll` | `ujdll\stornodisp` | Stornózott bizonylatok | Central workstation audit/report |
| `sumwuafa.dll` | `ujdll\sumwuafa` | WU/ÁFA summary helper | Backend aggregation/helper |
| `tranzdij.dll` | `ujdll\tranzakc` | Tranzakciós illetékek/díjak | Central workstation report/export |
| `trbdisp.dll` | `ujdll\trbdisp` | TRB tranzakciók kijelzése | Central workstation audit/report |
| `userin.dll` | `ujdll\userbelep` | Legacy username/password login | Replace with Google OAuth + backend RBAC |
| `westforg.dll` | `ujdll\western` | Western Union monthly traffic | Central workstation report |
| `wudisp.dll` | `ujdll\wunidisp` | WU és ÁFA visszatérítés adatok | Central workstation report |
| `wuwaadvet.dll` | `ujdll\wuafatranz` | WU/ÁFA átadás-átvétel ellenőrzés | Central workstation audit/report |
| `zarasctrl.dll` | `ujdll\zarasctrl` | Zárás beérkezések felügyelete | Backend status + workstation dashboard |

## Standalone tool families

These are not all first-class product modules. Many are maintenance/reporting utilities that should be absorbed or retired.

High relevance for central workstation:

- `fejleszt\arfolyam\verzio22\arfolyam.exe`: full legacy rate editor/publisher.
- `fejleszt\server\server.exe` and `fejleszt\helga\locserver\locserver.exe`: define central workflows and menu map.
- `fejleszt\confident\confident.exe`: anonymous confidential reports, likely internal audit/compliance.
- `fejleszt\okmctrl\okmctrl.exe`: missing documents.
- `fejleszt\uctrl\butitott\ugyfctrl.exe`, `fejleszt\ugyfelcontrol\ugyfctrl\ugyfctrl.exe`: customer/transaction control.
- `fejleszt\jogiszemely\jogiszem.exe`, `fejleszt\personal\kereso\kereso.exe`, `fejleszt\police\*`: customer/legal-person/police-list search and export.
- `fejleszt\korlevel\zsuzsa\korlevel.exe`: circular/announcement management.
- `fejleszt\frissdat\frissdat.exe`: cashier update freshness monitoring.
- `fejleszt\litenews\litenews.exe`: rate publishing to light-news/display service.

Server/background relevance:

- `fejleszt\recptor\wrecept.exe`: watches incoming cash-desk closing packages.
- `ujdll\unpacker\makedll\unpacker.dll`: decodes incoming packages and writes Firebird tables.
- `fejleszt\recptor\dll\makedll\maktablo.dll`: table creation/helper for package ingestion.
- `fejleszt\evnyito\evnyito.exe`, `fejleszt\newyear\evnyito.exe`: annual opening/setup.
- `fejleszt\mentes\mentes.exe`, `fejleszt\napiment\napiment.exe`, `fejleszt\fdbtomorito\tomorito.exe`: backup/compress/restore operations.

Lower-priority historical/reporting tools:

- `hrkvetel.exe`, `western.exe`, `westuni.exe`, `wuniforg.exe`, `mgram.exe`.
- `verseny.exe`, `acversny.exe`, `modibank.exe`.
- `havitablo.exe`, `tablomak.exe`, `stablo.exe`, `summa.exe`, `vevok.exe`, `makeszlt\keszlex.exe`.
- `postterm.exe`, `pttrfee.exe`, `ptarctrl.exe`, `haszon.exe`, `kezdij.exe`.

## Data and file-protocol observations

Hardcoded legacy roots:

- `C:\receptor\database`
- `C:\receptor\mail`
- `C:\receptor\mail\in`
- `C:\receptor\mail\archive`
- `C:\receptor\mail\arfolyam`
- `C:\receptor\mail\exchange`
- `C:\receptor\mail\posta`
- `C:\exchange\data`
- `C:\cartcash\database`

Important database files:

- `receptor.fdb`: central system/reference data.
- `daybook.fdb`: closing status/calendar.
- `vNN.fdb`: branch/monthly cashier databases.
- `kezdij.fdb`, `tranzdij.fdb`, `allugyfel.fdb`, `alljogi.fdb`: specialized modules.

Security-sensitive legacy observations:

- Firebird credentials appear in source and binary strings: `SYSDBA` / `dek@nySo`.
- FTP is used for legacy rate publishing.
- Legacy local paths and direct file writes are pervasive.
- Legacy password UI exists in `userin.dll`; this should be replaced, not ported.

Modern replacement principle:

- The Electron workstation must never get direct database credentials.
- Server/API owns database writes, validation, publication, and audit.
- Workstation submits signed/idempotent commands/packages over authenticated API.
- Server performs RBAC/ABAC checks, not just UI hiding.
- Legacy file formats may be supported as import/export compatibility, but not as the trust boundary.

## Proposed central workstation module map

First-class modules to build into the "Központi helyi munkaállomás":

1. Árfolyamkészítő and publish monitor.
2. Zárás beérkezés dashboard and missing-closing monitor.
3. Beérkezett adatok áttekintése and branch/period report viewer.
4. MNB/compliance reporting.
5. Átlagárfolyam and árfolyameltérítés reporting.
6. WU/ÁFA/TRB/stornó audit reports.
7. Dolgozói and jutalék administration/reporting.
8. Iroda/körzet/értéktár maintenance.
9. Bank import/export generation.
10. Ügyfél/jogi személy/okmány/internal audit tools.

Keep server-side:

1. Cash-desk package receiving.
2. Package decoding and ingestion.
3. Database creation/migration and daily/yearly rollover jobs.
4. Rate publication authority and cash-desk distribution.
5. Audit trail, idempotency, immutable publication history.
6. Scheduled backups, export generation, and report materialization.

Do not port as-is:

1. Legacy username/password login.
2. Direct Firebird access from the desktop app.
3. FTP-based publication as the main path.
4. Direct `C:\receptor` file mutation from operator UI.
5. Hardcoded SYSDBA credentials.

## Implementation order recommendation

1. Freeze this inventory as the starting module map.
2. Rename/reshape the current `arfolyam-keszito-client` concept into a generic central workstation shell, or create a sibling `kozponti-client` shell and move the rate maker into it as module one.
3. Define a backend module-permission manifest: after Google OAuth login, the backend returns the allowed central modules for the active role.
4. Implement the rate maker as the first module because it is already partially modernized.
5. Add read-only zárás/status dashboards next; they carry high operational value and low write risk.
6. Add report/export modules gradually.
7. Add administrative write modules last, with strict backend validation and audit.

## Implemented central workstation shell on 2026-05-12

Decision update: the central/főértéktári/belső ellenőri functions are now placed
into a dedicated local Electron application, not into a server desktop UI.

Implemented package:

- `kozponti-client`
- product name: `Valutavalto Kozponti Iranyitokozpont`
- app id: `com.bestchange.kozponti`
- renderer flavor: `central-workstation`
- default route: `/central-workstation`
- app mode: `full`
- dev renderer port: `3020`

The shell reuses the modern Electron security pattern: backend-mediated Google
OAuth/JWT login, secure token storage, production URL loading, API proxy via
Electron, navigation restrictions, and single-instance locking. The workstation
does not receive direct database credentials and does not mutate `C:\receptor`
paths directly.

Implemented frontend entry:

- `frontend-react/src/pages/central/CentralWorkstationPage.tsx`

The first screen is a dense module launcher for the modern replacements of the
legacy EXE/DLL functions. It groups the audited modules into:

- Árfolyam és főértéktár
- Zárás és beérkezés
- MNB, bank és export
- Audit/AML
- Törzsadat és dolgozói admin
- Ügyfél/okmány/kommunikáció

Installer produced after the mandatory version bump:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.42.exe
SHA256: 421C0FC8B4211913D1E9F587E8FC736A4A8478C5519A5985CFD4F370B96A27EF
```

Verification:

- `npm run package:kozponti`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`

Operational rule added to repo memory: every new installer must get a strictly
higher version number before packaging, and the final `.exe` must be copied to
`C:\Users\Kósa Zoltán\Downloads` with SHA256 verification.

## Backend module-permission manifest implemented on 2026-05-12

The implementation-order item "backend module-permission manifest" is now
closed for the central workstation shell.

Implemented source of truth:

- backend utility: `backend/src/main/java/hu/puzzleir/valuta/util/CentralModuleManifest.java`
- auth DTO field: `LoginResponseDto.centralModules`
- password login: `WorkerService.login(...)`
- Google OAuth login: `GoogleLoginService.loginWithGoogle(...)`
- multi-role finalization: `AuthController.selectRole(...)`
- frontend auth store: `frontend-react/src/stores/authStore.ts`
- module launcher consumer:
  `frontend-react/src/pages/central/CentralWorkstationPage.tsx`

Operational rule:

- If the backend returns `centralModules`, the central workstation launcher uses
  those module IDs as the display manifest.
- If an old backend response does not contain the field, the launcher falls back
  to its existing local role filter for backward compatibility.
- `ADMIN`/`admin` receives every central module.
- For multi-role users, the selected `activeRole` wins over inactive roles after
  `/auth/login/select-role`, so a user does not inherit central modules from a
  role they did not choose for the session.

This closes the memory/code gap found during the four-block audit:
pénztár, értéktár, RFM árfolyamkészítő, and központi continue to use the same
auth response, but only the központi block consumes `centralModules`.

Verification:

- `npm run check:four-area-alignment`
- `npm --prefix frontend-react run typecheck`
- `npm --prefix frontend-react test -- authStore`
- `backend/.mvnw "-Dtest=CentralModuleManifestTest,GoogleLoginServiceTest,AppModeRoleConstantsTest" test`
- `npm run lint` (0 errors; existing i18next literal-string warnings remain)

## Implemented closing-arrival monitor on 2026-05-12

Legacy target:

- `zarasctrl.dll`
- `beerk.dll`
- `missctrl.dll`
- `daybook.fdb` closing-arrival/missing-closing logic

Implemented modern placement:

- Backend/API remains authoritative for branch closing-control state.
- Central workstation renders the operator dashboard and sends auditable
  warning commands through the API.
- Cashier/local branch workflows remain separate.

Backend changes:

- `ClosingControlDto` now includes branch identity and computed status fields:
  branch code/name/city, completed/required counters, and `missingRecord`.
- `ClosingControlService.checkAllBranches(date)` now returns every active branch
  in the current company, not only already existing `closing_control` rows.
  This is the important legacy parity fix: a missing zárás can no longer
  disappear because no row exists yet.
- Missing past-date rows are marked `CRITICAL`; incomplete current-day rows are
  marked `WARNING`; complete rows are `NONE`, unless an explicit stored alert is
  already present.
- Queries are company-scoped to avoid cross-tenant leakage.
- `sendAlert` validates that the branch belongs to the current company before
  creating/updating the warning row and dispatching the notification.

Frontend changes:

- New API client: `frontend-react/src/services/api/closing-control.ts`
- New central page: `frontend-react/src/pages/central/ClosingControlPage.tsx`
- New route: `/central/closing-control`
- New menu item under `Központ`: `Zárás beérkezés`
- Central launcher tile `Zárás beérkezés` now points to the implemented page and
  is marked `ready`.
- `DaybookPage` accepts `branchId` and `date` query parameters so the central
  monitor can jump into a specific branch/date daily book context.

Installer produced after mandatory version bump:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.43.exe
SHA256: 9D51AF39DA0F408CCB87553FB3B7A924315F5F8AED1483E5841AF888583AD5A9
```

Verification:

- `npm run package:kozponti`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `cd backend; .\mvnw -Dtest=ClosingControlServiceTest test`

## Implemented received-data overview on 2026-05-12

Legacy target:

- `beerk.dll`
- `datadisp.dll`
- `getdisp.dll`
- daily report / received package overview around `daybook.fdb`

Implemented modern placement:

- Backend/API provides a central, company-scoped received-data overview.
- Central workstation renders the operational table and CSV export.
- Branch/cashier workflow stays separate; this module is a central monitoring
  and drill-down surface.

Backend changes:

- New DTOs:
  - `CentralReceivedDataOverviewDto`
  - `CentralReceivedDataRowDto`
- New service:
  - `CentralReceivedDataService`
- New endpoint:
  - `GET /api/v1/central/received-data/status?date=YYYY-MM-DD`
- The endpoint merges:
  - active branches for the current company,
  - `daily_report` rows for the selected date,
  - `closing_control` rows for the selected date.
- Every active branch appears even when no daily report exists. Missing past-day
  data becomes `CRITICAL`; missing same-day data is `WAITING` unless the closing
  status already escalates it.
- The summary includes branch count, received/submitted/missing counts, warning
  and critical closing counts, transaction totals, buy/sell/fee/profit totals.

Frontend changes:

- New API client: `frontend-react/src/services/api/central-received-data.ts`
- New page: `frontend-react/src/pages/central/ReceivedDataOverviewPage.tsx`
- New route: `/central/received-data`
- New menu item under `Központ`: `Beérkezett adatok`
- Central launcher tile `Beérkezett adatok` now points to the implemented page
  and is marked `ready`.
- The page supports date selection, text search, status filtering, CSV export,
  and drill-down into the daily book for the selected branch/date.

Installer produced after mandatory version bump:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.44.exe
SHA256: 0B273FAF1A8CE69870D0B9DD65C6EF59CBBE21B94997E94570B5022A1FD8F056
```

Verification:

- `npm run package:kozponti`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `cd backend; .\mvnw "-Dtest=CentralReceivedDataServiceTest,ClosingControlServiceTest" test`

## Implemented central sprint board on 2026-05-12

User request:

- Place every function already founded from the server legacy audit into one
  sprint inside the central Electron program.

Implemented modern placement:

- New central sprint page:
  `frontend-react/src/pages/central/CentralSprintPage.tsx`
- New route:
  `/central/sprint`
- New menu item:
  `Központ / Központi sprint`
- New launcher tile in the central workstation:
  `Sprint és irányítás / Központi sprint`

The sprint board lists the already identified central workstation functions with
operational metadata:

- work area,
- modern module name,
- legacy source file/function group,
- current sprint state (`kész`, `sprintben`, `következő`, `release`),
- priority (`P0`, `P1`, `P2`),
- modern target route,
- expected business outcome.

It includes the already implemented central items:

- central Electron workstation shell,
- Google OAuth auto-detection leadership login,
- local rate-maker and rate publication workflow,
- closing-arrival monitor,
- received-data overview,
- permission matrix / role filtering,
- report, audit, AML, worker, customer, document and communication modules
  identified from the legacy server folder.

Installer produced after mandatory version bump:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.45.exe
SHA256: A5588061B9E179A020B257861901B0E426D6FCCBE9CC7F9C385BE8E7B21CF613
```

Verification:

- `npm --prefix frontend-react run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `npm run typecheck`
- `npm run package:kozponti`

## Three-client alignment on 2026-05-12, version 2.5.47

The installer folder was found to contain only partial and mismatched versions.
The release set was therefore normalized to one higher version: `2.5.47`.

Functional alignment changes:

- `teruleti_vezeto` and `biztonsagi_vezeto` are accepted in the central `full`
  appMode because the local central workstation is intended for these leadership
  roles as well.
- Backend Google-login app-mode calculation now returns `kamera` + `full` for
  these roles, so server-side and frontend-side filtering match.
- The rate-maker remains intentionally restricted to `foertektar`, `ugyvezeto`,
  and legacy `ADMIN`.
- The central menu and the central workstation launcher now both send
  `Országos készlet` to `/cashier-stocks`.
- The three Electron products remain separate installations with unique
  `appId` and `productName`, but all use the same production API:
  `https://excvaluta.com/api/v1`.

Installer set copied to Downloads:

```text
C:\Users\Kósa Zoltán\Downloads\Penztar-Setup-2.5.47.exe
SHA256: C602495CA8D9D38EDFB5DF9729AFC4F98539FB9257663DE4455B393F45CF5EBF

C:\Users\Kósa Zoltán\Downloads\Arfolyamkeszito-Setup-2.5.47.exe
SHA256: 4AFC802E045D07FA567F2518E4CE637750A692EF8476299E450E813325AB02FD

C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.47.exe
SHA256: 9D7CE24A47F06228C300E08D8C25AACEA475F3C1CF62B51CEDC54A49AF5B7862
```

Verification:

- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `cd backend; .\mvnw '-Dtest=AppModeRoleConstantsTest,GoogleLoginServiceTest,RatePublishServiceTest' test`
- `npm --prefix penztar-client run package:unsigned`
- `npm run package:arfolyam-keszito`
- `npm run package:kozponti`

## Four-area prepackage alignment on 2026-05-12, version 2.5.48

User clarification:

- The release gate must align four functional areas, not merely three installer
  files:
  pénztár, értéktár, RFM/rate-maker, and central.

Implemented:

- New mandatory prepackage gate:
  `scripts/check-four-area-alignment.mjs`
- New root command:
  `npm run check:four-area-alignment`
- All three Electron `package` and `package:unsigned` scripts run this gate
  before packaging.
- The legacy `check:three-client-endpoints` command remains as a compatibility
  wrapper and delegates to the four-area gate.
- Browser/web `full` mode is now treated as reserve server access in the UI:
  default route and post-login route go to `/central-workstation`, and the main
  layout shows a reserve web access warning band.

Functional model:

- Pénztár: `penztar` appMode, `/cashier`, shared local client.
- Értéktár: `ertektar` appMode, `/treasury`, shared local client.
- RFM/rate-maker: `rate-maker` appMode, `/rates/creation`, dedicated client.
- Központi: `full` appMode, `/central-workstation`, dedicated client and web
  reserve surface.

Installer set copied to Downloads:

```text
C:\Users\Kósa Zoltán\Downloads\Penztar-Setup-2.5.48.exe
SHA256: 53C8BA6887772D3699D66F9A9152AF03CDF819C6DA2A3D5C93EBBD1CB54AD430

C:\Users\Kósa Zoltán\Downloads\Arfolyamkeszito-Setup-2.5.48.exe
SHA256: 8178408E46C60915EE49DD85C1A3ADA0888403D0C19AF2BEC99BC6947D9617E7

C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.48.exe
SHA256: DC2A03659EC09A9BC197B44241284F4F443BF9A94E0AD8460CB96995CC712714
```

Verification:

- `npm run check:four-area-alignment`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates useAppMode`
- all three installer builds, each with the four-area gate executed first
- Dev renderer smoke test:
  `http://127.0.0.1:3020/central/sprint` returned HTTP 200 and redirected to
  the protected login screen without page runtime errors.

## Central services completion pass on 2026-05-12

User request:

- After confirming that not every central service could honestly be called fully
  implemented, finish the remaining central Electron sprint items.

Implemented fixes and completion pass:

- `DailyChecklistPage` now works against the real backend DTO contract:
  `itemTitle`, `itemDescription`, `checked`, `checkedAt`, `checkedByWorkerId`,
  `notes`.
- `DailyChecklistPage` now sends the backend request contract:
  `{ checked, notes }`, not the previously ignored frontend-only field names.
- `DailyChecklistPage` gained central branch selection and branch status cards.
  This turns the old branch-local checklist screen into a usable central
  supervision screen while preserving the per-branch checklist workflow.
- `WesternUnionPage` gained branch selection for central operators and no longer
  depends on a localStorage-only branch id.
- `CircularPage` was realigned with the actual backend API:
  `/circulars/active`, `/circulars/archived`, `/circulars/by-type/{type}`,
  `/circulars/typed`, `/circulars/{id}/archive`, and
  `/circulars/{id}/acknowledge-worker`.
- `CircularPage` now uses the actual backend fields:
  `registrationNumber`, `circularType`, `priority`, `createdByName`,
  `validFrom`, `archived`, `acknowledged`, and `acknowledgmentCount`.
- Central launcher status was updated to `ready` for the remaining legacy
  modules that already have a concrete frontend/backend route.
- The `Országos készlet` launcher now points to `/cashier-stocks`, the actual
  countrywide cashier stock overview, instead of the local vault-stock page.
- `CentralSprintPage` now marks every central sprint item as `kész` after the
  completion pass.

Important boundary:

- This means the central Electron services are implemented and wired at
  UI/API/build level inside the application.
- It does not mean that external third-party production integrations are proven
  live in the user's operating environment. Those still depend on the configured
  backend adapters, credentials, server data, and real external service access.

Installer produced after mandatory version bump:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.46.exe
SHA256: A6F63CE77D8F6151ED34644D20615EB2B906ABEF6420F2399089504A80C62EE8
```

Verification:

- `npm --prefix frontend-react run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `npm run typecheck`
- `npm run package:kozponti`
