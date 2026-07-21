# Spec: Closing Wizard same-day start guard

> Dátum: 2026-07-21 · Szerző: Planner/Coder pipeline · Állapot: JÓVÁHAGYVA
> Szabály: a szerződést a felhasználó a 20260721-fix-closing-wizard-stale-lock terv részeként jóváhagyta.

## 1. Cél

A Closing Wizard indítási őre csak az adott iroda mai, IN_PROGRESS állapotú varázslóját tekintse blokkolónak. A korábbi napról beragadt varázsló ne akadályozza az új üzleti nap zárását, de módosítás nélkül, azonosítóval és dátummal kerüljön figyelmeztető naplóba. A varázslóoldal HTTP 400 esetén a backend `message` mezőjét jelenítse meg a hiba toastban.

## 2. NEM cél (out of scope)

- Korábbi napi varázsló automatikus megszakítása, törlése vagy bármilyen módosítása.
- Meglévő varázsló folytatására vagy idempotens újranyitására szolgáló funkció.
- Adatbázis-migráció vagy új egyedi constraint.
- FKH-020 vagy FKH-024 kódutak módosítása.
- A párhuzamos azonos napi indítások közötti TOCTOU-verseny megszüntetése.
- Controller-, identity- vagy jogosultsági szerződés módosítása.

## 3. Érintett területek

- `backend/src/main/java/hu/puzzleir/valuta/repository/ClosingWizardRepository.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/ClosingWizardService.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/ClosingWizardServiceTest.java`
- `frontend-react/src/pages/closing/ClosingWizardPage.tsx`
- `frontend-react/src/pages/closing/ClosingWizardPage.test.tsx`

## 4. Rögzített döntések és kényszerek

- A blokkoló lekérdezés kulcsa: `branchId`, `WizardStatus.IN_PROGRESS`, `LocalDate.now()`.
- A guard és az új rekord ugyanazt a lokális `today` értéket használja.
- A korábbi napi IN_PROGRESS rekordok csak `WARN` szintű naplóbejegyzést okoznak; az üzenet felsorolja az id-ket és dátumokat.
- A szerver által meghatározott branch- és worker-azonosság változatlan marad.
- A meglévő `testStartWizard_alreadyActive` és `startWizard_authenticatedScopesBranchAndWorkerByCompany` tesztek repository-stubjának dátumozott lekérdezésre frissítése dokumentált specifikációváltozás. A tesztek azonos napi duplikációt tiltó állítása és minden ellenőrzése változatlan marad; ez nem tesztgyengítés.
- A frontend a már meglévő `getErrorMessage` segédfüggvényt használja. Nem Axios `Error` esetén megmarad a nyers/humanizált üzenet; nem `Error` elutasításnál az elfogadott fallback: `Ismeretlen hiba történt`.
- A production gyökérok a kódból és a hibajelenségből DERIVED, erős hipotézis; production DB-, log- vagy HAR-bizonyíték nem áll rendelkezésre.

## 5. Edge case-ek

- Éjfél után a szerver alapértelmezett időzónája szerinti előző napi varázsló stale lesz; ez szándékos új üzleti napi viselkedés.
- SAME-day IN_PROGRESS varázsló továbbra is blokkol, és a hibaüzenet tartalmazza az `aktív` szót.
- PRIOR-day IN_PROGRESS varázsló nem blokkol, nem módosul, és id/dátum formában naplózásra kerül.
- COMPLETED, FAILED és CANCELLED rekord nem blokkol, mert mindkét lekérdezés kizárólag IN_PROGRESS állapotú rekordot keres.
- Az azonos napi két párhuzamos start közötti check-then-insert TOCTOU-verseny megmarad; nincs hozzá új adatbázis-constraint.
- A branch és worker továbbra is szerveroldali security contextből és company-scope-pal kerül feloldásra.
- A frontend teszt valódi `AxiosError` példányt használ, hogy a backend `response.data.message` ága fusson.

## 6. Elfogadási kritériumok (EARS)

- WHEN a branch has an IN_PROGRESS wizard with closingDate < today, THEN `startWizard` SHALL create and return a new wizard for today and SHALL log a warning naming the stale wizard ids.
- WHEN a branch has an IN_PROGRESS wizard with closingDate = today, THEN `startWizard` SHALL throw ValidationException whose message contains "aktív" (HTTP 400 via GlobalExceptionHandler).
- WHEN the start POST fails with HTTP 400, THEN the wizard page SHALL show the backend `message` field in the error toast, not the Axios status string.

## 7. Tesztterv

Strict RED-GREEN sorrendben:

1. Backend regressziós osztály — workdir `D:/repo/valutavalto-program-mainbuild/backend`:
   - `./mvnw.cmd -Dtest=ClosingWizardServiceTest test`
   - RED: pontosan a két új teszt bukik, az eredeti öt zöld.
   - GREEN: `Tests run: 7, Failures: 0, Errors: 0`.
2. Frontend célzott teszt — workdir `D:/repo/valutavalto-program-mainbuild/frontend-react`:
   - `npm.cmd run test -- src/pages/closing/ClosingWizardPage.test.tsx`
   - RED: az új teszt a generikus Axios státuszüzenetet kapja a backendüzenet helyett.
   - GREEN: minden teszt zöld a fájlban.
3. Frontend statikus ellenőrzések — ugyanott:
   - `npm.cmd run lint`
   - `npm.cmd run typecheck`
   - `npx.cmd prettier --check src/pages/closing/ClosingWizardPage.tsx src/pages/closing/ClosingWizardPage.test.tsx`
4. Backend compile sanity — workdir `D:/repo/valutavalto-program-mainbuild/backend`:
   - `./mvnw.cmd -q compile`

## 8. Kockázatok / visszavonási terv

- Maradó kockázat: adatbázis-constraint hiányában két valóban párhuzamos, azonos napi indítás átjuthat a guardon.
- Maradó kockázat: a szerver alapértelmezett időzónája határozza meg a napváltást.
- Visszavonás: az egységenkénti commitok normál `git revert` művelettel visszavonhatók; nincs migráció vagy production adatmutáció.
