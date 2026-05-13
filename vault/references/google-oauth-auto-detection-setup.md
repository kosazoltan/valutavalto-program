---
date: 2026-05-12
status: active
source: docs/architecture/google-oauth-auto-detection-setup.md
tags:
  - google-oauth
  - setup-wizard
  - electron
  - auth
---

# Google OAuth Auto-Detection Setup

The EXZ local Electron setup is Google-first for non-cashier workers. The backend validates the Google ID token, then uses the verified email to resolve worker, branch, role, and app mode from master data.

Cashier setup remains password-based.

Shared branch email requires a second step: worker selection from the branch/region worker list.

Do not commit Google OAuth secrets. Desktop OAuth credentials belong only in ignored local env files and deployment secret stores.
