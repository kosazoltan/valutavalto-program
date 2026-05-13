---
date: 2026-05-12
type: implementation-session
status: captured
priority: P0
related:
  - docs/architecture/google-oauth-auto-detection-setup.md
---

# Google OAuth Auto-Detection Setup

User decision: leaders and central workers should log in with Google OAuth. Email from verified Google identity identifies branch, worker, and role from master data. Cashiers keep username/password login.

Implemented direction:

- added backend setup identification endpoint at `/api/v1/public/setup/google-identify`;
- added server-side token-first identification, with no raw email trust;
- supported exact worker-email matching and shared branch-email matching;
- required worker selection for shared branch email;
- added Google setup mode to the Electron first-run config save path;
- kept password setup only for cashier-style local setup;
- added local desktop OAuth credential wiring into gitignored env files only;
- ensured backend development config can accept `GOOGLE_DESKTOP_CLIENT_ID` as a token audience.

Verification:

- backend compile: passed;
- frontend typecheck: passed;
- Electron typecheck: passed;
- `GoogleLoginServiceTest`: passed after updating the `foertektar` expectation to include `rate-maker`;
- `SetupWizard` tests: passed;
- Electron `first-run` tests: passed.

Secret handling:

- The Google desktop OAuth credential JSON was read locally without printing its content.
- Client secret was not placed in chat, docs, patches, or committed files.
- Values were written only to ignored local env files.
