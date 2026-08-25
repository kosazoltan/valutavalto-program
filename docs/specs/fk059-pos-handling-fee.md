# FK-059 — POS handling-fee daily report contract

Status: APPROVED

Scope: backend and central React renderer (`frontend-react`)

## Goal

Provide a read-only daily POS handling-fee report for one branch or all eligible
branches in the authenticated company. The report includes only completed card
sales and exposes JSON, CSV, and the `/reports/pos-handling-fee` page.

## Non-goals

- Introducing code-level prohibition of card purchases (`CARD + BUY`).
- Modifying the cashier client's OTP terminal integration.
- Addressing cash handling-fee ledger anomalies.
- Activating or deleting `HandlingFeeDecadeService`.
- Adding a `payment_method` database check constraint.
- Modifying bank receipt transfers.
- Extending `sumCardSalesByCurrencyAndBranchAndDate` for the all-office view.
- Involving data belonging to another company.

No migration, version bump, OpenAPI regeneration, deploy, release, merge, or push
is part of this change.

## Functional acceptance

### FR-1 — Branch daily summary

Given two `CARD + SELL + COMPLETED` transactions on 2026-07-01 in one branch,
each with HUF 36,500 net and HUF 1,500 fee, when the JSON endpoint is queried for
that branch and day, then it returns one row with `netAmount=73000` and
`feeAmount=3000`.

### FR-2 — All-office additive summary

Given eligible branches A and B in the authenticated company with daily net/fee
amounts of 10,000/500 and 20,000/800, when the endpoint is queried without
`branchId`, then it returns a company-scoped row with `netAmount=30000` and
`feeAmount=1300`.

### FR-3 — Sales only

Given a completed `CARD + BUY` transaction with a non-zero fee, when either
report scope is queried, then the transaction contributes to neither net nor fee.

### FR-4 — Vault-counterparty exclusion

Given a `VAULT_COUNTERPARTY` branch with a completed card sale, when the
all-office report is queried, then that branch contributes to neither net nor
fee. The query must preserve the canonical null-safe clause:
`LEFT JOIN b.branchType bt ... AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY')`.
Entity-created test data must not attempt an impossible null `branchType`.

### FR-5 — Page and navigation

Given a user with one of the allowed report roles, when the user opens Reports
and selects “Kezelési díj — POS”, then `/reports/pos-handling-fee` displays date
filters, a branch selector including “— Minden iroda —”, and a query button.

### FR-6 — Daily table

Given a selected date range and branch scope, when the query is submitted, then the
table shows one row per (day, Banki kód, Pénztárszám) combination with columns Dátum,
Banki kód, Pénztárszám, POS nettó, and POS KK. In all-office scope a single day
therefore yields one row per contributing office; the period summary cards and the
table footer keep summing every row, so the totals are unchanged. A branch with a
blank bank code renders an empty Banki kód cell; Pénztárszám (`branch.code`) is always
populated. It has no Vétel column.

### FR-7 — CSV parity

Given either a branch or all-office result, when CSV export is requested, then
the CSV request uses exactly the same `startDate`, `endDate`, and optional
`branchId` as the displayed query, and the exported rows represent that view.

### FR-8 — RBAC and denied-access audit

Given a `PENZTAR` or `CASHIER` user, when either report operation is requested,
then access is denied with `VV-AUTH-005`, an `ACCESS_DENIED` audit record is
written, and no report repository query runs.

## Non-functional requirements

| ID    | Requirement  | Measurable criterion                                                                   |
| ----- | ------------ | -------------------------------------------------------------------------------------- |
| NFR-1 | Performance  | 31-day branch p95 < 500 ms; 65-branch company p95 < 1000 ms                            |
| NFR-2 | Localization | Hungarian labels and `hu-HU` date formatting                                           |
| NFR-3 | HUF display  | Stored amounts displayed as whole forints                                              |
| NFR-4 | Table style  | `.data-grid` class with the established alternating-row presentation                   |
| NFR-5 | Isolation    | Branch access is IDOR-safe; all-office company ID comes only from the security context |

## RBAC matrix

| Role                   | Read JSON | Export CSV |
| ---------------------- | --------- | ---------- |
| `ROLE_FOERTEKTAR`      | yes       | yes        |
| `ROLE_UGYVEZETO`       | yes       | yes        |
| `ROLE_IRODAVEZETO`     | yes       | yes        |
| `ROLE_BELSO_ELLENOR`   | yes       | yes        |
| `ROLE_TERULETI_VEZETO` | yes       | yes        |
| `ROLE_PENZUGYI_VEZETO` | yes       | yes        |
| Other or no authority  | no        | no         |

