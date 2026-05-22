# C4 — Menü + pénztárműveletek: EXCMD-spec vs tényleges kód összevetés

Forrás-specek: `b5-fomenu.md`, `b5-penztar-mozgasok.md`, `b5-penztarallas-listak.md`, `b5-kezeles-cimletezes-engedelyezes.md`
Vizsgált kód: backend `hu.puzzleir.valuta.*` + `frontend-react/src/` (a penztar-client renderer ezt használja).
Készült: 2026-05-22 — KUTATÁS-only.

## b5-fomenu.md (FR-FM)

| FR | Státusz | Kód-bizonyíték | Hiány |
|---|---|---|---|
| FR-FM-07 ÁTADÁS-ÁTVÉTEL menüpont | IMPLEMENTED | `CashierMainMenu.tsx:33` (`route:'/transfers'`) | — |
| FR-FM-08 MAI BIZONYLAT SZTORNÓJA | IMPLEMENTED | `CashierMainMenu.tsx:34` (Stornó → `/transactions`), `StornoPage.tsx` | — |
| FR-FM-09 PILLANATNYI PÉNZTÁRÁLLÁS | PARTIAL | `StockSnapshotPage.tsx` (multi-branch HUF-aggregátum), `InventoryPage.tsx` (értéktár flow) | Lásd FR-PA-01 — nincs egy-pénztáros NYITÓ/BEVÉTEL/KIADÁS/KEZ-I DÍJ/ZÁRÓ nézet |
| FR-FM-10 NAPI/HAVIZÁRÁS, CÍMLETEZÉS | IMPLEMENTED | `ClosingWizardPage.tsx`, `MonthlyClosingPage.tsx`, `DenominationPage.tsx` | — |
| FR-FM-11 BIZONYLATOK MEGTEKINTÉSE | IMPLEMENTED | `TransactionListPage.tsx`, `ReceiptPage.tsx` | — |
| FR-FM-15 KÜLÖNFÉLE LISTÁK | IMPLEMENTED | `CashierMainMenu.tsx:49` (`/reports` aggregátor), `ReportsPage.tsx` | — |
| FR-FM-19 alsó F1–F12 sor | PARTIAL | `CashierMainMenu.tsx:68-80` (F1–F8 hotkeys) | Nincs az F9 KÉSZLET/F10 ÁTADÓLAP/F12 W.UNION konkrét F-billentyű-leképezés; a 2 oldal/lapozás modell eltér |

## b5-penztar-mozgasok.md (FR-PM)

| FR | Státusz | Kód-bizonyíték | Hiány |
|---|---|---|---|
| FR-PM-01/02/03 társpénztár-választó | IMPLEMENTED | `TransferPage.tsx:755-780` (cél-iroda select + `filterTransferTargetBranches`) | Lista-szűrés (terület+TH+1.sz Főp.), nem teljes lapozott lista — üzleti döntés |
| FR-PM-08 mozgalom-főmenü almenük | PARTIAL | `TransferPage.tsx` (irány out/in + type select), `availableTransferTypes` | Nincs külön "Horvát kuna beküldése" / "E-kereskedelem pénzforgalma" menüpont a transfer-flow-ban |
| FR-PM-09 szállítás-űrlap (szállító+plomba+megj.) | IMPLEMENTED | `TransferPage.tsx:879-914` + entity `Transfer.java:98-102` (carrierName, sealNumber) | — |
| FR-PM-09 KÖNYVELHETŐ kötelező-validáció | IMPLEMENTED | `TransferPage.tsx:261-268` (carrier+seal kötelező) | — |
| ERB egyedi kötés (FR-KC-07 + TRB/ERB/FRB kódok) | PARTIAL | `Transfer.TransferType` enum (`Transfer.java:119-121`: CURRENCY/CASH/HANDLING_FEE/VAULT_*/CORRECTION/OTHER) | Nincsenek dedikált ERB/FRB/TRB/FRB/PRB/TV/téves-könyvelés technikai gyűjtő-kódok mint külön kötés-típus |

## b5-penztarallas-listak.md (FR-PA)

