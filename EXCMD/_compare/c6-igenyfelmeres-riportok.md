# C6 — Igényfelmérés + Riportok: EXCMD spec vs. tényleges kód

Verifikáció: 2026-05-22, v2.26.18. Forrás-spec: b7-fejlesztesi-lepesek + b8-forgalom-keszlet + b8-atadas-atvetel-wu-afa-kktg + b8-atlagarfolyam + b8-terrorlista. Csak konkrét FR-ekre; b7 magas szintű = modul-meglét.

## b8 — Forgalmi és készlet riportok

| FR | Státusz | Kód-bizonyíték | Hiány |
|---|---|---|---|
| FR-1 fejléc cég+hónap | IMPLEMENTED | `MonthlyReportService.generateFullReport` branchName/branchCode/taxId (251-257) | — |
| FR-2 oszlopok (vétel/eladás/átadás/átvétel/Ft/készpénzes/bankkártyás) | PARTIAL | `MonthlyReportFullDto.CurrencyLineDto` (102-114): opening/closing/buy/sell/buyHuf/sellHuf/rate. `TurnoverReportDto.CurrencyTurnoverDto` buy/sell/fee/count | Nincs KÉSZPÉNZES vs BANKKÁRTYÁS bontás; ÁTADÁS/ÁTVÉTEL külön transferLines-ben, nem a forgalmi oszlopban |
| FR-3 valutánkénti sorok | IMPLEMENTED | `MonthlyReportService` allCurrencies TreeSet (126-184) GROUP BY currency | — |
| FR-4 körzet→iroda→valuta→ÖSSZESEN fa | PARTIAL | iroda→valuta megvan; `CentralReportService` cég-szint | A KÖRZET-szintű hierarchikus fa a forgalmi riportban hiányzik (csak MNB-riportban van regionCode) |
| FR-5 körzetek (8 régió) | PARTIAL | `MnbRegionReportDto.regionCode/regionName` (17-18), `RegionSnapshotDto` | Régió-szint csak MNB + stock-snapshot; a havi forgalmi riport nem csoportosít körzetre |
| FR-6 cég-szintű + záró ÖSSZESEN | IMPLEMENTED | `CentralReportService` (company-scoped daily/weekly/monthly CSV) | — |
| FR-7 több cég külön lap | PARTIAL | multi-tenant companyId-szűrés mindenhol | Egy lekérdezés = egy cég; "több cég egy nézetben külön lapon" nincs |
| FR-8..12 napi pénztárjelentés (fejléc, tételsor, nyitó/záró/forgalom mátrix, darab) | IMPLEMENTED | `DailyReportService`/`DailyReportGenerator` + `DailyReportFullDto` (closingBalanceHuf/Foreign/Total 26-28, receiptNumber 129), `DaybookPage.tsx`, `DailyJournalController` PDF | — |
| FR-13..15 körzet havi forgalmi összesítő (trend%, átl.forg, előzőhó) | MISSING | — | Nincs körzet-szintű havi riport vevők/eladók-számmal, trend%-kal, munkanap/átl.forg/előzőhó számított sorokkal |
| FR-16 Ft-formátum | IMPLEMENTED | `roundHuf` util + frontend formázás | — |
| FR-17 éves trend 2015–2024 | MISSING | — | Nincs több-éves trend riport |

## b8 — Átadás-átvétel, WU, ÁFA, kez.ktg, haszon

