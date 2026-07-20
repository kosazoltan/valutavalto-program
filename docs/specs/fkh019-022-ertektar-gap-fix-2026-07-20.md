# Spec: FKH-019 / FKH-020 / FKH-021 / FKH-022 Értéktári hiányok lezárása

> Dátum: 2026-07-20 · Szerző: Codex · Állapot: VÁZLAT
> Szabály: 3+ fájlt érintő vagy bizonytalan feladat csak JÓVÁHAGYOTT spec után indul.

## 1. Cél

A 2026-07-19/2026-07-20-i hibajelzések alapján a kódbázisban ténylegesen hiányzó vagy félkész
értéktári funkciókat véglegesíteni kell. A javítási kör négy tételre fókuszál: szerepkör-alapú
session-telephely feloldás (`FKH-019`), értéktári napi zárás kötelező címletezési gate-je
(`FKH-020`), havi zárás értéktári jogosultság + scope javítása (`FKH-021`), valamint a törött
`Naplókönyv` lecserélése működő FF/UF HUF-naplóra (`FKH-022`).

## 2. NEM cél (out of scope)

- `FKH-023` nem része a javításnak, mert a visszajelzés szerint működik.
- A többi belinkelt dokumentum (`FKH-024`, `FK-054`, `FK-056`, `FK-057`, stb.) nem kerül ebbe a
  patch-szeletbe, hacsak a fenti négy hibához nem szükséges közvetlen mellékjavítás.
- Nincs deploy, release, installer-build vagy adatbázis-adattisztítás ebben a körben.
- A pénztári viselkedés csak annyiban változhat, amennyiben regressziót kell megőrizni.

## 3. Érintett területek

- `backend/src/main/java/hu/puzzleir/valuta/controller/AuthController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/WorkerService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/GoogleLoginService.java`
- `backend/src/main/java/hu/puzzleir/valuta/security/JwtTokenProvider.java`
- új közös backend session-branch feloldó logika és kapcsolódó repository-bővítés
- `backend/src/main/java/hu/puzzleir/valuta/controller/ClosingWizardController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/ClosingWizardService.java`
- `frontend-react/src/pages/closing/ClosingWizardPage.tsx`
- `frontend-react/src/pages/closing/EveningClosingPage.tsx`
- `backend/src/main/java/hu/puzzleir/valuta/controller/MonthlyClosingController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/MonthlyClosingService.java`
- `frontend-react/src/pages/closing/MonthlyClosingPage.tsx` csak ha frontend-oldali regresszióhoz kell
- `backend/src/main/java/hu/puzzleir/valuta/controller/DailyReportController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/DailyReportService.java`
- új HUF-napló backend DTO/repository/controller/service réteg
- `frontend-react/src/pages/reports/DaybookPage.tsx`
- `frontend-react/src/services/api/settings.ts`
- célzott backend/frontend tesztek a fenti szelethez

## 4. Rögzített döntések és kényszerek

- `FKH-019`: az értéktári jellegű operatív szerepkörök session branch-e a dolgozó régiójához
  tartozó aktív `is_vault=true` branch legyen, ne a worker mentett default branch-e.
- `FKH-019`: ugyanaz a feloldott branch menjen a JWT `branchId` claimbe és a `WorkerDto`-ba.
- `FKH-020`: az értéktári napi zárás a meglévő `ClosingWizard` bővítésével valósul meg, nem új
  párhuzamos wizarddal.
- `FKH-020`: értéktári kontextusban az eltérés teljes blokkolás, nincs indoklásos felülírás.
- `FKH-021`: mind az 5 havi zárás végpont jogosultsági listája bővül, és a write út is kap teljes
  cég- és territory-guardot.
- `FKH-022`: a jelenlegi `daily_report`-alapú napló nem maradhat elsődleges adatforrás; a működő
  napló FF/UF shipment adatokból épül.
- Meglévő tesztet gyengíteni, törölni vagy skipelni tilos.
- Ha új perzisztens mező/tábla kell `FKH-022`-höz, csak új Flyway migrációval kerülhet be.

## 5. Edge case-ek

- Értéktári role, de nincs pontosan egy aktív vault branch a dolgozó régiójához.
- Több role-os login, ahol a branch csak role-select után véglegesül.
- Google login és jelszavas login eltérő session-építési útjai.
- Territory-scoped értéktáros idegen branchId-vel próbál havi zárást vagy HUF-naplót lekérni.
- Értéktári napi zárásnál a fizikai címletezés több valután nullás vagy hiányos.
- `DaybookPage` üres napi adatra ne hibázzon, hanem üres állapotot adjon.
- `FKH-022` esetén a sztornó FF/UF tételek se vesszenek el.

## 6. Elfogadási kritériumok (EARS)

- WHEN egy dolgozó értéktári operatív szerepkörrel jelentkezik be THEN the system SHALL a
  session branch-et a saját régiójához tartozó aktív vault branch-re feloldani.
- WHEN ugyanaz a login/session válasz elkészül THEN the system SHALL ugyanazt a feloldott branch-et
  használni a JWT claimben és a `WorkerDto.branch*` mezőkben.
- WHEN értéktáros megnyitja a napi zárási wizardot THEN the system SHALL nem 403-at adni, és a
  wizard értéktári kontextusban a megfelelő készletforrással számoljon.
- WHEN értéktári zárásnál bármely valuta fizikai és várt készlete eltér THEN the system SHALL a
  zárást blokkolni indoklásos felülírás nélkül.
- WHEN értéktáros, főértéktáros vagy ügyvezető havi zárás végpontot hív THEN the system SHALL
  átengedni a jogosult kérést, de idegen cégre vagy idegen territory branch-re NEM.
- WHEN a `Naplókönyv` oldal adott napra FF/UF adatot kér THEN the system SHALL shipment-alapú,
  HUF-os, soros naplót visszaadni külön átadás/átvétel oszloppal.
- WHEN a `Naplókönyv` oldalon nincs tétel az adott napra THEN the system SHALL hiba helyett üres,
  kezelhető állapotot megjeleníteni.

## 7. Tesztterv

- Backend unit/integration teszt `FKH-019` session-branch feloldásra jelszavas, Google és role-select
  útvonalra.
- Backend security/service teszt `FKH-020` wizard jogosultság + értéktári eltérés-blokkolásra.
- Backend security/service teszt `FKH-021` 5 végpont RBAC + cross-tenant/cross-territory guardra.
- Backend repository/service teszt `FKH-022` FF/UF napló-lekérdezésre, kizárásokra és sztornóra.
- Frontend teszt `ClosingWizardPage` és `DaybookPage` kulcsállapotaira.
- Csak a legszűkebb hasznos tesztek futnak először; teljes gate nem cél ebben a körben.

## 8. Kockázatok / visszavonási terv

- Kockázat: a login/session branch módosítás mellékhatással lehet más kliensek branch-kijelzésére.
- Kockázat: a `ClosingWizard` közös komponens, ezért pénztári regressziót védeni kell.
- Kockázat: `FKH-022` adatmodell-bővítés érintheti a shipment létrehozási utat.
- Visszavonás: a módosítások egyetlen célzott patch-szeletben készülnek; szükség esetén git reverttel
  visszaállíthatók, adatmodell-változásnál külön migrációs rollback-terv dokumentálandó.
