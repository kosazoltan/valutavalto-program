---
type: analysis
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "AML and BIGCTRL Rule-Level Parity"
load: on-demand
---

# AML and BIGCTRL Rule-Level Parity

> Cel: a `BIGCTRL.DLL` es a kapcsolodo AML/KYC szabalyok lebontasa konkret szabalyokra, modern hivaslanccal es teszt-bizonyitekkal.
> Gepi matrix: `generated/aml-bigctrl-rule-parity-2026-04-09.csv`

---

## S1 LEGACY_SZABALYKESZLET

| Rule ID | Legacy szabaly | Forrasallitas |
|---------|----------------|---------------|
| `R-300K` | 300 000 Ft felett kotelezo azonositas | `AmlService` BIGCTRL header, `AmlFlowTest` |
| `R-1.5M` | 1 500 000 Ft felett reszletes azonositas | `AmlService` BIGCTRL header, `AmlFlowTest` |
| `R-3.6M-annual` | eves gongyolesi limit 3.6M | `AmlService` header es annual total logika |
| `R-daily-900K` | napi gyanus limitezes 900K | `AmlFlowTest`, `AmlService` |
| `R-weekly-8day` | 8 napos ablak a weekly gongyolesre | `AmlBigctrlC1C2C3Test` |
| `R-type-6` | `hasforint >= 50M` | `AmlBigctrlC1C2C3Test` |
| `R-type-5` | `hasforint >= 10M` | `AmlBigctrlC1C2C3Test` |
| `R-type-4` | negyedev 4+ tranzakcio es >= 25M | `AmlBigctrlC1C2C3Test` |
| `R-type-3` | evi max >= 8M es hasforint >= 8M | `AmlBigctrlC1C2C3Test` |
| `R-type-2` | kulfoldi ugyfel | `AmlBigctrlC1C2C3Test` |
| `R-type-1` | belfoldi PEP | `AmlBigctrlC1C2C3Test` |
| `R-type--1` | kulfoldi ugyfel nem kaphat USD-t | `AmlControllerCheckAllThresholdsTest`, `AmlBigctrlC1C2C3Test` |
| `R-sanctions` | terror/szankcios lista ellenorzes | `TERROR` legacy, modern `SanctionScreeningService` |
| `R-blacklist` | tiltott ugyfel blokk | legacy `UGYFEL`/`TERROR` vilag, modern blacklist stack |
| `R-structuring` | darabolt tranzakcio felismerese | modern `isStructuring` logika |
| `R-reverse` | sztorno utan annual gongyoles visszaforgatasa | `AmlReverseAccumulationTest` |
| `R-conversion-double` | konverzional dupla HUF-ertek az AML kuszobhoz | legacy Eszter-elemzes, modernben ellenorizendo |
| `R-100K-ui` | 100K felett "Nem azonositom" UI korlatozas | legacy UX/compliance szabaly |

---

## S2 SZABALY_PARITY_MATRIX

