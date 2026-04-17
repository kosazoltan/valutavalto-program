# Changelog

## [2.1.1] - 2026-04-17

### Fixed
- **First-Run Setup Wizard admin jelszó végre beíródik a backend-be** (kritikus 2.1.0 regresszió javítás). Korábban a wizard csak validálta a jelszót, majd `.env`-be írt és relaunch-olt — a jelszó tehát sehova sem került. Új `POST /api/v1/auth/bootstrap-admin` endpoint idempotens módon (`system_parameter.auth.bootstrap-completed`) létrehozza / frissíti az ADMIN role-ú workert a megadott jelszó BCrypt-hash-ével.
- **Wizard iroda-listája most a valós DB-t tükrözi**. Új publikus endpoint `GET /api/v1/public/branches?companyCode=EBC` (permitAll), ami csak a {code, name, city, address} mezőket adja vissza. Ha a backend offline, a wizard a statikus `DEFAULT_BRANCHES` listára fallback-el — nem marad üres képernyő.
- **LoginPage verzió kijelzés** korábban fix `v2.0` volt; most `package.json`-ból injektált build-idejű `__APP_VERSION__` konstanst használ, így a felület SOHA nem fog eltérni a valós build verziótól.
- **Wizard hibakezelés**: ha a backend nem elérhető az `saveSetupConfig` során, konkrét magyar hibaüzenetet kap a user (hálózati hint, service nevek), helyette a korábbi silent fail-nek.

### Added
- `AdminBootstrapService` + 7 db JUnit 5 teszt (happy path, idempotencia, ismeretlen cégkód, branch nélküli cég, status check).
- `PublicBranchController` (no auth, company-szűrt, 0 érzékeny mező).
- Electron `waitForBackend()` helper: `/actuator/health` polling 45 s-ig, 1.5 s intervallummal.
- Electron `fetchBranchesFromBackend()` + `bootstrapAdmin()` net.request alapú hívások.
- Flyway V144: `system_parameter.auth.bootstrap-completed` flag seed.

### Changed
- `setup:branches` IPC handler most opcionálisan átveszi `{ apiUrl, companyCode }` paramétert, és a wizard ezt propagálja a 3. lépés URL/cégkód változásánál.
- `SecurityConfig` permitAll-ra téve a `/api/v1/public/**`, `/api/v1/auth/bootstrap-admin`, `/api/v1/auth/bootstrap-status` útvonalakat.

## [2.1.0] - 2026-04-17

### Added
- **First-Run Setup Wizard** (Electron pénztár kliens)
  - 4 lépéses varázsló az első indításkor: Üdvözlő → Iroda választás (60 iroda, 2×8 rács kereséssel + lapozással) → Szerver konfiguráció ("Kapcsolat tesztelése" gombbal vagy offline móddal) → Admin jelszó.
  - Auto-generált titkos kulcsok: `JWT_SECRET`, `SQLCIPHER_KEY`, `OFFLINE_LICENSE_SECRET` (256-bit, `crypto.randomBytes`).
  - Atomikus `.env` írás (`%APPDATA%\valutavalto-branch\.env`) `0o600` jogokkal.
  - Szerver-teszt az Electron `net.request`-en keresztül (rendszer proxy tiszteletben tartása).
  - Main process + React renderer szétválasztva, 4 IPC csatorna: `setup:check`, `setup:branches`, `setup:test-connection`, `setup:save`.
- **Standalone "Penztar-Eltavolito" build** (`installer/build-cleanup.ps1`)
  - 1 másodperc alatt lefordul, ~60 KB méretű önálló EXE.
  - Régi / törött telepítés teljes eltávolítása: szolgáltatások, PostgreSQL, process-ek, Program Files, ProgramData, tűzfalszabályok, PGPASSFILE, registry.
- **Telepítési útmutató kollégáknak** (`installer/README.md`, magyar nyelven).

### Changed
- **Verzió egységesítés**: `penztar-client`, `frontend-react`, `backend` és az installer pipeline mind `2.1.0`-ra (korábban az installer 1.9.2-n rekedt, miközben a szoftver már 2.0.0 volt a CHANGELOG szerint — ezt konszolidáltuk).
- **NSIS source encoding hardening**: `Penztar-Setup.nsi` és `Penztar-Cleanup.nsi` ékezetei ASCII-ra cserélve (Windows-1252 NSIS forrás → tiszta EXE metadata, nincs több mojibake a Product/FileDescription mezőben).