| FR | Státusz | Kód-bizonyíték | Hiány |
|---|---|---|---|
| FR-PA-01 PILLANATNYI PÉNZTÁRÁLLÁS oszlopok (VNEM/NYITÓ/BEVÉTEL/KIADÁS/KEZ-I DÍJ/ZÁRÓ) | **MISSING** | `StockSnapshotPage.tsx:159-181` (csak branch+lastUpdated+HUF-érték oszlopok), `InventoryPage.tsx:116-124` (nyitó/átvett/átadott/záró/diff — DE transzfer-flow, nem vétel/eladás, és `opening==null` "jelenleg csak a záró elérhető" `InventoryPage.tsx:174-182`) | Nincs egy-pénztáros valutánkénti NYITÓ/BEVÉTEL(=napi vétel)/KIADÁS(=napi eladás)/KEZ-I DÍJ/ZÁRÓ egy-képernyős nézet |
| FR-PA-04 alsó gombsor (állás+kez.díj nyomtatás) | MISSING | — | Nincs "PILLANATNYI ÁLLÁS KINYOMTATÁSA" / "KEZELÉSI DÍJ NYOMTATÁSA" gomb a fenti nézeten |
| FR-PA-05 bizonylat-szűrés 8 opció | PARTIAL | `TransactionListPage.tsx:232-242` (BUY/SELL/REVERSAL/CONVERSION + dátum) | Hiányzik: "Csak ügyfeles", "Csak pénz-átadási", "Csak pénz-átvételi" szűrő-opció |
| FR-PA-06 hónap/nap kapcsoló | PARTIAL | `TransactionListPage.tsx:213-229` (dátumtól-dátumig) | Nincs "A HÓNAP ÖSSZES" / "CSAK A VÁLASZTOTT NAP" gyors-kapcsoló |
| FR-PA-08 ÖSSZESÍTETT PÉNZTÁRFORGALOM időszak-választó | IMPLEMENTED | `TurnoverController.java:27-64` (daily/weekly/monthly/yearly/company), `DailyTurnoverPage.tsx:74-91` | — |

## b5-kezeles-cimletezes-engedelyezes.md (FR-KC)

| FR | Státusz | Kód-bizonyíték | Hiány |
|---|---|---|---|
| FR-KC-01 KEZELÉSI KÖLTSÉGEK menü (átvétel/átutalás/jelenlegi készlet) | PARTIAL | `HandlingFeeController.java` (calculate/discount/report), `Transfer.TransferType.HANDLING_FEE` | Nincs külön "kez.ktg jelenlegi készlete" + "kez.ktg átvétel/átutalás" menüstruktúra; report van |
| FR-KC-03/04 címletező rács (címlet × darab → összeg) | IMPLEMENTED | `DenominationPage.tsx`, `DenominationCalculatorService.java`, `DenominationController.java` | — |
| FR-KC-08 HAVI TABLÓ + FR-KC-09 hónap/egység választó | PARTIAL | `MonthlyReportService.java:65-292` (teljes havi aggregátum backend) | Lásd alább — nincs dedikált havi-tabló frontend oldal |
| FR-KC-08 FORGALMI GRAFIKONOK | **MISSING** | `DailyTurnoverPage.tsx:67-117` (csak kártya+táblázat, `BarChart3` csupán ikon; nincs recharts/svg chart) | Nincs vizuális forgalmi grafikon sehol a frontenden |
| FR-KC-08 FORGALOM/KÉSZLET-EXCEL | IMPLEMENTED | `StockSnapshotExcelService.java`, `StockSnapshotPage.tsx:90-106` | — |
| FR-KC-10 ÜGYFÉL ORSZÁGOS ELLENŐRZÉSE | PARTIAL | `SanctionScreeningService.java`, `AmlService.java` | Szankció+AML van, de nem köti egységes "országos ellenőrzés" panelba a 10M-es engedélyezéssel |
| FR-KC-11 / NFR-KC-02 10M feletti BLOKKOLÓ engedély (engedélyező + pénz forrása) | **MISSING (PARTIAL)** | `AmlService.java:319,432` (10M = TranzTipus 5 → csak `requiresIdentification`/`requiresDetailedId`); engedély-blokk csak ANNUAL_ROLLING-nál (`AmlService.java:172-183`); `CustomerPanel.tsx:155,301` sourceOfFunds szabad input | Nincs 10M-küszöbhöz kötött kötelező engedélyező-azonosító + "Engedély megadása/Nem engedélyezett" blokkoló kapu |
| FR-KC-13 vásárlás-email visszajelzés | PARTIAL | `EmailPage.tsx` (email modul) | Nincs az engedély-kéréshez kötött "AZ E-MAILEKET SIKERESEN ELKÜLDTEM" megerősítő flow |

