# Terv: Frontend E2E javítás — a main-en bukó 2 Playwright teszt (spec-követés)

Dátum: 2026-07-02 · Orchestrator: Fable 5 · Coder: gpt-5.5 · Reviewer: glm-5.2
Branch: `fix/e2e-main-red-shipments-turnover`

## Elv (teszt-integritás)
Mindkét bukás oka DOKUMENTÁLT termékváltozás, amelyet a teszt nem követett le.
A teszt frissítése az ÚJ, commitolt szerződésre = megengedett spec-követés.
TILOS: assert gyengítése, skip, a régi viselkedés visszacsempészése.

## Task 1 — daily-turnover-company.spec.ts: egyértelmű combobox-szelektor

**Gyökérok:** FK-045/FK-047 óta a Napi forgalom oldalon több `<select>` van
(év, hónap, Egység, feltételes Terület/Pénztár). A teszt `page.getByRole('combobox')`
hívása "strict mode violation: resolved to 3 elements" hibával hal.

**A oldal hibája is:** az `Egység` label nincs összekötve a select-tel (nincs htmlFor/id,
nincs aria-label) — accessibility hiány.

Fájlok:
- `frontend-react/src/pages/reports/DailyTurnoverPage.tsx` (~239. sor, Egység select)
- `frontend-react/e2e/daily-turnover-company.spec.ts` (~125. sor)

Lépések:
1. `DailyTurnoverPage.tsx`: az Egység `<select>`-re `aria-label="Egység"` (a meglévő
   `Területi szűrő` aria-label mintára — lásd DailyCheckPage). SEMMI más nem változik.
   (Opcionálisan ugyanígy aria-label a Terület/Pénztár feltételes selectekre — ha
   minimális diff-fel megy: `aria-label="Terület"`, `aria-label="Pénztár"`.)
2. Teszt: `page.getByRole('combobox').selectOption('company')` →
   `page.getByRole('combobox', { name: 'Egység' }).selectOption('company')`.
3. A teszt többi assertje (URL-paraméterek, 'Cég összesen') VÁLTOZATLAN.

## Task 2 — shipments.spec.ts:137: deliver-flow az új (d499a650) szerződésre

**Gyökérok:** a d499a650 (FR-4/FR-6, átadás-átvétel készletkönyvelés) óta:
- a gomb title-je "Kézbesítés" → **"Megérkezett"**,
- a gomb KIZÁRÓLAG az átvevő (target) fiók felhasználójának látszik:
  `canDeliver = (APPROVED|IN_TRANSIT) && shipment.targetBranchId === worker.branchId`.
A teszt mockja szerint a bejelentkezett worker `branchId: 'branch-1'` = a FELADÓ
(fromBranchId), így az új szabály szerint a gomb helyesen nem jelenik meg → timeout.

Fájl: `frontend-react/e2e/shipments.spec.ts`

Lépések:
1. A 137-es teszt mock workerét tedd az ÁTVEVŐ fiókba: `branchId: 'branch-2'`
   (= a shipment `toBranchId`-ja). Ha a worker-objektum közös a többi teszttel,
   csak ehhez a teszthez készíts átvevő-worker változatot — a többi teszt
   (DRAFT szerkesztés stb.) viselkedése NEM változhat.
2. `getByTitle('Kézbesítés')` → `getByTitle('Megérkezett')`.
3. Ellenőrizd, hogy a mock shipment mezőnevei megfelelnek a frontend
   API-konverziónak (transactions.ts ~1398: requestStatus/targetBranchId/…
   ← a mock nyers API-válasz formában megy, a konverzió a kliensben fut —
   a mock maradjon az API-oldali alakban, ahogy most).
4. A cancel-lépés: a „Sztornó" gomb státusz-alapú (canCancel), az átvevő-worker
   mellett is látszik — a teszt cancel-assertje változatlan marad.
5. PLUSZ (regresszió-védelem, kötelező): új, kis teszt
   `deliver gomb NEM latszik a felado fiok felhasznalojanak` — feladó-worker
   mockkal assert: a 'Megérkezett' title-ű gomb count = 0. Ez kódolja az
   FR-6 negatív ágát, hogy a jogosultsági szabály tesztben is éljen.

## Nem-célok
- Bármely src/ oldali logika-változás az aria-label attribútumokon túl.
- Más spec-fájlok érintése. Assert-gyengítés, skip, timeout-emelés.

## Verifikáció (a coder futtassa, eredményt jelentse)
- `cd frontend-react && npx playwright test e2e/daily-turnover-company.spec.ts e2e/shipments.spec.ts` → PASS
- `npx vitest run src/pages/reports src/pages/shipments` (érintett unit tesztek) → PASS
- `npx tsc --noEmit` → 0 hiba
