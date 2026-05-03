# Valutavalto ERP - frissitett teljes koru AI javitasi utasitaskeszlet

> **STATUS** (2026-05-03 utan): Ez az audit doksi a 2026-05-03-i sprint
> KIINDULASI bazisa volt. A P0/P1 reszek tobbsege azota MEGOLDODOTT
> a PR #351-#368 sorozatban. Az ide leirt P0.3 (refresh token findAll/stream),
> Google OAuth implementacio, audit-P0.* tipusu szakaszok mar lefedve.
> A kovetkezo agent: ezt historic baseline-kent olvasd, validald a
> `git log origin/main`-bol mi van mar elvegezve.

**Datum:** 2026-05-03  
**Repo:** `<repo-root>` (a doksi a `docs/` mappaban van — minden hivatkozas a repo-rootbol indul)  
**Kimenet celja:** letoltheto, onalloan vegrehajthato javitasi utasitas mesterséges intelligencia ugynoknek.  
**Forras:** mai session ujraolvasas + repo index + memoriak + statikus ellenorzes + korabbi 2026-05-03 reportok.  
**Nem allitas:** ez nem merge-ready/deploy-ready bizonyitek; ez javitasi terv es audit baseline.

## 0. Mai session artefaktumai

Ebben a sessionben korabban ket kulon MD keszult:

```text
docs/AI_AGENT_FULL_REPAIR_INSTRUCTIONS_2026-05-03.md
docs/AI_AGENT_GOOGLE_OAUTH_LOGIN_IMPLEMENTATION_2026-05-03.md
```

Ez a mostani fajl ezek frissitett, osszevont, vegrehajtasi sorrendbe rendezett valtozata. A kovetkezo ugynok olvassa mindharmat, de **ez legyen a primary checklist**.

Aktualis `git status` a frissites idejen:

```text
## feat/v2.5.4-admin-unlock-endpoint-and-precise-login-error...origin/feat/v2.5.4-admin-unlock-endpoint-and-precise-login-error [gone]
 M penztar-client/test-results/.last-run.json
?? docs/AI_AGENT_FULL_REPAIR_INSTRUCTIONS_2026-05-03.md
?? docs/AI_AGENT_GOOGLE_OAUTH_LOGIN_IMPLEMENTATION_2026-05-03.md
?? docs/AI_AGENT_FULL_REPAIR_INSTRUCTIONS_2026-05-03_REFRESHED.md
```

**Utasitas:** `penztar-client/test-results/.last-run.json` nem altalam keszult valtozas. Ne reverteld, ne takaritsd ki automatikusan.

## 1. Repo meret es friss statikus terkep

Friss meres:

```text
tracked files: 5532
backend/frontend/electron/packages source files: 1435
Java files: 1284
TSX files: 178
TS files: 124
SQL migrations tracked: 181
Flyway migration files under backend/resources: 171
controller mapping annotations: 1009
controller classes: 145
Electron ipcMain.handle channels: 75
shared-ipc declared routes: 3
CREATE TABLE occurrences: 208
CREATE INDEX / CREATE UNIQUE INDEX occurrences: 464
as any / : any / <any> hits in source/test scope: 24
TODO/FIXME/eslint-disable/ts-expect-error style debt hits: 29
Flyway IF NOT EXISTS / repair / out-of-order style hits: 668
```

## 2. Friss ellenorzesi eredmenyek

Futtatott parancsok:

```powershell
npm --prefix frontend-react run typecheck
npm --prefix penztar-client run typecheck
npm --prefix frontend-react run lint
npm --prefix penztar-client run lint
cd backend; .\mvnw.cmd -q -DskipTests compile
```

Eredmeny:

- Frontend typecheck: PASS
- Electron typecheck: PASS
- Backend compile `-DskipTests`: PASS
- Frontend lint: 0 error, 1 warning
- Electron lint: 0 error, 1 warning

Warningok:

