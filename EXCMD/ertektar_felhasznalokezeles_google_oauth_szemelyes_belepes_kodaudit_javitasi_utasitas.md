# Értéktári felhasználókezelés és személyes belépés - kódaudit és javítási utasítás

**Modul:** lokál értéktári felület / Google OAuth / auth-RBAC  
**Audit dátuma:** 2026-06-02  
**Kérés forrása:** `C:\Users\Kósa Zoltán\Downloads\fejlesztesi-keres-ertektar-felhasznalokez (1).md` és a mellékelt képernyőkép  
**Korlát:** Ez az audit kizárólag a repóban található kódra, tesztekre és migrációkra támaszkodik. Futó production adatbázis-lekérdezés nem történt.

## Lost-in-the-middle rövid emlékeztető

Ne új üzleti táblával kezdj. A kódban már van `worker` tábla, `password_hash`, `worker_session`, `worker_role_assignment`, branch-kapcsolat és Google OAuth whitelist. A fő javítási irány: a meglévő `Worker` modellre épített kétlépcsős értéktári login, plusz a külön kóddal igazolt `/inventory/vault-stock` RBAC hiba javítása.

## Vezetői összefoglaló

A mellékelt kérés lényege kóddal igazolt problémára mutat: a közös értéktári Google-fiók jelenleg egyetlen `Worker` rekordra mapelődik. Szeged esetén a migrációban létező `G_SZEGED_ET` worker neve `Szeged Ertektar`, emailje `szeged.ebc@gmail.com`, és `ertektar` role assignmentet kap. Ez nem személyes dolgozó, ezért a műveletek nem köthetők valós személyhez.

A képernyőképen látható `Hozzáférés megtagadva` hibának van egy külön, közvetlen kódbeli oka is: az `Értéktári készlet` menüpont az értéktáros lokál felületen elérhető, de a backend `GET /api/v1/inventory/vault-stock` endpoint nem engedi a `ERTEKTAR` szerepkört. Ez önmagában is 403-at okozhat. A személyes dolgozóválasztó bevezetése ezt nem javítja meg automatikusan, ha az endpoint jogosultságlistája változatlan marad.

## Képernyőképből ellenőrizhető tünet

- Lokál értéktári kliens fut: bal menüben `ÉRTÉKTÁR (LOKÁL)`.
- Bejelentkezett azonosító: `Szeged Ertektár`, jobb felső sarokban `ID: G_SZEGED_ET`.
- Az `Értéktári készlet` oldalon megjelenik: `Nincs jogosultsága a művelet végrehajtásához`.
- Toast: `Hozzáférés megtagadva`.
- A kártya `0 valuta`, a táblázat üres.

## Kóddal igazolt jelenlegi login folyamat

### Frontend

Érintett fájlok:

- `frontend-react/src/pages/auth/LoginPage.tsx`
- `frontend-react/src/services/api/auth.ts`
- `penztar-client/electron/google-oauth.ts`
- `penztar-client/electron/preload.ts`

Tények:

- A Google gomb után a kliens `authApi.googleLogin()` hívást küld.
- Weben ez `POST /auth/google-login` a rendererből.
- Electronban elsődlegesen `window.electronAPI.googleOAuthFlowWithBackend(appMode)` fut, amely a main processben szerzi meg a Google ID tokent, majd meghívja a backend `POST /auth/google-login` endpointot.
- A frontend jelenleg a Google OAuth válasz után közvetlenül `handleLoginResponse(response)` ágra megy.
- Nincs külön Google utáni személyes dolgozóválasztó képernyő.
- Nincs Google utáni személyes jelszóbekérő képernyő.

### Backend

Érintett fájlok:

- `backend/src/main/java/hu/puzzleir/valuta/controller/GoogleAuthController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/GoogleLoginService.java`
- `backend/src/main/java/hu/puzzleir/valuta/repository/WorkerRepository.java`
- `backend/src/main/java/hu/puzzleir/valuta/entity/Worker.java`

Tények:

