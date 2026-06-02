# Doc↔kód konformancia-audit — b8 AML / szankció / forgalom-riport / átadás-átvétel-WU-ÁFA

Dátum: 2026-06-02
Auditált doc-ok:
- `EXCMD/b8-atadas-atvetel-wu-afa-kktg.md`
- `EXCMD/b8-forgalom-keszlet-riportok.md`
- `EXCMD/b8-terrorlista-szankcios.md`

Módszer: minden FR + adatmodell-állítás egyenként verifikálva az aktuális kód ellen. IMPLEMENTED csak `file:line` bizonyítékkal. Bizonytalan → VERIFIKÁLANDÓ.

---

## 1. b8-terrorlista-szankcios.md (AML / szankció — compliance-érzékeny)

| # | Követelmény (doc) | Státusz | Bizonyíték / Eltérés |
|---|---|---|---|
| FR-1 | TXT + EU XML (`xmlFullSanctionsList_1_1` / `sanctionEntity`) import | ⚠️ RÉSZBEN | EU XML: `SanctionScreeningService.java:328` `importEuSanctionList` parse-olja a `sanctionEntity`-t (`:340`). UN XML: `importSanctionList` (`:219`) az `INDIVIDUAL`+`ENTITY` tag-eket. **A statikus `.txt` (Terrorlista2008.txt) import NEM létezik** — sem service-metódus, sem endpoint. A doc IN-scope-ja és FR-1 explicit említi a `.txt`-t. |
| FR-2 | Unicode NFD + kisbetű + `\p{M}+` + írásjel-törlés | ✅ IMPLEMENTED | `SanctionScreeningService.java:491` `normalizeName` — NFD (`:496`), lowercase ROOT (`:497`), `\p{M}+` (`:499`), `[^\p{L}\p{Nd}\s]` (`:499`). Megj.: a doc példája ("DE-B-RE-CEN") megtévesztő, a kötőjeleket a kód eltávolítja. |
| FR-3 | EXACT=1.0→CONFIRMED, ALIAS=0.9 (pontos), PARTIAL=0.8, FUZZY Levenshtein≤2 | 🔴 ELTÉRÉS (pontszámok + alias-szabály) | `SanctionScreeningService.java:41-43`: `EXACT=1.0`, **`PARTIAL=0.7` (doc: 0.8)**, **`ALIAS=0.5` (doc: 0.9)**. Az ALIAS nem pontos-egyezés-only: contains + Levenshtein≤2 is ALIAS-t ad (`:197-201`). FUZZY: a `score = 1.0-(dist/maxlen)`, min `0.3` (`:184-185`) — de a kód `PARTIAL` típussal jelöli, nem külön "FUZZY"-val (`determineRiskLevel` csak EXACT→CONFIRMED, minden más→POSSIBLE, `:435-441`). Funkcionálisan helyes (POSSIBLE/CONFIRMED), de a doc pontszám-táblája NEM egyezik a koddal. |
| FR-4 | `sanction_screening_log`-ba minden szűrés mentve | ✅ IMPLEMENTED | `SanctionScreeningService.java:459` `logScreening` → `screeningLogRepository.save` (`:485`); entity `SanctionScreeningLog.java`; tábla `V5__sanction_screening.sql`. Mezők (worker_id/name, branch_code, supervisor_approved/name) az entity-ben megvannak. |
| Integ. | `POST /api/sanctions/screen` | ⚠️ ÚTVONAL-ELTÉRÉS | Tényleges: `POST /api/v1/sanctions/screen` (`SanctionScreeningController.java:33,44`). A doc `/api/sanctions/...` prefix-et ír (hiányzik `/v1`). |
| Integ. | `POST /api/sanctions/import/eu` + `/import/un` (külön) | ❌ MISSING | Csak EGY endpoint van: `POST /api/v1/sanctions/import` (`SanctionScreeningController.java:80`), ami az `importSanctionList`-et (UN) hívja (`:86`). **Nincs `/import/eu` és `/import/un` külön végpont.** Az `importEuSanctionList` service-metódus csak a `SanctionListScheduler.java:86`-ból (ütemezett) hívódik, controllerből NEM elérhető. Kerestem: grep `import/eu`, `import/un` → csak doc-találat. |
| Integ. | Stale warning: `listAgeDays > 30` (`MAX_SANCTION_LIST_AGE_DAYS`) | 🔴 ÉRTÉK-ELTÉRÉS | `SanctionScreeningService.java:45`: `MAX_SANCTION_LIST_AGE_DAYS = 7` (doc: **30**). A logika (`isSanctionListStale` `:429`) helyes, de a küszöb 7 nap, nem 30. |
| Workflow | POSSIBLE/CONFIRMED → tranzakció zárolva, supervisor feloldás | ⚠️ VERIFIKÁLANDÓ (backend) | A screening visszaadja a `riskLevel`-t, de a `/screen` endpoint maga NEM zárol tranzakciót — a blokkolás/feloldás a hívó (tranzakció-flow / frontend) felelőssége. A `supervisor_approved` mező létezik, de a `SanctionScreeningController`-ben NINCS feloldó/jóváhagyó endpoint. A "tranzakció automatikusan zárolásra kerül" állítás kód-szinten nem itt valósul meg. |
| NFR-2 | Szűrés <200 ms | ⚠️ VERIFIKÁLANDÓ | `screenName` lineáris végigmegy minden aktív bejegyzésen (`:161-209`) Levenshteinnel — nincs index/teljesítmény-teszt erre. Nem mérve. |
| Data | `sanction_entries` (uuid PK, full_name, aliases, list_type EU/UN/OFAC, active...) | ✅ IMPLEMENTED | `SanctionEntry.java` mind. Megj.: oszlop `is_active` (entity `:75`, migr `V5`), a doc `active`-ot ír — logikai név OK. |
| Data | `sanction_screening_log` (mezők) | ✅ IMPLEMENTED | `SanctionScreeningLog.java` — minden doc-mező megvan. |
| Data | SQLite mirror: `sanction_entries` tükrözve penztar-clientbe, offline AML | ⚠️ VERIFIKÁLANDÓ | Nem ellenőriztem a penztar-client SQLite-sémát ebben az auditban; backend-oldalon nincs bizonyíték. A doc-állítás kliens-oldali — külön verifikációt igényel. |
| Plus | FATF ország-kockázat (kódban van, doc-ban nincs) | ℹ️ TÖBBLET | `screenCustomer` 7-arg + `FatfCountryRiskService` (`:50,83`), `SanctionScreeningResult.fatfTier/fatfRiskCountry`. A kód TÖBBET tud, mint a doc — nem hiba, de a doc nem említi. |