| FR | Státusz | Kód-bizonyíték | Hiány |
|---|---|---|---|
| FR-1 "EGYÉB HAVI ADATAI" fejléc | PARTIAL | `MonthlyReportService` WU/ÁFA/kktg/e-ker blokkok (207-291) | A blokkok a havi riportban vannak, nem külön "egyéb havi adatai" riportként |
| FR-2 napi soros bontás | PARTIAL | `WesternUnionService.getDailyReport` (428) napi; `DailySubledgerSnapshot` napi | Havi riport opening/closing-ot ad, nem 1–31 napi sort minden blokkra |
| FR-3 WU NYITÓ/BEVÉTEL/KIADÁS/ZÁRÓ | IMPLEMENTED | `MonthlyReportService` wuUsd/wuHuf Opening/Income/Expense/Balance (208-216), `WuBalance` entity | — |
| FR-4 kez.ktg (befizetés értéktárnak/bevétel ügyféltől/átvétel pénztártól) | IMPLEMENTED | `HandlingFeeService`/`HandlingFeeCalculator`/`HandlingFeeTransaction`+`HandlingFeeType`, MonthlyReport handlingFee Opening/Income/Expense (224-227), `HandlingFeeDecadeService` | — |
| FR-5 e-ker NYITÓ/BANK/PÉNZTÁR/VISSZATÉRÍTÉS USD+HUF | PARTIAL | `MonthlyReportService` ECOMMERCE subledger opening/income/expense/balance (230-233) | Csak HUF-dimenzió a havi riportban; nincs USD+HUF al-egyenleg + külön "visszatérítés" mező |
| FR-6 ÁFA-visszatérítés napi | IMPLEMENTED | `VatRefundTransaction`+`VatRefundService`+`VatRefundController`, `VatRefundPage.tsx`, V132 migráció, MonthlyReport afa Opening/Income/Expense (218-221) | — |
| FR-7 MATRICA/TELEFON | PARTIAL | `StampService`+`StampAssignment` (matrica/illeték) | TELEFON értékesítés nincs |
| FR-8 ÁTADÁS/ÁTVÉTEL napi mező | IMPLEMENTED | `MonthlyReportService.buildTransferLines` (300-331), `TransferRepository.sumTransfersIn/OutByPeriod` | — |
| FR-9 körzet→iroda hierarchia | PARTIAL | lásd forgalmi FR-4/5 | körzet-szint hiányzik |
| FR-10 cégenként külön lap | PARTIAL | companyId-szűrés | "egy nézet több lap" nincs |
| FR-11..14 kez.ktg jelentés bizonylat (K- prefix, KEZELÉSI DÍJ/NYITÓ/ZÁRÓ mátrix, aláírás) | IMPLEMENTED | `HandlingFeeDecadeReport`+`HandlingFeeDecadeService`+`HandlingFeeDecadePage.tsx` | — |
| FR-15 ÁFA+kktg havi összesítő | IMPLEMENTED | MonthlyReport afa+handlingFee blokk | — |
| FR-16 haszon riport pénztáranként | PARTIAL | `TurnoverReportDto`: spread/fees/netProfit + byWorker (13-40) | "Haszon pénztáranként" mint dedikált riport nincs; netProfit cég-szinten van |

## b8 — Átlagárfolyam (AcAtlagarf oszlop-összevetés)

| FR | Státusz | Kód-bizonyíték | Hiány |
|---|---|---|---|
| FR-1 önálló átlagárfolyam-riport | IMPLEMENTED | `AverageRateReportService` + `AverageRateReportController` + `AverageRateReportPage.tsx` | — |
| FR-2 valutánkénti átlag adott időszakra | IMPLEMENTED | `AverageRateReportService.generate` GROUP BY currency, súlyozott avg = SUM(huf)/SUM(currencyAmount) (69-130) | — |
| FR-3 részletes oszlopstruktúra | PARTIAL | `AverageRateReportDto`: periodStart/End, branch, currency, count, totalCurrency, totalHuf, weightedAverageRate (24-61) | A spec FR-3-ban TBD (binary forrás); a meglévő DTO egy súlyozott átlagot ad — vétel/eladás külön átlag NINCS (transactionType szűrő van, de egy hívás = egy típus, nem párhuzamos buy+sell oszlop) |

**AcAtlagarf vs AverageRateReport:** a forrás-xlsx OLE2 binary → oszlopstruktúrája spec szinten TBD, így nincs ellenőrizhető oszlop-eltérés. A meglévő impl egyetlen HUF-súlyozott átlagot ad valutánként; ha a legacy külön VÉTEL-átlag + ELADÁS-átlag oszlopot tartalmazott, az a jelenlegi egy-soros DTO-ból külön hívással (type=BUY / type=SELL) állítható elő, de nem egy nézetben.

## b8 — Terror/szankciós lista

| FR | Státusz | Kód-bizonyíték | Hiány |
|---|---|---|---|
| FR-1 plain-text fejléc | N/A (legacy format) | importer `importSanctionList`/`importEuSanctionList` (183, 255) UN/EU XML | A 2008-as plain-text `.txt` formátum NEM importálható; csak ENSZ/EU XML feed (modernebb, kívánatos) |
| FR-2 név + opcionális azonosító | IMPLEMENTED | `SanctionEntry.fullName`+`listReference` (39-64), XML REFERENCE_NUMBER/euReferenceNumber | — |
| FR-3 azonosító nélküli sorok | IMPLEMENTED | `listReference` nullable | — |
| FR-4 alias/azonosító-dedup | IMPLEMENTED | `SanctionEntry.aliases` JSON + `screenName` alias-loop (156-172) | — |
| FR-5 személy+szervezet | PARTIAL | INDIVIDUAL csak; típus-mező nincs | Szervezet (ENTITY) tag nem importált; nincs person/org típus |
| FR-6 multi-script normalizálás | PARTIAL | `normalizeName` (418-431): latin ékezet-strip + lowercase | Görög/cirill NEM kezelve — `[^a-z0-9\\s]` mindent eldob, így görög/cirill input üres stringre normalizálódik (NEM Unicode NFC+diakritika-strip, ahogy NFR-1 kéri) |
| FR-7 vegyes névsorrend | IMPLEMENTED | contains + Levenshtein (142-153) tolerálja | — |
| FR-8 vezető szóköz trim | IMPLEMENTED | `normalizeName` `\\s+`→" " trim (429-430) | — |
| FR-9 AML-szűrő bemenet | IMPLEMENTED | `screenCustomer` (54-118), `SanctionScreeningController`, `SanctionListScheduler`, #4 stale-fallback (102-117) | — |

