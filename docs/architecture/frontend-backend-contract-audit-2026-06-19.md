# Frontend-backend contract audit - 2026-06-19

Status: IN PROGRESS - NAV discrepancy frontend contract approval required

## Scope

This audit checks whether high-confidence frontend REST calls have matching
Spring `@RestController` endpoints, and whether backend endpoints without a
literal frontend caller are either intentionally backend-only/integration-only
or require a targeted frontend follow-up.

The frontend side is production-only: unit tests, Playwright specs, Storybook
stories and test setup files are excluded so mocked REST calls cannot prove a
real UI/backend binding.

The contract audit now has two backend-reference levels:

- literal frontend REST calls: direct `api.get/post/...`, `fetch`, Electron and
  resolved template calls in production frontend/client source;
- production UI/app referenced REST calls: direct production calls plus API
  wrapper method calls only when the specific `wrapper.method` is referenced by
  production UI/app code outside `frontend-react/src/services/api`.

This distinction prevents an unused API wrapper method from proving that a
backend function is actually surfaced in the application.

Route/page coverage is checked separately with:

```powershell
python scripts/dev-tools/frontend-route-api-audit.py
```

That tool parses routed lazy pages from `frontend-react/src/App.tsx` and follows
local page imports recursively so wrapper/tab pages do not look like false
frontend-only screens.

Frontend API-wrapper production usage is checked separately with:

```powershell
python scripts/dev-tools/frontend-api-wrapper-usage-audit.py
```

That tool lists exported `*Api` wrappers under `frontend-react/src/services/api`
which are not referenced by production UI/app code outside the API service
folder. Test/spec/story/setup files are excluded, so a mocked test cannot prove
real UI usage.

Regression coverage for the audit helpers:

```powershell
python scripts/dev-tools/frontend-audit-self-test.py
```

Authoritative command:

```powershell
python scripts/dev-tools/frontend-backend-contract-audit.py --show-unreferenced --show-unreferenced-summary --show-ui-unreferenced --show-ui-unreferenced-summary --limit 120
```

Latest verified result:

```text
backend endpoints: 991
frontend literal REST calls: 1030
frontend production UI/app referenced REST calls: 937
frontend unresolved dynamic calls: 0
unmatched frontend REST calls: 0
backend endpoints not referenced by literal calls: 46
backend endpoints not referenced by production UI/app calls: 117
```

Route/page audit result:

```text
routed lazy pages: 160
routes without direct API/service signal: 0
known shell/local exceptions: 9
```

API-wrapper production usage audit result:

```text
exported Api wrappers: 119
wrappers referenced by production UI/app code: 118
wrappers without production UI/app reference: 0
known infrastructure/legacy exceptions: 1
```

API-wrapper method-level inventory result:

```text
exported Api wrapper methods: 668
methods referenced by production UI/app code: 520
methods without direct production UI/app reference: 148
known infrastructure/legacy method exceptions: 0
```

This method-level inventory remains informational by itself, but it is now also
fed into the contract audit's production UI/app reference level. That stricter
view is the current evidence source for "backend endpoint is wrapped but not
proven used by UI/app" follow-up work.

## Implemented fixes in this audit slice

- Mobile work area exposes safe read-only/informational integration status for
  POS, Western Union, NAV closings and cash-register diagnostics.
- Diagnostics UI now uses `GET /diagnostics/health`, and renderer error reports
  post to `POST /diagnostics/error-report` with legacy `/error-report` fallback.
- NAV report UI now uses `GET /nav/closings`,
  `GET /nav/closings/{id}/summary`,
  `GET /nav/closings/ptgszlah/monthly`, and
  `GET /nav/closings/ptgszlah/custom`.
- The audit script classification was corrected so NAV discrepancy endpoints are
  no longer hidden under generic device integration.
- The audit script now excludes frontend test/spec/story/setup files from the
  production REST-call inventory.
- The stale E-B8 App route comment was updated after verifying that
  `BankOrderPage` is a backend-integrated implementation, not a skeleton.
- Added route/page audit tooling. It found no routed business page without a
  production API/service signal after recursive local child inspection. The
  remaining exceptions are navigation shells or the local Electron customer
  display route.