- `POST /api/v1/auth/google-login` publikusan elérhető.
- `GoogleLoginService` ellenőrzi a Google ID tokent.
- Ezután `WorkerRepository.findGoogleLoginCandidatesByEmail(canonicalEmail)` alapján keres `Worker` rekordot.
- A lookup feltételei: `googleLoginEnabled = true` és `LOWER(w.email) = LOWER(:email)`.
- Ha nincs találat: belépés elutasítva.
- Ha több találat van: konfigurációs hiba (`ConflictException`).
- Ha pontosan egy találat van: a backend ezt a `Worker` rekordot lépteti be.
- Első Google login esetén a Google `sub` claim ráíródik a worker `googleSubject` mezőjére, ha engedélyezett.
- A JWT és `WorkerSession` ehhez az egy workerhez készül.

Következtetés: a jelenlegi Google login modell email -> egyetlen worker. Nem támogatja azt, hogy egy intézményi Google-fiók mögött több személyes dolgozó közül válasszon a felhasználó.

## Kóddal igazolt adatminta Szegedre

Érintett migráció:

- `backend/src/main/resources/db/migration/V179__google_login_employee_seed.sql`

Kóddal igazolt seed:

```sql
('G_SZEGED_ET', 'Szeged Ertektar', ..., 'szeged.ebc@gmail.com', true, ...)
```

Ugyanez a migráció `G_SZEGED_ET` workerhez `ertektar` canonical role-t rendel:

```sql
WHERE w.code IN (..., 'G_SZEGED_ET', ...)
  AND r.code = 'ertektar'
```

Következtetés: a képernyőképen látható `ID: G_SZEGED_ET` nem valós személyt azonosít, hanem intézményi értéktár-fiókot. Ez alátámasztja a felhasználói panaszt, hogy a műveletek nem köthetők személyhez.

## Meglévő modell, amit nem szabad figyelmen kívül hagyni

Érintett fájlok:

- `backend/src/main/java/hu/puzzleir/valuta/entity/Worker.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/WorkerService.java`
- `backend/src/main/java/hu/puzzleir/valuta/controller/WorkerController.java`
- `backend/src/main/resources/db/migration/V2__create_worker_tables.sql`
- `backend/src/main/resources/db/migration/V178__worker_google_login_whitelist.sql`

Tények:

- A `worker` tábla már létezik.
- A `Worker` entitás tartalmaz:
  - `company`
  - `code`
  - `name`
  - `passwordHash`
  - `role`
  - `branch`
  - `active`
  - `email`
  - `googleSubject`
  - `googleLoginEnabled`
  - `googleLinkedAt`
  - `googleLastLoginAt`
- A `WorkerService.createWorker()` bcrypt-tel hasheli a jelszót.
- A `WorkerService.login()` jelszavas belépést és 5 hibás próbálkozás utáni 15 perces lockoutot tartalmaz.
- A lockout jelenleg in-memory `ConcurrentHashMap`, nem adatbázis-mező.
- A `WorkerController.createWorker()` jelenleg csak `SUPERVISOR`, `MANAGER`, `ADMIN` role-oknak engedett.
- A `WorkerManagementController.resetPassword()` csak `MANAGER`, `ADMIN` role-oknak engedett.

Következtetés: a mellékelt dokumentumban javasolt új `vault_user` tábla nem kódból következő szükségszerűség. A repó jelenlegi architektúrája alapján a személyes értéktári felhasználókat célszerű a meglévő `Worker` modellben kezelni, vagy külön döntési dokumentumban kell indokolni, miért kell párhuzamos `vault_user` identitásmodell.

## Kóddal igazolt RBAC hiba a képen látható `Hozzáférés megtagadva` mögött

### Frontend menü engedi az értéktárosnak

Érintett fájl:

- `frontend-react/src/layouts/menuGroups.ts`

Az `Értéktár (lokál)` menücsoport canonical role-ja:

```ts
canonicalRoles: ERTEKTAR_ROLES
```

Az `Értéktári készlet` menüpont ugyanebben a csoportban:

```ts
{ path: "/inventory", label: "Értéktári készlet", icon: Wallet }
```

### Frontend endpoint hívás

Érintett fájl:

- `frontend-react/src/pages/inventory/InventoryPage.tsx`

Az oldal ezt hívja:

```ts
api.get<VaultStockRow[]>('/inventory/vault-stock')
```

### Backend endpoint nem engedi az `ERTEKTAR` role-t

Érintett fájl:

- `backend/src/main/java/hu/puzzleir/valuta/controller/InventoryController.java`

Jelenlegi jogosultság:

