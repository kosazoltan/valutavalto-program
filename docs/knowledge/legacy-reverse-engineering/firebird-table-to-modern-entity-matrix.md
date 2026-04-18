---
type: analysis
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Firebird Table to Modern Entity Matrix"
load: on-demand
---

# Firebird Table to Modern Entity Matrix

> Cel: a legacy Firebird tabla- es tablafamilia-nevek konkret modern PostgreSQL tablakhoz, entity-khez, migraciokhoz es service-ekhez kotese.
> Gepi matrix: `generated/firebird-table-to-modern-entity-matrix-2026-04-09.csv`

---

## S1 P0_P1_MATRIX

| Legacy table/family | Legacy role | Modern table(s) | Entity path(s) | Migration path(s) | Primary service(s) | Mapping type | Confidence |
|---------------------|-------------|-----------------|----------------|-------------------|--------------------|--------------|------------|
| `IRODAK` | iroda torzsadat | `branch` | `backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java` | `backend/src/main/resources/db/migration/V0_1__base_tables.sql`, `V95__branch_region_code.sql` | `BranchService.java` | 1:1 core + enriched | documented |
| `ARFOLYAM` | veteli/eladasi/elszamolasi rate | `exchange_rate` | `backend/src/main/java/hu/puzzleir/valuta/entity/ExchangeRate.java` | `V3__create_transaction_tables.sql`, `V100__rate_management_multi_tenant_and_limits.sql` | `ExchangeRateService.java` | 1:N | documented |
| `BLOKKFEJ` | bizonylat fej | `receipt`, `transaction` | `Receipt.java`, `Transaction.java` | `V3__create_transaction_tables.sql`, `V42__receipt_sequence_and_rounding.sql` | `TransactionService.java` | 1:N | documented |
| `BLOKKTETEL` | bizonylat tetel | `transaction_line` | `backend/src/main/java/hu/puzzleir/valuta/entity/TransactionLine.java` | `V3__create_transaction_tables.sql` | `TransactionService.java` | 1:1 logical | documented |
| `BFyyMM` | honapos blokkfej archive | `archived_transaction`, archive tables | `backend/src/main/java/hu/puzzleir/valuta/entity/ArchivedTransaction.java` | `V44__monthly_archive.sql`, `V138__daily_closing_archive_tables.sql` | archival/reporting services | N:1 normalized | code-inferred |
| `BTyyMM` | honapos blokktetel archive | archive family | `ArchivedTransaction.java` + archive schema | `V44__monthly_archive.sql`, `V138__daily_closing_archive_tables.sql` | archival/reporting services | N:1 normalized | code-inferred |
| `DAYB{YYMM}` | napkonyv / erkezesi matrix | `daily_session`, closing tables | `backend/src/main/java/hu/puzzleir/valuta/entity/DailySession.java`, `ClosingControl.java` | `V11__closing_control.sql`, `V104__daily_checklist.sql`, `V138__daily_closing_archive_tables.sql` | `DailyClosingService.java` | behavior-only normalized | code-inferred |
| `MNB` | zaras / MNB riport | `daily_balance`, `mnb_report`, `mnb_report_line` | `DailyBalance.java`, `MnbReport.java`, `MnbReportLine.java` | `V6__mnb_reports.sql`, `V45__daily_balance.sql`, `V137__daily_balance_mnb_fields.sql` | `MnbReportService.java` | 1:N | documented |
| `CIMTAR` | cimletezes | `denomination`, `denomination_balance`, `daily_denomination_snapshot` | `Denomination.java`, `DenominationBalance.java`, `DailyDenominationSnapshot.java` | `V81__vault_ertektar_tables.sql`, `V129__transaction_banknote_table.sql` | treasury/denomination services | 1:N | documented |
| `HARDWARE` | workstation/day state | `workstation`, `closing_control` | `Workstation.java`, `ClosingControl.java` | `V11__closing_control.sql`, `V43__pos_terminal_config.sql` | workstation/open-close stack | 1:N | code-inferred |
| `WUNI*` | Western Union | `wu_transaction` | `backend/src/main/java/hu/puzzleir/valuta/entity/WuTransaction.java` | `V91__wu_transaction_status_enum_and_constraints.sql`, `V96__wu_company_id.sql`, `V99__wu_customer_unique_constraint.sql` | `WesternUnionService.java` | 1:N | documented |
| `WAFA*` | WU AFA | `daily_wu_afa_transaction` | `backend/src/main/java/hu/puzzleir/valuta/entity/DailyWuAfaTransaction.java` | `V132__vat_refund_transaction.sql` | WU/AFA service stack | 1:1 logical | documented |
| `TRADyyMM` | trade havi adatok | `trade` | legacy modern trade entity/service family | `V26__trades.sql` | trade services | N:1 | code-inferred |
| `RENDSZER` | global system params | `system_parameter` | `backend/src/main/java/hu/puzzleir/valuta/entity/SystemParameter.java` | multiple base/system migrations | settings/system services | 1:N split | code-inferred |
| `VTEMP` | DLL kozti staging | nincs direkt tabla | nincs direkt entity | nincs | DTO/service state | replaced-by-api | documented |

