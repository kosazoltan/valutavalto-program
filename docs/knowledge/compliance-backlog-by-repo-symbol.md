---
type: implementation-backlog
scope: compliance
version: 2026-04-09
format: repo-symbol-matrix
description: "Concrete compliance backlog mapped to repo symbols: frontend files, backend services/controllers, DB fields and missing tests"
---

# Compliance Backlog By Repo Symbol

> Cel: a mar felirt jogi, GDPR, AML/szankcios, ceges es adozasi baseline-bol konkret fejlesztesi backlog keszitese.
> Szabaly: csak olyan tetel szerepeljen, amelyre a repo-ban talalhato kod vagy hiany kozvetlen bizonyitekot ad.

---

## Prioritas skala

- `P0` = magas kockazatu compliance hiany vagy tenant/data leak veszely
- `P1` = erosen ajanlott parity / audit / legal-flow hiany
- `P2` = masodik koros, de konkretan indokolt compliance erosites

---

## S1 Osszefoglalo

| Priority | Count | Fo tema |
|----------|-------|---------|
| `P0` | 8 | AML audit, multi-tenant vedelmek, receipt/privacy access, szankcios naplozas |
| `P1` | 8 | frontend PEP/source-of-funds parity, branch capability, GDPR controller/processor model, fee/tax/rate model |
| `P2` | 5 | privacy request workflow, import audit UI, evidence attachment, accounting export reszletek |

---

## S2 Konkrét backlog

