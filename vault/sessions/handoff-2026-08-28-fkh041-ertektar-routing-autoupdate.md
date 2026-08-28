# Handoff — FKH-041 értéktár routing + auto-update javítás (2026-08-28)

Branch: `pipeline/20260828-fkh041-ertektar-routing-autoupdate` (5 commit, base 94c48665).
Terv: `.hermes/pipeline/20260828-fkh041-ertektar-routing-autoupdate/round-1/10-plan.md`.

## Változott forrásfájlok (5)
1. `frontend-react/src/utils/defaultProtectedRoute.ts` (ÚJ) + `App.tsx` — a `/` landolás
   lokál terminálon szerepkör-alapú: ertektar→/treasury, penztar→/cashier,
   ertekszallito→/transfers; flavor/full/rate-maker felülírás változatlan.
2. `frontend-react/src/layouts/MainLayout.tsx` — `shouldRequireDailySession`
   szerep-tudatos: penztar módban csak a kanonikus `penztar` szerep gatelt;
   értéktáros nem kerül /cashdesk/day-open-re. Gate-skip log.info (C9 bizonyíték).
3. `frontend-react/src/hooks/useSuiteUpdate.ts` — nem-pénztár módban SHIFT_OPEN-t
   jelent (D5 Option A), napi-session API-hívás nélkül; appMode a useCallback depsben,
   módváltás után újrareportál (R3 teszt igazolja).
4. `frontend-react/src/hooks/reportLoginScreenIdleForUpdate.ts` — 3. opcionális
   appMode param; nem-pénztár módban soha IDLE. Gate-ternary szövege érintetlen.
5. `frontend-react/src/pages/auth/LoginPage.tsx` — useAppMode() az effekt ELŐTT;
   jelentés csak appModeLoading=false után (D8).

## D5 kétoldalú döntés
Option A (elfogadva): a RENDERER jelenti a konzervatív SHIFT_OPEN-t, ha appMode ≠ penztar —
appMode-t csak a renderer ismer (SQLite app_mode), IPC-kontraktus nem változik.
Option B (elutasítva): main process telepítési kapu config-store függőséget kapott volna
a biztonsági-kritikus telepítési úton. Elfogadott trade-off: értéktár terminál sosem
auto-telepít; manuális telepítő (Penztar-Setup) marad. NE javítsd vissza.

## C6 második belépési pont
A LoginPage belépőképernyő-jelentése is javítva (fent #4) — ez tüzelt mount-on,
appMode ismerete nélkül, és nyitotta a hamis telepítési ablakot.

## C9 nyitott tétel
Éles validáció a bejelentő gépén: main.log `muszak-allapot: SHIFT_OPEN` +
`Napi-session kapu kihagyva` sorok, `automatikus csendes telepites` nélkül.

## Jegyzet
Offline restore penztar módban csak penztar/CASHIER role-t fogad el
(`offlineAuthRestore.ts:54-64`) — meglévő viselkedés, nem regresszió, nem javítottuk.
