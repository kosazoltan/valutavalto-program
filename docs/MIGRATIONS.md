# Flyway Migrációk — V1.1–V41

> Generálva: 2026-03-06  
> Összesen: 41 migráció | ~80 tábla létrehozva/módosítva

## Megjegyzés

A `company` és `branch` alaptáblák JPA `hibernate.ddl-auto=update` révén jönnek létre az első futáskor.  
A Flyway `baseline-on-migrate=true` beállítással indul, tehát a V1.1 migráció a már létező sémán fut.

## Migráció → Tábla Mapping

| Migráció | Fájlnév | Művelet | Érintett táblák |
|----------|---------|---------|-----------------|
| V1.1 | `V1_1__add_company_code.sql` | ALTER | `company` (code oszlop hozzáadás) |
| V2 | `V2__create_worker_tables.sql` | CREATE | `worker`, `worker_session` |
| V3 | `V3__create_transaction_tables.sql` | CREATE | `currency`, `exchange_rate`, `customer`, `daily_session`, `transaction`, `cash_balance`, `denomination`, `exchange_rate_history` |
| V4 | `V4__missing_tables.sql` | CREATE | `qr_parameters`, `sync_queue`, `bank_cash_journal`, `decade_reports`, `stamp_receipts`, `stamp_data`, `wu_balances`, `wu_customers`, `wu_transactions` |
| V5 | `V5__sanction_screening.sql` | CREATE | `sanction_entries`, `sanction_screening_log` |
| V6 | `V6__mnb_reports.sql` | CREATE | `mnb_report`, `mnb_report_line` |
| V7 | `V7__nav_closings.sql` | CREATE | `nav_closing`, `nav_closing_line` |
| V8 | `V8__data_collection.sql` | CREATE | `data_collection`, `collected_transaction`, `collected_inventory` |
| V9 | `V9__hrk_transactions.sql` | CREATE | `hrk_transaction` |
| V10 | `V10__evening_closing.sql` | CREATE | `evening_closing` |
| V11 | `V11__closing_control.sql` | CREATE | `closing_control` |
| V12 | `V12__customer_control.sql` | CREATE | `customer_restriction`, `customer_screening_log` |
| V13 | `V13__monthly_closing.sql` | CREATE | `monthly_closing_summary` |
| V14 | `V14__commission.sql` | CREATE | `commission_calculation`, `commission_rule` |
| V15 | `V15__worker_management.sql` | CREATE | `worker_attendance`, `worker_break` |
| V16 | `V16__stamps.sql` | CREATE | `stamp_batch`, `stamp_assignment` |
| V17 | `V17__rate_approvals.sql` | CREATE | `rate_approval`, `led_display`, `inventory_regeneration` |
| V18 | `V18__police_requests.sql` | CREATE | `police_request` |
| V19 | `V19__decade_reports.sql` | CREATE | `decade_report` |
| V20 | `V20__handling_fee_transactions.sql` | CREATE | `handling_fee_transaction` |
| V21 | `V21__rate_categories.sql` | CREATE | `rate_category` |
| V22 | `V22__competitions.sql` | CREATE | `worker_competition`, `worker_competition_entry` |
| V23 | `V23__packaging.sql` | CREATE | `packaging_record` |
| V24 | `V24__data_import.sql` | CREATE | `data_import_jobs` |
| V25 | `V25__audit_log.sql` | ALTER | `audit_log` (oszlopok hozzáadása) |
| V26 | `V26__trades.sql` | CREATE | `trade` |
| V27 | `V27__sync_log.sql` | CREATE | `sync_log` |
| V28 | `V28__branch_status.sql` | CREATE | `branch_status` |
| V29 | `V29__backup.sql` | CREATE | `backup_record` |
| V30 | `V30__license.sql` | CREATE | `license` |
| V31 | `V31__print_templates.sql` | CREATE | `print_template` |
| V32 | `V32__rate_history.sql` | CREATE | `rate_history` |
| V33 | `V33__inventory_movement_log.sql` | ALTER | `inventory_movement` (oszlopok hozzáadása) |
| V34 | `V34__scheduled_tasks.sql` | CREATE | `scheduled_task` |
| V35 | `V35__rounding_rules.sql` | CREATE | `rounding_rule` |
| V36 | `V36__aml.sql` | CREATE | `aml_report`, `aml_threshold` |
| V37 | `V37__cash_register.sql` | CREATE | `cash_register_event` |
| V38 | `V38__led_display_config.sql` | CREATE | `led_display_config` |
| V39 | `V39__scanned_documents.sql` | CREATE | `scanned_document` |
| V40 | `V40__ftp_sync.sql` | CREATE | `ftp_sync_log` |
| V41 | `V41__translations.sql` | CREATE | `translation` |

## Összesítés

- **CREATE TABLE:** ~75 tábla
- **ALTER TABLE:** `company`, `audit_log`, `inventory_movement`
- **JPA-managed táblák (nem Flyway):** `company`, `branch`, `notification`, `organization`, `own_company`, `reservation`, `role`, `system_parameter`, `workstation`, stb.
- **Alap séma:** JPA `hibernate.ddl-auto` kezeli (199 @Entity → ~146+ tábla)

## Szintaktikai Ellenőrzés Eredménye

✅ Minden SQL fájl szintaktikailag helyes  
✅ Nincs duplikált táblanév a CREATE TABLE-ök között  
✅ A foreign key referenciák helyes táblanevekre mutatnak  
⚠️ **Megjegyzés:** Nincs explicit V1 migráció — a `company` és `branch` táblák JPA auto-DDL révén jönnek létre, a Flyway `baseline-on-migrate=true` beállítással kezeli ezt.
