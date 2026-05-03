# Valutavalto ERP - Google OAuth/OIDC dolgozoi belepes megvalositasi utasitaskeszlet AI ugynoknek

**Datum:** 2026-05-03  
**Repo:** `D:\repo\valutavalto-program`  
**Cel:** whitelistes, dolgozoi Google bejelentkezes pontos, biztonsagos implementalasa a meglevo Spring Boot + React + Electron kompatibilis Valutavalto programba.  
**Fontos:** titkokat, client secretet, tokeneket, valos production ertekeket nem szabad ebbe vagy mas repo-fajlba irni.

## 0. Terminologia es dontes

A feladat neve a mindennapi nyelvben "Google OAuth login", de a helyes technikai modell a program jelenlegi webes beleptetesehez:

- **Authentication:** Sign in with Google / Google Identity Services, OIDC ID tokennel.
- **Backend input:** Google altal kiadott JWT **ID token**.
- **Backend kimenet:** a sajat Valutavalto JWT + HttpOnly refresh cookie.
- **Authorization Google API-khoz:** kulon folyamat. A Gmail OAuth access/refresh tokenek nem dolgozoi loginra valok.

Az AI ugynok **ne** hasznalja dolgozoi loginra a Gmail OAuth access tokent vagy refresh tokent. A Gmail integracio mar kulon domain: `GmailOAuthConfig`, `EmailAccountService`, `/api/v1/email/accounts/callback`.

## 1. Hivatalos Google forrasok, amelyeket kovetni kell

Ezek az implementacio igazsagforrasai:

- Google ID token backend validalas: https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
- Sign in with Google JavaScript API referencia: https://developers.google.com/identity/gsi/web/reference/js-reference
- Google Identity Services migration: https://developers.google.com/identity/gsi/web/guides/migration
- OAuth 2.0 web server flow, csak Gmail/authorization flow-hoz: https://developers.google.com/identity/protocols/oauth2/web-server

Kulcs kovetelmenyek a Google docs alapjan:

- Backend oldalon validalni kell az ID token alairasat.
- `aud` pontosan a sajat web client ID legyen.
- `iss` `accounts.google.com` vagy `https://accounts.google.com`.
- `exp` nem jarhatott le.
- `email_verified` legyen true.
- Workspace-domain korlatozaskor `hd` claimet kell hasznalni; pusztan az email domain nem eleg.
- Productionben Google API client library vagy altalanos JWT library ajanlott, nem sajat kezi validalas.
- Az ID token mezot a GIS `CredentialResponse.credential` adja.

## 2. Jelenlegi repo-allapot

Mar letezo, hasznalando elemek:

```text
frontend-react/src/pages/auth/LoginPage.tsx
frontend-react/src/services/api/auth.ts
frontend-react/src/services/api/auth.test.ts
frontend-react/src/vite-env.d.ts
backend/src/main/java/hu/puzzleir/valuta/controller/GoogleAuthController.java
backend/src/main/java/hu/puzzleir/valuta/dto/auth/GoogleLoginRequestDto.java
backend/src/main/java/hu/puzzleir/valuta/config/SecurityConfig.java
backend/src/main/java/hu/puzzleir/valuta/entity/Worker.java
backend/src/main/java/hu/puzzleir/valuta/repository/WorkerRepository.java
backend/src/main/resources/db/migration/V101__worker_google_email_setup.sql
backend/src/main/resources/db/migration/V162__google_oauth_whitelist_emails.sql
```

Jelenlegi pozitívumok:

- Frontend már használja az `@react-oauth/google` csomagot.
- Login oldalon van `GoogleOAuthProvider` + `GoogleLogin`.
- Frontend a `CredentialResponse.credential` értékét küldi `idToken` néven.
- Backend publicként engedi a `/api/v1/auth/google-login` endpointot.
- Backend oldalon van `GoogleAuthController`.
- Worker entityben van `email`.
- V162 migracio már 5 whitelistes EBC emailt dokumentál.

