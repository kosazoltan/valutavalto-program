# Changelog

A `valutavalto-program` monorepo verzió-történet.

Formátum: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
verziószám: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.5.50] — 2026-05-13 (13 PR marathon + 24 Codex finding visszamenőleges audit)

### Released — 4 új migration + security + camera_export 4-eyes + discount granular

#### Sprint 1-5 features (PR #566-#572, korábbi nap-szakaszban)
- **PR #566 Sprint 1** — Címletezés v2 (DenominationOptimization strategies + rules + log)
- **PR #567 Sprint 2** — Bank API integráció status + admin UI
- **PR #568 Sprint 3.A** — MFA / TOTP (RFC 6238, Google Authenticator-kompat)
- **PR #569 Sprint 3.B+C** — MFA verify endpoint + frontend self-enrollment UI
- **PR #570 Sprint 4.A** — Hatósági kamera export 4-eyes dual approval
- **PR #571 Sprint 4.B** — VIP discount granular approval (P2-D)
- **PR #572 Sprint 5** — Mobile/PWA alapok (P3-A) — manifest + service-worker

#### Hotfix + production fix
- **PR #573 hotfix v2.5.49** — SetupWizard EXZ→"Valuta Pénzváltó" + **V222** W-S011 over-permissive role cleanup (security incident: pénztáros kódból minden modulba bejutott)
- **PR #574** — V211 fresh-deploy time bomb javítás + F15 lint whitelist mechanizmus (FLYWAY_REPAIR_ON_MIGRATE=true egyszeri Hetzner deploy)
- **PR #575** — F15 allowlist BASE revision-ből olvasás (Codex P1 #574 follow-up: self-bypass elhárítás)

#### Codex backlog audit — 24 finding visszamenőleg
- **PR #577 security** — `CentralReceivedDataController` `@PreAuthorize` legacy + canonical roles (CASHIER kizárva) + 12 új security teszt + CodeQL CSRF fix
- **PR #578 camera_export 4-eyes** — **V223** status VARCHAR(20)→VARCHAR(30) + rejected_by/at oszlopok + **V224** CHECK constraint a status enum-okra + getPendingRequests AWAITING_SECOND_APPROVAL + rejectExport audit-preserve
- **PR #579 cashier-tx** — 5-iter Codex P1 konvergencia: per-session quota counter + handleSubmit/Cancel/Esc ref-clear + stale rowKey prune + in-band edit prune + non-blocking quota refetch + BASE-rate HUF isWithinBand
- **PR #580 discount + UTC** — **V225** DISCOUNT_MAX_PCT seed (15.0 default) + 15% upper cap reject + REGIONAL_MGR + raw operational codes (CHIEF_VAULT, OFFICE_MGR, AUDITOR) + ClosingControlPage UTC date → local

### Migration (4 új V222-V225 production-on)
- **V222** — Bali Henriett (W-S011) 14 role → 2 (penztar+foertektar); G_SZEGED_ET → ertektar; BALI inaktív cleanup. Production security incident lezárva.
- **V211** — repair-on-migrate via FLYWAY_REPAIR_ON_MIGRATE=true (checksum 1782720344 → 180166643)
- **V223** — camera_export_request.status VARCHAR(30) + rejected_by + rejected_at
- **V224** — CHECK constraint a status oszlopon (7 enum value)
- **V225** — DISCOUNT_MAX_PCT system_parameter seed (15.0 default)

### Tech
- Backend mvn test: 1329-1341 PASS minden CI run-en
- Frontend tsc + eslint: 0 errors
- CodeQL: pass (CSRF disable a teszt SecurityFilterChain-ből kivéve)
- Production health: bootstrap-status completed=true, 66 branches API válasz
- 4-way version sync: package.json + frontend-react + penztar-client + backend/pom.xml 2.5.49 → 2.5.50

### Telepítő fájlok
- `Penztar-Setup-2.5.50-20260514.exe` — **280.9 MB** (294,550,275 byte), SHA256: `2C95C8D6AD9C5711642801A69E400B23AC75A815E5E9652EF22B2ACDE521196C`
- `Penztar-Eltavolito-2.5.50-20260514.exe` — **60 KB** (60,856 byte), SHA256: `1D09354016015FF5B95E7B76A79F98BC6B6E572399C533ED719552E1D3597044`

## [2.3.0] — 2026-04-25 (8 PR session audit + tisztaság-iteráció — installer P1 data-loss fix!)

### CRITICAL — Installer P1 data-loss fix (MEGKÖTELEZŐ frissítés!)
- **PR #222** — `installer/Penztar-Setup.nsi:230`: A SecInstall Fázis 1e2 unconditional `RMDir /r "C:\ProgramData\BestChange"`-t hajtott végre. **Az auto-upgrade flow ellenére az adatbázis + konfigurációs adatok TÖRLÖDTEK az új verzió telepítésekor!** Bevezetve `$UPGRADE_MODE` flag, conditional RMDir + `.onInit` upgrade ágában `StrCpy "1"`. Most az upgrade ténylegesen megőrzi a DB-t és a configot.
- **PR #222** — `installer/Penztar-Setup.nsi:.onInit`: `ReadRegStr` `SetRegView 64` nélkül futott, a 64-bit Windows-on a `Wow6432Node` redirect miatt nem találta a meglévő telepítést. Hozzáadva `SetRegView 64` az `UninstallString` lookup elé.
- **PR #222** — `penztar-client/electron/main.ts`: offline mode-ban (LAN-ban telepített pénztár, lokális backenddel) a SetupWizard `offline_mode=true`-t mentett, de a startup logika minden indításkor felülírta a `server_url`-t prod URL-re → offline telepítések törődtek indításkor. Új `offlineMode` ellenőrzés.
- **PR #222** — `frontend-react/src/pages/setup/SetupWizard.tsx`: offline mode + `selectedWorkerCode` konfliktus — offline-ban is worker-first-time-setup-ot indított. Most `!offlineMode` feltétel.
- **PR #222** — `penztar-client/electron/first-run.ts`: V100 device-registration `bootstrapPassword`-del loginolt a `workerFirstTimeSetup` után, ami már átállította a jelszót. Új `usedWorkerSetup` detection + `adminPassword` használat.