**Frontend**: `frontend-react/src/pages/sanction/SanctionPage.tsx` + `services/api/sanction.ts` (`/sanctions/screen|list|import|status`) létezik. ✅

---

## 2. b8-forgalom-keszlet-riportok.md

| # | Követelmény (doc) | Státusz | Bizonyíték / Eltérés |
|---|---|---|---|
| FR-1 | Havi forgalmi riport (cég + hónap) | ✅ IMPLEMENTED | `TurnoverController.java:41` `/api/v1/turnover/monthly` + `:56` `/company`; `ReportController.java:116` `/monthly-turnover`. |
| FR-2 | Havi készlet jelentés (nyitó, vétel, eladás, átadás, átvétel, korrekció, záró, WAC, HUF érték) | ⚠️ RÉSZBEN | Készlet-mozgás/egyenleg: `InventoryMovementController.java:33` `/movement-log`, `:45` `/daily-balance`. WAC-számítás: `WacService`/`CurrencyStock`. **A doc TBD-1 oszlopstruktúrája (WAC árfolyam + HUF készletérték EGY riportban, átadás/átvétel/korrekció bontással) mint egységes riport NEM egyértelműen létezik** — szét van szórva (inventory-movement + WAC profit). Verifikálandó, hogy egy DTO lefedi-e mind a 10 oszlopot. |
| FR-3 | Napi pénztárjelentés + tételsorok (sorszám, bizonylatszám, típus, RB/ERB/PRB/76 kód, összeg) | ⚠️ RÉSZBEN | `ReportController.java:33` `/daily-closing` (`ReportService.DailyClosingReport`). Tételsoros lista + RB/ERB/PRB/76 kód-oszlop megjelenítése a jelentésben VERIFIKÁLANDÓ — a `dest_code` mező a `transaction`-ban van (lásd lent), de hogy a napi jelentés tételesen kiírja-e, nem igazolt. |
| FR-4 | Körzet havi forgalmi összesítő (vétel/eladás HUF, ügyfélszám, pénztáros, havi összesen, munkanapok, napi átlag, trend%) | ✅ IMPLEMENTED (kis hiánnyal) | `RegionTurnoverReportDto.java` + `RegionTurnoverReportService` + `RegionTurnoverReportController`. Tartalmaz: buy/sellHuf, totalTurnover, distinctCustomers, **activeDays** (nem "munkanapok"), avgDailyTurnover, previousTurnover, trendPercent (`:35-45`). **Hiányzik**: napi "ügyeletes pénztáros" mező. Trend-képlet egyezik (előző hó arány). |
| FR-5 | Tranzakció-kódok (RB, ERB, PRB, JRB, 76) feloldása | ⚠️ VERIFIKÁLANDÓ | A `transaction.dest_code` mező létezik (lásd Data). A kód→megnevezés feloldó map/enum-ot nem találtam meg backend-oldalon; valószínűleg frontend label. Verifikálandó. |
| Data | `transaction` (receipt_number, transaction_type BUY/SELL/CASH_TRANSFER, dest_code, financial_effective, status...) | ✅ IMPLEMENTED | `Transaction.java`: `financial_effective` (`:288-289`), `dest_code` (grep igazolt). Mezőnevek egyeznek. |
| Data | `daily_cash_reports` (legacy NAPIZAR) | 🔴 TÁBLANÉV-ELTÉRÉS / MISSING | **Nincs `daily_cash_reports` tábla** — sem migráció, sem entity. A létező entity: `DailyReport.java:20` `@Table(name = "daily_report")`. A doc kétszer is `daily_cash_reports`-ra hivatkozik (`:116,:136`) + TBD-3. Helytelen táblanév. |
| Data | SQLite mirror: napi jelentés + bizonylatok offline | ⚠️ VERIFIKÁLANDÓ | Kliens-oldali állítás, ebben az auditban nem verifikált. |
| Integ. | `GET /api/reports/turnover`, `/api/reports/inventory`, `/api/reports/daily-cash` | 🔴 ÚTVONAL-ELTÉRÉS | Egyik sem létezik ezzel a névvel. Tényleges: forgalom `/api/v1/turnover/{daily,weekly,monthly,yearly,company}` (`TurnoverController.java`); riportok `/api/v1/reports/{daily-closing,period,monthly-turnover,transfers,handling-fees,...}` (`ReportController.java`); készlet `/api/v1/inventory-movements/{movement-log,daily-balance}`. A doc 3 endpoint-neve hibás. |