## Data and calculation contract

- Included rows are exactly `paymentMethod=CARD`, `transactionType=SELL`, and
  `status=COMPLETED` in the inclusive requested date range.
- Daily net is
  `SUM(hufAmount - COALESCE(handlingFee,0) - COALESCE(roundingAmount,0))`.
- Daily fee is `SUM(COALESCE(handlingFee,0))`.
- Zero-fee sales remain included in net turnover.
- Null payment method is legacy cash and is excluded.
- Reversed and out-of-range transactions are excluded.
- Branch scope validates the branch through `BranchService.findById` before the
  query. All-office scope obtains company ID from `SecurityUtils` and includes
  only active, non-vault, non-`VAULT_COUNTERPARTY` branches.
- JSON fields are `startDate`, `endDate`, `totalNetAmount`, `totalFeeAmount`, and
  daily `rows` containing `date`, `bankCode` (Banki kód, empty string when blank),
  `code` (Pénztárszám, always populated), `netAmount`, and `feeAmount`.
- CSV columns are `Dátum`, `Banki kód`, `Pénztárszám`, `POS nettó (Ft)`, `POS KK (Ft)`,
  followed by an `Összesen` row (with the two identity columns empty), UTF-8 BOM, and
  filename `kezelesi-dij-pos-napi-<start>-<end>.csv`.

## Approved design decisions

1. Add a dedicated vertical matching the FK-053 report architecture; do not
   refactor the cash report.
2. Use the net formula stated above because `hufAmount` is rounded payable HUF.
3. Do not filter on positive handling fee.
4. Pin `SELL` in the query and group by transaction date and branch identity
   (`bankCode`, `code`) so all-office scope yields one row per office per day
   (FK-095; supersedes the earlier date-only grouping).
5. Match `CARD` strictly; do not treat null payment method as card.
6. Enforce the six-role allowlist in the service, fail closed, audit denied
   access with entity type `POS_HANDLING_FEE_DAILY_SUMMARY`.
7. Audit CSV downloads best-effort with action `EXPORT` and event type
   `POS_HANDLING_FEE_DAILY_SUMMARY_EXPORT`; audit failure must not block download.
8. Use the DTO field names specified in the data contract.
9. Keep JSON/CSV parameter parity and the specified CSV shape.
10. Use the `reports.posHandlingFee` i18n namespace, `hu-HU` dates, and rounded
    HUF display.
11. Add no migration, version bump, or generated OpenAPI change.

## Error and audit contract

- `startDate > endDate` produces the established validation exception before any
  branch or repository call.
- Cross-tenant or missing `branchId` propagates the indistinguishable
  `ResourceNotFoundException` from `BranchService` and performs no query.
- Missing current company context fails through the established security utility.
- Unauthorized access writes `ACCESS_DENIED` in a new transaction with error code
  `VV-AUTH-005` and performs no repository operation.
- CSV export appends a hash-chained `EXPORT` audit event after report generation;
  audit append failure is logged but does not fail the download.

## EARS acceptance

- WHEN an allowed user requests a valid branch range, THE SYSTEM SHALL return
  daily completed card-sale net and fee aggregates for that branch.
- WHEN an allowed user omits `branchId`, THE SYSTEM SHALL aggregate only eligible
  branches in the authenticated company.
- WHILE aggregating all offices, THE SYSTEM SHALL exclude inactive, vault, and
  `VAULT_COUNTERPARTY` branches using the canonical null-safe join clause.
- IF a row is not `CARD + SELL + COMPLETED`, THE SYSTEM SHALL exclude it.
- IF handling fee is zero or nullable, THE SYSTEM SHALL retain eligible net
  turnover and treat the fee as zero.
- WHEN CSV is exported, THE SYSTEM SHALL use the current JSON filter parameters,
  emit the specified BOM/columns/total row, and attempt an `EXPORT` audit event.
- IF the caller lacks an allowed role, THE SYSTEM SHALL fail closed, audit the
  denial, and perform no report query.

## Explicit prohibitions

Do not implement `CARD + BUY` write-side enforcement; modify POS terminal
integration; extend `sumCardSalesByCurrencyAndBranchAndDate`; modify
`HandlingFeeDecadeService`; add a payment-method constraint; or modify
`penztar-client`.
