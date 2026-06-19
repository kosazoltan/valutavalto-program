# Frontend-backend contract audit - 2026-06-19

Status: IN PROGRESS

## Scope

This audit checks whether high-confidence frontend REST calls have matching
Spring `@RestController` endpoints, and whether backend endpoints without a
literal frontend caller are either intentionally backend-only/integration-only
or require a targeted frontend follow-up.

The frontend side is production-only: unit tests, Playwright specs, Storybook
stories and test setup files are excluded so mocked REST calls cannot prove a
real UI/backend binding.

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
python scripts/dev-tools/frontend-backend-contract-audit.py --show-unreferenced --show-unreferenced-summary --limit 120
```

Latest verified result:

```text
backend endpoints: 991
frontend literal REST calls: 1036
frontend unresolved dynamic calls: 0
unmatched frontend REST calls: 0
backend endpoints not referenced by literal calls: 27
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
would expose discrepancy approval and notification side effects.

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
python scripts/dev-tools/frontend-backend-contract-audit.py --show-unreferenced --show-unreferenced-summary --limit 120
python scripts/dev-tools/frontend-route-api-audit.py
python scripts/dev-tools/frontend-api-wrapper-usage-audit.py
npx.cmd eslint src/App.tsx --max-warnings 9999
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