| Rule ID | Legacy jelentese | Modern implementacio | Endpoint / caller | Teszt | Status | Risk |
|---------|------------------|----------------------|-------------------|-------|--------|------|
| `R-300K` | alap azonositas | `AmlService.checkTransaction` | tranzakcios hivaslanc | `backend/src/test/java/hu/puzzleir/valuta/integration/AmlFlowTest.java` | full | P0 |
| `R-1.5M` | reszletes azonositas | `AmlService.checkTransaction` | tranzakcios hivaslanc | `backend/src/test/java/hu/puzzleir/valuta/integration/AmlFlowTest.java` | full | P0 |
| `R-3.6M-annual` | annual rolling limit | `AmlService.checkTransaction`, annual repo query | tranzakcios hivaslanc | `backend/src/test/java/hu/puzzleir/valuta/integration/AmlFlowTest.java` | full | P0 |
| `R-daily-900K` | napi suspicious flag | `AmlService.checkTransaction` | tranzakcios hivaslanc | `backend/src/test/java/hu/puzzleir/valuta/integration/AmlFlowTest.java` | full | P0 |
| `R-weekly-8day` | 8 napos ablak | `AmlService.getWeeklyTotal()` | `checkAllThresholds` | `backend/src/test/java/hu/puzzleir/valuta/service/AmlBigctrlC1C2C3Test.java` | full | P0 |
| `R-type-6` | 50M feletti tipus 6 | `AmlService.classifyTransaction` | `/api/v1/aml/check-all-thresholds` | `AmlBigctrlC1C2C3Test.java` | full | P0 |
| `R-type-5` | 10M feletti tipus 5 | `AmlService.classifyTransaction` | `/api/v1/aml/check-all-thresholds` | `AmlBigctrlC1C2C3Test.java` | full | P0 |
| `R-type-4` | negyedeves 4+ es 25M | `AmlService.classifyTransaction` | `/api/v1/aml/check-all-thresholds` | `AmlBigctrlC1C2C3Test.java` | full | P0 |
| `R-type-3` | evi max + 8M | `AmlService.classifyTransaction` | `/api/v1/aml/check-all-thresholds` | `AmlBigctrlC1C2C3Test.java` | full | P0 |
| `R-type-2` | kulfoldi ugyfel | `AmlService.classifyTransaction` | `/api/v1/aml/check-all-thresholds` | `AmlBigctrlC1C2C3Test.java` | full | P1 |
| `R-type-1` | PEP | `AmlService.classifyTransaction` | `/api/v1/aml/check-all-thresholds` | `AmlBigctrlC1C2C3Test.java` | full | P1 |
| `R-type--1` | foreign USD block | `AmlService.checkTransaction(..., currencyCode)`, `WesternUnionService.performAmlCheck(..., "USD")`, `AmlService.checkAllThresholds(..., currencyCode)` | tranzakcios hivaslanc, WU flow, `/api/v1/aml/check-all-thresholds` | `backend/src/test/java/hu/puzzleir/valuta/service/AmlBigctrlC1C2C3Test.java`, `backend/src/test/java/hu/puzzleir/valuta/service/WesternUnionServiceTest.java`, `backend/src/test/java/hu/puzzleir/valuta/controller/AmlControllerCheckAllThresholdsTest.java` | full | P0 |
| `R-sanctions` | szankcios screening | `SanctionScreeningService` + `AmlService` | AML/tranzakcio hivaslanc | `AmlFlowTest.java`, `AmlServiceCompletionTest.java` | full | P0 |
| `R-blacklist` | tiltott ugyfel | `BlacklistService` + `AmlService.checkTransaction` | blacklist/customer flow + AML tranzakcios hivaslanc | `backend/src/test/java/hu/puzzleir/valuta/service/AmlServiceCompletionTest.java` | full | P1 |
| `R-structuring` | darabolas felismeres | `AmlService.isStructuring` | AML/reporting flow | `AmlFlowTest.java` | full | P1 |
| `R-reverse` | sztorno visszaforgatas | `AmlService.reverseAccumulation` | reversal/storno path | `backend/src/test/java/hu/puzzleir/valuta/service/AmlReverseAccumulationTest.java` | full | P1 |
| `R-overdue-report` | AML report hatarido | `AmlDeadlineScheduler`, AML report flow | AML endpoints | `AmlDeadlineTrackingTest.java`, `AmlOverdueEndpointTest.java` | full | P1 |
| `R-conversion-double` | konverzios HUF megduplazas | `TransactionConversionService.executeConversion` -> doubled rounded HUF AML base, target currency passed to AML | conversion hivaslanc | `backend/src/test/java/hu/puzzleir/valuta/service/TransactionConversionServiceTest.java` | full | P0 |
| `R-100K-ui` | 100K UI limit | frontend UX-szintu szabaly | legacy UX parity | nincs dedikalt modern teszt | partial | P2 |
| `R-WU-aml` | WU AML | `WesternUnionService.performAmlCheck` | WU send/receive + IC flow, fail-closed ha nincs HUF es nincs ervenyes USD-arfolyam | `backend/src/test/java/hu/puzzleir/valuta/service/WesternUnionServiceTest.java` | full | P1 |

---

## S3 HIVASLANC

### Fobb modern belépési pontok

- `AmlService.checkTransaction`
- `AmlService.checkAllThresholds`
- `TransactionService.performAmlCheck`
- `TransactionOperationHelper` jellegu tranzakcios orchestration
- `WesternUnionService.performAmlCheck`
- `AmlService.reverseAccumulation`

### Kulcs endpointek

- `GET /api/v1/aml/check-all-thresholds`
- AML report es overdue endpoint csalad
- transaction/WU endpoint-ek, amelyek belul AML-t hivnak

---

## S4 NYITOTT_GAP_EK

| Tema | Leiras | Kockazat |
|------|--------|----------|
| conversion double legal classification | technikai parity mar bizonyitott, de kulon jogi kerdes marad, hogy ez jogszabalyi vagy intezmenyi belso szabaly | P1 |
| stale docs | nehany korabbi markdown meg mindig hianynak jelol olyan BIGCTRL reszeket, amik mar kodban megvannak | P2 |

---

## S5 AJANLOTT_KOVETKEZO_TESZTEK

1. `Conversion foreign-USD target-currency regression`
2. `Quarterly + 8-day combined edge-case regression`
3. `WU + transaction shared AML regression pack`
4. `Blacklist + sanctions audit-log parity`
5. `Conversion caller-chain integration regression`