```java
@GetMapping("/vault-stock")
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'IRODAVEZETO')")
public ResponseEntity<List<VaultStockRowDto>> getVaultStock() {
    return ResponseEntity.ok(inventoryService.getVaultStockFlow());
}
```

Az `ERTEKTAR` nincs a listában.

Következtetés: a lokál értéktár menüben elérhető oldal backendje nem engedi a lokál értéktáros canonical role-t. Ez kóddal igazolt 403-forrás. Javítani kell külön is, függetlenül a kétlépcsős személyes login bevezetésétől.

## Hibák és kockázatok

### P0 - Google OAuth után nincs személyes dolgozóválasztás

**Tény:** A jelenlegi `POST /auth/google-login` egyből végleges `LoginResponseDto`-t ad vissza egyetlen workerre.

**Hatás:** Közös értéktári Google-fióknál a session `G_SZEGED_ET` jellegű intézményi workerhez tartozik. A naplózás és audit nem valós személyt mutat.

**Javítási irány:** Kétfázisú flow kell az intézményi Google-fiókokra:

1. Google ID token validálása és intézményi értéktár azonosítása.
2. Csak az adott értéktár aktív személyes dolgozóinak listázása.
3. Dolgozó kiválasztása.
4. A kiválasztott dolgozó saját jelszavának ellenőrzése.
5. A végleges JWT már a személyes `Worker` azonosítójával készüljön.

### P0 - `Értéktári készlet` endpoint nem engedi az `ERTEKTAR` role-t

**Tény:** A menü `ertektar` role-nak mutatja az oldalt, de a backend nem engedi `ERTEKTAR` szerepkörrel.

**Hatás:** A képen látható `Hozzáférés megtagadva` reprodukálhatóan magyarázható.

**Javítási irány:** Ha üzletileg az értéktáros láthatja saját értéktári készletét, a `GET /inventory/vault-stock` endpointot ki kell bővíteni `ERTEKTAR` role-lal. Ezzel együtt ellenőrizni kell, hogy a service csak az aktuális company/saját értéktári scope adatait adja-e vissza. Ha a service jelenleg országos VAULT készletet ad vissza, területi/saját vault szűrés is kell.

### P1 - Ne hozz létre párhuzamos `vault_user` táblát döntés nélkül

**Tény:** A rendszerben már van `Worker` identitásmodell jelszóval, branch-csel, sessionnel és role assignmenttel.

**Kockázat:** Egy külön `vault_user` tábla duplikálná az identitást, sessiont, jogosultságot, auditot és jelszókezelést. Ez növeli az inkonzisztencia és audit-hiány kockázatát.

**Javítási irány:** Alapértelmezett javaslat: a meglévő `Worker` modell bővítése és új auth-flow. Új tábla csak akkor készüljön, ha külön architektúra-döntés bizonyítja, hogy a `Worker` nem alkalmas.

### P1 - Új értéktári dolgozó felvitele jelenleg nem engedett `ERTEKTAR` role-nak

**Tény:** `POST /api/v1/workers` csak `SUPERVISOR`, `MANAGER`, `ADMIN` role-oknak engedett.

**Felhasználói kérés:** bármelyik bejelentkezett értéktáros vehessen fel új munkatársat.

**Javítási irány:** Új, szűkített végpont kell, nem a teljes admin worker CRUD felnyitása. A végpont csak az aktuális értéktár/branch alá hozhat létre aktív, `ertektar` szerepkörű személyes workert, és nem engedhet company/branch/role tetszőleges választást.

### P1 - Offline személyes auth nincs implementálva

**Tény:** `penztar-client/electron/sqlite.ts` tartalmaz `cached_workers` táblát, de nincs benne `password_hash`.

**Kockázat:** A mellékelt dokumentum offline jelszó-hash cache-t kér, de ez biztonsági döntés. Helyi bcrypt hash tárolása növeli az offline credential-kockázatot.

**Javítási irány:** Első iterációban online személyes azonosítás legyen. Offline auth csak külön security tervvel, titkosítással, lockouttal és revocation-stratégiával.

### P2 - Elfelejtett jelszó létezik, de nem értéktári dolgozóválasztóhoz illesztve

**Tény:** Van globális `POST /auth/forgot-password` email-alapú flow és `POST /auth/reset-password`.