---

## VALÓS GAP-EK (prioritás szerint)

### P1 — üzleti/megfelelőségi hiány

1. **10M feletti tranzakció kötelező engedélyező-blokk hiányzik (FR-KC-11, NFR-KC-02).**
   A 10M (`THRESHOLD_10M`) csak besorolási flag, nem blokkol:
   `AmlService.java:431-433` → `return 5;` (csak TranzTipus). A blokkoló engedély csak a göngyölt éves limitnél van (`AmlService.java:179-182`). A spec viszont rögzített szabály: "10 millió felett engedély nélkül nem könyvelhető" + kötelező "Engedélyező" mező + "A pénz forrása". A `sourceOfFunds` jelenleg opcionális szabad-szöveg (`CustomerPanel.tsx:259` `sourceOfFunds.trim() || undefined`), nincs hozzá engedélyező-azonosító + jóváhagyás/elutasítás kapu.

2. **Pillanatnyi pénztárállás egy-képernyős nézet hiányzik (FR-PA-01, FR-PA-04, FR-FM-09).**
   Nincs egy-pénztáros valutánkénti **NYITÓ / BEVÉTEL / KIADÁS / KEZ-I DÍJ / ZÁRÓ** oszlopos táblázat. A `StockSnapshotPage.tsx` multi-branch HUF-aggregátum (`StockSnapshotPage.tsx:159-181` oszlopok: branch/lastUpdated/HUF-érték/valuta-szám). Az `InventoryPage.tsx` értéktár-transzfer-flow (nyitó/átvett/átadott/záró), és saját megjegyzése szerint a nyitó/átvett/átadott jelenleg nincs feltöltve: `InventoryPage.tsx:174-182` ("jelenleg csak a záró elérhető"). Hiányzik a "PILLANATNYI ÁLLÁS KINYOMTATÁSA" + "KEZELÉSI DÍJ NYOMTATÁSA" gomb is.

### P2 — funkcionális/UX hiány

3. **Bizonylat-szűrés hiányos opciók (FR-PA-05).**
   `TransactionListPage.tsx:232-242` csak BUY/SELL/REVERSAL/CONVERSION. Hiányzik: "Csak ügyfeles", "Csak pénz-átadási", "Csak pénz-átvételi" szűrő, és a hónap/nap gyors-kapcsoló (FR-PA-06).

4. **Forgalmi grafikon hiányzik (FR-KC-08 "FORGALMI GRAFIKONOK").**
   `DailyTurnoverPage.tsx:67-117` csak összesítő kártya + táblázat, vizuális chart-library (recharts/svg) sehol nincs a forgalmi nézetekben (`BarChart3` csak lucide-ikon).

### P3 — modellbeli/menüstruktúra eltérés (nagyobb refaktor)

5. **Technikai gyűjtő kötés-kódok (ERB/FRB/TRB/PRB/TV/téves-könyvelés) nincsenek külön típusként (FR-KC-07, FR-PM-08/10).**
   `Transfer.java:119-121` enum csak CURRENCY/CASH/HANDLING_FEE/VAULT_DEPOSIT/VAULT_WITHDRAW/CORRECTION/OTHER. A legacy egyedi-kötés-RB (ERB) szállítás-űrlap mint külön kötés-kategória nincs leképezve; "Horvát kuna beküldése" / "E-kereskedelem pénzforgalma" almenük sincsenek a transfer-flow-ban.

6. **Dedikált "Havi tabló" oldal hiányzik (FR-KC-08/09).**
   A backend kész (`MonthlyReportService.generateFullReport`), de nincs frontend havi-tabló nézet a statisztika/forgalom/grafikon/valutakészlet/Excel almenükkel; csak `MonthlyClosingPage` (zárás) + `DailyTurnoverPage` (forgalom-aggregátum) léteznek külön.
