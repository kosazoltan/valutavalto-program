# Google OAuth Auto-Detection Setup

Date: 2026-05-12
Status: active decision

## Decision

The local Electron applications use Google OAuth auto-detection for non-cashier workers. The worker's verified Google email identifies the account, branch, and role from server-side master data. Cashiers remain on username/password login.

The first-run setup wizard no longer has to ask leaders for a local/admin password. It starts with Google login, then the backend validates the Google ID token and resolves:

- worker email match: worker, branch, roles, and app mode are selected automatically;
- HQ worker match: central role is selected automatically, including `full` and `rate-maker` where applicable;
- branch shared email match: branch is selected automatically, then the user chooses their own worker record from the branch/region worker list;
- no match: setup/login is denied.

## Implementation

- Backend endpoint: `POST /api/v1/public/setup/google-identify`.
- Backend service: `SetupGoogleIdentificationService`.
- The endpoint accepts only a Google ID token, company code, requested app mode, and optional selected worker code. It does not trust a raw email from the client.
- Google ID token verification now carries profile `name` and `picture` in the verified identity model for setup UX.
- `WorkerRepository` has a company-scoped Google login candidate lookup.
- `BranchRepository` has a company-scoped active branch email lookup for shared branch email setup.
- `SetupWizard` performs Google login first, auto-fills branch/worker/app mode, asks for worker selection only for shared branch email, and skips password fields for non-cashier Google setup.
- `saveSetupConfig()` supports `authMode=google`, stores Google setup metadata locally, writes no bootstrap password, and still generates per-install JWT/SQLCipher/offline-license secrets.
- Cashier setup keeps the existing password path.

## Desktop OAuth

The desktop OAuth credential file was read locally and safely on 2026-05-12. Its secret content was not printed or committed. The values were written only to gitignored local env files:

- root `.env`: `GOOGLE_DESKTOP_CLIENT_ID`, `GOOGLE_DESKTOP_CLIENT_SECRET`
- `penztar-client/.env.local`: `VITE_GOOGLE_DESKTOP_CLIENT_ID`, `VITE_GOOGLE_DESKTOP_CLIENT_SECRET`

The backend accepts the desktop OAuth client ID through `google.desktop.client.id=${GOOGLE_DESKTOP_CLIENT_ID:}` so Electron ID tokens can pass audience verification alongside the web OAuth client ID.

## Security Notes

- Google subject binding is finalized only after setup confirmation.
- A Google subject already bound to another worker is rejected.
- Multiple worker or branch matches for one email are treated as configuration conflicts.
- Shared branch email never silently binds to a person; worker selection is required.
- Cashier passwords remain because cashier operation still needs the existing local/password flow.
