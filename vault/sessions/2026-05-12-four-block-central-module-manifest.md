# 2026-05-12 - Four-block audit follow-up: central module manifest

## Decision

During the four-block comparison (pénztár, értéktár, RFM árfolyamkészítő,
központi), the current memory/code gap was the central workstation
module-permission manifest.

The central workstation must not decide central module visibility from a
frontend-only role list. The backend now returns `centralModules` in the login
response, and the central Electron launcher uses that manifest when present.

## Implemented

- `backend/src/main/java/hu/puzzleir/valuta/util/CentralModuleManifest.java`
  is the backend SSOT for central module IDs and their allowed roles.
- `LoginResponseDto` now includes `centralModules`.
- Password login, Google OAuth login, and `/auth/login/select-role` populate
  the manifest.
- `frontend-react/src/stores/authStore.ts` persists the manifest for the active
  session and clears it on logout.
- `frontend-react/src/pages/central/CentralWorkstationPage.tsx` uses backend
  module IDs when available, with a backward-compatible local role fallback only
  for old backend responses.

## Four-block effect

- Pénztár: unchanged local appMode `penztar`; shared auth response remains
  compatible.
- Értéktár: unchanged local appMode `ertektar`; shared auth response remains
  compatible.
- RFM árfolyamkészítő: unchanged appMode `rate-maker`; főértéktáros/ügyvezető
  access remains governed by appMode roles and rate-page write guards.
- Központi: now consumes `centralModules` for module launcher visibility.

## Verification

- `npm run check:four-area-alignment`
- `npm --prefix frontend-react run typecheck`
- `npm --prefix frontend-react test -- authStore`
- `backend/.mvnw "-Dtest=CentralModuleManifestTest,GoogleLoginServiceTest,AppModeRoleConstantsTest" test`
- `npm run lint`

All passed on 2026-05-12. Lint finished with 0 errors and 217 existing
`i18next/no-literal-string` warnings unrelated to this change.