### Security
- Dependabot alert #80 (`follow-redirects`) + #81 (`aquasecurity/trivy-action`) lezárva.
- CI pipeline teljesen zöld: Security Pipeline, UTF-8 Guardrail, Frontend E2E.
- OWASP Dependency Check átszervezve: heti ütemezésre + manual dispatch. PR / push eseményekre Trivy + GitHub Dependency Review fut (90+ perc → ~75 másodperc).

### Backend
- `AmlService.checkTransaction` 5-argumentumos overload (deviza-kód támogatás).
- `BlacklistService.findActivePersonMatch` (aktív tiltott személy gyors keresés).
- `WesternUnionService.performAmlCheck` árfolyam-paraméter, USD-only tranzakciók helyes HUF-ra átszámítása.
- `SecurityConfig`: deprecated `permissionsPolicy` → `permissionsPolicyHeader` (Spring Security 6.2+ kompatibilitás).
- `CashBalance.version` `@Builder.Default` (Lombok warning fix).
- **CB-016**: `NavClosingService` hardcoded `VAT_RATE = 0.27` megszüntetése. Új `NavTaxCode` enum (STANDARD / REDUCED_18 / REDUCED_5 / ZERO) + `resolveVatRate(NavTaxCode)` metódus, amely a `system_parameter` tábla `nav.vat-rate.<TAX_CODE>` kulcsaiból olvas; hiány/hiba esetén logolt fallback a beépített táblára. V143 Flyway migráció a 4 default értékkel. +7 új unit teszt (`NavClosingServiceVatRateTest`). Jogszabályváltozás redeploy nélkül kezelhető.
- **Wizard default URL**: `frontend-react/src/pages/setup/SetupWizard.tsx` Szerver URL mezője `https://` helyett a Hetzner VPS címét tölti elő (`https://api.excvaluta.com/api/v1`).

### Tools
- `scripts/security/companyid-audit.ps1` — multi-tenant boundary statikus audit: végigmegy az entity-ken + repository-kon, és minden `@Query` / derivált `findBy/getBy/existsBy/countBy/deleteBy` metódust jelöl, amelynek sem nevében, sem SQL-jében nincs `company_id` vagy `branch` szűrő. Kimenet: `security-reports/latest/companyid-audit.md`. Első futás: 61 entity, 57 repository, 379 metódus, 172 gyanús sor manuális review-ra.

## [2.0.0] - 2026-03-06

### Added
- Teljes Electron pénztár kliens (47 képernyő)
- Értéktár mód (ugyanaz az app, config alapú)
- AML pénzmosás elleni modul (300K/4.5M/2M küszöb)
- MNB napi/havi jelentés (XML export)
- NAV adatszolgáltatás (2M+ Ft)
- Trade modul (irodák közötti devizakereskedés)
- Deviza kalkulátor (cross-rate, kerekítés)
- Záró wizard (5 lépéses)
- Dashboard (összesítő)
- Pénztárgép integráció (NAV online)
- LED kijelző kezelés
- Dokumentum szkenner
- FTP szinkronizáció bridge
- i18n többnyelvűség (hu/en/de)
- Config export/import
- Cég/Fiók adminisztráció
- Backup/Restore
- Licenc kezelés
- Nyomtatási sablonok
- Audit trail (teljes)
- Értesítés rendszer + NotificationBell
- Scheduler (rate sync, backup, closing reminder, health check)
- GlobalExceptionHandler (6 hibakód)
- ErrorBoundary + Toast rendszer
- Swagger UI v2.0
- 245 teszt (177 backend + 68 frontend)

### Migration
- 41 Flyway migráció (V1-V41)
- 146 entity
- 106 controller
- 400+ REST endpoint

### Tech Stack
- Java 21 + Spring Boot 3.2
- React 19 + TypeScript + Vite
- Electron (offline pénztár)
- PostgreSQL + SQLite (sql.js WASM)
- JWT auth