Jelenlegi hianyossagok:

- `GoogleAuthController` production loginhoz `https://oauth2.googleapis.com/tokeninfo` HTTP endpointot hiv minden loginra.
- Nincs `GoogleIdTokenVerifier`-es backend validalas.
- Nincs explicit `iss`, `exp`, signature validalas sajat library-n keresztul.
- Nincs `google_sub` tarolas, pedig Google `sub` a stabil account azonosito.
- `WorkerRepository.findByEmail(email)` global, nem company-scoped, nem case-insensitive, es nincs explicit whitelist flag.
- Google login nem adja ki ugyanazt a HttpOnly refresh cookie-t, mint `AuthController.login`.
- Google login response nem tolti a `passwordChangeRequired` es `validAppModes` mezoket ugyanolyan logikaval, mint `WorkerService.login`.
- Nincs backend teszt a Google login security pathokra.
- Nincs frontend teszt a Google gomb siker/hiba/role-selection flow-ra.

## 3. Celfolyamat

1. Dolgozo megnyitja a login oldalt.
2. Frontend csak akkor mutat Google gombot, ha `VITE_GOOGLE_CLIENT_ID` be van allitva.
3. Dolgozo a Google popup/One Tap nelkuli gombbal bejelentkezik.
4. Google visszaad egy ID tokent a `CredentialResponse.credential` mezoben.
5. Frontend elkuldi:

   ```json
   {
     "idToken": "<google-id-token>"
   }
   ```

   endpoint:

   ```text
   POST /api/v1/auth/google-login
   ```

6. Backend Google client libraryvel validalja az ID tokent.
7. Backend a validalt Google accountot whitelistre illeszti.
8. Backend csak akkor engedi be:
   - a token ervenyes,
   - audience egyezik,
   - issuer helyes,
   - token nem jart le,
   - email verified,
   - email canonicalizalva whitelisten van,
   - worker aktiv,
   - worker company/branch ervenyes,
   - ha `google_sub` mar kotve van, akkor megegyezik,
   - ha `google_sub` meg nincs kotve, biztonsagos elso kotest vegez.
9. Backend letrehozza a sajat Valutavalto JWT-t, sessiont, `last_login_at` frissitest.
10. Backend kiadja a HttpOnly refresh cookie-t ugyanugy, mint jelszavas login.
11. Frontend a normal `handleLoginResponse` agat hasznalja: role selection, appMode RBAC, navigacio.

## 4. Konfiguracio

### Backend env/property

Mar letezik:

```properties
google.client.id=${GOOGLE_CLIENT_ID:}
google.client.secret=${GOOGLE_CLIENT_SECRET:}
google.redirect.uri=${GOOGLE_REDIRECT_URI:...}
```

Dolgozoi Google loginhoz kotelezo:

```properties
google.client.id=${GOOGLE_CLIENT_ID:}
google.login.allowed-domains=${GOOGLE_LOGIN_ALLOWED_DOMAINS:}
google.login.bind-sub-on-first-login=${GOOGLE_LOGIN_BIND_SUB_ON_FIRST_LOGIN:true}
```

Megjegyzes:

- `GOOGLE_CLIENT_SECRET` nem kell a popupos GIS ID token loginhoz.
- `GOOGLE_CLIENT_SECRET` maradhat a Gmail OAuth flow miatt.
- `google.redirect.uri` a Gmail/email authorization callbackhez tartozik, nem a popupos dolgozoi loginhoz.

### Frontend env

Kotelezo:

```text
VITE_GOOGLE_CLIENT_ID=<ugyanaz a web OAuth client ID>
```

Figyelem:

- Vite env build-time. Production build/deploy pipeline-nak a frontend build idejen kell megkapnia.
- Frontendbe csak a client ID kerulhet. Client secret soha.

### Google Cloud Console

Az AI ugynok ellenoriztesse az emberrel, de ne kerjen vagy taroljon secretet:

- OAuth client type: Web application.
- Authorized JavaScript origins:
  - `https://excvaluta.com`
  - `https://www.excvaluta.com`, ha hasznalva van
  - staging/dev originok csak indokoltan
  - `http://localhost:3000` vagy `http://localhost:5173` csak fejleszteshez
- Ha redirect UX-t valasztanak, authorized redirect URI pontosan egyezzen. A jelenlegi popup flow-nal ez nem a fo login ut.
- Gmail OAuth callback kulon:
  - `https://excvaluta.com/api/v1/email/accounts/callback`

## 5. Adatmodell es whitelist

### Minimalisan javasolt Worker oszlopok

Adj uj Flyway migraciot, peldaul:

```sql
ALTER TABLE worker
  ADD COLUMN IF NOT EXISTS google_email VARCHAR(255),
  ADD COLUMN IF NOT EXISTS google_subject VARCHAR(255),
  ADD COLUMN IF NOT EXISTS google_login_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS google_linked_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS google_last_login_at TIMESTAMP;
```

Ha a repo stilusa miatt `email` marad a whitelist email, akkor is kell legalabb:

```sql
ALTER TABLE worker
  ADD COLUMN IF NOT EXISTS google_subject VARCHAR(255),
  ADD COLUMN IF NOT EXISTS google_login_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS google_linked_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS google_last_login_at TIMESTAMP;
```

### Indexek

Case-insensitive email lookup:

```sql
CREATE INDEX IF NOT EXISTS idx_worker_google_email_lower
  ON worker (LOWER(COALESCE(google_email, email)))
  WHERE google_login_enabled = TRUE;
```

Subject egyediseg:

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_worker_google_subject
  ON worker (google_subject)
  WHERE google_subject IS NOT NULL;
```

Company-scoped email egyediseg:

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_worker_company_google_email_lower
  ON worker (company_id, LOWER(COALESCE(google_email, email)))
  WHERE google_login_enabled = TRUE
    AND COALESCE(google_email, email) IS NOT NULL;
```

### Whitelist elv

Whitelistes dolgozoi login csak admin altal explicit engedelyezett workerhez tartozhat:

- `google_login_enabled = true`
- canonical email pontos egyezes
- worker aktiv
- company aktiv
- branch aktiv
- opcionálisan allowed hosted domain egyezes

Ne hozz letre automatikusan uj workert Google loginbol. Ez ERP rendszer, nem self-service SaaS.

### V162 migracio kezelese

A V162 jelenleg emailt allit be BORSI/BALI/KASZA/KOSA/FABULYA workerekhez. Uj migracio:

- ezeket a workereket allitsa `google_login_enabled=true`-ra,
- `google_email = LOWER(TRIM(email))`, ha kulon oszlop lesz,
- ne tartalmazzon uj titkot,
- ne tartalmazzon jelszot, ha nem muszaj.

## 6. Backend implementacio

### 6.1 Hozz letre GoogleIdTokenService-t

Uj service:

```text
backend/src/main/java/hu/puzzleir/valuta/service/GoogleIdTokenService.java
```

Feladata:

- egyszer injektalt `GoogleIdTokenVerifier` hasznalata,
- `google.client.id` audience,
- token parse/verify,
- normalizalt eredmeny DTO visszaadasa.

Javasolt return tipus:

```java
public record VerifiedGoogleIdentity(
    String subject,
    String email,
    boolean emailVerified,
    String hostedDomain,
    String issuer,
    String audience
) {}
```

Javasolt validalasi sorrend:

1. `idToken` not blank.
2. `GoogleIdTokenVerifier.verify(idToken)`.
3. Ha null: invalid token.
4. Payload:
   - `subject` not blank.
   - `email` not blank.
   - `emailVerified == true`.
   - `audience == google.client.id`.
   - issuer/expiry verifier altal kezelve, de tesztben ellenorizd, hogy a service ezekre tamaszkodik.
5. Email normalizalas:
   - `trim`
   - `lowercase(Locale.ROOT)`
   - csak osszehasonlitasra hasznald; eredeti display emailt nem kell logolni.