- Added stdlib self-tests for the audit helpers. They verify that frontend
  test/spec files are excluded from production REST inventory, NAV discrepancy
  endpoints keep the financial-contract-required classification, and route
  audit follows local child page imports.
- Added frontend API-wrapper usage audit tooling and fixed the proven production
  gaps it found:
  `centralReceivedDataApi` is now used by the routed central received-data page,
  `currencyGroupApi` by the currency group CRUD page, `competitorApi` by the
  competitor CRUD page, `monthlyClosingApi` by the monthly closing list, and
  `reservationsApi` by the reservation list/create/cancel/fulfill/receipt flow.
- Extended the audit helper self-test so API-wrapper references from test-only
  files do not count as production UI usage.
- Extended `frontend-backend-contract-audit.py` so it separates wrapper-only
  literal calls from REST calls reachable through a production UI/app referenced
  API wrapper method. The self-test now proves that wrapper-only calls do not
  count as production UI/app backend coverage.
- Hardened `frontend-backend-contract-audit.py` so static and dynamic sibling
  routes do not create false backend coverage; for example `GET /users/{id}`
  no longer proves `GET /users/me`, and `GET /users/me` no longer proves
  `GET /users/{id}`. The self-test covers this matching rule.
- Optimized the new production UI/app reference scan by caching frontend source
  text once per audit run instead of re-reading files per API method.
- Classified the backward-compatible audit endpoints and the alternate admin
  branch update path as backend-only/compatibility surface instead of open UI
  gaps.
- Wired the routed anonymous report details action to
  `GET /anonymous-reports/{id}`. The list row no longer reuses only the summary
  object when opening the details panel.
- Classified the legacy top-level authorized representative create endpoint and
  the representative transaction-log helper as backend-only compatibility
  surface after verifying the routed create page uses the customer-scoped
  register endpoint.
- Wired the bank order list details action to `GET /bank-orders/{id}` so the
  routed bank order page loads the backend detail representation before showing
  the details panel.
- Wired the BankTransactions bank master panel to `POST /banks` and
  `DELETE /banks/{id}` so the existing bank selection master data can be managed
  from the routed treasury bank workflow.
- Classified `GET /branch-groups/active` as an alternate read helper after
  verifying that the routed BranchGroupPage uses `/branch-groups` and
  `/branch-groups/roots` for the management view.
- Wired the TreasuryDashboard stock summary cards to
  `GET /cash-balances/company-totals`, `GET /cash-balances/alerts/low`, and
  `GET /cash-balances/alerts/high`, with mobile render coverage.
- Corrected the frontend `BranchBalanceSummary` contract to the backend
  `CashBalanceService.BranchBalanceSummary` shape and wired CashDesk read-only
  stock summary/detail UI to `GET /cash-balances/summary`,
  `GET /cash-balances/currency/{currencyId}`, and
  `GET /cash-balances/code/{currencyCode}`, with mobile render coverage.
- Wired the routed CashDeskBreak page to
  `GET /cash-desk-breaks/active/{cashDeskId}` so the active break banner uses
  the backend active-break lookup instead of deriving the state only from the
  list response, with mobile render coverage.
- Wired the routed DenominationPage summary to
  `GET /cash-desks/{cashDeskId}/denominations` and
  `GET /cash-desks/{cashDeskId}/denominations/currency/{currencyId}/total` so
  the page shows persisted server-side denomination rows and total beside the
  edited local total, with mobile render coverage.
- Wired the routed DenominationPage master-data read side to
  `GET /denominations`, `GET /denominations/alerts/low-stock`,
  `GET /denominations/code/{currencyCode}`,
  `GET /denominations/summary/{currencyId}`, and
  `GET /denominations/optimal-change` so the page shows denomination master
  counts, low-stock count, code-check count, backend summary and read-only
  optimal-change calculation, with mobile render coverage.
- Wired routed CommissionRatePage editing to `GET /commission-rates/{id}` so
  the edit form opens from the backend detail representation instead of only
  the list row snapshot, with mobile render coverage.
- Wired routed CompetitorPage editing to `GET /competitors/{id}` so the edit
  form opens from the backend detail representation instead of only the list
  row snapshot, with mobile render coverage.
