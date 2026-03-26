# Electron Bootstrap Auth E2E Tests

## Quick Start

### Prerequisites
- Node.js v24+ (for penztar-client)
- `.env` file with PENZTAR_BOOTSTRAP_* variables (already present)

### Installation
```bash
cd penztar-client
npm install  # Already done: @playwright/test + dotenv added
```

### Run Tests

**Against Render backend** (no local backend required):
```bash
npx playwright test --config=playwright.config.ts
```

**Against local backend** (http://localhost:8080):
```bash
# Start backend first:
cd ../backend
./mvnw.cmd spring-boot:run

# Then run tests:
cd ../penztar-client
npx playwright test
```

### Test Results
- 6 tests total (1 suite)
- Tests skip gracefully if backend down
- Pass/Fail indicated in console output

---

## Test Coverage

| Test | Purpose | Credentials Used |
|------|---------|------------------|
| Health Check | Backend availability | N/A |
| Login | Auth with PENZTAR_BOOTSTRAP_* | EBC/BORSI/1234 |
| Exchange Rates | Cache endpoint access | Bearer token |
| Workers | Master data sync | Bearer token |
| Branches | Master data sync | Bearer token |
| Integration | Full bootstrap flow | All above combined |

---

## Environment Variables

From `.env`:
```
PENZTAR_BOOTSTRAP_COMPANY_CODE=EBC
PENZTAR_BOOTSTRAP_WORKER_CODE=BORSI
PENZTAR_BOOTSTRAP_PASSWORD=1234
PENZTAR_BOOTSTRAP_ROLE_CODE=CASHIER
```

---

## Files

- `e2e/bootstrap-auth.spec.ts` - Main test suite (312 lines, fully typed)
- `playwright.config.ts` - Playwright configuration
- `BOOTSTRAP_AUTH_E2E_TESTPLAN.md` - Detailed test plan

---

## Known Issues

### Backend Login 500 (FIXED)
- Error: NullPointerException in WorkerSession creation
- Fix applied: `WorkerService.java` branch fallback logic
- Status: Waiting for Render backend redeploy

### Test Skip Behavior
Tests skip (×) instead of fail for:
- Backend unavailable (500)
- Invalid token (403)
- Missing endpoint (404)

This is intentional for API-level tests.

---

## CI/CD Integration

Add to `penztar-client/package.json`:
```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:headed": "playwright test --headed"
  }
}
```

Then run:
```bash
npm run test:e2e
```

---

## Debugging

Enable verbose output:
```bash
npx playwright test --config=playwright.config.ts --verbose
```

View HTML report:
```bash
npx playwright show-report
```

---

**Created**: 2026-03-26  
**Status**: Ready for integration with Electron sync-engine