**Frontend**: `ReportsPage.tsx`, `RegionTurnoverReportPage.tsx`, `DailyTurnoverPage.tsx`, `CashierTurnoverReportPage.tsx`, `InventoryPage.tsx` léteznek. ✅

---

## 3. b8-atadas-atvetel-wu-afa-kktg.md

| # | Követelmény (doc) | Státusz | Bizonyíték / Eltérés |
|---|---|---|---|
| FR-1 | "EGYÉB HAVI ADATAI" riport fejléc (cég+hónap) | ⚠️ VERIFIKÁLANDÓ | Nem találtam dedikált "egyéb havi adatai" riport-végpontot/DTO-t. A WU/ÁFA/kktg adatok külön végpontokon érhetők el; az egységesített havi riport-lap megléte nem igazolt. |
| FR-2 | Napi soros bontás (1–31) | ⚠️ VERIFIKÁLANDÓ | Mint FR-1: az egységes napi-soros "egyéb havi" lap nem azonosított. |
| FR-3 | WU manuális napi NYITÓ/BEVÉTEL/KIADÁS/ZÁRÓ (Záró=Nyitó+Bev-Kiad) | 🔴 ELTÉRÉS (modell) | A tényleges WU-modell **MTCN-alapú pénzküldés/-fogadás tranzakció**: `WesternUnionController.java:42` `/send`, `:53` `/receive`, `:120/131` ic-in/ic-out, MTCN/sender/receiver/fee mezők (`WuTransaction`). A `WuBalance.java` egy **folyó USD/HUF egyenleg** branch-enként (`:42-48`), NEM napi nyitó/bevétel/kiadás/záró sorok. **A doc napi-egyenleg kézi rögzítési modellje (és a `western_union_daily_balances` tábla) NEM létezik így.** Van napi riport (`/daily-report`), de az aggregál, nem kézi nyitó/záró bevitel. |
| FR-4 | Kezelési költség blokk (BEFIZETÉS ÉRTÉKTÁRNAK, BEVÉTEL ÜGYFÉLTŐL, ÁTVÉTEL PÉNZTÁRTÓL) | ⚠️ RÉSZBEN | `HandlingFeeTransaction.java` létezik, DE a feltípus enum `FIXED/PERCENT/TIERED` (`:59-61`), **nem** `VAULT_DEPOSIT/CLIENT_INCOME/CASHIER_TRANSFER` és nincs `direction IN/OUT` / `bank_vault_code` mező, ahogy a doc adatmodell (`:138-144`) állítja. A 3 mozgástípus (befizetés/bevétel/átvétel) így NINCS ezen az entity-n. Van külön `HandlingFeeDecadeReport`, `HandlingFeeService`, `HandlingFeeController` — de a doc-beli mezőstruktúra nem egyezik. |
| FR-5 | E-kereskedelem USD/HUF egyenlegek (NYITÓ, BEVÉTEL BANKTÓL, KIADÁS PÉNZTÁRNAK, VISSZATÉRÍTÉS, ZÁRÓ) | ❌ MISSING | Nincs `EKERESKEDELEM`/`EKERDATA` megfelelő entity/tábla/endpoint. Kerestem: e-ker/electronic/EKER — nincs találat a backend-en. Prio a doc-ban: S. |
| FR-6 | ÁFA-visszatérítés: Tesco (V-) + Metro (AV-) prefix, 5/18/27% ÁFA, HUF kifizetés | 🔴 ELTÉRÉS (bizonylatprefix) | `VatRefundTransaction.java` létezik (`VatRefundController.java` CRUD + reverse), DE a `VoucherType` enum: **`AK` (külföldi ügyfél), `AB` (céges), `AV` (Innova Invest)** (`:196-203`), nem a doc-beli **Tesco `V-` / Metro `AV-`** prefix-szemantika. A migráció kommentje (`V132:36`) is AK/AB/AV. Az `AV` itt "Innova Invest", a doc-ban "Metro". A 5/18/27% kulcs és HUF-kifizetés nincs kényszerítve enum-szinten (szabad `vat_percentage`). **A doc ÁFA-prefix modellje és a kód NEM egyezik.** |
| FR-7 | Pénzszállítás plomba + szállító (plombaszam, szallito); plomba nem üres értéktárinál | ✅ IMPLEMENTED | `CreateTransferDto.java:37-48` `@NotBlank carrierName` + `@NotBlank @Pattern sealNumber`. |
| FR-8 | Haszon: realized = (sale_price - WAC) × qty, `profit_log`-ba | 🔴 NEM BEKÖTÖTT | A képlet implementálva: `WacService.java:101` `recordProfit` → `ProfitLog` save (`:120-133`). **DE `recordProfit` SEHOL nincs meghívva** a tranzakció-végrehajtásból (grep: csak definíció + a read-only `getXxxProfitSummary`). Vagyis a `profit_log` **soha nem töltődik fel** éles vétel/eladásnál. Ráadásul a `ProfitCalculationService.java` (amit a doc forrásként jelöl) **spread-alapú** aggregátum (sellHuf−buyHuf, `:106`), NEM WAC-per-tranzakció realized profit. Két, egymással nem összekötött logika. |
| FR-9 | carrierName max128, sealNumber max64 `^[A-Za-z0-9\-/]+$`, @NotBlank/@Size/@Pattern; tábla VARCHAR+CHECK | ✅ IMPLEMENTED | DTO: `CreateTransferDto.java:37-48` pontosan. Entity: `Transfer.java:100-104` `carrier_name VARCHAR(128)`, `seal_number VARCHAR(64)`. (CHECK-constraint a migrációban: VERIFIKÁLANDÓ, nem ellenőriztem külön.) |
| FR-10 | Nyomtatás gomb + bizonylaton Szállító/Plombaszám; PrintReceiptData bővül | ⚠️ VERIFIKÁLANDÓ (frontend/Electron) | `TransferDocumentPage.tsx` létezik; `handoverPrinted`/`receiptPrinted` flag a `Transfer.java:106-112`. A `generateTransferLines`/`generateTransferHtml`/`ReceiptPreviewModal` carrierName/sealNumber megjelenítése Electron/React-oldalon külön verifikálandó (nem ellenőriztem). |
| Data | `western_union_daily_balances` | 🔴 MISSING | Lásd FR-3. Tényleges: `wu_balances` (`V4__missing_tables.sql:113`), eltérő séma. |
| Data | `handling_fee_transactions` (plural) mezők VAULT_DEPOSIT/.../direction/bank_vault_code | 🔴 ELTÉRÉS | Tényleges tábla `handling_fee_transaction` (singular, `V20`), és a mezők mások (lásd FR-4). |
| Data | `cash_transfer` (uuid PK, source/target_branch_id, seal_number/carrier_name) | 🔴 TÁBLANÉV/PK-ELTÉRÉS | Tényleges: `transfer` tábla, `Transfer.java:23-24` **`Long` id (IDENTITY)**, nem uuid; `from_branch_id`/`to_branch_id` (nem source/target). Mezők logikailag léteznek (seal_number, carrier_name), de a táblanév és PK-típus a doc-ban hibás. |
| Data | `currency_stock` (total_quantity, total_acquisition_cost_huf) | ⚠️ OSZLOPNÉV-ELTÉRÉS | Tábla létezik (`V58`), de az entity mezők `quantity` + `weightedAvgCost` (WacService `:56-57`), nem `total_quantity`/`total_acquisition_cost_huf`. |
| Data | `profit_log` (transaction_id, realized_profit_huf) | ⚠️ OSZLOPNÉV-ELTÉRÉS + üres | Tábla+entity létezik (`V58`, `ProfitLog.java`), de az oszlop `realized_profit` (nem `realized_profit_huf`). És lásd FR-8: gyakorlatban nem töltődik. |
| Integ. | WU nincs külső API (csak manuális) | ⚠️ RÉSZBEN | Van `WesternUnionStubController` + `InternalWesternUnionAdapter`/`InactiveWesternUnionAdapter` (provider-adapter minta). A "csak manuális, nincs API" doc-állítás a stub-architektúrával árnyaltabb; alapból inaktív adapter, de a kód provider-integrációra fel van készítve. |

