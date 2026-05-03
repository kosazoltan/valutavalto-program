# Valutavalto ERP - teljes koru AI javitasi utasitaskeszlet

**Datum:** 2026-05-03  
**Repo:** `D:\repo\valutavalto-program`  
**Cel:** teljes repo-szintu feltaras alapjan vegrehajthato javitasi terv masik mesterséges intelligencia ugynoknek.  
**Allapot:** audit/javitasi utmutato, nem merge-ready allitas.

## 0. Hatokor es modszer

Az elemzes repo-szintu indexelessel, konfiguracio-olvasassal, memoriak skimelesével, majd celzott forrasolvasassal keszult. A feltaras erintette:

- backend: Spring Boot, security, controller, service, repository, DTO, entity, Flyway migraciok
- frontend: `frontend-react`, React 19, TypeScript, API kliens, route/service retegek
- Electron penztar: `penztar-client/electron`, IPC, SQLite, sync-engine, kamera, scanner, video, printer
- shared contractok: `packages/shared-api`, `packages/shared-ipc`
- adatbazis: `backend/src/main/resources/db/migration`
- memoriak es projekt-alkotmany: `AI_CONSTITUTION.md`, `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `.remember/remember.md`, `D:\valutavalto-vault`

Figyelmen kivul hagyando zaj: generalt build outputok, `node_modules`, `target`, regi worktree/cache mappak. A repo-ban a `.memory` jellegu regi rendszerek deprecated-ek; az aktiv memoriaforras a `D:\valutavalto-vault`.

## 1. Kotelezo ugynoki szabalyok

1. Kezdeskor futtasd:

   ```powershell
   git status --short --branch
   ```

   Ne irj felul es ne revertelj olyan valtozast, amit nem te keszitettel. A jelen feltaraskor mar volt egy fuggetlen modositas:

   ```text
   M penztar-client/test-results/.last-run.json
   ```

2. Olvasd be ebben a sorrendben:

   ```text
   AI_CONSTITUTION.md
   AGENTS.md
   CLAUDE.md
   CODEX.md
   .remember/remember.md
   D:\valutavalto-vault\README.md
   D:\valutavalto-vault\sessions\legfrissebb-*.md
   D:\valutavalto-vault\feedback\*.md
   docs\LESSONS_LEARNED.md
   ```

3. Javitas elott irj vagy modosits tesztet. Minden P0 javitas utan legalabb lint + typecheck + relevans unit/integration teszt kell.

4. Ne hasznalj ad-hoc validaciot, ha a repo-ban mar van ipari standard megoldas. Frontend/Electron validaciora preferalt: Zod. Backend oldalon preferalt: Bean Validation DTO-kon, typed enumok, repository szintu tenant scope.

5. Titkot, tokent, jelszot, production adatot ne irj fajlba. A reportban leirt ellenorzesek nem jogositanak production adat lekerdezesere.

## 2. Aktualis architektura terkep

### Backend

- Java 21, Spring Boot 4.0.6 parent, Spring Security 6.5.10, PostgreSQL, Flyway.
- Controller retegek: `backend/src/main/java/hu/puzzleir/valuta/controller`.
- Repo-szintu meres: 145 controller annotalt osztaly, 1009 mapping annotacio.
- Kritikus domain: auth/JWT, tranzakcio, konverzio, sztorno, cash balance, daily session, AML, NGM/riportok, ertektar, cash register, kamera/video, sync/offline restore.

### Frontend

- `frontend-react`: React 19.2.5, Vite 8.0.7, TypeScript strict.
- API kliens: `frontend-react/src/services/api/client.ts`.
- Domain API modulok: `frontend-react/src/services/api/*.ts`, kulonosen `transactions.ts`.
- Allapot: web token jelenleg `localStorage`-ben, silent refresh interceptorral.

### Electron penztar

- `penztar-client/electron`: main process mint lokalis backend.
- Renderer/web UI elv: `frontend-react` kod fusson webben es Electronban is; Electron csak SQLite/sync/nyomtatas/kamera/szkenner lokalis szolgaltato.
- IPC valosag: 75 `ipcMain.handle(...)` channel.
- Shared contract valosag: `packages/shared-ipc/src/index.ts` csak 3 route-ot definial. Ez szerzodes-drift.

### Adatbazis

- Flyway migraciok szama: 171.
- Jelentos index-migraciok: peldaul `V80__critical_missing_indexes.sql`, `V155__add_version_and_unique_constraints.sql`.
- Production Flyway: `application-production.properties` out-of-order false, validate true, de `repair-on-migrate=true` meg aktiv.

## 3. Gepi ellenorzesek, 2026-05-03

Ezek az elemzes keszitese kozben lefutottak:

```powershell
npm --prefix frontend-react run typecheck
npm --prefix penztar-client run typecheck
npm --prefix frontend-react run lint
npm --prefix penztar-client run lint
.\mvnw.cmd -q -DskipTests compile   # backend mappaban
```

Eredmeny:

- Frontend typecheck: PASS
- Electron typecheck: PASS
- Backend compile skipTests: PASS
- Frontend lint: 0 error, 1 warning
  - `frontend-react/src/pages/transactions/CashierTransactionPage.tsx:512` missing dependency: `openReceiptModal`
- Electron lint: 0 error, 1 warning
  - `penztar-client/electron/scanner.ts:34` explicit `any`

Nem futott: teljes backend test suite, frontend/electron unit suite, Playwright/e2e, security gate, GitHub review gate.

## 4. P0 - azonnal javitando hibak

### P0.1 Frontend silent refresh rossz endpointot hiv

**Bizonyitek:** `frontend-react/src/services/api/client.ts:157-195`

Jelenleg 401 utan az interceptor ezt hivja:

```ts
api.post('/auth/refresh')
```

A backend `POST /api/v1/auth/refresh` authentikalt endpoint, ez lejart access tokennel nem alkalmas silent refreshre. A HttpOnly cookie-s flow helyes endpointja: `POST /api/v1/auth/refresh-cookie`.

**Javitas:**

- `client.ts` interceptorban valtani `/auth/refresh-cookie`-ra.
- Zard ki retry/refresh alol mindket refresh endpointot: `/auth/refresh`, `/auth/refresh-cookie`.
- Tartsd meg `withCredentials: true`.
- Adj tesztet: lejart token + refresh cookie eseten uj access token bekerul; refresh failure eseten token clear + redirect/auth state reset.

**Elfogadas:**

```powershell
npm --prefix frontend-react run typecheck
npm --prefix frontend-react run test -- --run client
npm --prefix frontend-react run lint
```

### P0.2 Refresh cookie Secure flag proxy mogott hibasan lehet false

**Bizonyitek:** `backend/src/main/java/hu/puzzleir/valuta/controller/AuthController.java:88-91`, `:190-191`; nincs `server.forward-headers-strategy` beallitas.

`ResponseCookie.secure(request.isSecure())` reverse proxy mogott hamis false lehet, ha a forward headerek nincsenek bekapcsolva.

**Javitas:**

- Production profilban allitsd be:

  ```properties
  server.forward-headers-strategy=framework
  ```

- Productionban a refresh cookie `secure=true` legyen akkor is, ha a belso request HTTP.
- Adj integracios/security tesztet proxy headerrel.

### P0.3 Refresh token lookup O(osszes aktiv token) + BCrypt minden tokenre

**Bizonyitek:** `backend/src/main/java/hu/puzzleir/valuta/controller/AuthController.java:166-168`

`refreshTokenRepository.findAll().stream().filter(BCrypt.matches(...))` skala- es DoS-kockazat. Minden refresh cookie keres minden aktiv tokent.

**Javitas:**

- Vezess be refresh token selector/verifier mintat:
  - cookie: `selector.rawSecret`
  - DB: indexed `selector_hash` vagy unique selector, plusz `token_value_hash`
  - lookup selector alapjan, majd csak egy BCrypt/Argon2 verify
- Legyen DB index/unique constraint a selectoron.
- Rotation maradjon: regi token revoke, uj issue.
- Rate limiteld kulon a `/auth/refresh-cookie` endpointot.

**Elfogadas:**

- Unit teszt: valid cookie 1 indexed lookup.
- Unit teszt: random cookie nem okoz `findAll`.
- Terheles teszt: 10k token mellett refresh latency stabil.

### P0.4 JWT permission claim nincs GrantedAuthority-va alakitva

**Bizonyitek:**

- `JwtTokenProvider.java:88-89` tokenbe teszi a `permissions` claimet.
- `JwtAuthenticationFilter.java:74` csak `ROLE_...` authority-t ad.
- Egyes endpointok `hasAnyAuthority('VIDEO_EXPORT', ...)` stilusu ellenorzest hasznalnak.

**Hatas:** permission alapu endpointok jogos felhasznaloknak is 403-at adhatnak.

**Javitas:**

- A JWT `permissions` claimet olvasd ki es add hozza `SimpleGrantedAuthority(permission)` formaban.
- Maradjon a role authority is: `ROLE_ADMIN`, stb.
- Teszt: token `permissions=["VIDEO_EXPORT"]` eseten `@PreAuthorize("hasAuthority('VIDEO_EXPORT')")` atmegy.
- Teszt: permission nelkuli token 403.

### P0.5 IdempotencyGuard in-memory, payload hash nelkul, cleanup hiba

**Bizonyitek:** `backend/src/main/java/hu/puzzleir/valuta/util/IdempotencyGuard.java:22-88`

Problemak:

- Csak process-memory, multi-instance es restart utan elveszik.
- `completedResults` nem kap timestampet, cleanup mindig `false`, tehat novekvo memory leak.
- Az idempotency key nincs request payload hashhez kotve: ugyanaz a key mas body-val is regi eredmenyt adhat.
- Logban nyers idempotency key jelenik meg.

**Javitas:**

- Hozz letre perzisztens idempotency tablat vagy Redis store-t.
- Kulcs: tenant/company + worker/cash-register + endpoint + idempotency_key.
- Tarolj: request hash, status, response summary/body, created_at, expires_at.
- Ugyanaz key + mas payload hash: 409 Conflict.
- In-progress timeout kezelese.
- Nyers key logolasa helyett hash/prefix.

**Elfogadas:**

- Teszt: dupla azonos request csak egyszer hajtja vegre a domain muveletet.
- Teszt: ugyanaz key mas payload -> 409.
- Teszt: restart utan is mukodik.
- Teszt: TTL cleanup torli a regi entryket.

### P0.6 Filterek dupla regisztracios kockazata

**Bizonyitek:**

- `JwtAuthenticationFilter`, `IdempotencyFilter`, `ProductionCorsFilter` `@Component`.
- `SecurityConfig.java:117-123` ugyanazokat manualisan hozzaadja a security chainhez.

Spring Boot servlet filter beaneket automatikusan is regisztralhat. Ez ordering/dupla futas kockazat.

**Javitas:**

- Donts: vagy csak SecurityFilterChain kezeli oket, vagy servlet filterkent futnak.
- Ha SecurityFilterChainben maradnak, adj `FilterRegistrationBean<...>` beaneket `setEnabled(false)`-szal az auto-registration tiltashoz.
- Teszt: egy request alatt minden filter pontosan egyszer fut.

### P0.7 CashBalanceService startup/async SecurityContext bug

**Bizonyitek:**

- `CashBalanceService.java:132-150`
- `SecurityUtils.getCurrentCompanyId()` `ValidationException`-t dob, nem `IllegalStateException`-t.

A komment szerint startup/async SecurityContext nelkul megengedett, de a catch rossz exception tipust fog.

**Javitas:**

- `SecurityUtils` kapjon `getCurrentCompanyIdOrNull()` segedfuggvenyt, vagy a service fogja a `ValidationException`-t is.
- Branch company mismatch validacio maradjon authentikalt kontextusban.
- Teszt: `initializeBranchBalances(branchId)` SecurityContext nelkul sikeres.
- Teszt: authentikalt masik company branch-re ValidationException.

### P0.8 Konverzio harom completed Transaction sort hoz letre

**Bizonyitek:** `TransactionConversionService.java:111-194`

A konverzio jelenleg:

- parent `CONVERSION` transaction
- completed BUY receipt
- completed SELL receipt

Ez riportokban, KPI-ban, receipt listakban, AML/NGM exportban dupla/tripla szamolast okozhat, ha minden query nem explicit szuri a parentet.

**Javitas:**

- Domain dontes kell, de preferalt modell:
  - vagy csak ket penzugyi transaction sor legyen, kozos `conversion_group_id`-vel,
  - vagy a parent legyen `INTERNAL`/non-financial statusu es minden riport alapertelmezetten zarja ki.
- Migracio: vezess be `conversion_group_id`, `financial_effective boolean`, vagy hasonlo explicit mezot.
- Frissits minden riportot:
  - daily/session reports
  - receipt export
  - AML
  - NB/NGM/TRB report
  - cash-balance reconciliation

**Elfogadas:**

- Egy EUR->USD konverzio pontosan egyszer mozgatja a forint ellenoldalt.
- Receipt nyomtatasban ket bizonylat jelenik meg, nem harom penzugyi tetel.
- Daily report nem tripla forgalmat mutat.

### P0.9 Electron scanner/camera IPC path hardening

**Bizonyitek:**

- `penztar-client/electron/scanner.ts:60-87`
- `penztar-client/electron/camera.ts:78-88`

Problemak:

- `scan-get-document`: `resolved.startsWith(path.resolve(SCAN_DIR))` nem eleg; Windows alatt `C:\valuta\scan_evil\...` prefixkent atcsuszhat.
- `scan-save-document`: `documentType` TypeScript union, de runtime allowlist nincs; IPC input untrusted.
- `camera-save-recording`: `extension` nincs runtime allowlistelve, fajlnevbe kerul.

**Javitas:**

- Hasznalj kozponti helper-t:

  ```ts
  function assertInsideBase(resolved: string, base: string): void {
    const baseResolved = path.resolve(base)
    if (resolved !== baseResolved && !resolved.startsWith(baseResolved + path.sep)) {
      throw new Error('Invalid path')
    }
  }
  ```

- `documentType` runtime allowlist: `szemelyi|utlevel|jogositvany|egyeb`.
- `extension` runtime allowlist: `mp4|webm`; ne engedj slash, backslash, dotdot karaktereket.
- Teszteld sibling prefix tamadassal: `C:/valuta/scan_evil/file.enc`.
- Teszteld path traversal payloadokkal: `../`, `..\\`, `a/b`, `a\\b`.

### P0.10 Production Flyway repair-on-migrate maradek kockazat

**Bizonyitek:** `backend/src/main/resources/application-production.properties:40-48`

`spring.flyway.repair-on-migrate=true` productionban egy korabbi V174 incidens utan ideiglenes workaroundkent maradt bent.

**Javitas:**

- Ellenorizd production schema_history allapotat.
- Kontrollalt egyedi repair utan vedd ki `repair-on-migrate=true`-t production profilbol.
- Adj CI smoke tesztet: minden migracio entity table neve valos.
- A V174-incidens miatt kotelezo: migration iras elott entity `@Table` validacio.

## 5. P1 - kovetkezo sprintben javitando

### P1.1 Shared IPC contract legyen tenyleges single source of truth

**Bizonyitek:** `packages/shared-ipc/src/index.ts` 3 route-ot tartalmaz, mikozben Electronban 75 channel van.

**Javitas:**

- Minden `ipcMain.handle` channel keruljon `IpcRoutes` ala.
- `preload.ts` csak `IPC_CHANNELS` konstansbol hivjon.
- Adj tesztet, ami osszeveti:
  - `ipcMain.handle('...')`
  - `ipcRenderer.invoke('...')`
  - `IPC_CHANNELS`
- Hibazzon CI-ben drift eseten.

### P1.2 Frontend dead/missing endpoint adossag

**Bizonyitek:** `frontend-react/src/services/api/transactions.ts:1003-1068`, `:282`

Problemak:

- `shipmentRequestApi.create()` es `prepare()` direkt throw, mert backend endpoint nincs.
- `findByBranch` client-oldali full page fetch + filter.
- `reject` `/cancel` endpointot hasznal audit szempontbol nem azonos jelentesre.
- `transactionApi.getReceipt` `/transactions/{id}/receipt` hivasat egyeztesd backend route-tal.

**Javitas:**

- Vagy implementald a backend endpointokat, vagy torold/feature-flageld a frontend API-t.
- Native backend filter: `/shipments?branchId=...`.
- Dedikalt reject endpoint audit traillel.
- OpenAPI typegen utan frontend service-eket igazitsd.

### P1.3 Refresh/access token tarolas modernizalasa

**Bizonyitek:** `frontend-react/src/services/api/client.ts:16`, `:250-316`

Web access token `localStorage`-ben van. Ez XSS eseten token exfiltration.

**Javitas:**

- Weben in-memory access token + HttpOnly refresh cookie.
- Electronban secure storage / IPC auth-token boundary.
- Oldal reload utan `/auth/refresh-cookie` bootstrap.
- CSP es XSS hardening ellenorzes.

### P1.4 Rate limiting es X-Forwarded-For kovetkezetesseg

**Bizonyitek:** `RateLimitFilter` trusted proxy listat hasznal; `RefreshTokenService.clientIp` siman olvas `X-Forwarded-For`-t.

**Javitas:**

- Egyetlen `ClientIpResolver` komponens legyen.
- Csak trusted proxybol fogadd el az XFF-et.
- Multi-instance esetben in-memory rate limit helyett Redis/bucket4j/edge rate limit.

### P1.5 React Hooks lint debt

**Bizonyitek:** frontend lint warning: `CashierTransactionPage.tsx:512`; ESLint configban tobb React Hooks rule ki van kapcsolva.

**Javitas:**

- Eloszor javitsd az aktualis exhaustive-deps warningot.
- Modulonkent kapcsold vissza:
  - `react-hooks/set-state-in-effect`
  - `react-hooks/immutability`
  - `react-hooks/refs`
  - `react-hooks/static-components`
  - `react-hooks/purity`
- Minden kapcsolashoz celzott teszt/smoke.

### P1.6 Schema/index governance

**Bizonyitek:** 171 migration, sok `IF NOT EXISTS`/repair jellegu minta, V174 incidens.

**Javitas:**

- Uj migraciokhoz kotelezo preflight:
  - entity `@Table` nev egyezes
  - column nev egyezes
  - local Flyway clean/migrate teszt tesztadatbazison
  - production baseline drift check
- Ne hasznalj idempotens DDL-t drift elrejtesere. `IF NOT EXISTS` csak dokumentalt repair migrationben.
- Company-scoped tablakat ellenorizd: minden multi-tenant queryben explicit `company_id`.

### P1.7 Offline/sync szerzodes es server registration

**Bizonyitek:** vault feedback `cash-register-architecture.md`, `electron-architecture.md`; `first-run.ts` mar reszben kezeli.

**Javitas:**

- SetupWizard online regisztracio failure ne legyen nem-blokkolo full telepitesnel.
- Ha `offline_mode=true` vagy nincs `server_url`, SyncEngine ne inditson halozati ciklust. Ez reszben megvan, de legyen regresszios teszt.
- `cash_register_device_id` nelkul heartbeat/upload explicit degraded allapot.

### P1.8 OpenAPI es typed API contract

**Javitas:**

- Backend OpenAPI legyen CI artifact.
- `packages/shared-api` typegen minden backend route valtozasnal fusson.
- Frontend service-ek ne kezzel tippeljenek DTO-t, ahol OpenAPI tipus elerheto.

## 6. P2 - modernizacio es karbantarthatosag

### P2.1 `as any` es explicit `any` nullara csokkentese production kodban

Aktualis linter jelzes:

- `penztar-client/electron/scanner.ts:34` catch `e: any`

**Javitas:**

```ts
} catch (e: unknown) {
  if (e && typeof e === 'object' && 'code' in e && e.code === 'EEXIST') { ... }
}
```

Teszt: scanner key creation EEXIST branch.

### P2.2 `skipLibCheck` es TypeScript verzio drift

Frontend TypeScript 5.2.2, Electron TypeScript 5.7.3. `skipLibCheck` pragmatikus, de verzio driftet eltakarhat.

**Javitas:**

- Havi CI job: `skipLibCheck=false` probafuttatas.
- TS verzio osszehangolas root workspace szinten.

### P2.3 Electron build script robusztussag

`penztar-client/vite.config.ts` dev ASAR/copy/exec logikaja torik, ha path quoting, stale file vagy workspace drift van.

**Javitas:**

- ASAR csomagolast kulon scriptbe vinni.
- `npx asar pack` shell string helyett Node API vagy explicit argv.
- Dev helperhez teszt: space/ekezetes path.

### P2.4 TODO/FIXME backlog ticketelese

Kiemelt TODO-k:

- forgot-password email kuldes productionben
- POS provider live driver
- LED driver / Electron IPC bridge
- shipment backend native filter/reject

Minden TODO kapjon issue-t vagy torlesre keruljon, ha mar nem aktualis.

## 7. Backend API route audit utmutato

Mivel a controller mappingek szama nagy, az ugynok eloszor generalt route inventoryt keszitsen:

```powershell
rg -n "@RequestMapping|@GetMapping|@PostMapping|@PutMapping|@PatchMapping|@DeleteMapping" backend/src/main/java/hu/puzzleir/valuta/controller > docs/generated-route-inventory.txt
```

Utana kategorizald:

- Auth: login, role selection, refresh, refresh-cookie, password reset, bootstrap, first-time setup.
- Transaction: buy, sell, conversion, reversal, receipt, idempotency.
- Cash/session: balances, branch balances, daily opening/closing.
- AML/compliance: AML reports, sanctions, customer checks, NB/NGM/TRB exports.
- Treasury/ertektar: shipments, transfers, distributions, stocktake, vault territory.
- Admin master data: branch, worker, role/permission, company, rates.
- Electron/offline: cash register device, sync inbox/outbox, restore, heartbeat.
- Camera/video/scanner: export, local audit, encryption, retention.
- Health/public: bootstrap-status, public branches, actuator.

Minden route-hoz ellenorizd:

- Van-e `@PreAuthorize`.
- Van-e explicit company/branch scope.
- POST/PUT/PATCH/DELETE kap-e idempotency kezelest, ahol penzugyi hatasa van.
- DTO-n van-e Bean Validation.
- Response DTO nem szivarogtat-e entityt vagy titkot.
- Frontend service pontosan ugyanazt az endpointot hivja-e.

## 8. Adatbazis/schema/index javitasi lista

1. Flyway production cleanup:
   - `repair-on-migrate=true` eltavolitasa kontrollalt repair utan.
   - V174 postmortem tanulsag beemelese migration checklistbe.

2. Idempotency tabla:
   - `company_id`, `actor_id`, `endpoint`, `idempotency_key`, `request_hash`, `status`, `response_json`, `created_at`, `expires_at`
   - unique index: `(company_id, endpoint, idempotency_key)`
   - TTL cleanup job.

3. Refresh token selector:
   - selector indexed unique
   - verifier hash
   - revoked/expired index
   - device/user metadata.

4. Conversion model:
   - `conversion_group_id`
   - `financial_effective`
   - report filter indexek.

5. Multi-tenant query audit:
   - minden repository methodban explicit `company_id`
   - branch-id-only lookup csak akkor engedett, ha elotte company ownership validalt.

6. Index audit:
   - tranzakcio report queryk: `(company_id, branch_id, transaction_date, status)`
   - receipt lookup: unique/partial index branch+date+receipt
   - sync outbox/inbox: status+created_at+device/company
   - shipment/vault: territory+branch+status+created_at.

## 9. Electron IPC hardening checklist

Minden IPC handlerre:

- Runtime Zod/allowlist validacio, nem csak TypeScript tipus.
- Path parameterekre `path.resolve` + `base + path.sep` ellenorzes.
- Renderer soha ne adhasson arbitrary output pathot privileged irashoz.
- Large Buffer inputra meretlimit.
- Minden file export/decrypt audit log.
- Channel nev csak shared IPC contractbol.
- Teszt: channel uniqueness, path traversal, oversized payload, invalid enum, unauthorized state.

Kritikus kezdo file-ok:

```text
penztar-client/electron/main.ts
penztar-client/electron/preload.ts
penztar-client/electron/scanner.ts
penztar-client/electron/camera.ts
penztar-client/electron/video-manager.ts
penztar-client/electron/sync-engine.ts
packages/shared-ipc/src/index.ts
```

## 10. LSP/lint/type safety utmutato

Kotelezo parancsok minden javitasi csomag utan:

```powershell
npm --prefix frontend-react run typecheck
npm --prefix penztar-client run typecheck
npm --prefix frontend-react run lint
npm --prefix penztar-client run lint
cd backend; .\mvnw.cmd -q -DskipTests compile
```

P0 backend javitas utan:

```powershell
cd backend
.\mvnw.cmd test
```

P0 frontend/Electron javitas utan:

```powershell
npm --prefix frontend-react test -- --run
npm --prefix penztar-client test -- --run
```

Tiltott uj kod:

- `as any`
- `@ts-ignore`
- `@ts-nocheck`
- nyers `catch (e: any)`
- silent catch
- shell string concat inputbol
- path traversal
- SQL string concat user inputbol
- hard-coded secret

## 11. Javasolt vegrehajtasi sorrend

### Phase 0 - baseline freeze

1. `git status`.
2. Route inventory generalas.
3. OpenAPI snapshot/typegen.
4. Teljes lint/typecheck/backend compile.
5. Minimum smoke: login + refresh-cookie + protected endpoint.

### Phase 1 - auth/security P0

1. Frontend `/auth/refresh-cookie` fix.
2. Backend forward headers + secure cookie.
3. Refresh token selector lookup.
4. JWT permission authorities.
5. Filter registration cleanup.

### Phase 2 - financial correctness P0

1. Persistent idempotency guard.
2. CashBalanceService SecurityContext fix.
3. Conversion financial model fix.
4. Report/receipt/AML regression tests.

### Phase 3 - Electron hardening

1. Scanner/camera path and enum allowlist.
2. Shared IPC contract full coverage.
3. Sync/offline registration tests.
4. Electron security tests.

### Phase 4 - schema and migration governance

1. Flyway repair-on-migrate eltavolitas.
2. Migration preflight.
3. Index/query audit.
4. Multi-tenant repository audit.

### Phase 5 - modernization

1. React Hooks lint debt.
2. TypeScript version alignment.
3. `any` debt cleanup.
4. TODO backlog issue/ticket cleanup.

## 12. Vegso elfogadasi kapuk

Az ugynok csak akkor mondhatja, hogy egy javitasi csomag kesz, ha:

- `git diff` csak a tervezett fajlokat erinti.
- Frontend typecheck PASS.
- Electron typecheck PASS.
- Backend compile PASS.
- Lint 0 error; uj warning nincs.
- Relevans unit/integration tesztek PASS.
- Penzugyi P0-nal riport/receipt/cash-balance regresszios teszt PASS.
- Electron P0-nal path traversal es invalid enum teszt PASS.
- Security gate futott, ha auth/IPC/file/security valtozas tortent.
- GitHub PR eseten Codex/Sourcery P0/P1/P2 findingek lekerdezve es kezelve.

## 13. Gyors parancsok kovetkezo ugynoknek

```powershell
cd D:\repo\valutavalto-program
git status --short --branch
rg -n "as any|: any|@ts-ignore|@ts-expect-error|TODO|FIXME" frontend-react/src penztar-client/electron packages backend/src/main/java
rg -n "findAll\(\).*refresh|BCrypt|refresh-cookie" backend/src/main/java/hu/puzzleir/valuta
rg -n "SimpleGrantedAuthority|permissions|hasAnyAuthority|hasAuthority" backend/src/main/java/hu/puzzleir/valuta
rg -n "ipcMain\.handle|ipcRenderer\.invoke|contextBridge" penztar-client/electron packages/shared-ipc/src
rg -n "repair-on-migrate|out-of-order|baseline-version" backend/src/main/resources
```

Ezutan a Phase 1 P0.1 javitassal kezdj, mert az auth refresh hiba kis teruletu, gyorsan tesztelheto, es unblockolja a web session stabilitasat.
