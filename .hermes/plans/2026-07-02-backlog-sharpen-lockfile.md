# Terv: Backlog-hármas — E2E assert-élesítés + lockfile a bump-gate-be

Dátum: 2026-07-02 · Orchestrator: Fable 5 · Coder: gpt-5.5 · Reviewer: glm-5.2
Branch: `chore/backlog-e2e-sharpen-lockfile-gate`

## Task 1 — getByText('3') élesítése (GLM Low finding a #1269 review-ból)

Fájl: `frontend-react/e2e/daily-turnover-company.spec.ts` (134. sor)

A `await expect(page.getByText('3').first()).toBeVisible()` laza substring-assert.
A mock válasz alapján (a spec mockApis-ában a /turnover/company válasz totalBuy:3)
élesítsd a tényleges renderelt értékre. ELŐBB nézd meg a mockApis válaszát és a
DailyTurnoverPage renderjét (hogyan formázza: '3 Ft'? táblázat-cella?), és arra
asserteld, ami a totalBuy=3 SPECIFIKUS megjelenése — pl.
`getByRole('cell', { name: '3 Ft' })` vagy a pontos formázott szöveg.
Ez assert-ERŐSÍTÉS (Low → sharp), tilos lazítani.

## Task 2 — package-lock.json-ök bevonása a verzió-bump gate-be

Fájl: `installer/scripts/check-version-bump.ps1`

Kontextus: a v2.28.25 bumpnál kiderült, hogy a 4 kliens package-lock.json-jának
`version` mezője (top-level, x2: root "version" és packages."".version) NEM része
a 6-utas szinkronnak — a bump után driftben maradtak, csak az npm ci frissítette
őket mellékhatásként.

Teendő:
1. A `Get-AllProjectVersions` (installer/build-common.ps1) VAGY a check-version-bump.ps1
   drift-ellenőrzésébe vedd fel a 5 lockfile-t (root + frontend-react + penztar-client +
   arfolyam-keszito-client + kozponti-client package-lock.json), a JSON `version` és
   `packages."".version` mezőkkel.
2. AUTO-PATCH módban a bump frissítse őket is (npm version már frissíti a lockfile-t
   ha a workdirben fut — ellenőrizd; ha nem, közvetlen JSON-frissítés, format-megőrzéssel).
3. A kimenet listázza az új helyeket is (6-way → 11-way jelzés a Write-Hostban).
4. FONTOS: a script jelenlegi viselkedése (exit-kódok, KEPT_VERSION output, NoAutoPatch
   strict mód) NEM változhat — csak bővül a helyek listája.

Verifikáció (a coder futtassa):
- `pwsh installer/scripts/check-version-bump.ps1 -RepoRoot D:\repo\valutavalto-program -BuildDir D:\repo\valutavalto-program\installer\build -CurrentVersion 2.28.25` → PASS, mind a 11 hely 2.28.25
- Playwright: `npx playwright test e2e/daily-turnover-company.spec.ts` → PASS

## Nem-célok
- auto-fix workflow javítása (a secret létezik, a hiba a workflow belső SDK-hívásában van —
  külön vizsgálat, NEM ez a task).
- Bármi más spec vagy src fájl.