```text
frontend-react/src/pages/transactions/CashierTransactionPage.tsx:512
React Hook useCallback has a missing dependency: 'openReceiptModal'

penztar-client/electron/scanner.ts:34
Unexpected any. Specify a different type
```

Nem futott:

- teljes backend test suite
- teljes frontend/electron test suite
- Playwright e2e
- security gate
- GitHub/Codex/Sourcery review gate
- production smoke

## 3. Kotelezo ugynoki alapelvek

1. Eloszor olvasd (a `*` opcionalis ha nem letezik a fajlrendszereden):

   ```text
   AI_CONSTITUTION.md
   AGENTS.md
   CLAUDE.md
   CODEX.md
   .remember/remember.md             (* opcionalis - gitignored, lokalis handoff)
   D:\valutavalto-vault\README.md    (* opcionalis - lokalis Obsidian vault)
   D:\valutavalto-vault\sessions\legfrissebb-*.md
   D:\valutavalto-vault\feedback\*.md
   docs/LESSONS_LEARNED.md
   ```

2. A vault az egyetlen aktiv memoria:

   ```text
   D:\valutavalto-vault
   ```

3. Production-first:

   - lokalis DB seed nem lehet olyan, ami productionben nincs migracioval,
   - production adatot ne hasznalj tesztadatkent,
   - titkot ne irj repo-ba,
   - minden DB adatjavitas Flyway migration vagy explicit production runbook.

4. Minden javitas tesztkapuhoz kotott:

   - lint,
   - typecheck,
   - unit/integration test,
   - build,
   - security review, ha auth/IPC/file/DB erintett.

5. GitHub PR eseten:

   - Codex/Sourcery review query kotelezo,
   - P0/P1/P2 findinget kezelni kell,
   - nem lehet "kesz" bizonyitek nelkul.

## 4. Architektura osszefoglalo

### Backend

```text
backend/src/main/java/hu/puzzleir/valuta
  config
  controller
  dto
  entity
  errorlog
  exception
  mapper
  repository
  security
  service
  util
```

Fobb technologiak:

- Java 21
- Spring Boot 4.0.6
- Spring Security 6.5.x
- JPA/Hibernate
- PostgreSQL
- Flyway
- JWT + refresh token
- Google API/Gmail dependencyk

### Frontend

```text
frontend-react/src
  components
  config
  contexts
  features
  hooks
  i18n
  layouts
  pages
  services
  stores
  types
  utils
```

Fobb technologiak:

- React 19
- Vite 8
- TypeScript strict
- Zustand
- TanStack Query
- Axios
- Zod reszben elerheto, de nem mindenhol hasznalt
- `@react-oauth/google`

### Electron penztar

```text
penztar-client/electron
  main.ts
  preload.ts
  sqlite.ts
  sync-engine.ts
  scanner.ts
  camera.ts
  video-manager.ts
  printer.ts
  serial-printer.ts
  first-run.ts
```

Design-elv a vault szerint:

- Electron = lokalis backend: SQLite, sync, nyomtatas, kamera, scanner.
- UI = `frontend-react`, webben es Electronban ugyanaz a felulet.
- Offline mod csak regisztralt penztar utan lehet teljes erteku.

### Adatbazis

- PostgreSQL
- 171 backend Flyway migration
- sok repair/idempotens DDL minta
- V174 production outage tanulsag: entity table nev ellenorzese migracio elott kotelezo.

## 5. P0 kritikus javitasok

### P0.1 Frontend silent refresh rossz endpointot hiv

**Bizonyitek:** `frontend-react/src/services/api/client.ts:183`, `auth.ts:52`

Jelenleg:

```ts
api.post('/auth/refresh')
```

Ez az endpoint backend oldalon `@PreAuthorize("isAuthenticated()")`, vagyis lejart access tokennel nem jo silent refreshre. A cookie-s flow endpointja:

```text
POST /api/v1/auth/refresh-cookie
```

**Javitas:**