| ID | Prio | Legal driver | Frontend file / symbol | Backend file / symbol | DB field / migration gap | Missing test |
|----|------|--------------|------------------------|-----------------------|--------------------------|--------------|
| `CB-001` | `P0` | `Pmt. 300k`, receipt parity | `frontend-react/src/pages/transactions/TransactionPage.tsx` -> `handleSubmit` | `backend/.../TransactionService.java` already stores `sourceOfFunds` / `customerIsPep` | No new field. Wire existing `transaction.source_of_funds` and `transaction.customer_is_pep` end-to-end | Extend `frontend-react/src/pages/transactions/TransactionPage.test.tsx` to assert BUY/SELL payload includes `sourceOfFunds` and `customerIsPep` when required |
| `CB-002` | `P0` | `Pmt. 300k`, cashier parity | `frontend-react/src/pages/transactions/CashierTransactionPage.tsx` inline `BuyRequest` / `SellRequest` | `backend/.../TransactionService.java` already ready | No new field. Wire existing transaction columns to cashier flow | Create/extend cashier transaction page test to assert payload and block/unblock behavior |
| `CB-003` | `P1` | receipt legal block parity | `frontend-react/src/types/receipt.ts` -> `PrintReceiptData`; `frontend-react/src/components/electron/ReceiptPreviewModal.tsx` | `backend/.../ReceiptGeneratorService.java`, `EscPosReceiptService.java` | No new DB field if only print DTO parity. Reuse existing `transaction.source_of_funds` / `transaction.customer_is_pep` | Extend `ReceiptGeneratorServiceTest` and add frontend preview test for PEP + source-of-funds sections |
| `CB-004` | `P1` | conversion AML parity | `frontend-react/src/pages/transactions/ConversionPage.tsx` -> `handleSubmit` | `backend/.../TransactionConversionService.java`, `TransactionOperationHelper.java` | No proven new field yet; likely reuse existing transaction AML fields | Extend `TransactionConversionServiceTest`; add frontend conversion flow test for AML gate before submit |
| `CB-005` | `P0` | sanctions auditability | no frontend blocker; optionally show branch-aware screening result later | `backend/.../controller/SanctionScreeningController.java` -> `screenCustomer(...)`; `backend/.../service/AmlService.java` -> `checkTransaction(...)`; `backend/.../service/SanctionScreeningService.java` -> `logScreening(...)` | Add to `sanction_screening_log`: `company_id`, `transaction_id` nullable, maybe `rule_version` / `source_list_version`; existing `branch_code` is present but not filled | Extend `backend/src/test/java/.../controller/SanctionControllerTest.java`; add service test for transaction-triggered sanction log with branch/worker/company populated |
| `CB-006` | `P0` | multi-tenant isolation | no frontend change | `backend/.../service/ReceiptGeneratorService.java` -> `generatePdfForTransaction`, `generateEscPosForTransaction`; `backend/.../service/ReceiptService.java` -> `getById`, `print` | No new field required; enforce current `company_id` on access path | Add new service tests denying cross-company receipt/transaction access; extend `ReceiptGeneratorServiceTest` or create dedicated access-scope tests |
| `CB-007` | `P0` | multi-tenant branch safety | no frontend change | `backend/.../service/WesternUnionService.java` -> `findBranch(...)`; use `verifyBranchOwnership(...)` consistently | No DB field if validation only | Extend `backend/src/test/java/.../service/WesternUnionServiceTest.java` with foreign-branch rejection case |
| `CB-008` | `P0` | multi-tenant customer restriction safety | frontend later may benefit from safer screening history UI | `backend/.../entity/CustomerRestriction.java`; `backend/.../service/CustomerControlService.java` | Add `customer_restriction.company_id` FK/index; update repository queries to company-scoped lookups | Create/extend `CustomerControlService` tests for cross-company restriction isolation |
| `CB-009` | `P0` | blacklist tenant isolation | `frontend-react/src/pages/blacklist/BlacklistPage.tsx` import/create flows depend on safe backend scoping | `backend/.../service/BlacklistService.java` -> `createPerson`, `createCompany`, `updatePerson`, `updateCompany`, delete/import methods | Ensure persisted `prohibited_person.company_id` / `prohibited_company.company_id` is set and validated on update/delete; if already in DB, code wiring missing | Add `BlacklistService` tests for company assignment on create/import and forbidden cross-tenant update/delete |
| `CB-010` | `P1` | GDPR role model | no current UI surface | likely new backend module; touch `backend/.../entity/Customer.java`, `Company.java`, maybe `Transaction.java` | New fields/entities missing: `processing_role_context`, `legal_basis`, `retention_policy_id`, `privacy_notice_version`; likely new privacy tables + Flyway migration | New tests for privacy metadata persistence and access control; no existing direct test file found |
| `CB-011` | `P1` | consent / VIP / marketing compliance | `frontend-react/src/pages/customers/CustomerCreatePage.tsx` -> currently only `isVip` flag in form data, no visible consent capture | backend currently only `Customer.isVip` exists | New entity/table needed: `consent_record` with `customer_id`, `consent_type`, `granted_at`, `withdrawn_at`, `channel`, `policy_version` | Extend/create `CustomerCreatePage` test; create backend consent service/entity tests |
| `CB-012` | `P2` | data subject rights | no dedicated page/route found in frontend | no backend `data_export_request` / `data_erasure_request` / privacy workflow module found | New tables/entities needed for privacy request workflow, status, SLA, export artifacts | New frontend route test and backend workflow tests; no existing target file found |
| `CB-013` | `P1` | branch capability / public branch feed parity | likely future admin branch page(s), current public data only | `backend/.../entity/Branch.java` | Add explicit branch capability fields or relation: e.g. `supports_wu`, `supports_moneygram`, `supports_card_payment`, `quote_enabled`; current feed evidence supports this | Add branch mapping / export tests; no existing dedicated branch capability tests found |
| `CB-014` | `P1` | quote validity / public 100k+ quote rule | future quote UI; current customer/public form external | backend reservation/quote flow around `CreateReservationDto` and `ReservationService` | New policy field missing: `quote_validity_minutes` or equivalent branch/system parameter; current `expiresAt` is client-driven | Add reservation service test validating policy-derived expiration and rejection of out-of-policy values |
| `CB-015` | `P1` | accounting FX parity | no frontend dependency yet beyond reports | `backend/.../entity/Transaction.java` currently only `exchangeRate`; related export/report services | Add transaction/accounting fields: `accounting_rate`, `accounting_rate_source`, optional `exchange_rate_id` FK; current model cannot separate customer rate vs book rate | Add accounting export test; no `NavClosingServiceTest` currently present |
| `CB-016` | `P1` | fee tax classification | no frontend tax visibility yet | `backend/.../entity/Transaction.java`; `backend/.../service/NavClosingService.java` hardcodes `VAT_RATE = 0.27` | Add fields such as `handling_fee_tax_code`, `handling_fee_vat_rate`, `vat_exemption_basis`; remove hardcoded single-rate assumption | Create `backend/src/test/java/hu/puzzleir/valuta/service/NavClosingServiceTest.java` |
| `CB-017` | `P2` | accounting FX difference audit | no frontend dependency yet | `backend/.../entity/DailySubledgerSnapshot.java` and export services | Add fields/entity for `book_value_huf`, `settlement_value_huf`, `fx_difference_huf` or equivalent export line model | Create treasury/accounting export tests validating FX difference output |
| `CB-018` | `P0` | AML audit completeness | no frontend dependency yet | `backend/.../service/TransactionService.java` currently builds `Transaction` without setting `amlSuspicious` / `amlAnnualLimitReached`; `AmlService`; `CustomerScreeningLog` write path absent | No new transaction fields needed for AML booleans; likely new log fields/table write path needed for `CustomerScreeningLog` | Extend `TransactionServiceIdentificationTest`, `TransactionFlowTest`, and add tests for `CustomerScreeningLog` persistence |
| `CB-019` | `P2` | suspicious report evidence path | `frontend-react/src/pages/suspicious/SuspiciousReportPage.tsx` -> `CreateReportForm` | backend report upload endpoint not evidenced in current review | Likely new attachment table / blob metadata if product requires evidence files | Add frontend attachment test and backend multipart endpoint tests once API exists |
| `CB-020` | `P2` | anonymous report confidentiality / assignment integrity | `frontend-react/src/pages/reports/AnonymousReportPage.tsx` | `backend/.../service/AnonymousReportService.java` -> `assign(...)` | No new field required unless audit enrichment added; current code should validate assigned worker belongs to same company | Add service test rejecting cross-company assignment and frontend role/confidentiality test |
| `CB-021` | `P2` | MNB report provenance | `frontend-react/src/pages/reports/MnbReportPage.tsx` | backend report DTO/service path not yet carrying provenance fields in reviewed evidence | Add report metadata fields if absent: `generated_at`, `generated_by`, `source_snapshot_id` | Add `MnbReportPage` UI test and backend DTO/service serialization test |
| `CB-022` | `P2` | customer detail minimization | `frontend-react/src/pages/customers/CustomerDetailPage.tsx` | backend may also need field-level masking DTO variant | No DB field required; use role-aware DTO or masking policy | Add role-based UI test for masked document number / PEP visibility |