### Fixed — CI / lint / warning teljes tisztogatás
- **PR #223** — `LoginPage.tsx:524` `catch (err)` unused variable + `transactions.ts:986` obsolete `eslint-disable-next-line no-console` directive (Security Pipeline 5x failure unblock).
- **PR #224** — Sourcery P3: `LoginPage.tsx` catch blokk dev-mode logger.debug (anti-enumeration mellett dev-debugging) + E2E T10 `bootstrap-status` 3x retry (Hetzner deploy-window flakiness elimináció).
- **PR #225** — 4 db Lombok `@Builder` warning entitás-fájlokon (`DailyBalance`, `Customer`, `AmlReport`, `DailySession`): `@Builder.Default` annotáció hozzáadva. `GmailOAuthConfig.setApprovalPrompt("force")` deprecated API: `@SuppressWarnings("deprecation")` + indokló komment (Google API Builder nem expose-olja `setPrompt(String)`-et). Maven [WARNING] szám: 5 → **0**.
- **PR #226** — 32 e2e lint hiba (`no-useless-escape × 28`, `no-empty × 2`, `prefer-const × 1`, `unused-vars × 1`) az `e2e/excvaluta-live.spec.ts` és `excvaluta-full-menu.spec.ts` fájlokban. `npx eslint .`: 32 → **0**.

### Fixed — `.gitignore` Unicode byte-exact (Codex P2 + Sourcery P3)
- **PR #227** — Cosmetic dedupe: 4 db duplikált `Felmérés/` egyetlen-re reduce-olva, NSIS Cleanup duplikátok eltávolítva.
- **PR #228** — Codex P2 finding (#227 follow-up): a `.gitignore` pattern matching **byte-exact**, NEM Unicode-aware. A korábbi dedupe behavioral regression volt: macOS HFS+ NFD-encoded `Felmérés/` mappa nem lett volna kizárva. NFD pattern visszahozva a NFC mellé.
- **PR #229** — Sourcery P3 (#228 follow-up): bővített figyelmeztető komment a NFD entry mellett (NFC + NFD bytes hex form, ATTENTION: editor / formatter NE auto-normalizálja).

### Megjegyzések
- **Sentry** (24h): 0 frontend + 0 backend issue.
- **Production health** (`https://excvaluta.com/api/v1/auth/bootstrap-status`): HTTP 200 stabil.
- **CI**: `Security Pipeline`, `Frontend E2E`, `Deploy to Hetzner VPS`, `UTF-8 Guardrail` mind 8/8 PASS.

### Telepítő fájlok
- `Penztar-Setup-2.3.0-2026MMDD.exe` — kb. 273 MB, NSIS Unicode v3.x bundle (PG 17.5, NSSM 2.24, Eclipse Temurin JRE 21)
- `Penztar-Eltavolito-2.3.0-2026MMDD.exe` — kb. 60 KB, standalone uninstaller (`/PRESERVE_DATA=1` upgrade-mode-hoz, `/PRESERVE_DATA=0` factory reset)
- **Upgrade flow**: a Setup `.onInit` automatikusan futtatja a régi `Penztar-Eltavolito.exe`-t silent + PRESERVE_DATA=1-gyel, megőrizve az adatbázist + configot.

## [2.2.5] — 2026-04-24 (hotfix batch — 12 PR a v2.2.4 után)

### Critical — PenztarClient launcher PS 5.1-kompat fix (merge-blokkoló)
- **PR #193** — `scripts/_production-urls.ps1`: 4-arg `Join-Path` PS 5.1-ben parameter-binding error → **a launcher elsőként elesett** default Windows 10/11-en. Javítás: kaszkadolt `Join-Path` hívások. Nélküle a telepített pénztáros kliens indításkor azonnal crash-elt.

### Fixed — Frontend UI menük HTTP 400/404 crash-ek
- **PR #185** (Issue #184) — `RateHistoryController` + `RateCategoryPage`: `rate-history` és `rate-categories` menü 400 Bad Request. Backend default params (30 napos default ablak) + `RateHistoryRepository` optional query. Frontend `formatLocalDate()` UTC off-by-one javítás (este dátumváltás).
- **PR #183** — `CentralVaultDashboard` + `MnbReportPage`: stock-snapshot és MNB jelentések URL path typo (`/mnb-reports` → `/mnb/reports`). Új full menu Playwright e2e spec (44 authenticated oldal traversal).
- **PR #186** — `RateHistoryController` single `LocalDate.now()` (midnight race fix), swap logic csak akkor érvényesül, ha mindkét bound explicit megadva.
- **PR #187, #188, #192** — `MnbReportPage` backend field names (`reportDate` a `periodStart/End` helyett), `asArray<T>()` helper generikus safe-cast minden API hívásnál.
- **PR #192** — `CentralVaultDashboard` `hasStockData` gate + explicit "STOCK UNKNOWN" warning (üres snapshot esetén látszik, hogy adathiány).