6. Hosted domain:
   - ha `google.login.allowed-domains` nem ures, `payload.getHostedDomain()` legyen a listaban.
   - Gmail cimeknel allowed exact email whitelist eleg; Workspace domain policyhoz `hd` kell.

Ne hasznald production flowban a `tokeninfo` endpointot. Fejlesztes/debug eseten lehet kulon parancs, de app login ne fuggjon kulso HTTP round-triptol minden belepesnel.

### 6.2 Google verifier bean

Uj config:

```text
backend/src/main/java/hu/puzzleir/valuta/config/GoogleLoginConfig.java
```

Tartalom:

- `HttpTransport` mar van `GmailOAuthConfig.googleHttpTransport()` beanben; ujrahasznalhato, de keruld a Gmail OAuth configgel valo fogalmi osszekeverest.
- `JsonFactory` `GsonFactory.getDefaultInstance()`.
- `GoogleIdTokenVerifier` bean audience listaval.

Pelda irany:

```java
@Bean
public GoogleIdTokenVerifier googleIdTokenVerifier(HttpTransport transport) {
    return new GoogleIdTokenVerifier.Builder(transport, GsonFactory.getDefaultInstance())
        .setAudience(List.of(googleClientId))
        .build();
}
```

Ha `google.client.id` ures productionban, startupkor fail-fast legyen. Dev/test profilban lehet mock.

### 6.3 Repository metodusok

`WorkerRepository` bovites:

```java
Optional<Worker> findByGoogleSubject(String googleSubject);

@Query("""
    SELECT w FROM Worker w
    WHERE w.googleLoginEnabled = true
      AND LOWER(COALESCE(w.googleEmail, w.email)) = LOWER(:email)
""")
List<Worker> findGoogleLoginCandidatesByEmail(@Param("email") String email);
```

Ha nincs kulon `googleEmail`, akkor:

```java
@Query("""
    SELECT w FROM Worker w
    WHERE w.googleLoginEnabled = true
      AND LOWER(w.email) = LOWER(:email)
""")
List<Worker> findGoogleLoginCandidatesByEmail(@Param("email") String email);
```

Ne hasznald a regi global `findByEmail`-t Google loginra, mert:

- nem explicit whitelist,
- nem case-insensitive garantalt,
- multi-tenant utkozest nem kezel,
- nem ellenorzi az enable flaget.

### 6.4 GoogleAuthController refaktor

`GoogleAuthController` csak controller legyen, a logika service-be menjen:

```text
backend/src/main/java/hu/puzzleir/valuta/service/GoogleLoginService.java
```

Controller:

- `@PostMapping("/google-login")`
- `@PreAuthorize("permitAll()")`
- `@Valid @RequestBody GoogleLoginRequestDto`
- `HttpServletRequest`, `HttpServletResponse`
- meghivja `GoogleLoginService.login(...)`
- visszaadja `LoginResponseDto`

Service:

1. Validalja Google ID tokent `GoogleIdTokenService`-szel.
2. Email alapjan whitelistes worker candidate-eket keres.
3. Ha 0: 401 generikus uzenet.
4. Ha 2+: security error, 500/409 belso konfiguracios hiba; ne valasszon random workert.
5. Worker aktiv/company/branch ellenorzes.
6. `google_subject` kezeles:
   - ha null es bind engedelyezett: set subject + linked_at.
   - ha null es bind nem engedelyezett: 401, adminnak elobb kotnie kell.
   - ha nem null es nem egyezik: 401 + audit security event.
7. Role/permission logika pontosan egyezzen `WorkerService.login` logikaval.
8. `validAppModes` szamitas ne duplikalt, eltero kod legyen. Emeld ki kozos helperbe:

   ```text
   WorkerLoginResponseFactory
   ```

   vagy `WorkerService.buildLoginResponse(...)`.
9. Ments `WorkerSession` rekordot.
10. Frissitsd:
    - `worker.lastLoginAt`
    - `worker.googleLastLoginAt`