- `client.ts` 401 interceptor valtson `/auth/refresh-cookie`-ra.
- `authApi.refreshToken` vagy legyen atnevezve `refreshCookie`, vagy dokumentaltan csak legacy valid-token refresh.
- Zarj ki refresh loopbol:
  - `/auth/login`
  - `/auth/google-login`
  - `/auth/refresh`
  - `/auth/refresh-cookie`
- Teszteld:
  - expired access token + valid refresh cookie -> uj token,
  - refresh failure -> logout/token clear,
  - parhuzamos 401 queue helyesen oldodik.

### P0.2 Refresh cookie Secure flag proxy mogott

**Bizonyitek:** `AuthController.java` `.secure(request.isSecure())`

Reverse proxy mogott `request.isSecure()` hamis lehet, ha forward header strategia nincs bekapcsolva.

**Javitas:**

- production property:

  ```properties
  server.forward-headers-strategy=framework
  ```

- productionban refresh cookie mindig Secure legyen.
- Közös helper kell AuthController + Google login controller/service szamara.

### P0.3 Refresh token lookup O(osszes aktiv token)

**Bizonyitek:** `AuthController.java:168`

Jelenlegi minta:

```java
refreshTokenRepository.findAll().stream()
  .filter(rt -> bcrypt10.matches(rawRefresh, rt.getTokenHash()))
```

Ez skala- es DoS-kockazat.

**Javitas:**

- selector/verifier refresh token minta:
  - cookie: `selector.secret`
  - DB: indexed selector + hashed secret
- Unique index selectorre.
- Csak egy DB row verify legyen.
- Rate limit `/auth/refresh-cookie` endpointre.

### P0.4 JWT permission claim nincs authority-va alakitva

**Bizonyitek:**

```text
JwtTokenProvider.java: claims.put("permissions", permissions)
JwtAuthenticationFilter.java: SimpleGrantedAuthority("ROLE_" + role)
```

Ha controller `hasAuthority("VIDEO_EXPORT")` vagy hasonlot hasznal, jogos user is 403-at kaphat.

**Javitas:**

- `JwtAuthenticationFilter` adja hozza a permission code-okat `SimpleGrantedAuthority(permission)` formaban.
- Role authority maradjon.
- Teszt:
  - permission claim -> `hasAuthority` atmegy,
  - permission nelkul -> 403.

### P0.5 Google OAuth/OIDC dolgozoi login production hardening

**Bizonyitek:**

```text
backend/src/main/java/hu/puzzleir/valuta/controller/GoogleAuthController.java
frontend-react/src/pages/auth/LoginPage.tsx
frontend-react/src/services/api/auth.ts
backend/src/main/resources/db/migration/V162__google_oauth_whitelist_emails.sql
```

Jelenlegi hiba:

- Google login `tokeninfo` HTTP endpointot hiv production loginban.
- Nincs `GoogleIdTokenVerifier`.
- Nincs `google_sub` account binding.
- Nincs explicit `google_login_enabled`.
- `findByEmail` global es nem whitelistes.
- Google login nem ad HttpOnly refresh cookie-t.
- `validAppModes` es `passwordChangeRequired` response nem egyezik teljesen a jelszavas login logikaval.

**Javitas iranya:**

1. Uj migration:

   ```sql
   ALTER TABLE worker ADD COLUMN IF NOT EXISTS google_subject VARCHAR(255);
   ALTER TABLE worker ADD COLUMN IF NOT EXISTS google_login_enabled BOOLEAN NOT NULL DEFAULT FALSE;
   ALTER TABLE worker ADD COLUMN IF NOT EXISTS google_linked_at TIMESTAMP;
   ALTER TABLE worker ADD COLUMN IF NOT EXISTS google_last_login_at TIMESTAMP;
   CREATE UNIQUE INDEX IF NOT EXISTS uq_worker_google_subject
     ON worker (google_subject) WHERE google_subject IS NOT NULL;
   ```

2. V162-ben dokumentalt whitelist workerek enable flagje:

   ```text
   BORSI, BALI, KASZA, KOSA, FABULYA
   ```