### Fixed — Shipment API + Electron stack trace
- **PR #193** — `penztar-client/electron/main.ts`: `log.error()` 2nd arg full error object (nem csak `.message`), hogy a stack trace megmaradjon production config load failure esetén.
- **PR #194** — `shipmentRequestApi.findByBranch`: pagination loop `fetchPaged<T>()` reusable helperbe kiemelve. MAX_PAGES cap esetén `console.warn` silent truncation elkerülésére.

### Fixed — E2E test infrastructure
- **PR #176** (Codex P2, PR #193-ban javítva) — T09 login flow test skip path helyreállítva.
- **PR #183** — Playwright `full-menu.config.ts` authenticated storage state reuse.

### Fixed — AI_CONSTITUTION maturity labeling
- **PR #179** (Sourcery, PR #193-ban javítva) — "TDD kötelező állapotgép (L9 alapelv)" → "(alapelv, L2+ érettségi követelmény)".

### Added — AI review process scripts
- **PR #192** — `scripts/post-merge-signal-check.ps1` 15-perces iteratív polling (Sourcery/Codex bot-ok 15-30 perccel a merge után is küldhetnek új feedback-et).
- **PR #194** — script `-MinMinutes` paraméter (default 15) - **stability-exit NEM lehetséges** ezelőtt. KRITIKUS fix: a korábbi 4-perces korai kilépés miatt a Sourcery multi-round review-kat elvesztettük.

### Audit events
- **#187** — 9 mai-merge kihagyott finding utólagos javítása (1. protokoll-violation)
- **#193** — retroaktív scan 5 elmulasztott finding (PR #173, #174, #176, #179, #180) (4. audit event)
- **#194** — script design-hiba: stability-exit túl agresszív, Sourcery high-level feedback időzítése 15-25 min (5. audit event)

### Version bump
- `package.json` × 3: 2.2.4 → 2.2.5
- `backend/pom.xml`: nincs változtatás

### Upgrade path
- **Backend (Hetzner)**: ✅ automatikus deploy — a 12 PR backend-érintő része (`RateHistoryController`) már éles a https://excvaluta.com-on (main HEAD `16bb7e9a`)
- **Frontend admin (Hetzner)**: ✅ automatikus deploy
- **Pénztáros Electron kliens**: **v2.2.5 installer telepítése KÖTELEZŐ** a 12 PR fix-ért. A v2.2.4 client `app.asar`-jában még a régi bundle van (főleg: rate-history 400 crash, MNB reports 404, launcher PS 5.1 elesés).

### Breaking changes
- Nincs. Minden fix backward-compatible.

---

## [2.2.4] — 2026-04-24 (hotfix)

### Fixed — Szállítmányigények oldal 404 (pre-existing bug)
- **PR #180** — `frontend-react/src/services/api/transactions.ts` + `pages/shipments/ShipmentListPage.tsx`:
  A `shipmentRequestApi` `/api/v1/shipment-requests/*` URL-eket hívott, de a backend
  csak `/api/v1/shipments/*` alapján volt regisztrálva. `ShipmentListPage` HTTP 404-el
  esett el. Javítás:
  - `findByStatus(status)` → `/shipments?status={}&size=100` (Page<> content kifejtés)
  - `findByBranch(branchId)` → `/shipments?size=200` + client-side filter
  - `approve(id, …)` → `/shipments/{id}/approve`
  - `reject(id, workerId, reason)` → `/shipments/{id}/cancel` (backend nincs dedikált reject)
  - Status enum alignment: `REQUESTED/REJECTED/PREPARING/…` → backend `SUBMITTED/CANCELLED/DRAFT/APPROVED/IN_TRANSIT/DELIVERED`
- **6 új unit teszt** (`transactions.test.ts`): 511/511 frontend zöld.
- Live production verify: mind 6 backend enum érték HTTP 200 (volt 400).

### Added — AI Working Constitution
- **PR #179** — `AI_CONSTITUTION.md` új fájl a repo gyökérben (10 nem-alkuképes szabály + 7 tiltás + 7 réteg architektúra + L0–L5 érettségi modell). Forrás: *Új AI működési alapelvek: implementációs kézikönyv* (Kósa Zoltán user-direktíva, 2026-04-24). `CLAUDE.md` header mostantól ELSŐ PRIORITÁS-ként erre mutat. Jelen érettségi szint: **L2** (TDD + audit log + CI gate-ek + AI review automation).

### Version bump
- `package.json` × 3 + `backend/pom.xml`: 2.2.3 → 2.2.4

