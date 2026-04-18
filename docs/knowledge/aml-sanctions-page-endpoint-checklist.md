---
type: compliance-checklist
scope: aml-sanctions
version: 2026-04-09
format: checklist-matrix
description: "AML and sanctions obligations checklist by frontend page/route and backend endpoint"
---

# AML / Sanctions Page And Endpoint Checklist

> Cel: oldalankenti es backend endpointonkenti checklist a repo tenyleges feluleteihez es API-jaihoz kotve.

---

## S1 FRONTEND OLDALAK / ROUTE-OK

| Route / page | File | Checklist |
|--------------|------|-----------|
| `/transactions/new` | `frontend-react/src/pages/transactions/TransactionPage.tsx` | identification threshold jelzes, customer panel bekotese, AML warning UI, fee/rate/source fields, block-on-fail |
| `/transactions/cashier` | `frontend-react/src/pages/transactions/CashierTransactionPage.tsx` | `amlResultRef` enforced, submit block, supervisor path only where policy engedi |
| `/transactions/conversion` | `frontend-react/src/pages/transactions/ConversionPage.tsx` | conversion CDD parity, linked transaction aggregation, conversion receipt policy, sanctions/PEP check path |
| `/transactions/:id/storno` | `frontend-react/src/pages/transactions/StornoPage.tsx` | reversal audit, AML accumulation reversal, no silent hard delete |
| `/customers` | `frontend-react/src/pages/customers/CustomerListPage.tsx` | role-based search, no overbroad result exposure, audit search access if needed |
| `/customers/new` | `frontend-react/src/pages/customers/CustomerCreatePage.tsx` | minimal data collection, legal basis-aligned fielding, document validation |
| `/customers/:id` | `frontend-react/src/pages/customers/CustomerDetailPage.tsx` | masked display where needed, document copies retention label, AML/PEP visibility by role |
| `/blacklist` | `frontend-react/src/pages/blacklist/BlacklistPage.tsx` | sanctions/internal prohibition source tagging, import audit, distinction from JWT blacklist |
| `/pep` | `frontend-react/src/pages/pep/PepPage.tsx` | PEP category, review due date, EDD requirements, approval-limit metadata |
| `/suspicious-reports` | `frontend-react/src/pages/suspicious/SuspiciousReportPage.tsx` | draft/review/submit states, no disclosure to frontline roles, report evidence attachment path |
| `/anonymous-reports` | `frontend-react/src/pages/reports/AnonymousReportPage.tsx` | whistleblower confidentiality, assignment audit, restricted resolution actions |
| `/reports/mnb` | `frontend-react/src/pages/reports/MnbReportPage.tsx` | regulatory export provenance, generated-at / generated-by metadata |
| `/cashier` | `frontend-react/src/pages/CashierMainMenu.tsx` | AML-critical routes visible only to authorized roles, no bypass path to direct commit |

### Frontend kotelezo ellenorzo pontok

- van-e role-based visibility?
- van-e AML blokkolas backend hivas utan?
- van-e egyertelmu user feedback refusal / escalation eseten?
- logolodik-e a supervisor override?
- elkulonul-e a `PEP`, `sanctions`, `blacklist`, `suspicious report` fogalom?
- latszik-e a retention / legal-basis / privacy notice, ahol kell?

---

## S2 BACKEND AML / SANCTIONS KOZPONTI ENDPOINTOK