3. `GoogleIdTokenService`:

   - Google client libraryvel signature/aud/iss/exp ellenorzes,
   - `email_verified=true`,
   - exact email whitelist,
   - opcionális `hd` allowed domain.

4. `GoogleLoginService`:

   - worker candidate exact whitelistbol,
   - duplicate email -> konfiguracios hiba,
   - inactive worker -> deny,
   - first login `google_subject` binding,
   - subject mismatch -> deny + audit event,
   - sajat JWT + HttpOnly refresh cookie.

5. Frontend:

   - `VITE_GOOGLE_CLIENT_ID` nelkul vagy `"none"` erteknel gomb rejtve,
   - Google ID token ne keruljon storage/logba,
   - offline Electron modban gomb rejtve/disabled.

Részletes utmutato:

```text
docs/AI_AGENT_GOOGLE_OAUTH_LOGIN_IMPLEMENTATION_2026-05-03.md
```

### P0.6 IdempotencyGuard nem production-grade

**Bizonyitek:** `backend/src/main/java/hu/puzzleir/valuta/util/IdempotencyGuard.java`

Problemak:

- process-memory only,
- restart/multi-instance eseten elveszik,
- `completedResults` cleanup soha nem torol,
- nincs request payload hash,
- ugyanaz key mas body-val is regi resultot adhat,
- raw idempotency key logolodik.

**Javitas:**

- DB/Redis idempotency store.
- Kulcs: `(company_id, actor_id/device_id, endpoint, idempotency_key)`.
- Tarolj request hash-t, statuszt, response-t, timestampet, TTL-t.
- Ugyanaz key mas payload -> 409.
- In-progress timeout es cleanup job.

### P0.7 Filterek dupla regisztracioja

**Bizonyitek:**

```text
JwtAuthenticationFilter @Component + SecurityConfig.addFilterBefore
IdempotencyFilter @Component + SecurityConfig.addFilterBefore
ProductionCorsFilter @Component + SecurityConfig.addFilterBefore
```

**Javitas:**

- Security chainben hasznalt filterek servlet auto-registrationjet tiltsd:

  ```java
  FilterRegistrationBean<JwtAuthenticationFilter> bean = new FilterRegistrationBean<>(filter);
  bean.setEnabled(false);
  ```

- Teszt: egy request alatt filter pontosan egyszer fut.

### P0.8 CashBalanceService SecurityContext exception bug

**Bizonyitek:** `CashBalanceService.initializeBranchBalances`, `SecurityUtils.getCurrentCompanyId`.

A service `IllegalStateException`-t fog, de `SecurityUtils` `ValidationException`-t dob.

**Javitas:**

- `getCurrentCompanyIdOrNull()` vagy `ValidationException` catch.
- Teszt startup/async SecurityContext nelkuli futasra.
- Teszt mas company branch tiltasa authentikalt requestben.

### P0.9 Conversion triple transaction / riport dupla szamolas

**Bizonyitek:** `TransactionConversionService.java`

Konverzio jelenleg:

- parent `CONVERSION`,
- completed BUY receipt,
- completed SELL receipt.

Ez riportokban es KPI-kban dupla/tripla szamolast okozhat.

**Javitas:**

- Vagy csak ket penzugyi sor legyen `conversion_group_id`-vel,
- vagy parent legyen non-financial/internal es minden riport zarja ki.
- Teszt:
  - daily report,
  - receipt list,
  - AML,
  - NB/NGM/TRB export,
  - cash balance reconciliation.

### P0.10 Electron scanner/camera IPC path es runtime validation

**Bizonyitek:**

```text
penztar-client/electron/scanner.ts:34,60-87
penztar-client/electron/camera.ts:78-88
```

Problemak:

- `scanner.ts` `catch (e: any)`.
- `scan-get-document` `resolved.startsWith(path.resolve(SCAN_DIR))` nem eleg sibling prefix ellen.
- `documentType` csak TS union, runtime allowlist nincs.
- `camera-save-recording` `extension` runtime allowlist nelkul megy fajlnevbe.