- Wired routed CurrencyGroupPage editing to `GET /currency-groups/{id}` so the
  edit form opens from the backend detail representation instead of only the
  list row snapshot, with mobile render coverage.
- Wired routed HandoverSheetPage details to `GET /handover-sheets/{id}` so the
  list action opens the backend detail representation, with mobile render
  coverage.
- Wired routed ClosingControlPage branch details to
  `GET /closing-control/branch/{id}` so the central closing monitor opens the
  backend branch-level status representation, with mobile render coverage.
- Wired routed MonthlyClosingPage report details to
  `GET /closing/monthly/{branchId}/{yearMonth}` so the monthly closing list
  opens the backend report representation without invoking the state-changing
  monthly close action, with mobile render coverage.
- Wired routed DariusReportPage daily lookup to `GET /darius/by-date` so the
  DARIUS admin view can open the backend daily report representation for a
  chosen date without generating or submitting a report, with mobile render
  coverage.
- Wired routed OrganizationPage to `GET /organizations/active`,
  `GET /organizations/root`, and `GET /organizations/{id}` so the organization
  admin view shows backend active/root counts and opens the edit form from the
  backend detail representation, with mobile render coverage.
- Wired the routed `MnbReportPage` read-only controls to
  `GET /mnb/reports/{id}`, `GET /mnb/reports/daily`,
  `GET /mnb/reports/monthly`, and `GET /mnb/reports/validate`, and corrected
  the frontend MNB DTO/month query contract to match the backend
  `MnbReportController`, with mobile render coverage.
- Wired the routed WorkstationPage to `GET /workstations/active` and
  `GET /workstations/{id}` so the workstation admin view shows backend active
  counts and opens the edit form from the backend detail representation, with
  mobile render coverage.
- Wired the routed OrganizationalSystemParameterPage edit action to
  `GET /organizational-system-parameters/{id}` so organization-specific
  parameter editing opens from the backend detail representation, with mobile
  render coverage.
- Wired the routed PermissionPage module filter to
  `GET /permissions/module/{module}` so permission administration uses the
  backend module-specific read endpoint instead of only filtering the full list
  client-side, with mobile render coverage.
- Wired the routed SystemParameterPage read controls to
  `GET /system-parameters/active`, `GET /system-parameters/category/{category}`,
  `GET /system-parameters/key/{key}`, `GET /system-parameters/value/{key}`, and
  `GET /system-params` so the settings page exposes backend active/managed
  counts, backend category filtering and key/value lookup, with mobile render
  coverage.
- Wired the routed rate-maker CurrencyManagerModal read controls to
  `GET /currencies/search` and `GET /currencies/code/{code}` so the existing
  currency management workflow uses backend search and backend code-detail
  lookup instead of only the full currency list, with rate-maker mobile render
  coverage.
- Wired the routed RateHistoryPage canonical read controls to
  `GET /exchange-rates/code/{currencyCode}`, `GET /exchange-rates/buy-rate`,
  `GET /exchange-rates/sell-rate`, and `GET /exchange-rates/history` so the
  rate history view can verify current backend rates, amount-specific buy/sell
  calculations and canonical rate history, with mobile render coverage.
- Wired the routed ExtendedReportsPage read-only report types to
  `GET /reports/cash-status`, `GET /reports/today-summary`, and
  `GET /reports/currency/{currencyId}` so the existing extended reports view
  can query current cash status, same-day closing summary and currency turnover
  from backend report APIs, with mobile render coverage.
- Wired additional routed ExtendedReportsPage read-only report types to
  `GET /reports-extended/monthly-turnover`,
  `GET /reports-extended/handling-cost`,
  `GET /reports-extended/daily-cash-desk`, and
  `GET /reports-extended/current-cash-desk-status` so the extended report view
  can query monthly turnover, handling-cost, daily cash-desk and current
  cash-desk status reports, with mobile render coverage.
- Wired routed VaultStocktakeDetailPage to `GET /vault-stocktake/{id}/summary`
  so the detail view shows the backend stocktake summary beside the item-derived
  local counts, with mobile render coverage.
- Wired routed ReservationPage to `GET /reservations/reserved-stock` so the
  foglaló workflow shows the branch-level reserved stock summary calculated by
  the backend, with mobile render coverage.