| Endpoint | File | Checklist |
|----------|------|-----------|
| `POST /api/v1/aml/check` | `backend/.../AmlController.java` | authz, full request audit, sanctions-first execution, deterministic result code |
| `GET /api/v1/aml/customer-risk/{customerId}` | `AmlController.java` | only privileged access, customer scoping, no cross-tenant leakage |
| `POST /api/v1/aml/report` | `AmlController.java` | report immutability, restricted submit roles, evidence retention |
| `GET /api/v1/aml/pending` | `AmlController.java` | queue visibility by role/company, stale item handling |
| `GET /api/v1/aml/overdue` | `AmlController.java` | SLA / deadline alerting, no suppressed overdue states |
| `GET /api/v1/aml/summary` | `AmlController.java` | aggregate only, no unnecessary personal data |
| `GET /api/v1/aml/check-all-thresholds` | `AmlController.java` | threshold rules versioned, frontend-visible explanation codes |
| `GET /api/v1/aml/structuring-check/{customerId}` | `AmlController.java` | linked transaction window, tenant-safe aggregation, audit of result |
| `POST /api/v1/sanctions/screen` | `SanctionScreeningController.java` | authenticated use only, source list version, exact-match / fuzzy policy trace |
| `GET /api/v1/sanctions/list` | `SanctionScreeningController.java` | restricted read, list provenance, update timestamp |
| `POST /api/v1/sanctions/import` | `SanctionScreeningController.java` | file validation, import audit, source tagging, rollback on failure |
| `GET /api/v1/sanctions/status` | `SanctionScreeningController.java` | current list health, last import, rule version |
| `GET /api/v1/customer-control/{id}/restrictions` | `CustomerControlController.java` | access scoping, legal basis visibility |
| `POST /api/v1/customer-control/{id}/restrict` | `CustomerControlController.java` | reason required, actor required, expiry/review date where relevant |
| `GET /api/v1/customer-control/{id}/annual-total` | `CustomerControlController.java` | correct aggregate basis, company filter |
| `GET /api/v1/customer-control/{id}/screening-log` | `CustomerControlController.java` | immutable timeline, actor and timestamp audit |
| `GET/POST /api/v1/blacklist/*` | `BlacklistController.java` | list provenance, distinction from sanctions screening, import audit |

---

## S3 TRANZAKCIOS ENDPOINTOK, AHOL AML GATE KOTELEZO

| Endpoint | Service path | Checklist |
|----------|--------------|-----------|
| `POST /api/v1/transactions/buy` | `TransactionService.performAmlCheck()` | threshold CDD, sanctions screen, refusal path, receipt blocked on fail |
| `POST /api/v1/transactions/sell` | `TransactionService.performAmlCheck()` | same as above plus source-of-funds rules where applicable |
| `POST /api/v1/transactions/conversion` | `TransactionConversionService -> helper.performAmlCheck()` | conversion-specific AML parity, linked-transaction logic |
| `POST /api/v1/western-union/send` | `WesternUnionService.performAmlCheck()` | partner-specific compliance + AML gate |
| `POST /api/v1/western-union/receive` | `WesternUnionService.performAmlCheck()` | inbound screening, document checks, audit |
| `POST /api/v1/western-union/ic-in` | `WesternUnionController.java` | verify whether AML gate is same strength as send/receive |
| `POST /api/v1/western-union/ic-out` | `WesternUnionController.java` | verify partner + AML parity |
| `POST /api/v1/transactions/reversal` | `TransactionReversalService -> amlService.reverseAccumulation()` | no forward AML gate, but accumulation reversal + audit mandatory |

---

## S4 HIANYZASRA / REVIEW-RA JELOLT TERULETEK

1. `ConversionPage` frontendrol tovabbi ellenorzes kell, hogy a buy/sell oldalhoz azonos erossegu AML gate van-e bekotve.
2. `BlacklistController` belso tiltólista-e, vagy tenyleges tranzakcios blokkolasra kotott lista; jelen allas szerint a server-side AML gate elsodlegesen a sanctions service-re tamaszkodik.
3. `anonymous-reports` es `suspicious-reports` kozt workflow-es adatvedelmi overlap lehet, ezt kulon policy-vel kell szetvalasztani.
4. Multi-tenant szures validalasa kulon kotelezo minden AML/customer-control endpointon.

---

## S5 MINIMUM TESZTCSOMAG

### Frontend

- threshold atlepeskor kotelezo azonositasi UI jelenik meg
- szankcios vagy AML blokk eseten a submit disabled / refused
- PEP adat csak jogosult szerepnek latszik
- suspicious report oldalon a confidential mezok nem latszanak altalanos usernek

### Backend

- `/transactions/buy|sell|conversion` nem hajtodik vegre, ha AML `blocked`
- `/sanctions/import` hibas fajllal auditoltan elbukik
- `/customer-control/{id}/restrict` indok nelkul `400` vagy validacios hiba
- `/aml/report` csak jogosult szerepnek engedelyezett

### Audit

- minden talalatnak van `who`, `when`, `rule_version`, `decision`, `case_id`
- linked transaction detection visszakeresheto
- reversal eseten AML accumulation visszaallitas nyoma megmarad