**Javitas:**

- `catch (e: unknown)`.
- `assertInsideBase(resolved, base)` helper:

  ```ts
  resolved === base || resolved.startsWith(base + path.sep)
  ```

- runtime allowlist:
  - documentType: `szemelyi|utlevel|jogositvany|egyeb`
  - extension: `mp4|webm`
- Teszt:
  - `C:/valuta/scan_evil/...` deny,
  - `../` deny,
  - invalid enum deny.

### P0.11 Production Flyway repair-on-migrate

**Bizonyitek:** `application-production.properties` tartalmaz `spring.flyway.repair-on-migrate=true`.

Ez V174 outage utan ideiglenes megoldas volt, de hosszu tavon driftet fedhet el.

**Javitas:**

- kontrollalt production schema history ellenorzes,
- egyszeri repair runbook,
- utana `repair-on-migrate=true` eltavolitasa,
- CI migration preflight entity table nev validalassal.

## 6. P1 magas prioritasu javitasok

### P1.1 Shared IPC contract drift

**Bizonyitek:**

```text
Electron ipcMain.handle: 75
packages/shared-ipc/src/index.ts routes: 3
```

**Javitas:**

- Minden channel keruljon `IpcRoutes` ala.
- `preload.ts` ne hardcodeolja channel stringeket.
- CI teszt hasonlitsa:
  - `ipcMain.handle`,
  - `ipcRenderer.invoke`,
  - `IPC_CHANNELS`.

### P1.2 Frontend dead/missing endpointok

**Bizonyitek:** `frontend-react/src/services/api/transactions.ts`

Problemak:

- `shipmentRequestApi.create()` throw: backend endpoint hianyzik.
- `prepare()` throw.
- `findByBranch` full fetch + client filter.
- `reject()` `/cancel` endpointot hasznal audit szempontbol mas jelentessel.
- `getReceipt` `/transactions/{id}/receipt` egyeztetendo backenddel.

**Javitas:**

- Backend endpointok implementalasa vagy frontend API eltavolitasa/feature flag.
- `/shipments?branchId=...` native filter.
- Dedikalt reject endpoint audit traillel.
- OpenAPI typegen.

### P1.3 Web token tarolas

**Bizonyitek:** `frontend-react/src/services/api/client.ts` weben `localStorage` auth token.

**Javitas:**

- Web: in-memory access token + HttpOnly refresh cookie bootstrap.
- Electron: secure store IPC boundary.
- CSP/XSS hardening.

### P1.4 Rate limit es client IP SSOT

**Problemak:**

- RateLimitFilter trusted proxy listat hasznal,
- RefreshTokenService IP olvasas mas logikaval.

**Javitas:**

- `ClientIpResolver` komponens.
- X-Forwarded-For csak trusted proxybol.
- multi-instance rate limit Redis/Bucket4j/edge.

### P1.5 React Hooks lint debt

**Aktualis warning:** `CashierTransactionPage.tsx:512`

**Javitas:**

- dependency javitasa vagy callback szerkezet atalakitas.
- fokozatosan visszakapcsolni React Hooks extra szabalyokat.

### P1.6 Schema/index governance

**Javitas:**

- Uj migration checklist:
  - entity `@Table` nev ellenorzes,
  - column nev ellenorzes,
  - local clean/migrate teszt,
  - no silent idempotent DDL drift-elrejtes,
  - company_id scope ellenorzes.

### P1.7 Offline/sync registration policy

**Vault feedback szerint:**

- penztar telepites elso lepese online regisztracio,
- offline mod csak kesobbi allapot,
- SyncEngine offline/server_url null eseten ne spameljen.

**Javitas:**

- SetupWizard full installban device registration failure legyen blokkolo vagy explicit degraded.
- SyncEngine regresszios teszt offline mode-ra.

### P1.8 Forgot password production email

**Bizonyitek:** `AuthController`, `PasswordResetService` TODO.