### Upgrade path
- **Backend**: ✅ automatikus Hetzner deploy (nincs backend-változás ebben a release-ben)
- **Frontend (admin)**: ✅ automatikus Hetzner deploy (PR #180 fix már éles)
- **Pénztáros Electron kliens**: **v2.2.4 installer telepítése JAVASOLT** — a v2.2.3 desktop app `app.asar`-jában még a régi frontend build van, ami a Szállítmányigények oldalon 404-et dob.

### Visszamaradó nagyobb refaktor (későbbi release)
- Backend `GET /shipments?branchId=…` natív branch-filter
- Backend `POST /shipments/{id}/reject` dedikált endpoint (audit trail)
- Backend `POST /shipments/{id}/prepare` endpoint
- `shipmentRequestApi.create` body-semantika backend-del egyeztetés

---

## [2.2.3] — 2026-04-24

### Kritikus bug-fix (frontend / desktop klienst érinti)
- **PR #163** — `frontend-react/src/services/api/client.ts`: Idempotency-Key header
  AxiosHeaders 1.x kompatibilis `set()` API használat (direkt assignment helyett).
  A pénztáros Electron kliens ugyanezt a frontend build-et használja, tehát
  ez a fix desktop-on is blokkoló volt a VETEL/ELADÁS/STORNO flow-ra.
  Live verify: **V017100012 10 EUR VETEL** sikeresen szerveren 2026-04-23 20:05.

### Új feature-k
- **PR #164** — `backend/DailySessionService`: új `cash_balance` auto-init
  `updateCashBalancesForOpening()`-ben (Issue #110 lezárás). Új branch-ek
  napnyitáskor automatikusan kapnak üres cash_balance rekordokat minden
  aktív valutára, így a tranzakció-sync nem esik el 404-gyel.

- **PR #175** — `.github/workflows/playwright-live.yml`: új GitHub Actions
  workflow manuális + nightly 03:30 UTC Playwright e2e tesztekhez
  `excvaluta.com` ellen. 10 teszt (T01–T10), T09 authenticated flow
  GitHub Secrets credentials-szel.

### Refaktor
- **PR #172** — `docs/LEGACY_COVERAGE_MATRIX.md`: 2026-04-24 legacy audit,
  129/129 = 100% modern lefedés bizonyítva (tiltcopy, recguard, vevo_mend
  mind `SanctionScreeningService`, `CameraCleanupService`, `CustomerController`
  révén lefedve).

- **PR #173** — Production URL SSOT teljes propagáció (3 réteg):
  - Backend: `WebSocketConfig` + `ProductionCorsFilter` `List.of(...)` → `ProductionUrls.BASE_URL + WWW_BASE_URL`
  - **ÚJ** `scripts/_production-urls.ps1` shared PS helper (`$PRODUCTION_URLS` hash + getter-ek)
  - `scripts/start-valuta-ecosystem.ps1`: dot-source helper, minden hardcoded URL `$PRODUCTION_URLS.*`
  - Electron `main.ts`: új `loadProductionUrls()` (packagedPath vs devPath)
  - `electron-builder.json`: `extraResources += config/production-urls.json`

### Infrastruktúra
- **PR #165** — `scripts/session-memory-auto-save.ps1` Windows PS wrapper + 2026-04-24 session handoff YAML+QMD
- **PR #170** — `scripts/setup-knowledge-mcp.ps1` diagnostic + `docs/knowledge/COGNEE_OBSIDIAN_SETUP.md`
- **PR #171** — Obsidian host IPv4 (`127.0.0.1`) default

### AI review follow-up
- **PR #166, #167, #168, #169** — Sourcery 8 findings javítva (`session-memory-auto-save.ps1`, 4 iteráció)
- **PR #174** — Sourcery 3 findings javítva (`$script:ErrorActionPreference` scope, summary, fallback log)
- **PR #176** — Sourcery 4 findings javítva (explicit waits, stabil selectors, health check exit 1, `--with-deps` komment)

### Quality gate
- Backend: **978/978 zöld**
- Penztar-client: **97/97 zöld**
- Frontend-react: zöld
- Playwright live (T10 smoke): zöld
- Open PR: 0 / remote branch: 1 (main) — branch policy v2 teljesítve
- Hetzner deploy: minden merge után SUCCESS

### Upgrade path
- **Backend**: automatikus Hetzner deploy main merge után (nincs manuális lépés)
- **Frontend (admin)**: automatikus Hetzner deploy (deploy-frontend job)
- **Pénztáros Electron kliens**: **v2.2.3 installer telepítése JAVASOLT** a PR #163 fix miatt.
  A régi v2.2.2 desktop app-ban a VETEL tranzakció 400-as hibával elesik, amíg a user nem frissíti.

---

## [2.2.2] - 2026-04-23 hotfix (vault cash flow javitas)

### Fixed - Uzletmenet-kritikus vault/ertektar cash flow

**Root cause:** a v2.2.1 elesi teszt soran detektaltuk, hogy a Collection/Distribution/Transfer COMPLETED statuszra valtasa NEM tolta a kenyleges penzt a CurrencyStock + CashBalance tablakba. Csak status update tortent, tehat az ertektari cash flow kompletten inkonzisztens volt.

**Javitasok (egy hotfix-ben):**
- **V159 migration**: minden aktiv vault_territory-hez `currency_stock` HUF rekord a base_capital alapjan (WAC=1.0). Ez elintezi, hogy a VaultBankTransaction.createBankTransaction BUY ne dobjon 500-at "Nincs elegendo keszlet" hibaval.
- **VaultStockFlowService (uj)**: kozos helper service a Collection/Distribution/Transfer-hez. A `applyCollection` / `applyDistributionLine` / `applyTransfer` metodusok tolakolnak a vault CurrencyStock + branch CashBalance rekordokon.
- **VaultCollectionService.updateStatus**: COMPLETED-kor source branch CashBalance csokken + vault CurrencyStock no. Idempotent (csak ha oldStatus != COMPLETED).
- **VaultDistributionService.updateStatus**: COMPLETED-kor vault CurrencyStock csokken + target branch CashBalance no (per line). Idempotent.
- **VaultTransferService.completeTransfer**: branch->branch eseten CashBalance-t hasznaljuk (nem CurrencyStock WAC-ot), a PR #131 BR017->BR035 500 hiba megszunik. VAULT erintettseg eseten eredeti WAC logika marad.
- **VaultTerritoryService.create**: uj territory-hez HUF CurrencyStock auto-init a baseCapital alapjan.
- **VaultDistributionRepository**: `LEFT JOIN FETCH d.lines` a list query-khez, hogy a GET /distribution items=0 bug megszunjon.

### Verzio bump
- `package.json`, `penztar-client/package.json`, `frontend-react/package.json`, `backend/pom.xml`: 2.2.1 -> 2.2.2

## [2.2.0] - 2026-04-23 (Sprint 5-7 roadmap + Electron singleton + 9 AI review fix)

### Kotelezo ervenyu alaptorveny (CLAUDE.md)
- **Push = commit + merge to main AZONNAL**: Tilos nyitott PR / uncommitted feature branch hosszabb ideig - AI ugynokok javitasai es reported bugok fixei nem ernek el main-re, production nem javul.

### Added - Sprint 7.1 Ertektar leltar (Stocktake) modul
- **V157 Flyway migration**: `vault_stocktake_session` + `vault_stocktake_item` tablak generated `discrepancy` + `discrepancy_value` oszlopokkal (PostgreSQL).
- **Backend entity-k**: `VaultStocktakeSession` (Workflow: OPEN -> IN_PROGRESS -> REVIEW -> CLOSED / CANCELLED), `VaultStocktakeItem` (cimletenkent expected vs. actual).
- **VaultStocktakeService**: createSession (auto-init banknote_inventory-bol), setItemActual, moveToReview, closeSession (FOERTEKTAR+), cancelSession, getSummary discrepancy listaval, territoryId resolve + cross-tenant check.
- **VaultStocktakeController**: 7 REST endpoint (/api/v1/vault-stocktake).
- **Frontend pages**: `VaultStocktakeListPage` (session lista, KPI kartyak, uj leltar modal) + `VaultStocktakeDetailPage` (cimletenkenti felvetel, REVIEW/CLOSE workflow).
- **Penztar-client offline SyncEngine**: `pending_stocktake_items` SQLite tabla, `queueStocktakeCount` IPC handler, `syncStocktakeItems` sync-engine metodus retry + error tracking-gel.

### Added - Sprint 6.2 Compliance Dashboard (Pmt. 2017. LIII. tv.)
- **GET /api/v1/aml/rolling-window-audit** endpoint: 8 napos gordulo limit feletti ugyfelek listaja + high-risk flag.
- **Frontend ComplianceDashboardPage**: OVERDUE bejelentesek, Pending bejelentesek, 8 napos rolling window, napi AML summary KPI kartyakon.
- **RollingWindowAuditDto**: customerId, exceedPercent, windowDays, highRiskFlag.
- **TransactionRepository.findRollingWindowAuditCandidates**: `GROUP BY customerId HAVING SUM >= threshold` query.

### Added - Sprint 5.3 C2 AML hard-block (Pmt. 8 napos gordulo)
- **AmlCheckResult uj mezok**: `rollingWindowExceeded`, `rollingWindowLimit`, `rollingWindowTotal`, `rollingWindowDays`, `requiresManagerApproval`, `managerApprovalReason`.
- **AmlService.checkAllThresholds**: 4.5M HUF rolling limit explicit ellenorzes + TranzTipus >= 4 eseten manager approval kotelezo.
- **TransactionOperationHelper**: ValidationException hard-block ha `requiresManagerApproval=true` es nem supervisor+.

### Added - Sprint 7.2 CB-016 VAT dinamikus resolution
- **ContributionService.resolveRate**: SystemParameter-bol olvas (`nav.vat-rate.STANDARD`, `mnb.supervisory-fee-rate`) fallback-barat logikaval, hardcoded 0.27/0.0001 kulcsok helyett.
- **SystemParameterService.getValue(key, defaultValue)** overload: null-safe, @Slf4j log.warn fallback elott.

### Added - Sprint 6.1 C3 Evnyito scheduler
- **YearOpeningScheduler**: @Scheduled cron `0 15 0 1-7 1 *` (januar 1-7, 00:15 Europe/Budapest), minden ceghez idempotensen futtatja az evnyitot.

### Added - Cognee + Obsidian MCP integracio
- **docker-compose.mcp.yml** `knowledge-mcp` profile: `mcp-cognee` (port 8820), `mcp-obsidian` (port 8821).
- **.mcp.json**: Claude Code MCP server lista (filesystem, git, fetch, postgres, cognee, obsidian).
- **docs/MCP_INTEGRATION.md**: setup guide (env, Obsidian Local REST API plugin, troubleshoot).
- **scripts/session-memory-save.sh**: session handoff auto-save (YAML -> Cognee ingestion + Obsidian PUT).

### Fixed - Uzletmenet-kritikus Electron singleton lock
- **main.ts `app.requestSingleInstanceLock()`**: ha mar fut egy penztar-client instance, a masodik indulas azonnal kilep es az elso ablakot hozza elotertbe.
- **start-valuta-ecosystem.ps1 idempotent Electron check**: `Get-Process electron` ellenorzes, duplikalt instance NEM indul.
- **Hiba elotte**: 12+ Electron process (3 main window + 9 helper) fut parhuzamosan, amibol duplikalt tranzakciok, versengo SQLite write-ok, offline queue inkonzisztens allapot keletkezhetett.

### Fixed - 9 AI review feedback (Sourcery + Codex)
- **PR #128 Sourcery 5 issue**: JPQL `$Status.OPEN` startup-breaker, division-by-zero threshold=0, territoryId silent ignore, LocalDateTime.now() loopon belul, SystemParameterService exception swallow.
- **PR #129 Sourcery + Codex**: V156 ON CONFLICT DO NOTHING (V158 backport idempotency fix), JPQL CASE WHEN COUNT > 0 portability, name trim consistency (validacio+DB+persistence), getCompanyIdForJson -> getCompanyId rename, findByIdAndCompanyId multi-tenant query filter, existsByCompanyIdAndNameIgnoreCase DB-szintu check.

### Security
- **@xmldom/xmldom 0.8.12 -> 0.8.13**: 4 high severity CVE fix (GHSA-2v35-w6hq-6mfw, f6ww-3ggp-fr8h, x6wf-f3px-wcqx, j759-j44w-7fr8).
- **crypto.randomUUID polyfill**: non-secure context (HTTP LAN IP) eseten fallback implementacio (PR #124).

### Frontend
- **index.html title**: `RepZtecH Exclusive Best Change - Pénztári Rendszer` (elirasi hiba) -> `Valuta Pénztári Rendszer - Best Change`.
- **3 uj route**: `/vault-stocktake`, `/vault-stocktake/:id`, `/compliance`.

### Dependency bumps
- Lombok 1.18.44 -> 1.18.46 (pom.xml)
- Spring Boot 3.5.13 (latest stable, 3.5.14 meg nem letezik)
- Tomcat 10.1.54 override (CVE-2026-34483/34486/34487 miatt)

## [2.1.7] - 2026-04-21 (kumulalt AI review + production URL SSOT)

### Added
- **config/production-urls.json**: Single Source of Truth a production URL-ekre (domain, base_url, api_url, health_url, type_base, CORS origins). Minden komponens innen olvashatja build-time vagy deploy-time.
- **backend/.../ProductionUrls.java**: Java konstans osztaly (DOMAIN, BASE_URL, API_URL, HEALTH_URL, TYPE_BASE, FALLBACK_*). AI review PR #97 Sourcery P2 javaslat kielegitese.
- **installer/build-common.ps1**: Get-VersionFromPackageJson helper (DRY kozos version-olvas, JSON validation, clear error), mind a 4 installer build script dot-sources.

### Fixed (PR #104 - kumulalt AI review javitasok)

**P1 bug_risk:**
- **V155 migration duplicate pre-cleanup** (PR #98 Codex): production DB duplikatum eseten a CREATE UNIQUE INDEX elszallt volna. Pre-check DO block RAISE EXCEPTION + duplicate listing.
- **Launcher path quoting** (PR #100 Sourcery): Set-Location apostrophe-s path-on elszallt. Fix: Start-Process -WorkingDirectory.
- **Penztar-client main.ts packaged-client .env read** (PR #97 Codex): dotenv CSAK dev modban mukodik, packaged appban a process.env ures. Fix: userData/.env kozvetlen parsolas.

**P2 suggestion:**
- **RateCreationService competitorCode empty guard** (PR #98 Sourcery): non-alphanumeric name eseten fallback "COMP".
- **ConversionPage reset outputs** (PR #98 Codex): baseSellRate<=0 eseten reset.
- **fix-branch-code.mjs hardening** (PR #97): explicit args + cwd-independent wasm resolve.
- **Installer version helper centralization + JSON validation** (PR #103 Sourcery).

### Refactored (production URL SSOT)
- **ProblemDetailBuilder.TYPE_BASE** mostantol ProductionUrls.TYPE_BASE-rol olvas (backward-compat alias marad).
- Docu: config/production-urls.json a hibagyujto pont, minden uj URL-hivatkozas ott dokumentalando.

### Dependency bumps (dependabot)
- actions/checkout 4 -> 6 (PR #22)

## [2.1.6] - 2026-04-21

### Kotelezo ervenyu alaptorveny (CLAUDE.md)
- **Production-first**: TILOS divergens lokalis fejleszto stack. Minden dev a Hetzner production (https://excvaluta.com) ellen megy. Lokalis DB seed/manualis INSERT TILOS - Flyway migration az egyetlen ut.
- **Session memory workflow**: minden session elejen .remember/remember.md + docs/knowledge/memory/*.yaml be-olvasas, session vegen automatikus mentes (YAML + QMD + Cognee + Obsidian TODO).
- **Komplex okoszisztema**: a user "valuta program megnyitasat" utasitva TILOS reszlegesen (csak frontend vagy csak Electron) indulni - a teljes stack (frontend + Electron + Hetzner backend) egyben indul.
- **AI code review automation**: Sourcery + Codex PR review-k Claude Code Action-nel auto-javitas (.github/workflows/ai-review-auto-fix.yml).

### Added
- **scripts/start-valuta-ecosystem.ps1**: production-first launcher - Hetzner health check + Vite + Electron.
- **scripts/stop-valuta-ecosystem.ps1**: teljes leallitas (electron/node/Vite processek + port 3000/8080).
- **penztar-client/scripts/fix-branch-code.mjs**: one-off SQLite javito script a regebbi SetupWizard-telepitesekhez.
- **V155 migration**: @Version optimistic locking Customer/DailyBalance/DailySession/AmlReport entitasokon + unique constraint-ek (uq_daily_session_branch_date, uq_transaction_receipt_branch_date).
- **Auto-migration main.ts-ben**: regebbi SetupWizard (v2.1.3 elotti) telepiteseken VITE_BRANCH_CODE .env-bol SQLite config-ba at-masolas.
- **docs/LESSONS_LEARNED.md**: 14 lecke 8 kategoriaban (PowerShell, Vite/Dev szerverek, GitHub Actions, JPQL, React/TS, stb.).

### Fixed
- **Launcher npm.cmd bug** (PR #100): Start-Process -FilePath "npm" Unix shell scriptre nyilt -> %1: nem Win32 alkalmazas. Fix: child powershell.exe, ami megtalalja az npm.cmd-et.
- **SetupWizard Tovabb gomb levagodik** (PR #101): kartya max-h-[95vh] + content min-h-[520px] + overflow-hidden kombo kivagta a footert. Fix: content overflow-y-auto, footer/header shrink-0.
- **Penztar-client savePendingTransaction** (PR #97): "SetupWizard nem futott le: branch_code SQLite config hianyzik" hiba - a v2.1.3 elotti SetupWizard nem irta SQLite-ba a branch_code-ot.
- **RateCreationService NPE** (PR #98, cherry-pick cbe3c819): cr.getCompetitor() null-guard hozzaadva (toCompetitorRateDTO).
- **PrintTemplateService.valueOf NPE** (PR #98, cherry-pick cbe3c819+7a09acb4): valueOf() -> parseTemplateType() wrapper, null/blank input ValidationException.
- **RateCategoryService.valueOf** (PR #98): RateCategoryType.valueOf() try-catch -> 404 helyett 500.
- **CameraConfigPage JSON.parse** (PR #98): try-catch defense korrupt electron config ellen.
- **ConversionPage div-by-zero** (PR #98): toRate.baseSellRate > 0 guard.
- **Penztar-client dev default localhost override** (PR #97): TILOS a server_url automatikus localhost:8080-ra iras dev modban. Helyette: VITE_API_URL-t hasznaljuk, fallback https://excvaluta.com/api/v1.

### Removed (deprecate)
- **scripts/start-all-dev.{cmd,ps1}** (PR #99): legacy dev launcher torolve - Docker PostgreSQL + mvn spring-boot:run + frontend dev - sertette a production-first alaptorvenyt.

## [2.1.5] - 2026-04-20

### Added (valos munkakor-adatok + 3+1 program-tipus)
- **V145-V149 Flyway migraciok**: 64 penztar + 194 dolgozo EBC-xlsx alapjan, 4 duplikatum deaktivalas (BORSI/KASZA/KOSA V111+V145 atfedes, Madar Zoltan xlsx-ben ketszeres), BALI=ertektar, BORSI+KASZA=foertektar.
- **EBCiroda kanonikus 14 role integracio** (V147): ugyvezeto, irodavezeto, foertektar, irodai_dolgozo, teruleti_vezeto, ertektar, belso_ellenor, biztonsagi_vezeto, berszamfejto, csoportvezeto, penzugyi_vezeto, penztar, ertekszallito, arfolyam_nezo.
- **V150 permission seed**: 28 system permission + 14 role-permission mapping (penztar 7, ertektar 10, foertektar 14, teruleti_vezeto 19, ugyvezeto 28 teljes).
- **3+1 program-tipus szeparacio**:
  - Lokal Valutavalto Penztar (penztar role, 140 dolgozo)
  - Lokal Ertektar (ertektar role, 15 dolgozo)
  - Lokal Ertekszallitas (ertekszallito role, 22 dolgozo - csak fizikai szallitas dokumentalas)
  - Szerver bongeszo (ugyvezeto+foertektar+irodavezeto+belso_ellenor+teruleti_vezeto+egyeb szerver role, 22 dolgozo)
- **Backend validAppModes**: login response tartalmazza a dolgozo role-jabol szarmaztatott engedelyezett program-tipusokat (penztar / ertektar / ertekszallito / full).
- **SetupWizard uj 'program' lepes**: 3 kartya valasztas + SQLite app_mode save.
- **Transit tracking** (uton levo csomagok, csomagvesztes csokkentes):
  - TransitController: GET /incoming + /outgoing, POST /{type}/{id}/acknowledge
  - TransitPage.tsx: 2 tab (Bejovo + Kimeno), 30s auto-poll, Atvetel gomb validalasra
  - TransitBadge topbar widget: pending csomag count + gyors navigacio
- **Admin bulk email import** (WorkerPage): CSV/Excel paste modal, PATCH /workers/bulk-email, szuletes idempotencia-kulcs per hivas.
- **/workers admin route** + isActive/active JSON kulcs compat (eddig minden Inaktivnak tunt).
- **Regio-alapu dolgozo dropdown a LoginPage-en** (/public/workers?branchCode=XXX): Hetzner-rol tolti a penztarosokat, no cache.
- **Dolgozoi ID-KOD mapping**: xlsx 127 penztaros ID osszekotesse (W007570 BORSI, stb.).

### Fixed
- **SetupWizard DNS**: api.excvaluta.com -> excvaluta.com (nem letezo aldomain, csak root domain a Cloudflare-en).
- **DEFAULT_BRANCHES**: 60 fiktiv iroda -> 2 valos (KORUT + TISZA Szeged), fallback esetben.
- **Flyway lokalis telepito**: spring.flyway.enabled=true + ddl-auto=none (eddig false miatt ures DB).
- **CORS**: app://localhost + http://localhost:3000/5173/8080 + file:// (Electron + dev szerverek).
- **fix-backend-acl.ps1**: LocalSystem SID (nem NetworkService - az NSIS ObjectName egyez).
- **V150 permission INSERT created_at NOT NULL**: NOW() hozzaadva az INSERT-ekhez.
- **WorkerRepository.findByCompanyIdAndRegionAndActiveTrue**: property 'active' (nem 'isActive', a Worker.java entity fieldje ezt hasznalja).

### Changed
- Verzio: 2.1.3 -> 2.1.5 (2.1.4 kihagyva - belso fejlesztesi iteracio).
- Menustruktura teljesen ujra - 4 program-tipus szerint szurve (canonicalRoles array + appMode metszet).
- LoginPage SERVER_ALLOWED_ROLES -> SERVER_ALLOWED_CANONICAL_ROLES (EBCiroda 14 role hozzadva).
- Default login route: canonical role szerint (penztar -> /cashier, ertektar -> /treasury, ertekszallito -> /shipments, szerver -> /dashboard).

### Hetzner deploy realtime
- 66 branch + 197 worker (193 aktiv) a prod DB-ben.
- /api/v1/public/branches + /public/workers + /transit/* + /workers/bulk-email mind elo a https://excvaluta.com-on.

## [2.1.3] - 2026-04-20

### Fixed
- **Setup Wizard Hetzner kapcsolat** (kritikus blokker, user report: "nem akarja csatlakoztatni a Hetznerhez a lokalisan futo modellt"): `DEFAULT_API_URL` `https://api.excvaluta.com/api/v1` -> `https://excvaluta.com/api/v1`. A `api.` aldomain NEM letezik DNS-ben (`nslookup api.excvaluta.com` Non-existent domain), csak a Cloudflare-en keresztul futo root domain fogad kereseket (`curl https://excvaluta.com/api/v1/auth/bootstrap-status` -> 200 `{"completed":false}`). A 2.1.0 / 2.1.1 kliensek nem tudtak csatlakozni. Fajlok: `frontend-react/src/pages/setup/SetupWizard.tsx`, `deploy/nginx/*.conf`, `deploy/docker-compose.prod.yml`, `deploy/.env.example`, `deploy/README.md`, `backend/src/main/resources/application-production.properties`.
- **First-run wizard hamis branch-fallback** (user report: "nem olvassa be a dolgozoi es penztar adatbazist, nem azonositja a dolgozot"): `penztar-client/electron/first-run.ts` `DEFAULT_BRANCHES` korabban 60 fiktiv iroda. Ha a backend nem volt elerheto (DNS bug miatt mindig az), wizard fallbackelt erre a listara. Felhasznalo valasztott hamis branchet, bootstrap-admin "A ceghez nincs branch" HTTP 400 (AdminBootstrapService.java:137). Most KORUT + TISZA (Szeged, EBC), egyezik a Hetzner DB seed-jevel.
- **Lokalis backend Flyway letiltva** (ures DB uj install utan): `installer/Penztar-Setup.nsi` (install + upgrade ag) + `build-installer.ps1` + `build-final.ps1` mind `spring.flyway.enabled=false` + `spring.jpa.hibernate.ddl-auto=update` kombinacioval generaltak az `application-local.properties`-t. V110-V144 seed-migraciok (company `EBC`, branches, workers) nem futottak le. AdminBootstrapService 400. Most `spring.flyway.enabled=true` + `spring.flyway.baseline-on-migrate=true` + `out-of-order=true` + `ddl-auto=none`. A 144 V-migracio auto-lefut.
- **CORS tul szuk**: `cors.allowed-origins` most `http://localhost:3000,http://localhost:5173,http://localhost:8080,app://localhost,file://`.
- **fix-backend-acl.ps1 helytelen SID**: `NetworkService` -> `*S-1-5-18` (LocalSystem) grant, megegyezoen az NSIS L795 `ObjectName LocalSystem`-mel.

### Changed
- **Verzio bump**: `2.1.1` / `2.1.2` (thin) -> `2.1.3` egysegesen. 11 fajl: `backend/pom.xml`, `frontend-react/package.json`, `penztar-client/package.json`, `installer/build-installer.ps1`, `installer/build-final.ps1`, `installer/build-installer-thin.ps1`, `installer/build-cleanup.ps1`, `installer/Penztar-Setup.nsi`, `installer/Penztar-Cleanup.nsi`, `installer/Penztar-Setup-Thin.nsi`, `installer/tests/installer-validation-suite.ps1` (`1.5.0` -> `2.1.3`).

### Hetzner deploy realtime
- `excvaluta.com` GET/POST `/api/v1/auth/bootstrap-status`, `/public/branches?companyCode=EBC`, `/auth/login` mind 200 vagy 401 (ertelmes) valaszt adnak 2026-04-20-an. `api.excvaluta.com` DNS Non-existent.

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