---

## S3 Legjobb elso sprint

### Sprint 1 - highest risk, lowest ambiguity

1. `CB-001`
2. `CB-002`
3. `CB-005`
4. `CB-006`
5. `CB-007`
6. `CB-008`
7. `CB-009`
8. `CB-018`

Ez a csomag:

- a legfontosabb AML/legal parity hianyokat zarja,
- csokkenti a cross-tenant adatszivargas kockazatat,
- es a meglvo entity-k jo reszet uj schema nelkul vagy kis schema-bovitessel rendbe teszi.

---

## S4 Schema-first backlog tetelcsoport

Ezeknel eloszor Flyway / entity / repository valtozas kell:

- `CB-008` -> `customer_restriction.company_id`
- `CB-010` -> privacy metadata model
- `CB-011` -> `consent_record`
- `CB-013` -> branch capability fields/relation
- `CB-014` -> quote validity policy field
- `CB-015` -> accounting rate fields
- `CB-016` -> fee tax classification fields
- `CB-017` -> FX difference output model

---

## S5 Tesztfajl-szintu ajanlas

### Levo tesztet boviteni

- `frontend-react/src/pages/transactions/TransactionPage.test.tsx`
- `backend/src/test/java/hu/puzzleir/valuta/controller/SanctionControllerTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/ReceiptGeneratorServiceTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/WesternUnionServiceTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/TransactionConversionServiceTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/TransactionServiceIdentificationTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/integration/TransactionFlowTest.java`

### Uj tesztet letrehozni

- `backend/src/test/java/hu/puzzleir/valuta/service/NavClosingServiceTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/BlacklistServiceTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/CustomerControlServiceTest.java`
- `frontend-react/src/pages/transactions/CashierTransactionPage.test.tsx`
- `frontend-react/src/components/electron/ReceiptPreviewModal.test.tsx`
- privacy/consent workflowhoz uj backend + frontend tesztek

---

## S6 Megjegyzes

- A `Transaction` entity-ben a `rounding_amount`, `source_of_funds`, `customer_is_pep`, `aml_suspicious`, `aml_annual_limit_reached` mezok mar leteznek. Ezeknel a gond sokszor nem a schema hianya, hanem a bekotes, kitoltes vagy teszt hianya.
- A `bestchange.hu` / `excbestchange.hu` publikus branch-feedbol fakado branch capability baseline schema-bovitest indokol, de a tenyleges belso szervezeti scope-ot kulon validalni kell.