**Javitas:**

- Productionben token ne maradjon "TODO email".
- Gmail/SMTP kuldes implementalasa.
- Anti-enumeration maradjon.
- Token soha ne logolodjon.

## 7. P2 modernizacio

### P2.1 `any` debt

Production erintu konkret:

```text
penztar-client/electron/scanner.ts:34 catch (e: any)
```

Teszt oldali `as any` sok, de uj kodban tilos.

### P2.2 TypeScript verzio drift

- frontend TS 5.2.x
- Electron TS 5.7.x

**Javitas:** workspace-szintu verzio harmonizacio, havi `skipLibCheck=false` CI.

### P2.3 Electron build script robusztussag

`vite.config.ts`/dev ASAR logika path/space/ekezetes kornyezetben torhet.

**Javitas:** kulon script, Node API, argv alapu asar.

### P2.4 TODO backlog ticketeles

Kiemelt:

- POS live driver,
- LED Electron IPC bridge,
- shipment native filter/reject,
- forgot password email,
- daily handling fee subledger snapshot.

## 8. API route audit metodika

Generalj route inventoryt:

```powershell
rg -n "@RequestMapping|@GetMapping|@PostMapping|@PutMapping|@PatchMapping|@DeleteMapping" backend/src/main/java/hu/puzzleir/valuta/controller > docs/generated-route-inventory-2026-05-03.txt
```

Kategorizalj:

- auth: login, Google login, refresh, refresh-cookie, logout, role selection, bootstrap, forgot/reset
- workers/roles/permissions
- branches/companies/public
- transactions: buy/sell/conversion/reversal/receipt
- cash/session/balance
- AML/compliance/NB/NGM/TRB
- treasury/vault/shipment/transfer/stocktake
- email/Gmail OAuth
- camera/video/scanner/export
- sync/offline restore/cash register device
- health/actuator/swagger

Minden endpointnel ellenorizd:

- `@PreAuthorize` vagy security chain szabaly,
- tenant/company scope,
- branch scope,
- DTO validation,
- idempotency write endpointokon,
- response DTO nem entity/titok,
- frontend service route egyezes,
- OpenAPI typegen egyezes.

## 9. Database/schema/index ellenorzesi lista

1. `repair-on-migrate=true` eltavolitasi terv.
2. Idempotency perzisztens tabla.
3. Refresh token selector schema.
4. Google login schema:
   - `google_subject`,
   - `google_login_enabled`,
   - indexek.
5. Conversion model schema.
6. Multi-tenant indexek:
   - transaction company/branch/date/status,
   - daily_session company/branch/date,
   - receipt branch/date/receipt,
   - sync inbox/outbox device/status,
   - shipment branch/status/date,
   - vault territory/branch/status.
7. Migration preflight:
   - entity name,
   - column name,
   - duplicate precheck,
   - no production-only manual fix.

## 10. Electron hardening checklist

Minden IPC handler:

- channel shared contractban,
- runtime Zod/allowlist validacio,
- path traversal guard,
- buffer meretlimit,
- audit log file/decrypt/export muveletre,
- no raw token/path secret log,
- tests:
  - invalid enum,
  - sibling prefix path,
  - traversal,
  - oversized payload,
  - duplicate channel.

Kiemelt file-ok:

```text
penztar-client/electron/main.ts
penztar-client/electron/preload.ts
penztar-client/electron/scanner.ts
penztar-client/electron/camera.ts
penztar-client/electron/video-manager.ts
penztar-client/electron/sync-engine.ts
packages/shared-ipc/src/index.ts
```

## 11. Frontend javitasi checklist

1. Auth refresh `/refresh-cookie`.
2. Google login button offline/none guard.
3. `localStorage` auth token kivaltasa hosszabb tavon.
4. `transactions.ts` dead endpoints.
5. CashierTransactionPage hook warning.
6. OpenAPI generated types hasznalata.
7. React Hooks szabalyok fokozatos visszakapcsolasa.
8. UI role/appMode flow:
   - penztar,
   - ertektar,
   - ertekszallito,
   - full server mode.

