# Release Blocker Remediation — v2.28.49

## Status

Approved by the user on 2026-07-21 for full blocker remediation and signed release.
Before release dispatch, the user additionally approved integrating every recent non-Dependabot branch reported by the build-integrity gate.

## Goal

Restore all mandatory release gates on `main`, then build, publish, download, and verify the three signed Windows installer artifacts for v2.28.49.

## Non-goals

- No feature expansion beyond release blockers.
- No weakening, skipping, deleting, or rewriting assertions merely to make tests pass.
- No unrelated refactors or broad dependency upgrades.
- No standalone rate-maker installer.

## Build-integrity branch integration

The following patch-unique commits SHALL be integrated before the signed build, preserving their authorship and atomic history through `--no-ff` branch merges:

- `339c85a4`, `c3c1c720` — shipment receipt/audit fixes;
- `dd2a33f4`, `4d608627` — stale-delivery warning and its PostgreSQL fixture follow-up;
- `f59f2a6e`, `0a387d0e`, `39f0d420` — Windows/Electron development-tooling fixes.

Conflicts SHALL retain both the already verified release dependency fixes and the intended branch behavior. After integration, all release gates and remote CI SHALL run again from the new `main` HEAD.

## Confirmed blockers

1. Backend full suite: 3,206 tests, 2 failures and 6 errors across:
   - `AuthRefreshCookieIssueFailureTest`
   - `MonthlyReportServiceTest`
   - `ClosingFlowTest.testClosingWizard_calculateDifferences`
2. Frontend Playwright: 192 passed, 1 failed because its stale sparse-payload assertion rejected the required complete denomination snapshot.
3. GitHub Security Pipeline npm audit: high/critical build dependency findings.
4. Existing global root formatting debt is outside this release slice; every touched file must pass targeted formatting.

## Planned files

Exact dependency files will be finalized after audit-path analysis. Expected code/test scope:

- `frontend-react/e2e/closing-differences.spec.ts`
- existing backend failing test fixtures and only the minimal production files proven necessary by root-cause analysis
- root/client `package.json` and `package-lock.json` files required for audited fixed versions
- `arfolyam-keszito-client` and `kozponti-client` manifests/lockfiles because their Electron build chains contain the same high/critical advisories
- this specification

## Behavioral contract

### Denomination payload

WHEN a user submits denomination quantities,
THEN the client SHALL send a complete snapshot containing every displayed denomination, including explicit zero quantities,
AND the backend SHALL use explicit zeros to clear any previously positive persisted denomination balance,
AND SHALL preserve the full calculated currency total used by the differences endpoint,
AND SHALL reject negative input through the existing UI constraints.

### Backend fixture integrity

WHEN production services gain required collaborators or context guards,
THEN tests SHALL construct the same valid dependency graph and domain context as production,
WITHOUT weakening the tested business assertions.

### Dependency remediation

WHEN a high/critical advisory has a compatible patched version,
THEN the narrowest direct dependency or override SHALL be upgraded,
AND lockfiles SHALL be regenerated with the repository package manager,
AND package/build/type/test gates SHALL prove compatibility.

## Edge cases

- All denomination quantities are zero: the complete per-currency zero snapshot is sent so stale physical balances are cleared.
- Multiple currencies: every displayed denomination remains grouped under its currency code, including explicit zeros.
- Existing closing-wizard totals remain unchanged by complete snapshot submission.
- Test mocks must remain strict enough to detect missing authorization, tenant, branch, or role context.
- Dependency fixes must not silently change Electron major version or production runtime contracts unless the advisory requires it and tests prove compatibility.

## Acceptance criteria

- Targeted denomination Playwright test strictly asserts the complete replacement snapshot and passes.
- All 193 frontend Playwright tests pass.
- All backend tests pass with 0 failures and 0 errors.
- Root and all four client npm audits report no high/critical findings.
- `npm run lint`, `npm run typecheck`, touched-file Prettier, installer preflight, and release security gate pass.
- Local `main` is clean and equals `origin/main` before release dispatch.
- GitHub required CI workflows for the release commit are green.
- Signed workflow publishes exactly:
  - `Penztar-Setup-2.28.49-<date>.exe`
  - `Penztar-Eltavolito-2.28.49-<date>.exe`
  - `Kozponti-Munkaallomas-Setup-2.28.49.exe`
- Downloaded artifacts have valid Authenticode signatures and SHA-256 values matching the release manifest.
- The seven approved branch commits are patch-equivalent in `main`, with no remaining unmerged non-Dependabot feature/fix branch content intended for this release.