**Frontend**: `WesternUnionPage.tsx`, `VatRefundPage.tsx`, `TransferPage.tsx`, `TransferDocumentPage.tsx` léteznek. ✅

---

## Záró statisztika

- Auditált követelmény-sorok: **39** (3 doc FR + integráció + adatmodell).
- ✅ IMPLEMENTED (egyezik): **8**
- ⚠️ RÉSZBEN / VERIFIKÁLANDÓ: **16**
- 🔴 ELTÉRÉS (érték/modell/táblanév/útvonal): **12**
- ❌ MISSING: **3** (TXT-import endpoint, külön EU/UN import endpoint, E-kereskedelem modul)

### Legsúlyosabb, compliance-érzékeny eltérések
1. 🔴 **FR-3 (szankció pontszámok + ALIAS-szabály)**: PARTIAL 0.7 (doc 0.8), ALIAS 0.5 (doc 0.9), ALIAS nem pontos-egyezés-only. AML audit-trail félrevezető lehet.
2. 🔴 **Stale-küszöb 7 nap vs doc 30 nap** (`MAX_SANCTION_LIST_AGE_DAYS`). Nem hiba funkcionálisan (szigorúbb), de a doc téves.
3. ❌ **Külön EU/UN import endpoint hiányzik** — csak egy `/import` (UN-only) controller-végpont; EU import csak ütemezőből.
4. 🔴 **FR-8 haszon: a `profit_log` soha nem töltődik** (`recordProfit` nincs bekötve). A doc szerinti realized-WAC-profit per tranzakció NEM működik élesben.
5. 🔴 **FR-6 ÁFA prefix-szemantika** (Tesco V- / Metro AV- vs kód AK/AB/AV=Innova) — adat-modell és üzleti jelentés eltér.

### Pontatlan táblanevek a doc-okban (javítandó)
`western_union_daily_balances`→`wu_balances`; `cash_transfer`→`transfer` (Long PK); `handling_fee_transactions`→`handling_fee_transaction` (eltérő mezők); `daily_cash_reports`→`daily_report`; `currency_stock`/`profit_log` oszlopnevek.

### Pontatlan API-útvonalak a doc-okban
`/api/sanctions/*`→`/api/v1/sanctions/*`; `/api/reports/{turnover,inventory,daily-cash}` → ténylegesen `/api/v1/turnover/*`, `/api/v1/reports/*`, `/api/v1/inventory-movements/*`.