## b7 — Fejlesztési lépések (modul-meglét, magas szint)

FR-53..88 többsége IMPLEMENTED: DB/Flyway, auth+jelszó, RBAC, törzsadatok (cég/iroda/címlet/devizanem/ügyfél), váltás/foglaló/átadólap/bizonylat/zárás, árfolyam/díj, AML+tiltólista, riportok, szinkron. **Nem ellenőrzött részletek (b7 magas szint):** FR-57 3-havi kötelező jelszócsere (NFR-13) — külön verifikáció szükséges; FR-77 valuta-igény generálás; FR-88 hírlevél/verziókezelés (spec maga csonka).

---

## VALÓS GAP-EK (prioritással)

**P1 — jogszabályi / pénzügyi pontosság**

1. **Szankciós név-normalizálás nem Unicode-tolerant (FR-6/NFR-1).** `SanctionScreeningService.normalizeName` (418-431) a `replaceAll("[^a-z0-9\\s]", "")` lépéssel a görög/cirill karaktereket TÖRLI, nem transzliterálja. Egy görög/cirill szankciós név üres stringre normalizálódik → false negative AML-találat. Fix: `java.text.Normalizer.normalize(NFD)` + diakritika-strip a karakter-osztály eldobása helyett.

2. **Szervezet-nevek (ENTITY) nem importáltak (FR-5).** `importSanctionList` csak `getElementsByTagName("INDIVIDUAL")`-t olvas (196). A szankciós listák szervezet-tételei (terror-szervezet, cég) kimaradnak → szűrés hiányos. Fix: ENTITY/sanctionEntity entity-blokk párhuzamos parse + type mező a `SanctionEntry`-be.

**P2 — riport-funkció hiány (legacy parity)**

3. **Körzet-szintű havi forgalmi/trend riport hiányzik (FR-13..15).** Sem a `MonthlyReportService`, sem a `CentralReportService` nem ad körzet→összesítő nézetet vevők/eladók-számmal, trend%-kal (aktuális/előzőhó), munkanap/átl.forg sorral. Régió-bontás csak `MnbRegionReportDto`-ban van, de az MNB-jelentés, nem forgalmi. Fix: új `RegionTurnoverReportService` régió GROUP BY + előző-havi referencia.

4. **Forgalmi riportban nincs KÉSZPÉNZES vs BANKKÁRTYÁS bontás (FR-2).** `CurrencyLineDto` (102-114) nem tartalmaz fizetési-mód oszlopot. A tranzakcióban van payment method, de a riport-aggregáció nem bontja. Fix: GROUP BY paymentMethod a forgalmi aggregációban.

5. **E-ker blokk csak HUF, nincs USD al-egyenleg + visszatérítés-mező (FR-5).** `MonthlyReportService` ECOMMERCE subledger egydimenziós HUF (230-233). Fix: USD+HUF kétdimenziós subledger + visszatérítés külön mező.

**P3 — kisebb / kérdéses üzleti igény**

6. **Haszon-riport pénztáranként (FR-16) nincs dedikált nézetként** — `TurnoverReportDto.netProfit` cég-szintű; pénztárankénti haszon külön riport hiányzik.
7. **TELEFON-értékesítés mező (FR-7)** nincs (matrica/`StampService` van).
8. **Több-éves (2015–2024) trend riport (forgalmi FR-17)** nincs.

> Megj.: az átlagárfolyam-riport oszlopstruktúrája és a legacy plain-text Terrorlista2008.txt formátum a spec-ben TBD (binary/elavult forrás) — nem valós kód-gap, hanem hiányzó forrás-referencia; a modern XML-feed + súlyozott-átlag impl funkcionálisan lefedi.