- Wired routed ReceiptPage details to `GET /receipts/{id}` so the bizonylat
  detail modal opens from the backend detail representation instead of only the
  list row snapshot, with mobile render coverage.
- Wired routed CustomerListPage code lookup to
  `GET /customers/code/{customerCode}` so users can run an exact backend
  customer-code lookup beside the existing name/document search, with mobile
  render coverage.
- Wired routed UserPage editing to `GET /users/{id}` so the user administration
  edit form opens from the backend detail representation instead of only the
  list row snapshot, with mobile render coverage.
- Wired routed PermissionPage editing to `GET /permissions/{id}` so permission
  administration edit opens from the backend detail representation instead of
  only the list row snapshot, with mobile render coverage.

## Stricter production UI/app reference follow-up

The stricter audit currently reports 117 backend endpoints without a proven
production UI/app caller. This is a candidate inventory, not 117 confirmed UX
bugs: the list includes backend-only auth/session endpoints, device/integration
commands, legacy compatibility flows and exported helper methods that may be
valid library surface rather than visible screens. This number increased when
static/dynamic sibling route matching was corrected, because previous runs
could count routes such as `GET /users/{id}` and `GET /users/me` as mutual
proof.

Current summary:

```text
ui-candidate/list-or-view        27
ui-candidate/mutation            25
ui-candidate/detail              17
integration-or-device            15
backend-only/legacy-compat       8
workflow-action                  7
backend-only/auth-session        3
backend-only/diagnostics         3
backend-only/admin-maintenance   2
integration-or-callback          2
ui-candidate/financial-contract-required 2
workflow-action/financial-admin  2
backend-only/alternate-admin-api 1
backend-only/alternate-read-api  1
backend-only/legacy-alias        1
ui-candidate/export-download     1
```

The next audit slice should triage the `ui-candidate/*` groups by actual routed
workflow ownership before adding UI. Financial/state-changing endpoints still
need contract-first approval before implementation.

## Remaining backend endpoints without literal frontend caller

### Backend-only or compatibility endpoints

- `POST /auth/refresh` - legacy/session endpoint; frontend intentionally uses
  `POST /auth/refresh-cookie` (`frontend-react/src/services/api/client.ts`).
- `POST /notifications/{id}/mark-read` - legacy alias for canonical
  `PUT /notifications/{id}/read`, which is used by `notificationApi.markAsRead`.
- `POST /daily-closing/execute`,
  `POST /daily-sessions/close-with-validation`,
  `POST /daily-sessions/{sessionId}/close` - legacy/compat closing paths; the
  frontend user flow uses `closing-wizard` and canonical `daily-sessions/close`.
- `POST /cash-balances/init-branch/{branchId}`,
  `POST /cash-balances/init-all-branches` - idempotent admin retrofit endpoints,
  documented in `CashBalanceController` as deploy/maintenance initialization.
- `POST /error-log` - HMAC/operational error-log ingest, not a browser UI call.

### External callback or inbound integration endpoints

- `GET /email/accounts/callback` - OAuth redirect target; reached by provider
  redirect after `/email/accounts/{id}/auth`.
- `POST /sync/events` - inbound sync event receiver requiring
  `Idempotency-Key`; this is a client/sync-engine callback, not a direct UI
  button.

### Device or external integration command endpoints

These endpoints can trigger physical device/payment/WU behavior and should not
be exposed as generic mobile buttons without a separate operational contract:

- `POST /cash-register/open`
- `POST /cash-register/close`
- `POST /cash-register/receipt`
- `POST /cash-register/storno`
- `GET /cash-register/x-report/{branchId}`
- `GET /cash-register/z-report/{branchId}`
- `POST /cash-register/command`
- `POST /monitoring/heartbeat`
- `POST /pos-terminal-stub/authorize`
- `POST /pos-terminal-stub/settlement`
- `POST /pos-terminal-stub/void/{transactionId}`
- `POST /western-union-stub/send`
- `POST /western-union-stub/receive`

### NAV financial follow-up required

The audit found a real frontend gap candidate:

- `POST /nav/closings/validate-amount`
- `POST /nav/closings/{id}/approve-discrepancy`