**Eltérés:** A kért értéktári flow nem emailes önkiszolgáló resetet kér, hanem tájékoztatást, hogy adminisztrátortól kell segítséget kérni.

**Javítási irány:** A Google utáni személyes jelszó képernyőn elég lehet egy hu-HU tájékoztató link/modal. Backend audit esemény opcionális, de ha készül, ne fedje el a meglévő globális password-reset flow-t.

## Ajánlott célarchitektúra a meglévő kódhoz igazítva

### 1. Intézményi Google session ne legyen végleges alkalmazássession

Új backend válaszmodell javaslat:

```java
public record VaultSharedGoogleStartResponse(
    String challengeToken,
    String vaultBranchId,
    String vaultBranchCode,
    String vaultBranchName,
    List<VaultWorkerOptionDto> workers
) {}
```

Fontos:

- A `challengeToken` rövid életű legyen.
- Ne legyen teljes alkalmazás-JWT.
- Ne adjon hozzáférést üzleti API-khoz.
- A Google ID token alapján azonosított intézményi worker/branch csak a dolgozólista szűréséhez használható.

### 2. Dolgozólista a meglévő `Worker` táblából

Javasolt repository lekérdezés:

```java
@Query("""
    SELECT w FROM Worker w
    WHERE w.company.id = :companyId
      AND w.branch.id = :branchId
      AND w.active = true
    ORDER BY w.name
""")
List<Worker> findActiveByCompanyAndBranch(
    @Param("companyId") UUID companyId,
    @Param("branchId") UUID branchId
);
```

Ha az értéktár dolgozói nem ugyanarra a branch-re vannak kötve, akkor előbb az adatmodellt kell tisztázni: branch, region vagy külön worker-branch access alapján történjen-e a szűrés.

### 3. Személyes jelszó ellenőrzése után végleges JWT

Javasolt endpoint:

```http
POST /api/v1/auth/google-vault/select-worker
```

Javasolt request:

```json
{
  "challengeToken": "...",
  "workerId": 123,
  "password": "sajat-jelszo",
  "appMode": "ertektar"
}
```

Javasolt szerveroldali ellenőrzés:

```java
if (!passwordEncoder.matches(request.password(), selectedWorker.getPasswordHash())) {
    recordFailedAttempt(companyCode + ":" + selectedWorker.getCode());
    throw new AuthenticationException("Hibás jelszó.");
}
```

Javasolt véglegesítés:

- A JWT `workerId` a kiválasztott személyes worker legyen.
- `activeRole` legyen `ertektar`, ha a worker rendelkezik ilyen role assignmenttel.
- A `WorkerSession.worker` is a személyes worker legyen.
- Az intézményi Google branch/email szerepelhet audit kontextusként, de ne az legyen a user.

### 4. Új értéktári dolgozó felvitele szűkített végponttal

Javasolt endpoint:

```http
POST /api/v1/vault-workers
```

Javasolt szabályok:

- Csak `ERTEKTAR`, `FOERTEKTAR`, `UGYVEZETO`, `ADMIN` role-lal.
- `ERTEKTAR` csak saját branch/terület alá hozhat létre dolgozót.
- A request ne tartalmazzon szabad `companyId` értéket; a company a SecurityContextből jöjjön.
- A branch vagy a challenge/vault session alapján, vagy az aktuális worker branchéből jöjjön.
- Jelszó bcrypt hashként tárolódjon a meglévő `Worker.passwordHash` mezőben.
- Az új worker kapjon `ertektar` canonical role assignmentet.
- Ne kapjon automatikusan `googleLoginEnabled = true`, mert a személyes azonosítás jelszavas második lépcső.

Mintaszerű request:

```json
{
  "name": "Bali Henriett",
  "password": "ErősJelszo123",
  "passwordConfirm": "ErősJelszo123"
}
```

## Javítási utasítás AI fejlesztő ügynöknek