11. Generalj Valutavalto JWT-t.
12. Adj ki HttpOnly refresh cookie-t `RefreshTokenService.issue(...)` alapjan.

### 6.5 Refresh cookie egyezoseg

Google login ugyanazt a cookie-mintat hasznalja, mint jelszavas login:

```java
ResponseCookie cookie = ResponseCookie.from("refreshToken", issued.rawUuid())
    .httpOnly(true)
    .secure(isProductionOrRequestSecure)
    .sameSite("Strict")
    .path("/api/v1/auth")
    .maxAge(Duration.ofDays(7))
    .build();
```

Kapcsold ossze az elozo audit P0-val:

- productionban ne `request.isSecure()` dontse el onmagaban a secure flaget reverse proxy mogott,
- legyen `server.forward-headers-strategy=framework`,
- productionban refresh cookie mindig Secure.

### 6.6 Hiba- es auditpolitika

Usernek:

- invalid token: "Google bejelentkezés sikertelen."
- nem whitelisted email: "Google fiók nincs engedélyezve ehhez a rendszerhez."
- inactive worker: "Ez a dolgozó inaktív."

Logban:

- ne logolj teljes ID tokent,
- ne logolj teljes emailt feleslegesen,
- subjectet is csak hash/prefix formaban,
- audit event legyen:
  - GOOGLE_LOGIN_SUCCESS
  - GOOGLE_LOGIN_DENIED_NOT_WHITELISTED
  - GOOGLE_LOGIN_DENIED_SUB_MISMATCH
  - GOOGLE_LOGIN_DENIED_INACTIVE_WORKER
  - GOOGLE_LOGIN_CONFIG_ERROR

## 7. Frontend implementacio

### 7.1 LoginPage megtartando flow

Jelenlegi hely:

```text
frontend-react/src/pages/auth/LoginPage.tsx
```

Megtartando:

- `GoogleOAuthProvider clientId={googleClientId}`
- `GoogleLogin`
- `credentialResponse.credential`
- `authApi.googleLogin({ idToken })`
- `handleLoginResponse(response)`

Javitando/ellenorizendo:

- Google button csak akkor jelenjen meg, ha `VITE_GOOGLE_CLIENT_ID` letezik es nem `"none"`.
- Ha Electron offline mod van, Google gombot rejtsd el vagy disabled, mert Google login online szolgaltatas.
- Ne kerj Google access tokent frontendben.
- Ne tarolj Google ID tokent localStorage-ban.
- `onError` adjon ertheto, de nem tul reszletes uzenetet.
- Role selector Google login utan is mukodjon, mert `handleLoginResponse` kozos.

### 7.2 Nonce

Ha az `@react-oauth/google` hasznalt verzioja tamogatja, adj nonce-t:

- backend adhat public nonce endpointot, vagy frontend generalhat ephemeral nonce-t;
- backendnek validalnia kell a nonce claimet, ha nonce-t kuldunk.

Ha nincs nonce implementalva az elso iteracioban, ezt dokumentald P1 hardeningkent. A kotelezo minimum tovabbra is: signature/audience/issuer/expiry/email_verified/whitelist/sub binding.

### 7.3 Auth API

`frontend-react/src/services/api/auth.ts` mar jo alap:

```ts
googleLogin: async (data: GoogleLoginRequest): Promise<LoginResponse> => {
  const response = await api.post<LoginResponse>('/auth/google-login', data)
  return response.data
}
```

Ellenorizd, hogy az idempotency interceptor nem kovetel-e feleslegesen `Idempotency-Key`-t auth endpointon. A backend `IdempotencyFilter` jelenleg `/api/v1/auth/` prefixet kihagy, ez jo.

## 8. Electron es offline mukodes

Google login csak online mukodik. Electron flow:

- Online full/web mod: Google login engedelyezheto, ha `VITE_GOOGLE_CLIENT_ID` be van epitve.
- Offline penztar mod: Google gomb elrejtendo vagy disabled.
- Ha a dolgozo korabban online Google-lel lepett be, offline loginhoz ne Google ID tokent probalj ujrahasznalni. Offline auth kulon helyi session/token restore, a SyncEngine jelenlegi architekturajahoz igazitva.
- Google token soha ne keruljon SQLite-ba.
- A sajat Valutavalto JWT tarolasara a meglevo Electron secure store / SQLite token flow vonatkozik.

## 9. Tesztterv

### Backend unit tesztek

Uj teszt:

```text
backend/src/test/java/hu/puzzleir/valuta/service/GoogleLoginServiceTest.java
```

Esetek:

1. Valid Google token + whitelisted aktiv worker -> LoginResponseDto.
2. Token invalid -> 401/AuthenticationException.
3. `aud` mas client ID -> 401.
4. `email_verified=false` -> 401.
5. email null -> 401.
6. email nincs whitelisten -> 401.
7. worker inactive -> 401.
8. duplicate whitelist email -> konfiguracios hiba, ne lepjen be.
9. `google_subject` null + bind enabled -> subject mentve.
10. `google_subject` null + bind disabled -> 401.
11. `google_subject` mismatch -> 401 + audit.
12. egy role -> activeRole + permissions kitoltve.
13. tobb role -> roleSelectionRequired true.
14. `validAppModes` megegyezik a jelszavas login logikaval.
15. refresh cookie kiadas megtortenik controller/integration tesztben.

### Backend controller/integration teszt

Uj vagy bovitetett teszt:

```text
backend/src/test/java/hu/puzzleir/valuta/controller/GoogleAuthControllerTest.java
```

Hasznalj mockolt `GoogleIdTokenService`-t. Ne hivj valos Google endpointot.

Ellenorizd:

- `POST /api/v1/auth/google-login` permitAll.
- valid request 200.
- response tartalmaz `token`, `worker`, `roles`, `activeRole`, `permissions`.
- `Set-Cookie: refreshToken=...; HttpOnly; SameSite=Strict`.
- unauthorized esetben nincs Set-Cookie.

### Repository/migration teszt

Flyway/JPA teszt:

- V162 utani worker email-ek normalizalva vannak.
- uj migracio utan whitelisted workerek `google_login_enabled=true`.
- lower-case lookup mukodik.
- duplicate `(company_id, lower(email))` tiltva whitelist enable mellett.
- duplicate `google_subject` tiltva.

### Frontend unit tesztek

Bovitsd:

```text
frontend-react/src/pages/auth/LoginPage.test.tsx
frontend-react/src/services/api/auth.test.ts
```

Esetek:

1. `VITE_GOOGLE_CLIENT_ID` nelkul nincs Google gomb.
2. valid credential -> `authApi.googleLogin({ idToken })`.
3. hianyzo credential -> hiba.
4. Google API reject -> hiba megjelenik.
5. Google login roleSelectionRequired -> role selector modal.
6. Google login success -> `loginStore` + navigacio ugyanugy, mint jelszavas login.
7. Full mod RBAC Google login utan is blokkolja a nem szerver-role-t.

### E2E/smoke

Valos Google OAuth e2e automatizalasa nehez es nem ajanlott titkokkal. Helyette:

- mockolt Google credential frontend e2e,
- backend mock Google verifierrel test profile,
- production smoke manual:
  - whitelisted dolgozo belép,
  - nem whitelisted Gmail belépés megtagadva,
  - inactive worker megtagadva,
  - role selection mukodik,
  - refresh cookie mukodik oldalfrissites utan.

## 10. Biztonsagi elfogadasi kriteriumok

Implementacio csak akkor kesz, ha:

- Nincs tokeninfo alapú production login dependency.
- Backend Google library/JWT verifier validalja signature/aud/iss/exp mezoket.
- `email_verified` kotelezo.
- Exact whitelist kotelezo.
- `google_subject` tarolva es mismatch tiltva.
- Nincs automatikus worker creation.
- Nincs Google access/refresh token dolgozoi loginhoz.
- Client secret nincs frontendben es nincs repo-ban.
- Google ID token nincs localStorage/SQLite/log tarolasban.
- Login success ugyanazt a sajat JWT + role/permission modellt adja, mint jelszavas login.
- Google login is ad HttpOnly refresh cookie-t.
- Backend es frontend tesztek lefutnak.

## 11. Konkret modositasi sorrend

### Phase 1 - schema

1. Uj Flyway migration: Google whitelist mezok + indexek.
2. V162-bol ismert 5 dolgozo enable flagje.
3. Repository metodusok.
4. Migration teszt.

### Phase 2 - backend service

1. `GoogleLoginConfig` + `GoogleIdTokenVerifier` bean.
2. `GoogleIdTokenService`.
3. `GoogleLoginService`.
4. Login response builder kozositas `WorkerService.login` es Google login kozott.
5. Refresh cookie helper kozositas `AuthController.login` es Google login kozott.
6. `GoogleAuthController` vekony controllerre refaktor.

### Phase 3 - frontend

1. Google gomb `none`/offline guard.
2. Hiba uzenetek finomitasa.
3. Role selection tesztek Google loginra.
4. Env dokumentacio.

### Phase 4 - hardening

1. Audit eventek.
2. Nonce tamogatas, ha a lib es UX megengedi.
3. Rate limit kulon Google login endpointre.
4. Security review.

## 12. Futtatando parancsok

Backend:

```powershell
cd D:\repo\valutavalto-program\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests compile
```

Frontend:

```powershell
cd D:\repo\valutavalto-program
npm --prefix frontend-react run typecheck
npm --prefix frontend-react run lint
npm --prefix frontend-react test -- --run LoginPage auth
```

Repo-szintu gyors ellenorzes:

```powershell
rg -n "tokeninfo|oauth2.googleapis.com/tokeninfo|GoogleIdTokenVerifier|google-login|VITE_GOOGLE_CLIENT_ID" backend frontend-react
rg -n "GOOGLE_CLIENT_SECRET|client_secret|idToken|refresh_token" frontend-react/src
```

Az elso `rg` celja: `tokeninfo` ne maradjon production login flowban.  
A masodik `rg` celja: frontendben ne jelenjen meg secret vagy Google refresh token.

## 13. Tiltott implementacios mintak

- Ne validalj Google JWT-t sajat kezzelel JWK letoltes/parsing ad-hoc koddal, ha a Google client library elerheto.
- Ne hivd production loginban a `tokeninfo` endpointot minden belepeshez.
- Ne fogadj el tokent csak az email payload alapjan.
- Ne hagyd ki az `aud` ellenorzest.
- Ne hasznald az email domain reszet Workspace authorizaciora `hd` nelkul.
- Ne hozz letre automatikusan workert Google loginbol.
- Ne engedd be az aktiv flag nelkuli dolgozot.
- Ne tedd Google ID tokent localStorage-ba.
- Ne tedd Google client secretet frontend env-be.
- Ne logolj teljes ID tokent vagy teljes emailt.

## 14. Vegso mukodesi leiras uzemeltetesnek

Dolgozo Google belepes engedelyezese:

1. Admin felveszi vagy frissiti a workert.
2. Worker emailje pontosan az engedelyezett Google email.
3. `google_login_enabled=true`.
4. Elso sikeres Google belepeskor a rendszer a Google `sub` azonositot a workerhez koti.
5. Kesobbi belepeskor mar a `sub` egyezes is kotelezo.
6. Ha dolgozo Google fiokot valt, adminnak explicit ujrakotest kell vegeznie:
   - regi `google_subject` torlese,
   - email frissitese,
   - audit indoklas.

Ez a minta megorzi a whitelistes kontrollt, nem nyit self-registration kaput, es a Google login ugyanabba a Valutavalto jogosultsagi modellbe illeszkedik, mint a dolgozoi kod + jelszo flow.