These are cashier/supervisor financial controls, not external callbacks. The
required contract-first draft is:

```text
docs/specs/nav-closing-discrepancy-frontend-contract.yaml
```

Implementation should start only after that draft is approved, because the UI
would expose discrepancy approval and notification side effects. Current repo
evidence: the contract is waiting for approval (`status: "JÓVÁHAGYÁSRA VÁR"`),
so the next safe step is explicit contract approval, then a targeted `NavReportPage`
implementation with Vitest and Playwright coverage derived from that contract.

The audit also shows two state-changing NAV fiscal actions:

- `POST /nav/closings/daily`
- `POST /nav/closings/{id}/submit`

They remain financial-admin workflow actions and should not be added to the
mobile/desktop UI without explicit role flow and approval evidence.

## Verification

Commands verified after this slice:

```powershell
python -m py_compile scripts/dev-tools/frontend-backend-contract-audit.py
python -m py_compile scripts/dev-tools/frontend-route-api-audit.py
python -m py_compile scripts/dev-tools/frontend-api-wrapper-usage-audit.py
python -m py_compile scripts/dev-tools/frontend-audit-self-test.py
python scripts/dev-tools/frontend-audit-self-test.py
python scripts/dev-tools/frontend-backend-contract-audit.py --show-unreferenced --show-unreferenced-summary --show-ui-unreferenced --show-ui-unreferenced-summary --limit 120
python scripts/dev-tools/frontend-route-api-audit.py
python scripts/dev-tools/frontend-api-wrapper-usage-audit.py
python scripts/dev-tools/frontend-api-method-usage-audit.py
npx.cmd eslint src/App.tsx --max-warnings 9999
npx.cmd vitest run src/pages/cashdesk/CashDeskPage.test.tsx
npx.cmd playwright test e2e/cashdesk-summary.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npx.cmd eslint src/pages/cashdesk/CashDeskPage.tsx src/pages/cashdesk/CashDeskPage.test.tsx
npx.cmd vitest run src/pages/cashdesk/CashDeskBreakPage.test.tsx
npx.cmd playwright test e2e/cashdesk-break-active.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/cashdesk/CashDeskBreakPage.tsx src/pages/cashdesk/CashDeskBreakPage.test.tsx
npx.cmd vitest run src/pages/cashdesk/DenominationPage.test.tsx
npx.cmd playwright test e2e/cashdesk-denominations-summary.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/cashdesk/DenominationPage.tsx src/pages/cashdesk/DenominationPage.test.tsx
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 60
npx.cmd vitest run src/pages/commissions/CommissionRatePage.test.tsx
npx.cmd playwright test e2e/commission-rate-detail.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/commissions/CommissionRatePage.tsx src/pages/commissions/CommissionRatePage.test.tsx e2e/commission-rate-detail.spec.ts
npx.cmd vitest run src/pages/competitors/CompetitorPage.test.tsx
npx.cmd playwright test e2e/competitor-detail.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/competitors/CompetitorPage.tsx src/pages/competitors/CompetitorPage.test.tsx e2e/competitor-detail.spec.ts
npx.cmd vitest run src/pages/currencies/CurrencyGroupPage.test.tsx
npx.cmd playwright test e2e/currency-group-detail.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/currencies/CurrencyGroupPage.tsx src/pages/currencies/CurrencyGroupPage.test.tsx e2e/currency-group-detail.spec.ts
npx.cmd vitest run src/pages/handover/HandoverSheetPage.test.tsx
npx.cmd playwright test e2e/handover-sheet-detail.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/handover/HandoverSheetPage.tsx src/pages/handover/HandoverSheetPage.test.tsx e2e/handover-sheet-detail.spec.ts
npx.cmd vitest run src/pages/central/ClosingControlPage.test.tsx
npx.cmd playwright test e2e/closing-control-detail.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/central/ClosingControlPage.tsx src/pages/central/ClosingControlPage.test.tsx e2e/closing-control-detail.spec.ts
npx.cmd vitest run src/pages/closing/MonthlyClosingPage.test.tsx
npx.cmd playwright test e2e/monthly-closing-detail.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/closing/MonthlyClosingPage.tsx src/pages/closing/MonthlyClosingPage.test.tsx e2e/monthly-closing-detail.spec.ts
npx.cmd vitest run src/pages/darius/DariusReportPage.test.tsx
npx.cmd playwright test e2e/darius-by-date-detail.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/darius/DariusReportPage.tsx src/pages/darius/DariusReportPage.test.tsx e2e/darius-by-date-detail.spec.ts
npx.cmd vitest run src/pages/organizations/OrganizationPage.test.tsx
npx.cmd playwright test e2e/organization-detail.spec.ts --config=playwright.config.ts
npx.cmd eslint src/pages/organizations/OrganizationPage.tsx src/pages/organizations/OrganizationPage.test.tsx e2e/organization-detail.spec.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 70
npx.cmd vitest run src/pages/reports/MnbReportPage.test.tsx
npx.cmd eslint src/pages/reports/MnbReportPage.tsx src/pages/reports/MnbReportPage.test.tsx src/pages/mnb/MnbReportsPage.tsx src/services/api/mnbReports.ts e2e/mnb-report-readonly.spec.ts
npm.cmd run type-check
npx.cmd playwright test e2e/mnb-report-readonly.spec.ts --config=playwright.config.ts
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 70
npx.cmd vitest run src/pages/workstations/WorkstationPage.test.tsx
npx.cmd eslint src/pages/workstations/WorkstationPage.tsx src/pages/workstations/WorkstationPage.test.tsx e2e/workstation-detail.spec.ts
npm.cmd run type-check
npm.cmd run build
npx.cmd playwright test e2e/workstation-detail.spec.ts --config=playwright.config.ts
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 80
npx.cmd vitest run src/pages/organizations/OrganizationalSystemParameterPage.test.tsx
npx.cmd eslint src/pages/organizations/OrganizationalSystemParameterPage.tsx src/pages/organizations/OrganizationalSystemParameterPage.test.tsx e2e/organizational-system-parameter-detail.spec.ts
npm.cmd run type-check
npm.cmd run build
npx.cmd playwright test e2e/organizational-system-parameter-detail.spec.ts --config=playwright.config.ts
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 80
npx.cmd vitest run src/pages/settings/PermissionPage.test.tsx
npx.cmd eslint src/pages/settings/PermissionPage.tsx src/pages/settings/PermissionPage.test.tsx e2e/permission-module.spec.ts
npm.cmd run type-check
npm.cmd run build
npx.cmd playwright test e2e/permission-module.spec.ts --config=playwright.config.ts
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 80
npx.cmd vitest run src/pages/settings/SystemParameterPage.test.tsx
npx.cmd eslint src/pages/settings/SystemParameterPage.tsx src/pages/settings/SystemParameterPage.test.tsx e2e/system-parameter-backend-reads.spec.ts
npm.cmd run type-check
npx.cmd playwright test e2e/system-parameter-backend-reads.spec.ts --config=playwright.config.ts
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 120
npx.cmd vitest run src/pages/rates/components/CurrencyManagerModal.test.tsx
npx.cmd eslint src/pages/rates/components/CurrencyManagerModal.tsx src/pages/rates/components/CurrencyManagerModal.test.tsx e2e/currency-manager-backend-reads.spec.ts
npm.cmd run type-check
$env:VITE_APP_FLAVOR='rate-maker'; $env:PLAYWRIGHT_E2E_PORT='3131'; npx.cmd playwright test e2e/currency-manager-backend-reads.spec.ts --config=playwright.config.ts
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 120
npx.cmd vitest run src/pages/rates/RateHistoryPage.test.tsx
npx.cmd eslint src/pages/rates/RateHistoryPage.tsx src/pages/rates/RateHistoryPage.test.tsx src/services/api/exchange-rates.ts e2e/rate-history-exchange-rate-reads.spec.ts
npm.cmd run type-check
npx.cmd playwright test e2e/rate-history-exchange-rate-reads.spec.ts --config=playwright.config.ts
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 120
npx.cmd vitest run src/pages/reports/ExtendedReportsPage.test.tsx
npx.cmd eslint src/pages/reports/ExtendedReportsPage.tsx src/pages/reports/ExtendedReportsPage.test.tsx e2e/extended-reports-export.spec.ts
npx.cmd playwright test e2e/extended-reports-export.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 140
npx.cmd vitest run src/pages/reports/ExtendedReportsPage.test.tsx
npx.cmd eslint src/pages/reports/ExtendedReportsPage.tsx src/pages/reports/ExtendedReportsPage.test.tsx e2e/extended-reports-export.spec.ts
npx.cmd playwright test e2e/extended-reports-export.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 140
npx.cmd vitest run src/pages/vaultStocktake/VaultStocktakeDetailPage.test.tsx
npx.cmd eslint src/pages/vaultStocktake/VaultStocktakeDetailPage.tsx src/pages/vaultStocktake/VaultStocktakeDetailPage.test.tsx e2e/vault-stocktake-summary.spec.ts
npx.cmd playwright test e2e/vault-stocktake-summary.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 140
npx.cmd vitest run src/pages/reservations/ReservationPage.test.tsx
npx.cmd eslint src/pages/reservations/ReservationPage.tsx src/pages/reservations/ReservationPage.test.tsx src/services/api/settings.ts e2e/reservation-reserved-stock.spec.ts
npx.cmd playwright test e2e/reservation-reserved-stock.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 140
npx.cmd vitest run src/pages/receipts/ReceiptPage.test.tsx src/pages/receipts/ReceiptPage.types.test.ts
npx.cmd eslint src/pages/receipts/ReceiptPage.tsx src/pages/receipts/ReceiptPage.test.tsx e2e/receipt-detail.spec.ts src/i18n/hu.json
npx.cmd playwright test e2e/receipt-detail.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 140
npx.cmd vitest run src/pages/customers/CustomerListPage.test.tsx
npx.cmd eslint src/pages/customers/CustomerListPage.tsx src/pages/customers/CustomerListPage.test.tsx e2e/customer-code-search.spec.ts
npx.cmd playwright test e2e/customer-code-search.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 140
python -m py_compile scripts/dev-tools/frontend-backend-contract-audit.py scripts/dev-tools/frontend-audit-self-test.py
python scripts/dev-tools/frontend-audit-self-test.py
npx.cmd vitest run src/pages/settings/UserPage.test.tsx
npx.cmd eslint src/pages/settings/UserPage.tsx src/pages/settings/UserPage.test.tsx e2e/user-detail-edit.spec.ts
npx.cmd playwright test e2e/user-detail-edit.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 140
npx.cmd vitest run src/pages/settings/PermissionPage.test.tsx
npx.cmd eslint src/pages/settings/PermissionPage.tsx src/pages/settings/PermissionPage.test.tsx e2e/permission-module.spec.ts
npx.cmd playwright test e2e/permission-module.spec.ts --config=playwright.config.ts
npm.cmd run type-check
npm.cmd run build
python scripts/dev-tools/frontend-backend-contract-audit.py --show-ui-unreferenced --show-ui-unreferenced-summary --limit 140
```