## 12. Backend javitasi checklist

1. Auth refresh cookie flow.
2. Google OIDC flow.
3. JWT permissions authorities.
4. Persistent idempotency.
5. Filter registration.
6. CashBalance startup/async bug.
7. Conversion model.
8. Flyway production cleanup.
9. ClientIpResolver.
10. Forgot password email.
11. Multi-tenant repository audit.

## 13. Vegrehajtasi sorrend

### Phase 0 - baseline

```powershell
git status --short --branch
npm --prefix frontend-react run typecheck
npm --prefix penztar-client run typecheck
npm --prefix frontend-react run lint
npm --prefix penztar-client run lint
cd backend; .\mvnw.cmd -q -DskipTests compile
```

### Phase 1 - auth correctness

1. Frontend `/refresh-cookie` fix.
2. Backend secure cookie helper + forward headers.
3. Refresh token selector schema/service.
4. JWT permission authorities.
5. Google OIDC whitelistes login.

### Phase 2 - money correctness

1. Persistent idempotency.
2. Conversion financial model.
3. CashBalance SecurityContext fix.
4. Receipt/report/AML regression tests.

### Phase 3 - Electron/offline

1. Scanner/camera path validation.
2. IPC contract full coverage.
3. Offline setup/sync registration tests.
4. Secure token storage boundary tests.

### Phase 4 - DB governance

1. Flyway repair cleanup.
2. Migration preflight.
3. Index audit.
4. Multi-tenant repository audit.

### Phase 5 - polish/debt

1. Hook warning.
2. `any` debt.
3. TODO ticket cleanup.
4. TS version alignment.

## 14. Elfogadasi kapuk

Egy javitasi batch csak akkor tekintheto lezartnak, ha:

- `git diff` csak tervezett fajlokat erint,
- frontend typecheck PASS,
- Electron typecheck PASS,
- backend compile PASS,
- lint 0 error es uj warning nincs,
- relevans unit tesztek PASS,
- backend P0-nal `.\mvnw.cmd test` relevans modulokra PASS,
- auth/security P0-nal security regression test PASS,
- Electron P0-nal path traversal tests PASS,
- DB P0-nal Flyway test PASS,
- GitHub PR-nel Codex/Sourcery findingek lekerdezve es kezelve.

## 15. Gyors keresoparancsok kovetkezo ugynoknek

```powershell
cd D:\repo\valutavalto-program
rg -n "as any|: any|@ts-ignore|@ts-expect-error|eslint-disable|TODO|FIXME" frontend-react/src penztar-client/electron packages backend/src/main/java
rg -n "refresh-cookie|/auth/refresh\\b|request\\.isSecure|findAll\\(\\).*stream|BCrypt" backend/src/main/java frontend-react/src/services/api
rg -n "GoogleAuthController|tokeninfo|GoogleIdTokenVerifier|google-login|findByEmail" backend/src/main/java frontend-react/src
rg -n "SimpleGrantedAuthority|permissions|hasAuthority|hasAnyAuthority" backend/src/main/java
rg -n "ipcMain\\.handle|ipcRenderer\\.invoke|IPC_CHANNELS|IpcRoutes" penztar-client/electron packages/shared-ipc/src
rg -n "repair-on-migrate|out-of-order|baseline-version|IF NOT EXISTS|DO \\$\\$" backend/src/main/resources
```

## 16. Dontesi osszegzes

Legelso javitando csomag:

1. frontend refresh-cookie fix,
2. backend secure cookie helper/forward headers,
3. Google login production hardening tervezett schema-val,
4. JWT permission authority mapping.

Ezek kis teruletu, nagy hatasu auth/security javitasok. Ezutan johet a penzugyi korrektség: persistent idempotency es conversion model. A scanner/camera IPC hardening szinten P0, de kulon Electron batchben legyen, hogy a backend auth valtozasokkal ne keveredjen.