---

## S2 AMBIGUOUS_OR_SPLIT

| Legacy item | Modern allapot | Megjegyzes |
|-------------|----------------|------------|
| `RENDSZER` | split | reszben `system_parameter`, reszben org/company settings |
| `HIBAK` | unclear | lehet audit/notification/reporting bontas |
| `VTEMP` | replaced | modernben nem stabil fizikai tabla, inkabb request/state boundary |
| `DAYB{YYMM}` | normalized | dinamkus honapos tablak helyett normalizalt session/closing/reporting |
| `BFyyMM` / `BTyyMM` | normalized | archive tablakkal es reporting query-kkel kivaltva |
| `RECEPTOR.FDB` | multi-table hub | nem egy entityre, hanem bounded context-ekre esik szet |
| `booking.fdb` | partial | reservation stack-be oldodik |
| `police.gdb` | partial | police request bounded context |
| `korlevel.fdb` | partial | circulars bounded context |

---

## S3 MODERN_PATH_ANCHORS

### Entity gyoker

- `backend/src/main/java/hu/puzzleir/valuta/entity/`

### Fontos entity-k

- `Branch.java`
- `ExchangeRate.java`
- `Receipt.java`
- `Transaction.java`
- `TransactionLine.java`
- `ArchivedTransaction.java`
- `DailySession.java`
- `ClosingControl.java`
- `DailyBalance.java`
- `MnbReport.java`
- `MnbReportLine.java`
- `Denomination.java`
- `DenominationBalance.java`
- `DailyDenominationSnapshot.java`
- `WuTransaction.java`
- `DailyWuAfaTransaction.java`
- `SystemParameter.java`

### Fontos migraciok

- `V0_1__base_tables.sql`
- `V3__create_transaction_tables.sql`
- `V6__mnb_reports.sql`
- `V11__closing_control.sql`
- `V44__monthly_archive.sql`
- `V45__daily_balance.sql`
- `V81__vault_ertektar_tables.sql`
- `V95__branch_region_code.sql`
- `V100__rate_management_multi_tenant_and_limits.sql`
- `V129__transaction_banknote_table.sql`
- `V137__daily_balance_mnb_fields.sql`
- `V138__daily_closing_archive_tables.sql`

---

## S4 FURTHER_RECONSTRUCTION_TARGETS

1. `IRODAK` oszlopszintu map `Branch`/`BranchStatus` mezo szintre
2. `ARFOLYAM` oszlopszintu map legacy rate type -> modern rate publication modell
3. `DAYB{YYMM}` dinamikus tablaksablon -> modern reporting query matrix
4. `HIBAK` es `RENDSZER` konkret szetszedese bounded contextenkent