Previous UI verification in the same audit work:

```powershell
npm.cmd run test -- NavReportPage.test.tsx
npm.cmd run test -- ReceivedDataOverviewPage.test.tsx MonthlyClosingPage.test.tsx ReservationPage.test.tsx
npm.cmd run typecheck
npx.cmd eslint src/pages/reports/NavReportPage.tsx src/pages/reports/NavReportPage.test.tsx src/services/api/reports.ts --max-warnings 9999
npx.cmd eslint src/pages/central/ReceivedDataOverviewPage.tsx src/pages/central/ReceivedDataOverviewPage.test.tsx src/pages/currencies/CurrencyGroupPage.tsx src/pages/competitors/CompetitorPage.tsx src/pages/closing/MonthlyClosingPage.tsx src/pages/closing/MonthlyClosingPage.test.tsx src/pages/reservations/ReservationPage.tsx src/pages/reservations/ReservationPage.test.tsx src/services/api/exchange-rates.ts src/services/api/settings.ts --max-warnings 9999
npm.cmd run test:e2e -- nav-report.spec.ts
npm.cmd run test:e2e -- mobile-work-area.spec.ts
npm.cmd run test:e2e -- central-received-data.spec.ts
npm.cmd run test:e2e -- hrk-monthly-closing.spec.ts
```
