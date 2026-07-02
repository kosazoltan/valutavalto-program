# Terv-KIEGÉSZÍTÉS (2. kör): daily-turnover E2E a tényleges FK-045 szerződésre

Előzmény: `.hermes/plans/2026-07-02-e2e-main-red-fix.md` Task 1 — a coder Stop-and-Ask-kal
helyesen jelezte, hogy a terv hiányos volt. Ez a kiegészítés az ORCHESTRATOR által
kódból verifikált, AKTUÁLIS UI-szerződést rögzíti. A Task 2 (shipments) KÉSZ, NEM érintendő.

## A tényleges UI (DailyTurnoverPage.tsx 195-280, kódból ellenőrizve)

- Szűrősor: `Év` (select), `Hónap` (select), `Nap (tól)` (number input), `Nap (ig)` (number input),
  `Egység` (select, már van aria-label), feltételes `Terület`/`Pénztár` (select).
- A gomb felirata: **„Időszak rendben"** (276-278. sor), NEM „Lekérdezés".
- A lekérdezés `buildRange()`-ből épít from/to-t (év+hónap+napok), a query-paraméterek maradnak
  `from`/`to` ISO dátumok.
- EGYIK label sincs összekötve az inputjával (nincs htmlFor/id) — accessibility-hiány.

## Feladat

### 1. DailyTurnoverPage.tsx — aria-label minden szűrő-vezérlőre (minimál diff)
- Év select: `aria-label="Év"`
- Hónap select: `aria-label="Hónap"`
- Nap (tól) input: `aria-label="Nap (tól)"`
- Nap (ig) input: `aria-label="Nap (ig)"`
- Terület select: `aria-label="Terület"`, Pénztár select: `aria-label="Pénztár"`
  (a reviewer low note-ja is ezt kérte)
- SEMMI más nem változik a komponensben.

### 2. daily-turnover-company.spec.ts — a teszt lépései az új szerződésre
A teszt CÉLJA változatlan (a /turnover/company hívás szerződés-ellenőrzése) — csak a
lépések követik le az FK-045 UI-t:
- `getByLabel('Kezdő dátum').fill('2026-06-01')` + `getByLabel('Záró dátum').fill('2026-06-18')`
  HELYETT:
  - `getByRole('combobox', { name: 'Év' }).selectOption('2026')`
  - `getByRole('combobox', { name: 'Hónap' }).selectOption({ index: 5 })`  // június (0-index — ellenőrizd a months tömb value-ját: value={i+1}, tehát selectOption('6'))
  - `getByLabel('Nap (tól)').fill('1')`
  - `getByLabel('Nap (ig)').fill('18')`
- `getByRole('button', { name: /Lekérdezés/i })` HELYETT `getByRole('button', { name: /Időszak rendben/i })`
- A waitForRequest assert VÁLTOZATLAN marad: `from === '2026-06-01'` és `to === '2026-06-18'`
  — ez bizonyítja, hogy az új UI ugyanazt a backend-szerződést hívja (a teszt EREJE nem csökken).
- A záró assertek ('Cég összesen', EUR cell, overflow) változatlanok.
- FIGYELEM: ha a `Hónap` select value-alapú (value={i+1}), a selectOption('6') a helyes;
  futtasd a tesztet és a tényleges DOM szerint véglegesítsd — de a from/to assert nem lazulhat.

## Verifikáció
- `cd frontend-react && npx playwright test e2e/daily-turnover-company.spec.ts e2e/shipments.spec.ts` → MINDKETTŐ PASS
- `npx tsc --noEmit` → 0 hiba
- Jelentsd a pontos futási eredményt (passed/failed számokkal).