1. Ne kezdd új `vault_user` táblával. Először igazold, hogy a meglévő `Worker` modell elég-e. A jelen audit alapján elégségesnek tűnik.
2. Írj backend tesztet arra, hogy `G_SZEGED_ET` Google-login jelenleg intézményi workert azonosít, nem személyt. A tesztben ne használj production secretet.
3. Vezess be új kétlépcsős auth endpointot intézményi Google-fiókokra. A meglévő személyes Google-login flow-t ne törd el.
4. A dolgozóválasztó listát company + értéktár branch/scope szerint szűrd.
5. A végleges JWT-t csak személyes jelszóellenőrzés után add ki.
6. A lockoutot lehetőség szerint ne új in-memory mapben duplikáld. Ha a követelmény tartós lockoutot kér, adatbázis-mező vagy külön login-attempt tábla kell.
7. Javítsd a `/inventory/vault-stock` RBAC-ot: vagy engedd az `ERTEKTAR` role-t megfelelő scope szűréssel, vagy vedd ki a menüpontot az értéktáros lokál menüből. A felhasználói kérés és a menü alapján az engedélyezés + scope a helyes irány.
8. Készíts frontend oldalt/modal flow-t: Google siker -> dolgozólista -> jelszó -> belépés.
9. A bal alsó/felső user megjelenítés már `user.fullName` mezőt használ; ellenőrizd, hogy a végleges sessionben ez a személyes worker neve legyen, ne `Szeged Ertektar`.
10. Offline jelszó-hash cache-t ne implementálj automatikusan. Ha mégis kötelező, előbb készíts külön security tervet.

## Minimális tesztterv

Backend:

- `GoogleLoginService` vagy új auth service: intézményi Google email esetén nem ad végleges JWT-t, hanem challenge-et és dolgozólistát.
- `select-worker` siker: helyes jelszóval személyes worker JWT-t ad.
- `select-worker` hibás jelszó: 401, lockout számláló nő.
- `select-worker` cross-branch workerrel: 404 vagy 403, de ne legyen id-enumeráció.
- `POST /vault-workers`: `ERTEKTAR` csak saját értéktár alá hozhat létre workert.
- `GET /inventory/vault-stock`: `ROLE_ERTEKTAR` esetén 200, idegen company/terület adata nem szivárog.

Frontend:

- Google siker után dolgozóválasztó jelenik meg intézményi fióknál.
- Dolgozó kiválasztása után jelszómező jelenik meg.
- Hibás jelszó hu-HU hibaüzenetet mutat.
- Sikeres belépés után a header/sidebar a személyes nevet mutatja.
- `Értéktári készlet` oldal nem dob `Hozzáférés megtagadva` hibát érvényes `ERTEKTAR` sessionben.

## Javasolt célzott ellenőrzések

Frontend:

```powershell
cd frontend-react
npm test -- LoginPage
npm run typecheck
```

Backend:

```powershell
cd backend
.\mvnw.cmd test -Dtest=GoogleLoginServiceTest,InventoryControllerTest
```

Ha auth/RBAC vagy jelszókezelés módosul, a repo szabályai szerint szélesebb security ellenőrzés is indokolt:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

## Nem igazolt vagy kerülendő állítások

- Nem igazolt, hogy új `vault_user` tábla szükséges. A kód alapján a meglévő `Worker` modell már lefedi a személyes azonosító, jelszóhash, branch, session és role alapjait.
- Nem igazolt, hogy a képen látható 403 kizárólag a közös Google-fiók miatt történik. A `/inventory/vault-stock` endpoint `ERTEKTAR` hiánya önmagában kóddal igazolt 403-ok.
- Nem igazolt, hogy offline személyes jelszóbelépés jelenleg támogatott. A lokális `cached_workers` táblában nincs `password_hash`.
- Nem szabad a teljes `WorkerController` admin CRUD-ot megnyitni `ERTEKTAR` role-nak. Új, szűkített értéktári munkatárs-felvételi végpont kell.
- Nem szabad production jelszót, Google tokent vagy OAuth secretet auditba, logba vagy tesztfixture-be írni.

## Audit eredmény

A fejlesztési kérés fő állítása kóddal alátámasztott: Szegednél a közös `szeged.ebc@gmail.com` Google-fiók a `G_SZEGED_ET` intézményi workerhez kötődik, nem személyhez. A javításnak két része van: meglévő `Worker` alapú, Google utáni személyes dolgozó + jelszó választó flow, valamint a lokál értéktári `Értéktári készlet` endpoint RBAC javítása. A dokumentumban szereplő új `vault_user` tábla és offline hash-cache csak külön architektúra/security döntés után indokolt.
