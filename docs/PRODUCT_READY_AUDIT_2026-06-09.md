# Product Ready audit es javitasi terv - 2026-06-09

## Scope

Feladat: az `Anti/` es `EXCMD/` mappakban, valamint a Claude Code/vault handoffokban
talalhato leirasokhoz kepest felmerni a repo aktualis allapotat, es Product Ready celra
tenyalapu javitasi tervet adni.

Munkamodszer:
- `Anti/` es `EXCMD/` fajllista celzott feldolgozasa.
- Friss EXCMD master/audit riportok osszevetese a jelenlegi `main` munkafaval.
- Backend, frontend es Electron kliensek build/test/lint kapuinak futtatasa.
- Minden allitasnal kulon valasztva: **bizonyitott kodteny**, **dokumentumallitas**,
  **uzleti/compliance dontes kell**, **nem vizsgalt eles kornyezet**.

## Repo allapot

- Branch: `main`, `origin/main`-hez kepest 6 committal elorebb.
- Munkafa az audit kezdeten: untracked `.agents/`.
- Az audit soran javitott build-script hiba:
  - `package.json` root Maven parancsai Windows alatt `./mvnw` miatt buktak.
  - Javitas: `build:backend` es `test:backend` Windows-kompatibilis `mvnw.cmd` hivasra allitva;
    `dev:backend-only` a mar letezo cross-platform `scripts/dev-backend.mjs` launchert hasznalja.
  - `scripts/dev-backend.mjs` Windows parancsa relativ `.\mvnw.cmd`-re lett allitva a backend cwd-bol.

## Forras-dokumentumokbol levont kovetkeztetes

### Product Ready definicio

A `vault/references/product-ready-roadmap-2026-05-06.md` mar maga is elveti a szazalekos
"85%/95%" becslest, ha nincs meresi alap. Product Ready csak akkor mondhato ki, ha legalabb:
- P0 tetelek keszek es bizonyitottak.
- Acceptance suite zold eles vagy eles-szeru szerveren.
- DR/backup runbook tesztelt.
- Monitoring dashboard folyamatosan mukodik.
- End-user manualok nem-IT kollegaval validalva.
- NGM/AML compliance check pozitiv.

Mai audit alapjan: a repo lokalis build/test allapota jo, de **Product Ready allapot nem
allithato**, mert az eles acceptance, DR restore, 7 napos monitoring es jogi/compliance go-live
bizonyitas nincs lefuttatva ebben a korben.

### EXCMD allapot

Az `EXCMD/_compare/00-KONSZOLIDALT-GAPS.md` 2026-05-22-re 23/23 korabbi gapet kesznek jelol.
A frissebb `EXCMD/_ai-protokoll/2026-06-04-excmd-teljes-audit-statusz-es-javitas.md` szerint a
2026-06-02 master-gap lista nagy resze elavult, es mar csak nehany nyitott/uzleti donteses tetel
maradt.

Mai kodellenorzes ezt reszben tovabb frissiti:
- `profit_log` mar nem "0 hivo": `WacService.recordSellProfitIfEnabled`, after-commit hivasok es
  sztorno-korrekciok leteznek.
- FATF allampolgarsag/kockazat be van drotozva az AML utba.
- 50M forras-igazolas es 10M+ AML jovahagyas flag-gated backend/UI elemei leteznek.
- Reszletes bizonylat-szuro mar joval tobb, mint "csak bizonylatszam".

## Lefuttatott ellenorzesek

Zold:
- `npm run typecheck`
  - `frontend-react`, `penztar-client`, `arfolyam-keszito-client`, `kozponti-client` TypeScript OK.
- `.\mvnw.cmd test` a `backend/` alatt
  - 1967 teszt, 0 failure, 0 error.
- `npm --prefix frontend-react test -- --run`
  - 105 test file, 1241 teszt PASS.
- `npm --prefix penztar-client test`
  - 10 test file, 204 teszt PASS.
- `npm run lint`
  - exit 0; `agentward` es `ci-error-digest` OK, frontend 0 error.
- `npm run build:all`
  - backend jar, frontend build, penztar, arfolyam-keszito es kozponti build OK.

Nem blokkoló, de Product Ready backlog:
- Frontend lint: 836 warning, foleg `i18next/no-literal-string`.
- Vite build: nagy chunk warning es ineffective dynamic import warning.
- Maven/JDK 25 warningok: deprecated/native-access figyelmeztetesek.
- Backend compile warningok: Jackson/Spring deprecation, tesztoldali unreachable catch.

## Aktualitas szerinti gap lista

### P0 - Product Ready blokkolok, de nem mind kodhiba

1. **Eles acceptance nincs bizonyitva ebben a korben**
   - Lokalis unit/type/build zold, de nincs friss Playwright happy-path eles/eles-szeru szerveren.
   - Kovetkezo bizonyitas: vetel, eladas, konverzio, sztorno, napnyitas, napzaras, foglalo,
     10M+ AML jovahagyas, 50M forrasigazolas, receipt print/reprint, offline sync.

2. **DR/restore teszt nincs bizonyitva**
   - Dokumentacios/operacios Product Ready feltetel.
   - Kell: Postgres dump -> restore -> app indul -> smoke flow.

3. **Monitoring 7 napos bizonyitas nincs**
   - Build zold, de production observability Product Ready feltetel nem igazolt.
   - Kell: uptime, error rate, p99 latency, ClientErrorLog dashboard, alert teszt.

4. **Compliance go-live kapcsolok üzleti/jogi dontese**
   - `AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT` migracioban aktivalt, mas enforcementek flag-gatedek.
   - Meg kell erositeni: hard-block vs. warn/proceed, supervisor flow, korlevel block, FATF tier action,
     szankcios pontszam-kuszobok.

### P1 - valodi fejlesztesi / minosegi kockazatok

1. **Sajat hataskoru R/S napi limit concurrency**
   - 2026-06-09: az elavult "read-check-write nem atomikus" kodmegjegyzes javitva.
   - 2026-06-09: unit/contract bizonyitek mellett valos PostgreSQL tranzakcios lock-teszt is kesz:
     `WorkerRepositoryPostgresLockIT` Testcontainers PostgreSQL-en tartja az elso
     `PESSIMISTIC_WRITE` sort, es `lock_timeout` mellett igazolja, hogy a masodik tranzakcio
     nem szerzi meg ugyanazt a sort.

2. **NAV penztargep explicit parancsok**
   - 2026-06-09: az alacsony szintu `NavIntegrationController` placeholder kommentje javitva:
     az uzleti ut a `CashRegisterController` auditált endpointjain megy.
   - 2026-06-09: `POST /api/v1/cash-register/command` explicit parancs endpoint bekotve
     `DAY_OPEN`, `DAY_CLOSE`, `CURRENCY_LIST_CLEAR`, `CURRENCY_LIST_SET` parancsokra.
   - A napi nyitas/zaras most a legacy NAV QR payloadot hasznalja:
     `fiscat/AEE|OP`, illetve `fiscat/AEE|DC|0|0`.
   - Valuta torles/betoltes payload: `fiscat/AEE|CCL`, illetve determinisztikus
     `fiscat/AEE|CYS|...` sorok. A bridge tovabbra is fail-closed: eles driver vagy explicit
     szimulacio nelkul ERROR event/HTTP 502.
   - Hianyzik meg: valodi NAV penztargeppel vagy gyartoi driverrel vegzett acceptance.

3. **Raiffeisen Bank API / admin konfiguracio**
   - 2026-06-09: `bank_api_config` tabla, admin REST endpointok, titkositott
     `client_secret` persistence, secret-maszkolt DTO es manualis Raiffeisen fetch endpoint
     implementalva.
   - 2026-06-09: a Raiffeisen arfolyam letoltes a konfiguralt endpointot hasznalja,
     `SUCCESS`/`FAILED`/`SKIPPED` utolso futasi statust ir, es a bank integration
     monitoring ezt visszaadja.
   - A `REST_PRIMARY_WITH_HTML_FALLBACK` mod tudatosan HTML fallbacket futtat, mert a repoban
     nincs validalt Raiffeisen REST/OAuth2/mTLS szerzodes vagy credential.
   - Hianyzik meg: banki sandbox/production credential, hivatalos REST protokoll bizonyitek,
     Darius/Raiffeisen valodi API transport acceptance.

4. **"MEGSEM" megszakitott tranzakcio bizonylat**
   - 2026-06-09: dedikalt `CANCELLED_TRANSACTION` receipt tipus es backend/frontend rogzitesi ut
     implementalva, celzott tesztekkel bizonyitva.
   - 2026-06-09: a szerveres `CANCELLED_TRANSACTION` bizonylatbol Electron `PrintReceiptData`
     keszul; a frontend preview, az Electron HTML/ESC/POS printer es a soros printer is ismeri a
     `cancelled_transaction` tipust. A szerveres `isPrinted` csak sikeres fizikai print utan allitodik.
   - Hianyzik meg: fizikai nyomtatas/ujranyomtatas acceptance clean penztari kliensen, valodi nyomtatoval.

5. **Frontend i18n debt**
   - 2026-06-09: automatikusan javithato lint warningok es egy React Hooks dependency warning
     javitva.
   - Lint gate nem bukik, de 833 `i18next/no-literal-string` warning maradt; ez nem Product
     Ready minosegi cel, de kulon, nagyobb UI-szoveg migracios munka.

### P2 - polish / teljessegi feladatok

1. Chunk splitting es build warningok csokkentese.
2. JDK 25 native-access/deprecation warningok kezelese vagy tamogatott JDK 21 runtime rogzitese.
3. End-user manualok kepernyofotokkal frissitese a jelenlegi UI-hoz.
4. Telepito/installer friss-szuletesi smoke a harom Electron kliensre.

## Javitas, amit ez az audit mar elvegzett

### Build-gate javitas

Hiba: `npm run build:all` Windows alatt elbukott:

```text
'.' is not recognized as an internal or external command
```

Ok: root `package.json` `build:backend` / `test:backend` scriptek Unix-stilusu `./mvnw` hivasra
epultek, mikozben a repo futtatasi kornyezete Windows/PowerShell.

Javitas:
- `build:backend`: `cd backend && mvnw.cmd package -DskipTests`
- `test:backend`: `cd backend && mvnw.cmd test`
- `dev:backend-only`: `node scripts/dev-backend.mjs`
- `scripts/dev-backend.mjs`: Windows alatt backend cwd-bol `.\mvnw.cmd`

Bizonyitas: javitas utan `npm run build:all` exit 0.

## Product Ready vegrehajtasi pass - 2026-06-09

### R/S penztarosi sajat arfolyam napi limit

Teny: a `TransactionService.validateAndNormalizeCashierCustomRateQuota` mar pesszimista
`workerRepository.findByIdForUpdate(workerId)` zarral szerializalja az azonos penztaroshoz tartozo
kvotaellenorzeseket. Az audit soran elavult, ezzel ellentmondo "read-check-write nem atomikus"
komment maradt a kodban; ez javitva lett.

Javitas:
- a komment a tenyleges lockolt viselkedesre lett frissitve;
- `TransactionServiceCashierQuotaTest` most explicit ellenorzi, hogy:
  - `flag=false` es sub-threshold esetben nincs lock;
  - 400k+ custom-rate es limit-elutasitas eseten van `findByIdForUpdate(WORKER_ID)` hivas.

Bizonyitas:
- `cd backend && .\mvnw.cmd -Dtest=TransactionServiceCashierQuotaTest test`
  - 7 teszt, 0 failure, 0 error.
- `npm run acceptance:local:backend`
  - `TransactionServiceCashierQuotaTest` + `WorkerRepositoryLockContractTest`;
  - 8 teszt, 0 failure, 0 error.

2026-06-09 lock contract folytatas:
- `backend/src/test/java/hu/puzzleir/valuta/repository/WorkerRepositoryLockContractTest.java` letrehozva.
- A teszt reflection alapon rogziti, hogy `WorkerRepository.findByIdForUpdate(Long)`:
  - `@Lock(LockModeType.PESSIMISTIC_WRITE)` annotaciot hasznal;
  - explicit `SELECT w FROM Worker w WHERE w.id = :id` query-n keresztul olvas;
  - `Optional<Worker>` return contractot tart.
- `backend/src/test/java/hu/puzzleir/valuta/repository/WorkerRepositoryPostgresLockIT.java` letrehozva.
- `backend/pom.xml` test scope-ban Testcontainers `junit-jupiter` es `postgresql` modult hasznal.
- `acceptance:local:postgres-lock` root script bekotve, az osszesitett `acceptance:local` ezt is futtatja.
- Bizonyitas:
  - `cd backend && .\mvnw.cmd -Dtest=WorkerRepositoryPostgresLockIT test`
  - 1 teszt, 0 failure, 0 error.

2026-06-09 MEGSEM receipt bekotes utan:
- `npm run acceptance:local:backend`
  - `TransactionServiceCashierQuotaTest` + `WorkerRepositoryLockContractTest` + `ReceiptServiceB7Test`;
  - 29 teszt, 0 failure, 0 error.

### Helyi acceptance smoke gate

Javitas:
- root `acceptance:local` script hozzaadva:
  - `acceptance:local:backend`: celzott penzugyi/backend regressziok;
  - `acceptance:local:postgres-lock`: Testcontainers PostgreSQL row-lock bizonyitek;
  - `acceptance:local:flows`: Mockito-alapu backend uzleti service-flow tesztek;
  - `acceptance:local:frontend`: `frontend-react` Playwright smoke.
- `frontend-react` `test:e2e:smoke` script hozzaadva.
- `frontend-react/e2e/smoke.spec.ts` masodik smoke tesztje is mockolja a
  `/api/v1/auth/refresh-cookie` hivasat, igy nem termel Vite proxy `ECONNREFUSED` zajt backend nelkul.

Bizonyitas:
- `npm run acceptance:local`
  - backend: 7 teszt PASS;
  - frontend Playwright smoke: 2 teszt PASS.

Korlatozas: ez helyi smoke gate, nem eles-szeru full acceptance. Nem bizonyitja a teljes vetel/eladas/
konverzio/sztorno/napzaras/NAV/nyomtatas/offline sync folyamatot.

### Compliance flag matrix es regresszios kapu

Javitas:
- `docs/COMPLIANCE_FLAG_MATRIX_2026-06-09.md` letrehozva a kodbeli defaultokkal, migracios tenyallassal,
  enforcement helyekkel es megmarado Product Ready dontesekkel.
- root `compliance:flags:test` script hozzaadva.
- `scripts/compliance-golive-export.ps1` letrehozva a staging/production `system_parameter` exporthoz.
- `scripts/compliance-golive-export.ps1` Dockeres PostgreSQL klienseszkoz-fallbacket is tud hasznalni,
  ha a lokalis `psql` nincs PATH-on.
- `scripts/compliance-golive-synthetic-export.ps1` letrehozva: ideiglenes Docker PostgreSQL
  kontenerben minimalis `system_parameter` tablat seedel, majd query modban futtatja az exportot.
- `docs/COMPLIANCE_GO_LIVE_DECISION_TEMPLATE_2026-06-09.json` letrehozva a compliance go-live dontes
  explicit, nem titkos JSON sablonjakent.
- `scripts/compliance-golive-decision-verify.ps1` letrehozva a dontesfajl ellenorzesere. Preflight
  modban REVIEW-t ad a hianyzo jovahagyasi mezokre, `-RequireApprovedDecision` modban fail-closed.
- root parancsok:
  - `npm run compliance:golive:preflight`;
  - `npm run compliance:golive:export`;
  - `npm run compliance:golive:synthetic`;
  - `npm run compliance:golive:decision:preflight`;
  - `npm run compliance:golive:decision:approved`.

Bizonyitas:
- `npm run compliance:flags:test`
  - 40 backend teszt, 0 failure, 0 error.
- `npm run compliance:golive:preflight`
  - mode: `preflight`;
  - failed: 0;
  - reviewRequired: 0;
  - riport: `security-reports/compliance-golive/20260609-093900/report.md`.
- `npm run compliance:golive:synthetic`
  - mode: `query`;
  - PostgreSQL client tools: `docker:postgres:16-alpine`;
  - failed: 0;
  - reviewRequired: 3;
  - `PMT_STRICT_ENFORCEMENT` es `AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT` PASS;
  - `AML_HIGH_VALUE_APPROVAL_ENFORCEMENT`, `AML_FATF_TIER_ENFORCEMENT`,
    `CIRCULAR_ACK_BLOCKING_ENFORCEMENT` REVIEW, mert ezek uzleti/compliance donteshez kotottek;
  - riport: `security-reports/compliance-golive/20260609-114008/report.md`.
- `npm run compliance:golive:decision:preflight`
  - 16 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 8 ellenorzes REVIEW;
  - riport: `security-reports/compliance-golive-decision/20260609-122329/report.md`.
- `npm run compliance:golive:decision:approved`
  - vart jelenlegi eredmeny: FAIL, mert a repo dontesi sablonja meg DRAFT;
  - 16 ellenorzes PASS;
  - 8 ellenorzes FAIL;
  - 0 ellenorzes REVIEW;
  - riport: `security-reports/compliance-golive-decision/20260609-122337/report.md`;
  - fail okok: `decisionStatus=DRAFT`, `environment=staging-or-production`, hianyzo `decidedAt`,
    `decidedBy`, `approvedByCompliance`, valamint null `approvedValue` a harom compliance-donteshez
    kotott flagre.

Teny szerinti fontos defaultok:
- `PMT_STRICT_ENFORCEMENT`: kod-default `true`.
- `AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT`: kod-default `false`, de `V291` migracio `true`-ra aktiválja/frissiti.
- `AML_HIGH_VALUE_APPROVAL_ENFORCEMENT`: kod-default `false`.
- `AML_FATF_TIER_ENFORCEMENT`: kod-default `false`.
- `CIRCULAR_ACK_BLOCKING_ENFORCEMENT`: kod-default `false`.

Korlatozas:
- A `compliance:golive:synthetic` a DB export mechanizmust bizonyitja, de nem staging/production
  kornyezetet es nem jogi jovahagyast.
- Product Ready compliance bizonyitekhoz
  `npm run compliance:golive:export` futtatas kell staging vagy production DB ellen, megfelelo `PGHOST`,
  `PGUSER`, `PGDATABASE`/parameterek es jelszo nelkuli logolasi fegyelem mellett.
- A sablon `decisionStatus=DRAFT`; a Product Ready claimhez alairt/elfogadott `APPROVED` dontesfajl kell.
- A Product Ready compliance blokkolo meg fennall: a dontesfajl nem `APPROVED`, es az
  `AML_HIGH_VALUE_APPROVAL_ENFORCEMENT`, `AML_FATF_TIER_ENFORCEMENT`,
  `CIRCULAR_ACK_BLOCKING_ENFORCEMENT` flag Product Ready erteke meg nincs jogilag/compliance oldalon
  jovahagyva.

### Product Ready evidence preflight

Javitas:
- `scripts/product-ready-evidence-preflight.ps1` letrehozva.
- Root parancs: `npm run product-ready:evidence:preflight`.
- A script helyi repo-bizonyitekot ellenoriz acceptance, DR/backup, monitoring es production URL teruleten,
  majd `security-reports/product-ready-evidence/<timestamp>/report.md` es `summary.json` fajlt general.

Bizonyitas:
- `npm run product-ready:evidence:preflight`
  - 32 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-091107/report.md`.

2026-06-09 folytatas:
- A preflight mar a DR restore drill scriptet is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 34 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-091530/report.md`.

2026-06-09 monitoring folytatas:
- A preflight mar a monitoring preflight scriptet es a Grafana overview dashboardot is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 37 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-092005/report.md`.

2026-06-09 local gate folytatas:
- A preflight mar az osszesitett Product Ready local gate scriptet is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 39 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-093234/report.md`.

2026-06-09 compliance export folytatas:
- A preflight mar a compliance go-live export scriptet es dontesi sablont is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 43 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-093918/report.md`.

2026-06-09 compliance Docker/synthetic export folytatas:
- A preflight mar a Dockeres psql fallbacket, a szintetikus compliance export scriptet es az
  `compliance:golive:synthetic` npm wiringot is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 116 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-114051/report.md`.

2026-06-09 compliance go-live decision gate folytatas:
- A preflight mar a compliance dontesi verifier scriptet, a preflight/approved npm wiringot, a
  `RequireApprovedDecision` fail-closed utvonalat es az `approvedByCompliance` mezot is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 133 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riportok:
    - `security-reports/product-ready-evidence/20260609-122329/report.md`;
    - `security-reports/product-ready-evidence/20260609-122825/report.md` a 16 lepeses
      `product-ready:local-gate` futas belso evidence lepesebol.

2026-06-09 critical acceptance coverage folytatas:
- `docs/PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json` letrehozva a nyolc kritikus flow
  (`buy`, `sell`, `conversion`, `storno`, `dayClosing`, `navCashRegister`, `receiptPrint`,
  `offlineSync`) lokalis regresszios bizonyitekainak explicit mappingjekent.
- `scripts/product-ready-acceptance-coverage-verify.ps1` letrehozva. Ellenorzi, hogy minden
  kotelezo flow-hoz legyen parancs, bizonyitekfajl es a hivatkozott teszt-/kodminta tenylegesen
  szerepeljen a repo-ban.
- Root parancs: `npm run product-ready:acceptance-coverage`.
- `npm run product-ready:acceptance-coverage`
  - 94 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - riportok:
    - `security-reports/product-ready-acceptance-coverage/20260609-124629-420/report.md`;
    - `security-reports/product-ready-acceptance-coverage/20260609-124710-624/report.md`;
    - `security-reports/product-ready-acceptance-coverage/20260609-124823-579/report.md` a 18
      lepeses `product-ready:local-gate` futas belso coverage lepesebol;
    - `security-reports/product-ready-acceptance-coverage/20260609-125037-979/report.md` a
      szigorubb receipt type mintak utan;
    - `security-reports/product-ready-acceptance-coverage/20260609-125218-232/report.md` a
      legfrissebb 18 lepeses `product-ready:local-gate` futas belso coverage lepesebol.
- Korlatozas: ez lokalis coverage mapping es regresszios bizonyitek. Nem helyettesiti a staging vagy
  production kornyezetben tenylegesen lefuttatott acceptance riportot.

2026-06-09 seedelt PostgreSQL acceptance folytatas:
- `SeededPostgresAcceptanceIT` Testcontainers PostgreSQL-en bizonyitja a seedelt BUY/SELL/napi
  nyitott session round-tripet, a napi forgalom osszegzest, a keszletvaltozast es a tenant-scope
  receipt lookupot.
- `acceptance:local:postgres-seeded` root script bekotve, az osszesitett `acceptance:local` ezt is
  futtatja.
- Az acceptance coverage manifestben a `buy`, `sell` es `dayClosing` flow-k mar erre a seedelt
  PostgreSQL acceptance bizonyitekra is hivatkoznak.
- `npm run product-ready:acceptance-coverage`
  - 109 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - riport: `security-reports/product-ready-acceptance-coverage/20260609-133346-555/report.md`.
- `npm run acceptance:local`
  - backend celzott regressziok, PostgreSQL row-lock, seedelt PostgreSQL acceptance, service-flow
    acceptance es frontend Playwright smoke PASS;
  - a seedelt PostgreSQL acceptance reszben 2 teszt futott, 0 fail, 0 error, 0 skipped.
- Korlatozas: ez tovabbra is lokalis Testcontainers bizonyitek, nem staging/production acceptance
  riport es nem valos penztari uzemi jegyzokonyv.

2026-06-09 final external evidence gate folytatas:
- `docs/PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json` letrehozva a Product Ready-hez
  szukseges kulso/staging bizonyitekok explicit, nem titkos JSON sablonjakent.
- `scripts/product-ready-external-evidence-verify.ps1` letrehozva. Preflight modban REVIEW-t ad a
  hianyzo kulso bizonyitekokra, `-RequireComplete` modban fail-closed.
- `scripts/product-ready-local-evidence-bundle.ps1` letrehozva: a legfrissebb helyi Product Ready,
  acceptance, compliance, DR, monitoring, installer es audit riportokat SHA-256 hash-sel ellatott
  handoff bundle-be fogja ossze, es titokmintara szkenneli.
- `scripts/product-ready-final-gate.ps1` letrehozva: egy futasban inditja a helyi Product Ready gate-et,
  aktualis local evidence bundle-t keszit, majd a kulso evidence verifiert egy final-gate-scoped,
  nem commitolt evidence JSON-on futtatja az aktualis bundle hivatkozassal.
- `scripts/product-ready-external-evidence-pack.ps1` letrehozva: aktualis local bundle hivatkozassal
  draft external evidence JSON-t, verifier riportot, szakaszonkenti operatori guidance-szal ellatott
  `missing-evidence.md` handoffot es gepileg olvashato `missing-evidence.json` manifestet general
  az operacios/staging/production bizonyitekgyujteshez.
- `docs/PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md` es
  `scripts/product-ready-external-evidence-runbook.ps1` letrehozva: a legfrissebb external evidence
  packbol operatori runbookot keszit, beleertve a missing-evidence listat es a kitoltendo JSON mezok
  pointer-terkepet.
- `docs/PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json` es
  `scripts/product-ready-staging-acceptance-verify.ps1` letrehozva: a staging/production acceptance
  riportot strukturalt JSON-kent ellenorzi, a nyolc kritikus flow, operator, kornyezet, source metaadat
  es titok/PII biztonsagi deklaracio szintjen.
- Az external evidence verifier mar nem csak a `localEvidenceBundleRef` letezeset ellenorzi:
  a bundle JSON-t parse-olja, `LOCAL_EVIDENCE_BUNDLE_READY` statust var, es minden csomagolt
  `report.md`/`summary.json` aktualis SHA-256 hash-et visszahasonlitja.
- Az external evidence verifier mar az `acceptance.reportRef` mogotti strukturalt staging/production
  acceptance `summary.json` tartalmat is visszaellenorzi, ha a mezot kitoltik: `status=PASS`,
  `failed=0`, `reviewRequired=0`, strukturalt verifier-identitas es a kotelezo flow checkek PASS
  allapotat varja.
- Az external evidence verifier mar a `drRestore.reportRef` mogotti strukturalt DR restore
  `summary.json` tartalmat is visszaellenorzi, ha a mezot kitoltik: execute modot, 0 failed lepeset,
  `valuta_dr_*` scratch targetet, restore lepest, kritikus row-countokat es tiszta audit hash-chain
  smoke eredmenyt var.
- Root parancsok:
  - `npm run product-ready:external-evidence:preflight`;
  - `npm run product-ready:external-evidence:complete`;
  - `npm run product-ready:external-evidence:pack`;
  - `npm run product-ready:external-evidence:pack:refresh`;
  - `npm run product-ready:external-evidence:pack:complete`;
  - `npm run product-ready:external-evidence:runbook`;
  - `npm run product-ready:external-evidence:runbook:refresh`;
  - `npm run product-ready:staging-acceptance:preflight`;
  - `npm run product-ready:staging-acceptance:complete`;
  - `npm run product-ready:local-evidence-bundle`;
  - `npm run product-ready:final-gate:preflight`;
  - `npm run product-ready:final-gate:complete`.
- `npm run product-ready:local-evidence-bundle`
  - 55 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - bundle-ok:
    - `security-reports/product-ready-local-evidence-bundle/20260609-130038-154/bundle.json`;
    - `security-reports/product-ready-local-evidence-bundle/20260609-130534-801/bundle.json`;
    - `security-reports/product-ready-local-evidence-bundle/20260609-131135-009/bundle.json`;
  - legfrissebb riport: `security-reports/product-ready-local-evidence-bundle/20260609-131135-009/report.md`.
- `npm run product-ready:external-evidence:preflight`
  - 86 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 51 ellenorzes REVIEW;
  - riportok:
    - `security-reports/product-ready-external-evidence/20260609-123304/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-123946-192/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-124232-167/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-124710-626/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-124922-283/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-125317-979/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-130030-768/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-130417-498/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-131150-371/report.md`.
- `npm run product-ready:external-evidence:complete`
  - vart jelenlegi eredmeny: FAIL, mert a sablon DRAFT es a kulso bizonyitekok nincsenek kitoltve;
  - 86 ellenorzes PASS;
  - 51 ellenorzes FAIL;
  - 0 ellenorzes REVIEW;
  - riportok:
    - `security-reports/product-ready-external-evidence/20260609-123310/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-123950-792/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-125037-979/report.md`, ahol a
      jelenlegi DRAFT sablon 23 PASS / 51 FAIL / 0 REVIEW eredmennyel bukik;
    - `security-reports/product-ready-external-evidence/20260609-125742-978/report.md`, ahol a
      `localEvidenceBundleRef` bekotese utan a jelenlegi DRAFT sablon 23 PASS / 52 FAIL /
      0 REVIEW eredmennyel bukik;
    - `security-reports/product-ready-external-evidence/20260609-130426-781/report.md`, ahol a
      bundle-integritas mar PASS, de a kulso bizonyitekok hianya miatt 86 PASS / 51 FAIL /
      0 REVIEW az eredmeny;
    - `security-reports/product-ready-external-evidence/20260609-131150-483/report.md`.
- `npm run product-ready:evidence:preflight`
  - 153 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riportok:
    - `security-reports/product-ready-evidence/20260609-123317/report.md`;
    - `security-reports/product-ready-evidence/20260609-123519/report.md` a 17 lepeses
      `product-ready:local-gate` futas belso evidence lepesebol;
    - `security-reports/product-ready-evidence/20260609-123633/report.md`;
    - `security-reports/product-ready-evidence/20260609-123839/report.md` a frissitett pending
      external evidence lista utan;
    - `security-reports/product-ready-evidence/20260609-124230/report.md` a legfrissebb
      `product-ready:local-gate` futas belso evidence lepesebol;
    - `security-reports/product-ready-evidence/20260609-124716/report.md`;
    - `security-reports/product-ready-evidence/20260609-124921/report.md` a 18 lepeses
      `product-ready:local-gate` futas belso evidence lepesebol;
    - `security-reports/product-ready-evidence/20260609-125037/report.md` a szigorubb acceptance
      coverage manifest utan;
    - `security-reports/product-ready-evidence/20260609-125316/report.md` a legfrissebb 18 lepeses
      `product-ready:local-gate` futas belso evidence lepesebol;
    - `security-reports/product-ready-evidence/20260609-125730/report.md`;
    - `security-reports/product-ready-evidence/20260609-130029/report.md` a local evidence bundle
      wiring utan, a 18 lepeses `product-ready:local-gate` futas belso evidence lepesebol;
    - `security-reports/product-ready-evidence/20260609-130434/report.md`;
    - `security-reports/product-ready-evidence/20260609-131157/report.md`;
    - `security-reports/product-ready-evidence/20260609-132207/report.md`, ahol a final gate wiring
      utan 160/160 helyi evidence ellenorzes PASS.
- `npm run product-ready:final-gate:preflight`
  - 3 lepes PASS;
  - 0 lepes FAIL;
  - a local gate es a local evidence bundle PASS, az external evidence verifier preflight modban
    PASS/REVIEW allapottal futott;
  - riport: `security-reports/product-ready-final-gate/20260609-131716-371/report.md`.
- `npm run product-ready:final-gate:complete`
  - vart jelenlegi eredmeny: FAIL, mert a kulso/staging/production evidence meg nincs COMPLETE-re
    kitoltve;
  - 2 lepes PASS;
  - 1 lepes FAIL (`external_evidence_gate`);
  - riport: `security-reports/product-ready-final-gate/20260609-131926-760/report.md`.
- `npm run product-ready:external-evidence:pack`
  - exit 0;
  - draft evidence: `security-reports/product-ready-external-evidence-pack/20260609-132635-323/external-evidence.draft.json`;
  - missing handoff: `security-reports/product-ready-external-evidence-pack/20260609-132635-323/missing-evidence.md`;
  - local bundle: `security-reports/product-ready-local-evidence-bundle/20260609-132159-599/bundle.json`;
  - verifier: 87 PASS, 0 FAIL, 50 REVIEW;
  - missing checks: 50;
  - riport: `security-reports/product-ready-external-evidence-pack/20260609-132635-323/report.md`.
- `npm run product-ready:external-evidence:pack:complete`
  - vart jelenlegi eredmeny: FAIL, mert 50 missing external evidence check marad;
  - riport: `security-reports/product-ready-external-evidence-pack/20260609-132642-176/report.md`.
- `npm run product-ready:external-evidence:runbook`
  - exit 0;
  - operator runbook:
    `security-reports/product-ready-external-evidence-runbook/20260609-141020-518/operator-runbook.md`;
  - missing checks: 50;
  - JSON mezoterkep: 41 bejegyzes;
  - JSON pointer format ellenorizve: peldaul `/acceptance/status` tenyleges pointerkent szerepel;
  - az `acceptance.reportRef` elvart erteke mar strukturalt staging/production acceptance
    `summary.json` hivatkozas;
  - a `drRestore.reportRef` elvart erteke mar strukturalt DR restore drill `summary.json`
    hivatkozas;
  - riport: `security-reports/product-ready-external-evidence-runbook/20260609-141020-518/report.md`.
- `npm run product-ready:external-evidence:runbook:refresh`
  - exit 0;
  - friss external evidence pack forras:
    `security-reports/product-ready-external-evidence-pack/20260609-134320-571`;
  - operator runbook:
    `security-reports/product-ready-external-evidence-runbook/20260609-134320-157/operator-runbook.md`;
  - missing checks: 50;
  - JSON mezoterkep: 41 bejegyzes;
  - riport: `security-reports/product-ready-external-evidence-runbook/20260609-134320-157/report.md`.
- `npm run product-ready:evidence:preflight` az external evidence pack bekotese utan:
  - 167 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-132648/report.md`.
- `npm run product-ready:evidence:preflight` az external evidence operator runbook bekotese utan:
  - 181 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riportok:
    - `security-reports/product-ready-evidence/20260609-134308/report.md`;
    - `security-reports/product-ready-evidence/20260609-134437/report.md` a JSON pointer
      formatalasi javitas utan.

2026-06-09 strukturalt staging/production acceptance evidence folytatas:
- A staging/production acceptance sablon a nyolc kotelezo Product Ready flow-t kulon flow bejegyzeskent
  keri: `buy`, `sell`, `conversion`, `storno`, `dayClosing`, `navCashRegister`, `receiptPrint`,
  `offlineSync`.
- A verifier preflight modban REVIEW-kent kezeli a kitoltetlen sablont, `-RequirePass` modban
  fail-closed, igy a sablon nem hasznalhato hamis Product Ready acceptance igazolaskent.
- A local Product Ready gate most mar `staging_acceptance_preflight` lepest is futtat.
- A local evidence bundle most mar `product_ready_staging_acceptance_preflight` artifactot is hash-el.
- Az external evidence verifier a local bundle-ben ezt az artifactot is elvarja.
- `npm run product-ready:staging-acceptance:preflight`
  - 24 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 36 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-staging-acceptance/20260609-135115-167/report.md`.
- `npm run product-ready:staging-acceptance:complete`
  - vart jelenlegi eredmeny: FAIL, mert a staging/production acceptance sablon nincs kitoltve;
  - 24 ellenorzes PASS;
  - 36 ellenorzes FAIL;
  - 0 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-staging-acceptance/20260609-135123-966/report.md`.
- `npm run product-ready:evidence:preflight`
  - 194 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-135227/report.md`.
- `npm run product-ready:local-gate`
  - 19 lepes PASS;
  - 0 lepes FAIL;
  - `staging_acceptance_preflight` lepes PASS;
  - riport: `security-reports/product-ready-local-gate/20260609-135233/report.md`.
- `npm run product-ready:local-evidence-bundle`
  - 60 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - bundle: `security-reports/product-ready-local-evidence-bundle/20260609-135616-608/bundle.json`;
  - riport: `security-reports/product-ready-local-evidence-bundle/20260609-135616-608/report.md`.
- `npm run product-ready:external-evidence:preflight`
  - 91 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 51 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-135634-820/report.md`.
- `npm run product-ready:external-evidence:pack`
  - exit 0;
  - draft evidence: `security-reports/product-ready-external-evidence-pack/20260609-140304-375/external-evidence.draft.json`;
  - missing handoff: `security-reports/product-ready-external-evidence-pack/20260609-140304-375/missing-evidence.md`;
  - missing checks: 50;
  - riport: `security-reports/product-ready-external-evidence-pack/20260609-140304-375/report.md`.

2026-06-09 external acceptance report content gate folytatas:
- `scripts/product-ready-external-evidence-verify.ps1` bovult `Add-StructuredAcceptanceReportChecks`
  ellenorzessel. Ez a final external evidence `acceptance.reportRef` mezojet nem csak letezo
  hivatkozaskent fogadja el: lokalis strukturalt staging/production acceptance `summary.json`-t var,
  es annak belso PASS/0 fail/0 review allapotat, valamint a flow-szintu checkeket is szamon keri.
- `scripts/product-ready-evidence-preflight.ps1` mar ezt a bekotest is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 197 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-135958/report.md`.
- `npm run product-ready:external-evidence:preflight`
  - 91 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 51 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-140304-356/report.md`.
- `npm run product-ready:local-gate`
  - 19 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-140020/report.md`.
- `npm run product-ready:local-evidence-bundle`
  - 60 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - bundle: `security-reports/product-ready-local-evidence-bundle/20260609-140252-049/bundle.json`;
  - riport: `security-reports/product-ready-local-evidence-bundle/20260609-140252-049/report.md`.

2026-06-09 external DR restore report content gate folytatas:
- `scripts\dr-restore-drill.ps1` kritikus row-count outputja a final evidence schema neveihez igazodott:
  `transactions`, `audit_log`, `aml_report`, `customer`, `flyway_success`.
- `scripts\dr-restore-synthetic-drill.ps1` minimalis dumpja mar `customer` tablat es sort is letrehoz,
  hogy a synthetic restore ugyanazt a row-count proof pathot gyakorolja.
- `scripts/product-ready-external-evidence-verify.ps1` bovult `Add-StructuredDrRestoreReportChecks`
  ellenorzessel. Ez a final external evidence `drRestore.reportRef` mezojet nem csak letezo
  hivatkozaskent fogadja el: lokalis strukturalt DR restore `summary.json`-t var, es execute modot,
  0 failed lepeset, safe scratch DB nevet, restore lepest, row countokat es audit hash-chain smoke
  eredmenyt is ellenoriz.
- Kontrollprobaban egy ideiglenes external evidence JSON a synthetic DR summary-ra mutatott:
  - `security-reports/dr-restore-drills/20260609-140640/summary.json`;
  - `npm run product-ready:external-evidence:preflight` ekvivalens verifier futas:
    124 ellenorzes PASS, 0 ellenorzes FAIL, 40 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-140717-065/report.md`.
- `npm run dr:restore:synthetic`
  - exit 0;
  - riport: `security-reports/dr-restore-drills/20260609-140640/report.md`;
  - summary: `security-reports/dr-restore-drills/20260609-140640/summary.json`.
- `npm run product-ready:evidence:preflight`
  - 203 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-140653/report.md`.
- `npm run product-ready:local-gate`
  - 19 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-140727/report.md`.
- `npm run product-ready:local-evidence-bundle`
  - 60 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - bundle: `security-reports/product-ready-local-evidence-bundle/20260609-141000-403/bundle.json`;
  - riport: `security-reports/product-ready-local-evidence-bundle/20260609-141000-403/report.md`.
- `npm run product-ready:external-evidence:preflight`
  - 91 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 51 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-141013-072/report.md`.
- `npm run product-ready:external-evidence:pack`
  - exit 0;
  - draft evidence: `security-reports/product-ready-external-evidence-pack/20260609-141013-098/external-evidence.draft.json`;
  - missing handoff: `security-reports/product-ready-external-evidence-pack/20260609-141013-098/missing-evidence.md`;
  - missing checks: 50;
  - riport: `security-reports/product-ready-external-evidence-pack/20260609-141013-098/report.md`.

2026-06-09 external monitoring report content gate folytatas:
- `docs/PRODUCT_READY_MONITORING_EVIDENCE_TEMPLATE_2026-06-09.json` es
  `scripts/product-ready-monitoring-evidence-verify.ps1` letrehozva: a deployed monitoring
  bizonyitekot strukturalt JSON-kent ellenorzi, legalabb 168 ora megfigyelessel, scrape/dashboard/alert
  delivery, backend/Postgres/host metrics/ClientErrorLog es redaction/no-secret/no-PII mezokkel.
- `scripts/product-ready-external-evidence-verify.ps1` bovult `Add-StructuredMonitoringReportChecks`
  ellenorzessel. Ez a final external evidence `monitoring.reportRef` mezojet nem csak letezo
  hivatkozaskent fogadja el: lokalis strukturalt monitoring evidence `summary.json`-t var, es PASS,
  0 failed, 0 review, 168 ora es a kotelezo monitoring checkek allapotat is ellenorzi.
- A local Product Ready gate most mar `monitoring_evidence_preflight` lepest is futtat.
- A local evidence bundle most mar `product_ready_monitoring_evidence_preflight` artifactot is hash-el.
- Az external evidence verifier a local bundle-ben ezt az artifactot is elvarja.
- `npm run product-ready:monitoring-evidence:preflight`
  - 9 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 27 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-monitoring-evidence/20260609-141650-981/report.md`.
- `npm run product-ready:monitoring-evidence:complete`
  - vart jelenlegi eredmeny: FAIL, mert a sablonban nincs valodi staging/production monitoring evidence;
  - 9 ellenorzes PASS;
  - 27 ellenorzes FAIL;
  - 0 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-monitoring-evidence/20260609-141659-431/report.md`.
- `npm run product-ready:evidence:preflight`
  - 217 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-141650/report.md`.
- `npm run product-ready:local-gate`
  - 20 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-141711/report.md`.
- `npm run product-ready:local-evidence-bundle`
  - 65 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - bundle: `security-reports/product-ready-local-evidence-bundle/20260609-142459-631/bundle.json`;
  - riport: `security-reports/product-ready-local-evidence-bundle/20260609-142459-631/report.md`.
- `npm run product-ready:external-evidence:preflight`
  - 96 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 51 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-142529-218/report.md`.
- `npm run product-ready:external-evidence:pack`
  - exit 0;
  - draft evidence: `security-reports/product-ready-external-evidence-pack/20260609-142529-259/external-evidence.draft.json`;
  - missing handoff: `security-reports/product-ready-external-evidence-pack/20260609-142529-259/missing-evidence.md`;
  - missing checks: 50;
  - riport: `security-reports/product-ready-external-evidence-pack/20260609-142529-259/report.md`.
- `npm run product-ready:external-evidence:runbook`
  - exit 0;
  - operator runbook: `security-reports/product-ready-external-evidence-runbook/20260609-142529-263/operator-runbook.md`;
  - missing checks: 50;
  - riport: `security-reports/product-ready-external-evidence-runbook/20260609-142529-263/report.md`.
- `npm run product-ready:final-gate:preflight`
  - 3 lepes PASS;
  - 0 lepes FAIL;
  - local gate riport: `security-reports/product-ready-local-gate/20260609-142203/report.md`;
  - local evidence bundle: `security-reports/product-ready-local-evidence-bundle/20260609-142459-631/bundle.json`;
  - external evidence preflight riport: `security-reports/product-ready-external-evidence/20260609-142500-533/report.md`;
  - final gate riport: `security-reports/product-ready-final-gate/20260609-142202-602/report.md`;
  - verdikt: local final preflight PASS, de COMPLETE external evidence nelkul meg nem Product Ready proof.

2026-06-09 external installer report content gate folytatas:
- `scripts/product-ready-external-evidence-verify.ps1` bovult
  `Add-StructuredSignedInstallerReportChecks` es `Add-StructuredCleanVmInstallerReportChecks`
  ellenorzesekkel. Ez a final external evidence `installer.signedArtifactReportRef` es
  `installer.cleanVmReportRef` mezoit nem csak letezo hivatkozaskent fogadja el: lokalis strukturalt
  installer `summary.json` riportokat var.
- A signed artifact report tartalmi kovetelmenyei: `checkArtifacts=true`, `requireSignature=true`,
  `failed=0`, `skipped=0`, es mindharom kliensnel PASS artifact existence/age/SHA-256,
  Authenticode signature, packaged secret scan es ASAR secret scan.
- A clean Windows VM report tartalmi kovetelmenyei: `executeInstall=true`, `acceptVmMutation=true`,
  `skipUninstall=false`, `failed=0`, `skipped=0`, Clean Windows VM product-ready meaning, es mindharom
  kliensnel PASS silent install, installed exe, launch smoke, runtime secret scan, uninstall es
  post-uninstall removal.
- Kontrollprobaban egy ideiglenes external evidence JSON a lokalis, nem alairt es nem clean-VM
  preflight installer summary-kra mutatott:
  - `security-reports/installer-smoke/20260609-142433/summary.json`;
  - `security-reports/installer-clean-vm-smoke/20260609-142442/summary.json`;
  - preflight modban: 154 ellenorzes PASS, 0 ellenorzes FAIL, 65 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-142938-830/report.md`.
- Ugyanez `-RequireComplete` modban fail-closed:
  - 154 ellenorzes PASS;
  - 65 ellenorzes FAIL;
  - 0 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-142953-388/report.md`.
- `npm run product-ready:evidence:preflight`
  - 223 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-142922/report.md`.

2026-06-09 external compliance report content gate folytatas:
- `scripts/product-ready-external-evidence-verify.ps1` bovult
  `Add-StructuredComplianceDecisionReportChecks` es `Add-StructuredComplianceExportReportChecks`
  ellenorzesekkel. Ez a final external evidence `compliance.approvedDecisionRef` es
  `compliance.exportReportRef` mezoit nem csak letezo hivatkozaskent fogadja el: lokalis strukturalt
  compliance decision/export `summary.json` riportokat var.
- A compliance decision report tartalmi kovetelmenyei: approved-decision gate mod
  (`requireApprovedDecision=true`), `failed=0`, `reviewRequired=0`, approved decision verifier
  identitas, es PASS `decisionStatus`, environment, `decidedAt`, dontesgazda, compliance jovahagyo,
  valamint minden kotelezo go-live flag exists/approvedValue/rationale check.
- A compliance export report tartalmi kovetelmenyei: `mode=query`, DB cel metadata, `failed=0`,
  `reviewRequired=0`, PASS approved decision status es query execution, minden kotelezo flag PASS,
  tovabba a synthetic `updatedBy=synthetic` bizonyitek elutasitasa final proofkent.
- Kontrollprobaban egy ideiglenes external evidence JSON a DRAFT decision summary-ra es synthetic
  compliance export summary-ra mutatott:
  - `security-reports/compliance-golive-decision/20260609-143219/summary.json`;
  - `security-reports/compliance-golive/20260609-143222/summary.json`;
  - preflight modban: 141 ellenorzes PASS, 0 ellenorzes FAIL, 63 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-143707-113/report.md`.
- Ugyanez `-RequireComplete` modban fail-closed:
  - 141 ellenorzes PASS;
  - 63 ellenorzes FAIL;
  - 0 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-143715-095/report.md`.
- `npm run product-ready:evidence:preflight`
  - 228 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-143652/report.md`.

2026-06-09 external acceptance local coverage content gate folytatas:
- `scripts/product-ready-external-evidence-verify.ps1` bovult
  `Add-StructuredLocalAcceptanceCoverageChecks` ellenorzessel. Ez a final external evidence
  `acceptance.localCoverageReportRef` mezojet nem csak letezo hivatkozaskent fogadja el:
  lokalis strukturalt acceptance coverage `summary.json`-t var.
- A local coverage report tartalmi kovetelmenyei: `failed=0`, local critical-flow coverage verifier
  identitas, PASS coverage file/json/schema/status/environment/flows array checkek, es mind a nyolc
  kritikus flowhoz PASS exists/commands/evidenceRefs, valamint legalabb egy file es pattern evidence.
- Kontrollprobaban egy ideiglenes external evidence JSON a friss local acceptance coverage summary-ra
  mutatott:
  - `security-reports/product-ready-acceptance-coverage/20260609-143950-370/summary.json`;
  - preflight modban: 155 ellenorzes PASS, 0 ellenorzes FAIL, 44 ellenorzes REVIEW;
  - a REVIEW-ek a tovabbra is hianyzo staging/production acceptance es mas kulso bizonyitekok miatt
    maradtak;
  - riport: `security-reports/product-ready-external-evidence/20260609-144343-681/report.md`.
- `npm run product-ready:evidence:preflight`
  - 231 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-144331/report.md`.

2026-06-09 external final decision content gate folytatas:
- `docs/PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json` `finalDecision` szekcioja bovult
  `externalEvidenceRef` es `finalGateSummaryRef` mezokkel.
- `scripts/product-ready-external-evidence-verify.ps1` bovult `Add-StructuredFinalEvidenceChecks` es
  `Add-StructuredFinalGateSummaryChecks` ellenorzesekkel. Ez a final Product Ready dontest nem csak
  `readyForProductReadyClaim=true` boolean + nev + datum alapjan fogadja el: hivatkozott COMPLETE
  external evidence JSON-t es sikeres `product-ready:final-gate:complete` `summary.json`-t var.
- A completed evidence tartalmi kovetelmenyei: valid JSON, `schemaVersion=1`, `evidenceStatus=COMPLETE`,
  staging/production environment, letezo local evidence bundle ref es true final claim flag.
- A final gate summary tartalmi kovetelmenyei: `requireComplete=true`, `failed=0`, legalabb 3 PASS lepes,
  complete Product Ready verdict, PASS `local_product_ready_gate`, `local_evidence_bundle`,
  `external_evidence_gate`, es a summary `finalGateEvidencePath` erteke ugyanarra a completed evidence
  JSON-ra mutasson, mint a final decision.
- Kontrollprobaban egy ideiglenes external evidence JSON egy preflight final gate summary-ra mutatott:
  - `security-reports/product-ready-final-gate/20260609-142202-602/summary.json`;
  - preflight modban: 121 ellenorzes PASS, 0 ellenorzes FAIL, 49 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-145040-499/report.md`.
- Ugyanez `-RequireComplete` modban fail-closed:
  - 121 ellenorzes PASS;
  - 49 ellenorzes FAIL;
  - 0 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-145040-891/report.md`.
- `npm run product-ready:evidence:preflight`
  - 237 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-145010/report.md`.
- 2026-06-09 korrekcio: a `finalDecision.finalGateSummaryRef` nem lehet ugyanannak a final gate
  futasnak elofeltetele, mert a summary csak az external evidence verifier utan keletkezik. A modell
  javitva lett:
  - `finalDecision.externalEvidenceRef` marad kotelezo completed evidence JSON hivatkozas;
  - `scripts/product-ready-final-gate.ps1` automatikusan a final-gate-scoped evidence JSON-ra allitja
    ezt a mezot;
  - `finalDecision.finalGateSummaryRef` opcionális post-run proof: ha ki van toltve, tartalmilag
    ellenorzott, de nem blokkolja a sajat jovo-beli summaryjat letrehozo complete final gate futast.
- `npm run product-ready:final-gate:complete` a korrekcio utan:
  - vart jelenlegi eredmeny: FAIL, mert valos kulso/staging/production evidence meg hianyzik;
  - `local_product_ready_gate` PASS;
  - `local_evidence_bundle` PASS;
  - `external_evidence_gate` FAIL;
  - external evidence verifier: 103 PASS, 53 FAIL, 0 REVIEW;
  - final-gate evidence JSON `finalDecision.externalEvidenceRef` mezoje a sajat scoped JSON fajljara
    mutatott;
  - riport: `security-reports/product-ready-final-gate/20260609-150113-430/report.md`.
- `npm run product-ready:evidence:preflight`
  - 240 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-150106/report.md`.
- `npm run product-ready:local-gate`
  - 20 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-150113/report.md`.
- `npm run product-ready:local-evidence-bundle`
  - 65 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - bundle: `security-reports/product-ready-local-evidence-bundle/20260609-150335-028/bundle.json`;
  - riport: `security-reports/product-ready-local-evidence-bundle/20260609-150335-028/report.md`.
- `npm run product-ready:external-evidence:preflight`
  - 96 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 52 ellenorzes REVIEW;
  - riport: `security-reports/product-ready-external-evidence/20260609-150407-060/report.md`.
- `npm run product-ready:external-evidence:pack`
  - exit 0;
  - draft evidence: `security-reports/product-ready-external-evidence-pack/20260609-150412-560/external-evidence.draft.json`;
  - missing handoff: `security-reports/product-ready-external-evidence-pack/20260609-150412-560/missing-evidence.md`;
  - missing checks: 51;
  - riport: `security-reports/product-ready-external-evidence-pack/20260609-150412-560/report.md`.
- `npm run product-ready:external-evidence:runbook`
  - exit 0;
  - operator runbook: `security-reports/product-ready-external-evidence-runbook/20260609-150420-177/operator-runbook.md`;
  - missing checks: 51;
  - riport: `security-reports/product-ready-external-evidence-runbook/20260609-150420-177/report.md`.

2026-06-09 audit hash-chain folytatas:
- A preflight mar az audit hash-chain verifier scriptet, a legacy helper regresszios tesztet es az npm
  wiringot is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 48 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-095057/report.md`.

2026-06-09 installer smoke folytatas:
- A preflight mar az installer smoke preflight scriptet, a harom root package parancsot es az artifact
  ellenorzo utvonalat is ellenorzi.
- A synthetic artifact smoke script is bekerult a helyi bizonyitek-kapuba; dummy `.exe`
  artifactokkal bizonyitja az artifact-felismeres, frissesseg-ellenorzes es SHA-256 riport utvonalat.
- A synthetic script fail-closed: nem ir felul letezo installer artifactot; ha valodi artifact van a
  release konyvtarban, a `npm run installer:smoke:artifacts` parancsot kell futtatni.
- `npm run product-ready:evidence:preflight`
  - 54 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-100239/report.md`.
- `npm run product-ready:evidence:preflight` az installer synthetic artifact evidence bekotese utan:
  - 119 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riportok:
    - `security-reports/product-ready-evidence/20260609-114825/report.md`;
    - `security-reports/product-ready-evidence/20260609-115030/report.md`;
    - `security-reports/product-ready-evidence/20260609-115756/report.md`.
- `npm run product-ready:evidence:preflight` az installer resources/ASAR secret-leak scan evidence
  bekotese utan:
  - 121 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-120338/report.md`.
- `npm run product-ready:evidence:preflight` a clean Windows VM installer smoke runner bekotese utan:
  - 125 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riportok:
    - `security-reports/product-ready-evidence/20260609-120710/report.md`;
    - `security-reports/product-ready-evidence/20260609-121013/report.md`.
- `npm run product-ready:evidence:preflight` a fail-closed signed installer smoke bekotese utan:
  - 128 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riportok:
    - `security-reports/product-ready-evidence/20260609-121251/report.md`;
    - `security-reports/product-ready-evidence/20260609-121454/report.md`;
    - `security-reports/product-ready-evidence/20260609-121749/report.md`.

2026-06-09 MEGSEM receipt evidence folytatas:
- A preflight mar a `CANCELLED_TRANSACTION` DTO/controller/service/frontend wrapper/UI/test
  bekoteseket is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 63 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-102349/report.md`.

2026-06-09 MEGSEM fizikai print-path evidence folytatas:
- A preflight mar a `cancelled_transaction` PrintJobType/frontendes mapping/preview, Electron printer,
  soros printer es printer-regresszio teszt bekoteseket is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 70 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-103643/report.md`.

2026-06-09 NAV penztargep explicit command evidence folytatas:
- A preflight mar a cash-register explicit command DTO/service/controller/test bekoteseket es az
  acceptance backend tesztlista boviteset is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 77 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-104602/report.md`.

2026-06-09 Postgres lock es acceptance flow evidence folytatas:
- A preflight mar a Testcontainers PostgreSQL worker row-lock tesztet, a Testcontainers test
  dependencyt es az `acceptance:local:postgres-lock` npm wiringot is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 105 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-112013/report.md`.

2026-06-09 seedelt PostgreSQL acceptance evidence folytatas:
- A preflight mar a `SeededPostgresAcceptanceIT` fajlt, a seedelt BUY/SELL/day-session round-trip
  tesztet, a tenant-scope receipt lookup tesztet, az `acceptance:local:postgres-seeded` npm wiringot
  es az acceptance manifest hivatkozasait is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 172 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-133346/report.md`.

2026-06-09 DR Docker fallback es synthetic restore evidence folytatas:
- A preflight mar a Dockeres PostgreSQL klienseszkoz fallbacket, a szintetikus restore drill scriptet
  es az `dr:restore:synthetic` npm wiringot is ellenorzi.
- `npm run product-ready:evidence:preflight`
  - 109 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-112923/report.md`.

2026-06-09 monitoring synthetic/promtool evidence folytatas:
- A preflight mar a `monitoring:synthetic` scriptet, a Prometheus `promtool check config/rules`
  validaciot es a Grafana dashboard JSON parse ellenorzest is szamon keri.
- `npm run product-ready:evidence:preflight`
  - 113 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-113538/report.md`.

### Product Ready local gate

Javitas:
- `scripts/product-ready-local-gate.ps1` letrehozva.
- Root parancsok:
  - `npm run product-ready:local-gate`
  - `npm run product-ready:local-gate:full`
- Az alap gate futtatja:
  - `npm run typecheck`;
  - `npm run acceptance:local`;
  - `npm run product-ready:acceptance-coverage`;
  - `npm run compliance:flags:test`;
  - `npm run compliance:golive:preflight`;
  - `npm run compliance:golive:decision:preflight`;
  - `npm run compliance:golive:synthetic`;
  - `npm run audit:hash-chain:test`;
  - `npm run audit:hash-chain:preflight`;
  - `npm run installer:smoke:preflight`;
  - `npm run installer:smoke:artifacts`, ha mindharom 2.27.96 installer artifact letezik, kulonben
    `npm run installer:smoke:synthetic`;
  - `npm run installer:smoke:clean-vm`;
  - `npm run dr:restore:preflight`;
  - `npm run dr:restore:synthetic`;
  - `npm run monitoring:preflight`;
  - `npm run monitoring:synthetic`;
  - `npm run product-ready:evidence:preflight`;
  - `npm run product-ready:external-evidence:preflight`.
- A `:full` profil ugyanezek mellett `npm run lint` es `npm run build:all` futtatast is vegez.
- A gate riportot general `security-reports/product-ready-local-gate/<timestamp>/report.md` es
  `summary.json` fajlba.

Bizonyitas:
- `npm run product-ready:local-gate`
  - 6 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-092349/report.md`.
- `npm run product-ready:local-gate` a lock contract teszt bekotese utan:
  - 6 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-092859/report.md`.
- `npm run product-ready:local-gate` a compliance go-live preflight bekotese utan:
  - 7 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-093918/report.md`.
- `npm run product-ready:local-gate` az audit hash-chain gate bekotese utan:
  - 9 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-095057/report.md`.
- `npm run product-ready:local-gate` az installer smoke preflight bekotese utan:
  - 10 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-100239/report.md`.
- `npm run product-ready:local-gate` a MEGSEM receipt acceptance bekotese utan:
  - 10 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-101735/report.md`.
- `npm run product-ready:local-gate` a MEGSEM receipt evidence/UI szuro bekotese utan:
  - 10 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-102450/report.md`.
- `npm run product-ready:local-gate` a MEGSEM fizikai print-path bekotese utan:
  - 10 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-103543/report.md`.
- `npm run product-ready:local-gate` a NAV explicit command bekotese utan:
  - 10 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-104608/report.md`.
- `npm run product-ready:local-gate` a Testcontainers PostgreSQL lock acceptance bekotese utan:
  - 10 lepes PASS;
  - 0 lepes FAIL;
  - acceptance_local lepesben futott a `WorkerRepositoryPostgresLockIT` is;
  - riport: `security-reports/product-ready-local-gate/20260609-112019/report.md`.
- `npm run product-ready:local-gate` a szintetikus Dockeres DR restore drill bekotese utan:
  - 11 lepes PASS;
  - 0 lepes FAIL;
  - a `dr_restore_synthetic` lepes izolalt Docker PostgreSQL konteneren futtat restore + row count +
    Flyway + audit hash-chain smoke ellenorzest;
  - riport: `security-reports/product-ready-local-gate/20260609-112929/report.md`.
- `npm run product-ready:local-gate` a monitoring synthetic/promtool validacio bekotese utan:
  - 12 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-113544/report.md`.
- `npm run product-ready:local-gate` a compliance synthetic export bekotese utan:
  - 13 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-114057/report.md`.
- `npm run product-ready:local-gate` az installer synthetic artifact evidence bekotese utan:
  - 14 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-114844/report.md`;
  - verdikt: helyi Product Ready gate PASS, de kulso/staging bizonyitek nelkul nem vegso Product Ready proof.
- `npm run product-ready:local-gate` a valodi unsigned installer artifact evidence bekotese utan:
  - 14 lepes PASS;
  - 0 lepes FAIL;
  - `installer_smoke_artifacts` lepes futott, nem synthetic fallback;
  - riport: `security-reports/product-ready-local-gate/20260609-115511/report.md`;
  - verdikt: helyi Product Ready gate PASS, de kulso/staging bizonyitek nelkul nem vegso Product Ready proof.
- `npm run product-ready:local-gate` a resources/ASAR installer secret-leak scan bekotese utan:
  - 14 lepes PASS;
  - 0 lepes FAIL;
  - `installer_smoke_artifacts` lepesben 72/72 installer ellenorzes PASS;
  - riport: `security-reports/product-ready-local-gate/20260609-120045/report.md`;
  - verdikt: helyi Product Ready gate PASS, de kulso/staging bizonyitek nelkul nem vegso Product Ready proof.
- `npm run product-ready:local-gate` a clean Windows VM installer smoke preflight bekotese utan:
  - 15 lepes PASS;
  - 0 lepes FAIL;
  - `installer_clean_vm_preflight` lepes futott, telepites nelkul;
  - riportok:
    - `security-reports/product-ready-local-gate/20260609-120720/report.md`;
    - `security-reports/product-ready-local-gate/20260609-121804/report.md`;
  - verdikt: helyi Product Ready gate PASS, de kulso/staging bizonyitek nelkul nem vegso Product Ready proof.
- `npm run product-ready:local-gate` a compliance go-live decision preflight bekotese utan:
  - 16 lepes PASS;
  - 0 lepes FAIL;
  - `compliance_golive_decision_preflight` lepes futott, amely a DRAFT dontesfajlt REVIEW-kent,
    nem helyi gate failure-kent kezeli;
  - `product_ready_evidence_preflight` lepesben 133/133 helyi evidence ellenorzes PASS;
  - riportok:
    - `security-reports/product-ready-local-gate/20260609-122537/report.md`;
    - `security-reports/product-ready-evidence/20260609-122825/report.md`;
  - verdikt: helyi Product Ready gate PASS, de kulso/staging bizonyitek es APPROVED compliance dontes
    nelkul nem vegso Product Ready proof.
- `npm run product-ready:local-gate` a final external evidence preflight bekotese utan:
  - 17 lepes PASS;
  - 0 lepes FAIL;
  - `product_ready_external_evidence_preflight` lepes futott, amely a DRAFT external evidence sablont
    REVIEW-kent, nem helyi gate failure-kent kezeli;
  - `product_ready_evidence_preflight` lepesben 140/140 helyi evidence ellenorzes PASS;
  - riportok:
    - `security-reports/product-ready-local-gate/20260609-123323/report.md`;
    - `security-reports/product-ready-evidence/20260609-123519/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-123520/report.md`;
    - `security-reports/product-ready-local-gate/20260609-123638/report.md`;
    - `security-reports/product-ready-evidence/20260609-123839/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-123840/report.md`;
    - `security-reports/product-ready-local-gate/20260609-123958/report.md`;
    - `security-reports/product-ready-evidence/20260609-124230/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-124232-167/report.md`;
  - verdikt: helyi Product Ready gate PASS, de kitoltott es `COMPLETE` external evidence artifact,
    illetve sikeres `npm run product-ready:external-evidence:complete` nelkul nem vegso Product Ready proof.
- `npm run product-ready:local-gate` a critical acceptance coverage gate bekotese utan:
  - 18 lepes PASS;
  - 0 lepes FAIL;
  - `acceptance_coverage` lepesben 94/94 coverage ellenorzes PASS;
  - `product_ready_evidence_preflight` lepesben 153/153 helyi evidence ellenorzes PASS;
  - `product_ready_external_evidence_preflight` lepesben 86 PASS, 0 FAIL, 51 REVIEW;
  - riportok:
    - `security-reports/product-ready-local-gate/20260609-124722/report.md`;
    - `security-reports/product-ready-acceptance-coverage/20260609-124823-579/report.md`;
    - `security-reports/product-ready-evidence/20260609-124921/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-124922-283/report.md`;
    - `security-reports/product-ready-local-gate/20260609-125045/report.md`;
    - `security-reports/product-ready-acceptance-coverage/20260609-125218-232/report.md`;
    - `security-reports/product-ready-evidence/20260609-125316/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-125317-979/report.md`;
    - `security-reports/product-ready-local-gate/20260609-125757/report.md`;
    - `security-reports/product-ready-evidence/20260609-130029/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-130030-768/report.md`;
    - `security-reports/product-ready-local-evidence-bundle/20260609-130038-154/report.md`;
    - `security-reports/product-ready-local-gate/20260609-130927/report.md`;
    - `security-reports/product-ready-local-evidence-bundle/20260609-131135-009/report.md`;
    - `security-reports/product-ready-external-evidence/20260609-131150-371/report.md`;
    - `security-reports/product-ready-evidence/20260609-131157/report.md`;
  - verdikt: helyi Product Ready gate PASS. A Product Ready claim tovabbra is csak akkor teheto meg,
    ha a staging/production evidence artifact `COMPLETE` es a `product-ready:external-evidence:complete`
    is PASS.
- `npm run product-ready:local-gate` a seedelt PostgreSQL acceptance bekotese utan:
  - 18 lepes PASS;
  - 0 lepes FAIL;
  - `acceptance_local` lepesben futott az `acceptance:local:postgres-seeded` Testcontainers
    PostgreSQL acceptance is;
  - `acceptance_coverage` lepes PASS;
  - `product_ready_evidence_preflight` lepes PASS;
  - `product_ready_external_evidence_preflight` lepes REVIEW-kent kezeli a hianyzo kulso bizonyitekokat;
  - riport: `security-reports/product-ready-local-gate/20260609-133611/report.md`;
  - verdikt: helyi Product Ready gate PASS. Ez nem vegso Product Ready proof kulso/staging
    evidence nelkul.
- `npm run product-ready:local-gate` az external evidence operator runbook bekotese utan:
  - 18 lepes PASS;
  - 0 lepes FAIL;
  - `product_ready_evidence_preflight` lepes PASS, 181/181 helyi ellenorzessel;
  - `product_ready_external_evidence_preflight` lepes tovabbra is PASS/REVIEW modban fut, mert a
    kulso bizonyitekok meg nincsenek COMPLETE-re kitoltve;
  - riport: `security-reports/product-ready-local-gate/20260609-134457/report.md`;
  - verdikt: helyi Product Ready gate PASS. Ez tovabbra sem vegso Product Ready proof
    staging/production evidence nelkul.
- `npm run product-ready:local-gate:full`
  - 12 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-101844/report.md`.

Korlatozas:
- A helyi gate a repo jelenlegi lokalis bizonyitekait fogja ossze. Nem helyettesiti a staging/production
  teljes uzleti acceptance-et, valos backup restore drillt, live monitoring/alert tesztet, clean Windows VM
  installer smoke-ot es compliance go-live dontest.

### DR restore drill futtathato keret

Javitas:
- `scripts/dr-restore-drill.ps1` letrehozva.
- Root parancs: `npm run dr:restore:preflight`.
- Alapertelmezett mod: **nem destruktiv PLAN_ONLY**, nem csatlakozik DB-hez es nem torol/adatbazist nem hoz
  letre.
- Tenyeges restore csak explicit `-ExecuteRestore -DumpPath <dump>` kapcsoloval fut, es a target DB neve
  csak `valuta_dr_*` scratch mintara lehet ervenyes.
- Ha a lokalis PostgreSQL kliens binarisok (`psql`, `createdb`, `pg_restore`) hianyoznak, a script
  Dockeres PostgreSQL klienseszkoz-fallbacket tud hasznalni (`-UseDockerTools`, alap image:
  `postgres:16-alpine`).
- `scripts/dr-restore-synthetic-drill.ps1` letrehozva: ideiglenes Docker PostgreSQL kontenerre
  minimalis, szintetikus dumpot allit vissza, es a restore/row-count/Flyway/audit smoke utat kiprobalja.
- Root parancs: `npm run dr:restore:synthetic`.
- A script riportot general `security-reports/dr-restore-drills/<timestamp>/report.md` es `summary.json`
  fajlba.

Bizonyitas:
- `npm run dr:restore:preflight`
  - mode: `plan-only`;
  - failed: 0;
  - riport: `security-reports/dr-restore-drills/20260609-091514/report.md`.
- `npm run dr:restore:preflight` Dockeres kliens fallback bekotese utan:
  - mode: `plan-only`;
  - PostgreSQL client tools: `docker:postgres:16-alpine`;
  - failed: 0;
  - riport: `security-reports/dr-restore-drills/20260609-112501/report.md`.
- `npm run dr:restore:synthetic`
  - mode: `execute`;
  - ideiglenes Docker PostgreSQL konteneren futott;
  - kritikus row count, `flyway_schema_history`, audit hash-chain smoke PASS;
  - failed: 0;
  - riport: `security-reports/dr-restore-drills/20260609-112755/report.md`.

Korlatozas:
- A Dockeres szintetikus drill a restore automatizmust es ellenorzo SQL-eket bizonyitja, de nem
  production backup tartalmat.
- Product Ready DR bizonyitashoz kell egy izolalt scratch Postgres kornyezet + valos backup dump, majd:
  - restore futtatas,
  - kritikus tablazatok row countja,
  - `flyway_schema_history` allapot,
  - `audit_log` hash-chain smoke,
  - mert restore ido/RTO.

### Monitoring dashboard es preflight

Javitas:
- `deploy/hetzner/monitoring/grafana/dashboards/valuta-overview.json` letrehozva.
- `scripts/monitoring-preflight.ps1` letrehozva.
- Root parancs: `npm run monitoring:preflight`.
- A preflight ellenorzi:
  - monitoring compose stack fo szolgaltatasait;
  - loopback-bound portokat;
  - Prometheus scrape jobokat es rule betoltest;
  - kritikus alert rule-okat;
  - Alertmanager secret-file alapu SMTP jelszot es email route-ot;
  - Grafana datasource + dashboard provisioningot;
  - Grafana overview dashboard JSON parse-olhatosagat;
  - `docker compose config` renderelest dummy, nem titkos env ertekekkel.
- 2026-06-09: `promtool check config` es `promtool check rules` Dockeres Prometheus image-bol
  bekotve, igy a Prometheus config/rule fajlok tool-native parserrel is bizonyitottak.
- Root parancs: `npm run monitoring:synthetic`.
- A Product Ready local gate mar a `monitoring_synthetic` lepest is futtatja.

Bizonyitas:
- `npm run monitoring:preflight`
  - 45 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 1 live check SKIP;
  - riport: `security-reports/monitoring-preflight/20260609-091948/report.md`.
- `npm run monitoring:preflight` promtool/JSON validacio bekotese utan:
  - 48 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 1 live check SKIP;
  - riport: `security-reports/monitoring-preflight/20260609-113455/report.md`.
- `npm run monitoring:synthetic`
  - 48 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 1 live check SKIP;
  - riport: `security-reports/monitoring-preflight/20260609-113502/report.md`.

Korlatozas:
- Ez helyi konfiguracio-preflight. Product Ready monitoring bizonyitashoz tovabbra is kell deployed stack
  live scrape, Grafana dashboard load es alert delivery teszt.

### Audit log hash-chain integritas

Javitas:
- `AuditLogService` legacy helper utjai (`logAction`, `logTransactionEvent`, `logRateChange`,
  `logSecurityEvent`) most mar `applyHashChain(entry)` utan mentenek. Korabban ezek a helper utak
  kozvetlen `auditLogRepository.save(entry)` hivassal hash nelkuli `audit_log` sorokat irhattak.
- `backend/src/test/java/hu/puzzleir/valuta/service/AuditLogServiceHashChainTest.java` letrehozva.
- `scripts/audit-hash-chain-verify.ps1` letrehozva.
- Root parancsok:
  - `npm run audit:hash-chain:test`;
  - `npm run audit:hash-chain:preflight`;
  - `npm run audit:hash-chain:verify`.
- `docs/operations/compliance-audit-checklist.md` frissitve: a havi hash-chain verify mar nem
  "nincs commitolva" GAP, hanem scriptelt, de staging/production futasra es utemezesre varo PARTIAL.

Bizonyitas:
- `npm run audit:hash-chain:test`
  - `AuditEventServiceHashChainTest` + `AuditLogServiceHashChainTest`;
  - 11 teszt, 0 failure, 0 error.
- `npm run audit:hash-chain:preflight`
  - mode: `preflight`;
  - failed: 0;
  - riport: `security-reports/audit-hash-chain/20260609-095011/report.md`.

Korlatozas:
- A preflight nem csatlakozik DB-hez. Product Ready bizonyitekhoz staging/production
  `npm run audit:hash-chain:verify` futas kell, vagy autentikalt
  `/api/v1/diagnostics/audit/hash-chain-verify` API ellenorzes, majd utemezett futtatas es alert bizonyitek.

### Installer smoke preflight

Javitas:
- `scripts/installer-smoke-preflight.ps1` letrehozva.
- `scripts/installer-smoke-synthetic-artifacts.ps1` letrehozva.
- `scripts/installer-clean-vm-smoke.ps1` letrehozva:
  - alapbol nem telepit, csak artifact/hash preflight riportot keszit;
  - tenyleges install/launch/runtime secret scan/uninstall csak disposable VM-en,
    `-ExecuteInstall -AcceptVmMutation` kapcsolokkal futhat.
- Root parancsok:
  - `npm run package:penztar`;
  - `npm run package:arfolyam-keszito`;
  - `npm run package:kozponti`;
  - `npm run installer:smoke:preflight`;
  - `npm run installer:smoke:artifacts`;
  - `npm run installer:smoke:signed`;
  - `npm run installer:smoke:synthetic`;
  - `npm run installer:smoke:clean-vm`.
- A preflight ellenorzi:
  - installer dokumentacio: build/install/update/security/smoke checklist;
  - harom Electron kliens package es unsigned package scriptje;
  - `electron-builder` appId/productName/artifactName/NSIS/x64 szerzodes;
  - `production-urls.json` becsomagolasat;
  - `scripts/check-four-area-alignment.mjs` futasat;
  - artifact modban a friss installer fajlokat es a SHA-256 evidence fajlokat;
  - signed release modban fail-closed Authenticode `Valid` ellenorzest;
  - a `win-unpacked/resources` es `app.asar` tartalom magas bizonyossagu secret-leak mintait.

Bizonyitas:
- `npm run installer:smoke:preflight`
  - 51 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 3 artifact check SKIP;
  - riport: `security-reports/installer-smoke/20260609-114446/report.md`.
- `npm run installer:smoke:synthetic`
  - 60 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 0 ellenorzes SKIP;
  - riport: `security-reports/installer-smoke/20260609-114812/report.md`.
- Unsigned installer artifact buildek:
  - `npm run package:penztar` PASS, artifact:
    `penztar-client/release/Penztar-Setup-2.27.96.exe` (107544974 byte);
  - `npm run package:arfolyam-keszito` PASS, artifact:
    `arfolyam-keszito-client/release/Arfolyamkeszito-Setup-2.27.96.exe` (105894376 byte);
  - `npm run package:kozponti` PASS, artifact:
    `kozponti-client/release/Kozponti-Munkaallomas-Setup-2.27.96.exe` (107455358 byte).
- `npm run installer:smoke:artifacts`
  - 60 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 0 ellenorzes SKIP;
  - SHA-256 evidence fajlok generalva a harom artifactra;
  - riport: `security-reports/installer-smoke/20260609-115410/report.md`.
- `npm run installer:smoke:artifacts` a resources/ASAR secret-leak scan bekotese utan:
  - 72 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 0 ellenorzes SKIP a `20260609-120032` futasban, majd az Authenticode opcionális ellenorzes
    bekotese utan 3 signature check SKIP az unsigned artifact smoke-ban;
  - SHA-256 evidence fajlok generalva a harom artifactra;
  - resources + `app.asar` forbidden secret filename es high-confidence hard-coded secret pattern scan PASS;
  - riportok:
    - `security-reports/installer-smoke/20260609-120032/report.md`;
    - `security-reports/installer-smoke/20260609-121454/report.md`;
    - `security-reports/installer-smoke/20260609-121749/report.md`.
- `npm run installer:smoke:signed`
  - 72 ellenorzes PASS;
  - 3 ellenorzes FAIL;
  - 0 ellenorzes SKIP;
  - mindharom artifact Authenticode statusza `NotSigned`;
  - riport: `security-reports/installer-smoke/20260609-121654/report.md`.
- `npm run installer:smoke:clean-vm`
  - preflight mod, telepites nelkul;
  - 9 ellenorzes PASS;
  - 0 ellenorzes FAIL;
  - 3 install-execution ellenorzes SKIP;
  - riport: `security-reports/installer-clean-vm-smoke/20260609-120647/report.md`.

Korlatozas:
- Ez konfiguracios, build- es artifact evidence. A mostani artifactok unsigned buildek; a Product Ready
  release-hez alairt release artifact/code-signing evidence kell. A `npm run installer:smoke:signed`
  jelenlegi, bizonyitott allapota FAIL (`NotSigned` mindharom EXE-re), tehat ez tovabbra is Product
  Ready blokkoló hiany. Ezutan kell clean Windows VM install, launch, uninstall, rollback/update es
  runtime/log secret-leak smoke bizonyitek.

### MEGSEM / megszakitott tranzakcio bizonylat

Javitas:
- `CancelledTransactionReceiptRequest` DTO letrehozva validacioval.
- `ReceiptService.createCancelledTransactionReceipt(...)` letrehozva:
  - onallo `Receipt` rekordot ment `CANCELLED_TRANSACTION` tipussal;
  - `transaction_id` null marad, tehat nem hoz letre felkesz penzugyi tranzakciot;
  - `content` mezoben megorzi a megszakitott draft modjat, sorait, ugyfel-pillanatkepet es
    `financialEffect=NONE` jelolest;
  - `CANCELLED_TRANSACTION_RECEIPT_CREATED` audit logot ir hash-chain utvonalon.
- `POST /api/v1/receipts/cancelled-transaction` endpoint bekotve CASHIER/SUPERVISOR/MANAGER/ADMIN
  szerepkoroknek.
- `receiptApi.createCancelledTransaction(...)` frontend wrapper letrehozva.
- A penztarosi `CashierTransactionPage` Esc/Megse flow-ja best-effort modon rogziti a megszakitott
  bizonylatot, majd torli a draftot.
- A regi `/transactions/new` `TransactionPage` Mégsem/Esc flow-ja is ugyanezt az endpointot hasznalja,
  ha tenyleges draft-adat volt.
- A bizonylat-bongeszo `CANCELLED_TRANSACTION` tipusra magyar cimet es kulon szuro-opciot kapott.
- A bizonylat-bongeszo `CANCELLED_TRANSACTION` nyomtatasi gombja szerveres content JSON-bol
  `PrintReceiptData`-t kepez, Electron `printReceipt` uton nyomtat, es csak sikeres fizikai print utan
  hivja a szerveres `/print` flag endpointot.
- A frontend print contract, a preview modal, az Electron printer HTML/ESC/POS generator es a soros
  printer is felvette a `cancelled_transaction` tipust.
- `scripts/product-ready-evidence-preflight.ps1` most mar a MEGSEM receipt backend/frontend/test
  bekoteseket is szamon keri.

Bizonyitas:
- `cd backend && .\mvnw.cmd -Dtest=ReceiptServiceB7Test test`
  - 21 teszt, 0 failure, 0 error.
- `npm --prefix frontend-react test -- --run src/services/api/transactions.test.ts`
  - 21 teszt PASS.
- `npm --prefix frontend-react test -- --run src/pages/transactions/TransactionPage.test.tsx`
  - 16 teszt PASS.
- `npm --prefix frontend-react test -- --run src/pages/receipts/ReceiptPage.types.test.ts src/services/api/transactions.test.ts`
  - 50 teszt PASS.
- `npm --prefix frontend-react test -- --run src/pages/receipts/ReceiptPage.types.test.ts`
  - 32 teszt PASS.
- `npm --prefix penztar-client test -- electron/__tests__/printer.test.ts`
  - 31 teszt PASS.
- `npm run product-ready:evidence:preflight`
  - 63 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-102349/report.md`.
- `npm run product-ready:evidence:preflight` a MEGSEM fizikai print-path evidence bovites utan:
  - 70 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-103643/report.md`.
- `npm --prefix frontend-react run typecheck`
  - exit 0.
- `npm --prefix penztar-client run typecheck`
  - exit 0.

Korlatozas:
- Ez kod-, typecheck- es pure printer-generator bizonyitek. Product Ready-hez meg kell nezni tiszta
  Windows penztari kliensen, valodi nyomtatoval is: megszakitott bizonylat listazas, fizikai nyomtatas,
  ujranyomtatas es offline kapcsolatvesztes UX.

### NAV penztargep explicit parancsok

Javitas:
- `CashRegisterCommandType`, `CashRegisterCommandRequest` es `CashRegisterCurrencyCommandLine` DTO-k
  letrehozva.
- `POST /api/v1/cash-register/command` endpoint bekotve supervisor/manager/admin szerepkoroknek.
- A napi nyitas/záras a legacy NAV QR parancsokat kuldi:
  - `DAY_OPEN` -> `fiscat/AEE|OP`
  - `DAY_CLOSE` -> `fiscat/AEE|DC|0|0`
- Valuta-lista parancsok:
  - `CURRENCY_LIST_CLEAR` -> `fiscat/AEE|CCL`
  - `CURRENCY_LIST_SET` -> `fiscat/AEE|CYS|<key>|<nev>|<rate>|<rate>...`
- A valuta-lista betoltes determinisztikus kulcsot ad: HUF=`LOCA`, EUR=`CY00`, egyeb valutak
  `CY01`, `CY02`, ... vagy explicit `cashRegisterKey`.
- A bridge tovabbra is fail-closed: ha a NAV bridge nem ad sikert, az auditált
  `cash_register_event.raw_response` ERROR, a controller HTTP 502-t ad.
- Az alacsony szintu `NavIntegrationController` kommentje pontosítva: az uzleti parancsut a
  `CashRegisterController` auditált endpointja.
- `acceptance:local:backend` most mar a cash-register/NAV explicit parancs teszteket is futtatja.
- `scripts/product-ready-evidence-preflight.ps1` ellenorzi az explicit parancs DTO/service/controller/test
  bekoteseket.

Bizonyitas:
- `cd backend && .\mvnw.cmd "-Dtest=CashRegisterServiceTest,CashRegisterControllerTest,NavIntegrationServiceTest" test`
  - 16 teszt, 0 failure, 0 error.
- `npm run acceptance:local:backend`
  - 45 teszt, 0 failure, 0 error.
- `npm run product-ready:evidence:preflight`
  - 77 helyi ellenorzes PASS;
  - 0 helyi ellenorzes FAIL;
  - riport: `security-reports/product-ready-evidence/20260609-104602/report.md`.
- `npm run product-ready:local-gate`
  - 10 lepes PASS;
  - 0 lepes FAIL;
  - riport: `security-reports/product-ready-local-gate/20260609-104608/report.md`.

Korlatozas:
- Ez backend szerzodes es fail-closed bridge bizonyitek. Product Ready-hez tovabbra is kell valodi
  NAV penztargep vagy gyartoi driver acceptance: napnyitas, napzaras, valuta-lista torles/betoltes
  operatori visszaigazolassal es eszkozoldali naploval.

Korlatozas: a preflight nem lep be eles szerverre es nem hasznal credentialt. Tovabbra is hianyzik:
- production/staging full business acceptance execution evidence;
- production backup timer status es legfrissebb off-site backup letoltesi bizonyitek;
- test restore drill row counttal, Flyway state-tel, audit hash-chain checkkel es mert RTO-val;
- monitoring stack live scrape/dashboard/alert teszt;
- clean Windows VM installer smoke a harom Electron kliensre;
- compliance go-live dontes/export a relevans `system_parameter` ertekekrol.

### Friss ellenorzesek a pass utan

Zold:
- `npm run acceptance:local`
- `npm run compliance:flags:test`
- `npm run compliance:golive:preflight`
- `npm run compliance:golive:synthetic`
- `npm run audit:hash-chain:test`
- `npm run audit:hash-chain:preflight`
- `npm run package:penztar`
- `npm run package:arfolyam-keszito`
- `npm run package:kozponti`
- `npm run installer:smoke:preflight`
- `npm run installer:smoke:artifacts`
- `npm run product-ready:local-gate`
- `npm run product-ready:local-gate:full`
- `npm run product-ready:final-gate:preflight`
- `npm run product-ready:final-gate:complete`
- `npm run product-ready:evidence:preflight`
- `npm run product-ready:external-evidence:pack`
- `npm run product-ready:external-evidence:pack:refresh`
- `npm run product-ready:external-evidence:pack:complete`
- `npm run dr:restore:preflight`
- `npm run dr:restore:synthetic`
- `npm run monitoring:preflight`
- `npm run monitoring:synthetic`
- `npm run installer:smoke:synthetic`
- `npm run typecheck`
- `npm run lint`
- `npm run build:all`
- `cd backend && .\mvnw.cmd -Dtest=ReceiptServiceB7Test test`
- `cd backend && .\mvnw.cmd "-Dtest=CashRegisterServiceTest,CashRegisterControllerTest,NavIntegrationServiceTest" test`
- `cd backend && .\mvnw.cmd -Dtest=WorkerRepositoryPostgresLockIT test`
- `npm --prefix frontend-react test -- --run src/services/api/transactions.test.ts`
- `npm --prefix frontend-react test -- --run src/pages/transactions/TransactionPage.test.tsx`
- `npm --prefix frontend-react test -- --run src/pages/receipts/ReceiptPage.types.test.ts src/services/api/transactions.test.ts`
- `npm --prefix frontend-react run typecheck`

Nem blokkoló, de megmaradt Product Ready debt:
- frontend lint tovabbra is 836 warninggal fut le, foleg `i18next/no-literal-string`;
- Maven/JDK native-access es deprecation warningok tovabbra is megjelennek;
- Vite chunk/dynamic import warningok tovabbra is megjelennek.

## Product Ready vegrehajtasi terv

### 1. Stabilizalo sprint - 1-2 nap

- Tartsuk zolden a most bizonyitott kapukat:
  - `npm run typecheck`
  - `npm run lint`
  - `cd backend && mvnw.cmd test`
  - `npm --prefix frontend-react test -- --run`
  - `npm --prefix penztar-client test`
  - `npm run build:all`
- Javitsuk vagy dokumentaljuk a JDK 25 warningokat:
  - vagy JDK 21-et rogzitunk fejlesztoi/build runtime-kent,
  - vagy Maven/Jansi/native-access opciokat kezelunk.
- Keszitsunk egy explicit `acceptance:local` scriptet.
  - 2026-06-09: helyi minimum smoke kesz es zold.
  - 2026-06-09: backend üzleti flow acceptance script bekotve:
    `TransactionFlowTest`, `AmlFlowTest`, `ClosingFlowTest`, `RateCalculationIntegrationTest`,
    `TradeFlowTest` (Mockito-alapu service-flow, nem valos DB/Testcontainers).
  - 2026-06-09: seedelt Testcontainers PostgreSQL acceptance flow bekotve
    `SeededPostgresAcceptanceIT` teszttel BUY/SELL/napi session/tenant-scope receipt lookup
    bizonyitekkal.
  - Hianyzik meg: staging szerveres vagy production-szeru teljes happy-path acceptance riport.

### 2. Compliance go-live sprint - 2-4 nap

- Feature-flag matrix:
  - `AML_HIGH_VALUE_APPROVAL_ENFORCEMENT`
  - `AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT`
  - `CIRCULAR_ACK_BLOCKING_ENFORCEMENT`
  - FATF tier enforcement
  - szankcios kuszobok
- Minden flaghez:
  - jelenlegi default,
  - jogi/uzleti tulajdonos dontese,
  - penztaros UX,
  - offline/local-first viselkedes,
  - audit log bizonyitek.
- Celzott tesztek:
  - 10M+ tranzakcio supervisor PIN-nel es nelkul,
  - 50M+ tranzakcio elfogadott/tiltott dokumentumtipussal,
  - olvasatlan korlevel blokk,
  - FATF 1/a, 1/b, 2. tier utak.
  - 2026-06-09: statikus/helper szintu flag-regresszios kapu kesz es zold; POS/UI full-flow acceptance meg hianyzik.

### 3. Tranzakcios integritas sprint - 3-5 nap

- Sajat hataskoru R/S napi limit atomikussa tetele:
  - 2026-06-09: worker-soru pesszimista lock bizonyitva unit teszttel.
  - 2026-06-09: valos PostgreSQL tranzakcios konkurencia teszt hozzaadva
    `WorkerRepositoryPostgresLockIT` Testcontainers futassal; `acceptance:local:postgres-lock`
    es az osszesitett `acceptance:local` resze.
  - Hianyzik meg: ugyanennek staging/production telemetry-vel vagy incident-free eles idoszakkal
    alatamasztott uzemi bizonyiteka.
- Profit/WAC flow megerositese:
  - 2026-06-09: SELL profit record mar flag-gated es cold-start-safe.
  - 2026-06-09: teljes sztorno es reszleges visszaterites WAC profit-kompenzacio
    kompenzalo tranzakciohoz kotott idempotencia kulccsal vedett.
  - 2026-06-09: `V302__profit_log_compensation_key.sql`, `WacServiceTest` es
    `TransactionReversalServiceTest` bizonyitja a dupla negativ profit-szamolas elleni vedelmet.
- "MEGSEM" bizonylat:
  - 2026-06-09: backend receipt tipus + UI cancel-flow kesz es celzottan tesztelt.
  - Hianyzik meg: print/reprint acceptance Electron kliensen.

### 4. Kulso integraciok sprint - 1-2 het

- NAV penztargep explicit parancsok:
  - 2026-06-09: backend explicit command DTO/endpoint/payload builder kesz es tesztelt;
  - Hianyzik meg: valodi NAV penztargep/gyartoi driver acceptance checklist lefuttatasa.
- Raiffeisen Bank API:
  - 2026-06-09: `bank_api_config` admin tabla/API, titkositott secret persistence,
    scraping fallback es utolso futasi statusz implementalva es celzottan tesztelve.
  - Hianyzik meg: banki API dokumentacio/credential input, validalt REST/OAuth2/mTLS kliens,
    retry/backoff policy eles banki contract alapjan.
- Darius/Raiffeisen riport:
  - outbox/status/transport E2E bizonyitas.

### 5. Operacios Product Ready sprint - 1 het

- DR restore drill:
  - dump,
  - restore uj DB-be,
  - migracio validacio,
  - smoke flow.
- Monitoring:
  - uptime,
  - p99,
  - backend error rate,
  - Electron ClientErrorLog,
  - alert teszt.
- End-user manual:
  - penztaros,
  - ertektaros,
  - admin,
  - friss kepernyofotok,
  - nem-IT kollegas visszaolvasas.
- Installer smoke:
  - penztar,
  - kozponti,
  - arfolyam-keszito,
  - friss telepites + auto-update + rollback.
- Owner approvals:
  - 2026-06-09: strukturalt Product Ready owner approval template es verifier
    hozzaadva: `docs/PRODUCT_READY_APPROVALS_TEMPLATE_2026-06-09.json`,
    `scripts/product-ready-approvals-verify.ps1`,
    `product-ready:approvals:preflight`, `product-ready:approvals:complete`.
  - Az external evidence gate most mar `approvals.reportRef` alatt PASS allapotu,
    nulla failed/review structured approval summaryt ker, role-szintu nevvel,
    idoponttal, `approved = true` jelzessel, evidenceRef-fel es safety
    nyilatkozatokkal.
  - Hianyzik meg: valos product/operations/compliance owner alairas vagy
    immutable sign-off artifact, staging/production completed evidence refhez kotve.
- Final gate summary field map:
  - 2026-06-09: a runbook generator pontosítva lett, hogy
    `finalDecision.finalGateSummaryRef` opcionális post-run proof, nem ugyanazon
    `product-ready:final-gate:complete` futás előfeltétele.
  - Bizonyíték: `security-reports/product-ready-external-evidence-runbook/20260609-152002-185/operator-runbook.md`,
    field map entries: 44, missing checks: 52.
- External evidence handoff pack:
  - 2026-06-09: a missing evidence pack mar szakaszonkenti owner/template/parancs guidance-ot es
    `missing-evidence.json` gepi manifestet is general, hogy az operacios/staging/production evidence
    begyujtes auditálhato es kevesbe felreolvashato legyen.
  - Bizonyíték: `security-reports/product-ready-external-evidence-pack/20260609-152333-133/missing-evidence.md`,
    `security-reports/product-ready-external-evidence-pack/20260609-152333-133/missing-evidence.json`,
    missing checks: 52.
  - A friss operator runbook mar linkeli a gepi manifestet is:
    `security-reports/product-ready-external-evidence-runbook/20260609-152349-537/operator-runbook.md`.
- Missing evidence manifest verifier:
  - 2026-06-09: `scripts/product-ready-missing-evidence-verify.ps1` es root parancsok
    (`product-ready:missing-evidence:verify`, `product-ready:missing-evidence:closed`) hozzaadva.
  - Strukturális manifest ellenorzes: 285/285 PASS
    (`security-reports/product-ready-missing-evidence/20260609-152753-665/summary.json`).
  - Fail-closed closure ellenorzes: elvart modon FAIL, 285 PASS / 1 FAIL, mert a manifestben
    meg 52 missing external evidence check van
    (`security-reports/product-ready-missing-evidence/20260609-152753-787/summary.json`).
- External evidence template freshness guard:
  - 2026-06-09: `docs/PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json`
    `localEvidenceBundleRef` mezoje ures sablonertekre lett allitva, hogy a template ne
    hordozzon stale konkret local evidence bundle run-id-t.
  - `scripts/product-ready-evidence-preflight.ps1` uj negativ regex ellenorzest kapott, amely
    megfogja, ha a sablonba kesobb ujra konkret
    `security-reports/product-ready-local-evidence-bundle/20.../bundle.json` referencia kerul.
  - Bizonyitek: `npm run product-ready:evidence:preflight` 307/307 PASS
    (`security-reports/product-ready-evidence/20260609-165740-160-56440/summary.json`).
  - A pack tovabbra is aktualis bundle-t injektal a draftba:
    `security-reports/product-ready-external-evidence-pack/20260609-165750-933-54276/external-evidence.draft.json`
    -> `security-reports/product-ready-local-evidence-bundle/20260609-165751-380-49640/bundle.json`;
    external evidence preflight: 131 PASS / 0 FAIL / 52 REVIEW.
  - `product-ready:external-evidence:pack:complete` tovabbra is fail-closed: 131 PASS /
    52 FAIL / 0 REVIEW, mert 52 valos external evidence check hianyzik
    (`security-reports/product-ready-external-evidence-pack/20260609-165806-086-53816/summary.json`).
  - `npm run product-ready:final-gate:preflight` PASS: local gate PASS, local evidence bundle PASS,
    external evidence gate PASS preflight modban
    (`security-reports/product-ready-final-gate/20260609-165856-396-11000/summary.json`).
    A final-gate scoped evidence JSON mar a friss
    `security-reports/product-ready-local-evidence-bundle/20260609-170202-692-67456/bundle.json`
    referenciat injektalta; external verifier: 137 PASS / 0 FAIL / 54 REVIEW.
- Transfer staging acceptance evidence hardening:
  - 2026-06-09: a `transfer` / atadas-atvetel flow mar nemcsak a local acceptance coverage
    manifestben szerepel, hanem kotelezo staging/production evidence flow is:
    `docs/PRODUCT_READY_STAGING_ACCEPTANCE_TEMPLATE_2026-06-09.json`,
    `docs/PRODUCT_READY_EXTERNAL_EVIDENCE_TEMPLATE_2026-06-09.json`,
    `scripts/product-ready-staging-acceptance-verify.ps1` es
    `scripts/product-ready-external-evidence-verify.ps1` frissitve.
  - Az operator runbook es a generated missing-evidence pack guidance explicit flow-listaja is
    tartalmazza: buy, sell, conversion, transfer, storno, dayClosing, navCashRegister,
    receiptPrint, offlineSync.
  - Bizonyitek: `npm run product-ready:staging-acceptance:preflight` 26 PASS / 0 FAIL /
    39 REVIEW (`security-reports/product-ready-staging-acceptance/20260609-170624-201-37980/summary.json`);
    `npm run product-ready:acceptance-coverage` 140/140 PASS
    (`security-reports/product-ready-acceptance-coverage/20260609-170637-036-38880/summary.json`);
    `npm run product-ready:evidence:preflight` 313/313 PASS
    (`security-reports/product-ready-evidence/20260609-170746-967-57204/summary.json`).
  - Friss handoff pack: `security-reports/product-ready-external-evidence-pack/20260609-170746-960-63888/missing-evidence.md`
    es `missing-evidence.json`; acceptance guidance mar explicit transfer flow-t ker, external verifier
    132 PASS / 0 FAIL / 52 REVIEW.
  - 2026-06-09 tovabbi pontositas: az operator runbook es a runbook generator field map most mar
    kulon is megnevezi az `/acceptance/coveredFlows` mezot, es ugyanazt a teljes kritikus flow
    listat keri (`buy`, `sell`, `conversion`, `transfer`, `storno`, `dayClosing`,
    `navCashRegister`, `receiptPrint`, `offlineSync`).
  - Bizonyitek: `npm run product-ready:evidence:preflight` 315/315 PASS
    (`security-reports/product-ready-evidence/20260609-171012-915-13628/summary.json`);
    friss generated operator runbook:
    `security-reports/product-ready-external-evidence-runbook/20260609-171012-988-64164/operator-runbook.md`,
    field map entries: 45, missing checks: 52.
  - 2026-06-09 tovabbi hardening: `scripts/product-ready-evidence-preflight.ps1` mar strukturalt
    JSON exact-list ellenorzessel is osszeveti a kritikus flow-listat az acceptance coverage
    manifestben, a staging acceptance sablonban es az external evidence sablon
    `acceptance.coveredFlows` mezojeben. Elvart lista: `buy`, `sell`, `conversion`, `transfer`,
    `storno`, `dayClosing`, `navCashRegister`, `receiptPrint`, `offlineSync`.
  - Bizonyitek: `npm run product-ready:evidence:preflight` 320/320 PASS
    (`security-reports/product-ready-evidence/20260609-171402-300-54936/summary.json`);
    `npm run product-ready:staging-acceptance:preflight` 26 PASS / 0 FAIL / 39 REVIEW
    (`security-reports/product-ready-staging-acceptance/20260609-171402-295-52968/summary.json`);
    `npm run product-ready:external-evidence:preflight` 24 PASS / 0 FAIL / 54 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-171402-524-2984/summary.json`).
  - 2026-06-09 tovabbi backend javitas: az atadas-atvetel sztorno indoklasa mar nemcsak
    controller DTO szinten kotelezo, hanem a `TransferService.storno` service-szerzodesben is
    trimelve validalt. Ures/whitespace indoknal nincs worker lookup, nincs keszletmozgas es nincs
    mentett sztorno. A `getStornoPreview` endpoint most mar a tenyleges sztorno elott is visszaadja
    a `<eredeti>-SZ` sztorno bizonylatszamot, ahogy a FR-15 komment es a frontend API szerzodes
    elvarja.
  - Bizonyitek: `cd backend; .\mvnw.cmd -Dtest=TransferServiceTest test` PASS, 18 teszt,
    0 failure, 0 error (2026-06-09 19:48).
  - 2026-06-09 coverage pontositas: a `docs/PRODUCT_READY_ACCEPTANCE_COVERAGE_2026-06-09.json`
    `storno` flow-ja mar explicit evidencekent tartalmazza az atadas-atvetel sztorno regressziokat is:
    keszlet-visszaforditas, ures indok tiltas, sztorno-preview `-SZ` sorszam, valamint a frontend
    `transferApi.storno` es `transferApi.getStornoPreview` endpoint-szerzodes. Korabban ezek csak a
    `transfer` flow alatt, illetve backend oldalon voltak lathatok, mikozben Product Ready kritikus
    flow-kent a `storno` kulon is szerepel.
  - Bizonyitek: `npm --prefix frontend-react test -- --run src/services/api/transactions.test.ts`
    PASS, 23 teszt; `npm run product-ready:acceptance-coverage` 150/150 PASS
    (`security-reports/product-ready-acceptance-coverage/20260609-195443-390-56788/summary.json`);
    `npm run product-ready:evidence:preflight` 385/385 PASS
    (`security-reports/product-ready-evidence/20260609-195443-428-32944/summary.json`).
  - 2026-06-09 tovabbi coverage-parancs pontositas: a `storno` flow `commands` listaja mar
    nemcsak a backend acceptance parancsot tartalmazza, hanem a frontend API regresszios parancsot is:
    `npm --prefix frontend-react test -- --run src/services/api/transactions.test.ts`.
    A repo evidence preflight kulon orszemekkel ellenorzi a `/transfers/77/storno`,
    `/transfers/77/storno-preview` tesztmintakat es a coverage manifest frontend parancsat.
  - 2026-06-09 UI preview bekotes: a `TransferPage` sztorno modal megnyitasakor mar meghivja a
    `transferApi.getStornoPreview` endpointot, es a modalban a szerveroldali `stornoSerialNumber`
    jelenik meg, lokalis `<eredeti>-SZ` fallbackkel. Igy az FR-15 backend preview szerzodes nem
    csak API-szinten letezik, hanem a felhasznaloi sztorno folyamatban is hasznalva van.
  - Bizonyitek: `npm --prefix frontend-react run typecheck` PASS; `npm run product-ready:acceptance-coverage`
    155/155 PASS
    (`security-reports/product-ready-acceptance-coverage/20260609-195627-208-55676/summary.json`);
    `npm run product-ready:evidence:preflight` 387/387 PASS
    (`security-reports/product-ready-evidence/20260609-195627-661-62116/summary.json`).
  - 2026-06-09 UI preview race-vedelem: a sztorno preview betoltes `stornoPreviewRequestRef`
    tokennel vedett, es a modal minden zarasi aga (`closeStornoModal`) ervenyteleniti a folyamatban
    levo preview kerest. Igy egy keson visszatero preview valasz nem irhatja felul egy masik,
    aktualisan megnyitott sztorno modal celbizonylatat.
  - Bizonyitek: `npm --prefix frontend-react run typecheck` PASS; `npm run product-ready:acceptance-coverage`
    157/157 PASS
    (`security-reports/product-ready-acceptance-coverage/20260609-202025-220-55024/summary.json`);
    `npm run product-ready:evidence:preflight` 388/388 PASS
    (`security-reports/product-ready-evidence/20260609-195821-582-65332/summary.json`).
- External evidence pack local coverage auto-fill:
  - 2026-06-09: `scripts/product-ready-external-evidence-pack.ps1` most mar megkeresi a
    legfrissebb PASS allapotu `product-ready-acceptance-coverage` `summary.json` riportot, es
    az external evidence draft `acceptance.localCoverageReportRef` mezojebe injektalja. Refresh
    modban elotte ujra is futtatja a local acceptance coverage verifiert.
  - Ez nem helyettesiti a staging/production acceptance riportot; csak a helyi kritikus-flow
    coverage tamogato bizonyitekot zarja le gepileg.
  - Bizonyitek: `npm run product-ready:external-evidence:pack:refresh` PASS, missing checks 51
    (`security-reports/product-ready-external-evidence-pack/20260609-171733-522-58536/summary.json`);
    a draft `localCoverageReportRef` erteke:
    `security-reports/product-ready-acceptance-coverage/20260609-171733-958-55832/summary.json`.
  - Celozott visszaellenorzes: friss external evidence verifier 190 PASS / 0 FAIL / 51 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-171815-684-59788/summary.json`);
    missing-evidence manifest verifier 281/281 PASS
    (`security-reports/product-ready-missing-evidence/20260609-171815-597-50972/summary.json`);
    repo evidence preflight 323/323 PASS
    (`security-reports/product-ready-evidence/20260609-171815-848-57156/summary.json`).
  - Fail-closed kontroll: `npm run product-ready:external-evidence:pack:complete` tovabbra is
    elvart modon 1-es exit koddal megall, mert 51 valos kulso bizonyitek meg hianyzik
    (`security-reports/product-ready-external-evidence-pack/20260609-171830-576-38020/summary.json`).
  - Friss operator runbook: `security-reports/product-ready-external-evidence-runbook/20260609-171839-433-65712/operator-runbook.md`,
    source pack: `security-reports/product-ready-external-evidence-pack/20260609-171839-882-55104`,
    missing checks: 51.
- Final gate local coverage auto-fill:
  - 2026-06-09: `scripts/product-ready-final-gate.ps1` is ugyanazt a PASS allapotu local
    acceptance coverage `summary.json` keresest kapta meg, es a final-gate scoped
    `external-evidence.final-gate.json` `acceptance.localCoverageReportRef` mezojebe injektalja.
  - Bizonyitek: `npm run product-ready:final-gate:preflight` 3/3 PASS
    (`security-reports/product-ready-final-gate/20260609-172050-214-38996/summary.json`);
    a scoped evidence JSON `localCoverageReportRef` erteke:
    `security-reports/product-ready-acceptance-coverage/20260609-172246-294-38364/summary.json`.
    A final-gate external verifier 196 PASS / 0 FAIL / 53 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-172353-135-32248/summary.json`).
  - A 53 REVIEW mind kulso/dontesi evidence hiany: staging acceptance, approvals, compliance,
    DR restore, monitoring, installer es final decision. A local coverage ref mar nem hianyzik.
- External evidence runbook local coverage pontositas:
  - 2026-06-09: `docs/PRODUCT_READY_EXTERNAL_EVIDENCE_RUNBOOK_2026-06-09.md` gyujtesi sorrendje
    most explicit kimondja, hogy a `product-ready:external-evidence:pack:refresh` ujrafuttatja a
    local critical-flow coverage-et, friss local evidence bundle-t keszit, es a draft evidence JSON-ba
    injektalja a `localEvidenceBundleRef` es az `acceptance.localCoverageReportRef` mezoket.
  - `scripts/product-ready-evidence-preflight.ps1` uj ellenorzeseket kapott erre a statikus
    runbook tartalomra, igy a local coverage ref operator-leirasa nem tud csendben kiesni.
  - Bizonyitek: `npm run product-ready:evidence:preflight` 327/327 PASS
    (`security-reports/product-ready-evidence/20260609-173021-114-63984/summary.json`);
    `npm run product-ready:external-evidence:runbook:refresh` PASS,
    operator runbook: `security-reports/product-ready-external-evidence-runbook/20260609-173021-118-33748/operator-runbook.md`,
    source pack: `security-reports/product-ready-external-evidence-pack/20260609-173021-574-54408`,
    missing checks: 51. A source pack `localCoverageReportRef` erteke:
    `security-reports/product-ready-acceptance-coverage/20260609-173022-012-53340/summary.json`.
- Local evidence bundle acceptance coverage hash guard:
  - 2026-06-09: `scripts/product-ready-evidence-preflight.ps1` kulon ellenorzi, hogy
    `scripts/product-ready-local-evidence-bundle.ps1` a `product_ready_acceptance_coverage`
    artifactot is beemeli. Igy az external evidence `acceptance.localCoverageReportRef` mogotti
    local coverage riport a local evidence bundle hash-elt artifactjai kozott is kovetelmeny.
  - Bizonyitek: `npm run product-ready:evidence:preflight` 328/328 PASS
    (`security-reports/product-ready-evidence/20260609-173235-891-53740/summary.json`);
    `npm run product-ready:local-evidence-bundle` 92/92 PASS
    (`security-reports/product-ready-local-evidence-bundle/20260609-173238-403-14592/bundle.json`).
    A bundle `product_ready_acceptance_coverage` artifactja:
    `security-reports/product-ready-acceptance-coverage/20260609-173022-012-53340/summary.json`,
    summary SHA-256:
    `2509016CD48BE0619568E3F50471F42BAD2F77AFD2CB0B0479057AD3C07BBF38`.
- Bundle-derived local coverage reference hardening:
  - 2026-06-09: `scripts/product-ready-external-evidence-pack.ps1` es
    `scripts/product-ready-final-gate.ps1` mar nem kulon keresi a legfrissebb local acceptance
    coverage riportot. A `localCoverageReportRef` erteket a kivalasztott
    `localEvidenceBundleRef` `product_ready_acceptance_coverage` artifactjabol veszi, es ellenorzi,
    hogy a summary letezik, JSON-kent olvashato, `failed = 0`, es `Local critical-flow coverage map`
    verifier identitasu.
  - Ez megszunteti azt a lokalis bizonyiteklanc-kockazatot, hogy a draft/final-gate evidence egy
    masik, a bundle-ben nem hash-elt coverage summary-ra hivatkozzon.
  - Bizonyitek: `npm run product-ready:evidence:preflight` 330/330 PASS
    (`security-reports/product-ready-evidence/20260609-173516-917-19532/summary.json`);
    `npm run product-ready:external-evidence:pack:refresh` PASS, a pack `localCoverageReportRef`
    megegyezik a bundle `product_ready_acceptance_coverage` artifact `summary` ertekevel:
    `security-reports/product-ready-acceptance-coverage/20260609-173517-384-34344/summary.json`,
    artifact summary SHA-256:
    `D2FA1F2E25828753158DCBF76245A60472597565796FC0338D769C1E91AD17AA`.
  - Final-gate ellenorzes: `npm run product-ready:final-gate:preflight` 3/3 PASS
    (`security-reports/product-ready-final-gate/20260609-173541-661-56948/summary.json`);
    a final-gate scoped evidence `localCoverageReportRef`, a final gate summary
    `currentLocalCoverageReportRef`, es a bundle `product_ready_acceptance_coverage` artifact
    `summary` erteke mind:
    `security-reports/product-ready-acceptance-coverage/20260609-173751-792-52016/summary.json`.
    A final-gate external verifier 196 PASS / 0 FAIL / 53 REVIEW.
  - Fail-closed ujraellenorzes a modositas utan: `npm run product-ready:final-gate:complete`
    elvart modon 1-es exit koddal allt meg
    (`security-reports/product-ready-final-gate/20260609-174421-752-18876/summary.json`).
    Ebben a futasban a local gate 23/23 PASS, a local evidence bundle PASS, az
    `external_evidence_gate` FAIL volt, es az external verifier complete modban 196 PASS /
    53 FAIL / 0 REVIEW eredmenyt adott
    (`security-reports/product-ready-external-evidence/20260609-174727-845-64960/summary.json`).
    A final-gate `localCoverageReportRef`, a scoped evidence `acceptance.localCoverageReportRef`,
    es a bundle `product_ready_acceptance_coverage` artifact `summary` erteke mind:
    `security-reports/product-ready-acceptance-coverage/20260609-174622-798-60156/summary.json`,
    artifact summary SHA-256:
    `927F7130A640CC83D80D1B5280711B04F8B1CC96171D880AC095B614D259F1E4`.
  - Megjegyzes: egy koztes `product-ready:final-gate:complete` futasban
    (`security-reports/product-ready-final-gate/20260609-174016-460-55312/summary.json`) az
    `acceptance_local` lepes Playwright webServer inditasi hibaval bukott
    (`Process from config.webServer was not able to start. Exit code: 4294967295`). A
    `npm --prefix frontend-react run test:e2e:smoke` celzott ujrafuttatasa 2/2 PASS lett, majd a
    kovetkezo complete final gate futasban az `acceptance_local` PASS lett; igy ez jelenleg
    nem reprodukalodo lokalis testkornyezeti inditasi hiba, nem bizonyitott alkalmazaskod-regresszio.
- Frontend Playwright smoke webServer stabilizalas:
  - 2026-06-09: `frontend-react/playwright.config.ts` a smoke tesztet mar nem a normal dev
    `3000` porton inditja, hanem dedikalt E2E porton (`3100`), `PLAYWRIGHT_E2E_PORT`
    felulirasi lehetoseggel es Vite `--strictPort` kapcsoloval. Igy a local gate frontend smoke
    szervere kevesbe keveredik a normal fejlesztoi szerverrel, es portfoglalas eseten
    determinisztikus hibat ad.
  - Bizonyitek: `npm --prefix frontend-react run test:e2e:smoke` 2/2 PASS; a parhuzamosan
    inditott masodik smoke futas elvart modon `Port 3100 is already in use` hibaval allt meg,
    ami a `--strictPort` viselkedest bizonyitotta. Szekvencialis `npm run acceptance:local:frontend`
    2/2 PASS lett.
  - Tovabbi bizonyitek: `npm --prefix frontend-react run typecheck` PASS; `npm run
    product-ready:evidence:preflight` 333/333 PASS
    (`security-reports/product-ready-evidence/20260609-175035-004-54360/summary.json`);
    `npm run product-ready:local-gate` 23/23 PASS
    (`security-reports/product-ready-local-gate/20260609-175050-760-53376/summary.json`).
    Friss `npm run product-ready:final-gate:preflight` is 3/3 PASS
    (`security-reports/product-ready-final-gate/20260609-175437-212-49720/summary.json`);
    ebben a final-gate scoped external verifier 196 PASS / 0 FAIL / 53 REVIEW.
- Frontend Playwright smoke assert hardening:
  - 2026-06-09: `frontend-react/e2e/smoke.spec.ts` login UI ellenorzese mar nem tautologikus
    `count >= 0` feltetelt hasznal, hanem legalabb egy renderelt interaktiv elemet var el
    (`input`, `button` vagy `[role="button"]`). `scripts/product-ready-evidence-preflight.ps1`
    kulon negativ regex ellenorzest kapott arra, hogy a `toBeGreaterThanOrEqual(0)` forma ne
    keruljon vissza.
  - Bizonyitek: `npm --prefix frontend-react run test:e2e:smoke` 2/2 PASS;
    `npm --prefix frontend-react run typecheck` PASS; `npm run product-ready:evidence:preflight`
    335/335 PASS (`security-reports/product-ready-evidence/20260609-175930-503-51772/summary.json`);
    `npm run product-ready:local-gate` 23/23 PASS
    (`security-reports/product-ready-local-gate/20260609-175945-593-38948/summary.json`).
- Frontend Playwright smoke console-error hardening:
  - 2026-06-09: `frontend-react/e2e/smoke.spec.ts` login smoke tesztje mar nem enged altalanos
    `criticalErrors.length <= 2` turest. A mockolt unauthenticated `refresh-cookie` 401 browser
    resource zajt celzottan leválasztja, de kozben kulon bukik minden varatlan 401 response-ra,
    es a megmarado kritikus console error lista csak ures lehet.
  - `scripts/product-ready-evidence-preflight.ps1` kulon ellenorzi az `unexpectedUnauthorizedResponses`
    es `isExpectedUnauthenticatedResourceError` vedelmet, az ures `criticalErrors` assertet, es
    negativ regexszel tiltja a regi `toBeLessThanOrEqual(2)` turest.
  - Bizonyitek: az elso szigorito futas szandekosan bukott ket mockolt 401 resource erroron, ez
    feltarta a korabbi 2-es tures okat. A celzott 401-szures utan
    `npm --prefix frontend-react run test:e2e:smoke` 2/2 PASS;
    `npm --prefix frontend-react run typecheck` PASS; `npm run product-ready:evidence:preflight`
    339/339 PASS (`security-reports/product-ready-evidence/20260609-180806-264-63408/summary.json`);
    `npm run product-ready:local-gate` 23/23 PASS
    (`security-reports/product-ready-local-gate/20260609-180806-252-48304/summary.json`);
    `npm run product-ready:final-gate:preflight` 3/3 PASS
    (`security-reports/product-ready-final-gate/20260609-181204-166-36844/summary.json`), benne
    ujra futtatott local gate 23/23 PASS
    (`security-reports/product-ready-local-gate/20260609-181204-595-52112/summary.json`) es
    final-gate scoped external verifier 196 PASS / 0 FAIL / 53 REVIEW.
- Final-gate scoped missing evidence manifest:
  - 2026-06-09: `scripts/product-ready-final-gate.ps1` mar nemcsak az external verifier
    PASS/FAIL/REVIEW szamait rogziti, hanem ugyanabban a final-gate run directoryben
    `missing-evidence.md` es `missing-evidence.json` handoffot is general a scoped
    `external-evidence.final-gate.json` alapjan.
  - `scripts/product-ready-missing-evidence-verify.ps1` frissitve lett, hogy a legfrissebb
    final-gate manifestet is megtalalja, elfogadja a `finalGateEvidencePath` alapu
    manifestet, es ellenorizze a final-gate source evidence, local bundle, verifier report
    es section/missing count integritast.
  - Bizonyitek: `npm run product-ready:final-gate:preflight` 4/4 PASS
    (`security-reports/product-ready-final-gate/20260609-182917-579-59772/summary.json`);
    final-gate scoped external verifier 196 PASS / 0 FAIL / 53 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-183230-502-53352/summary.json`);
    friss hianylista:
    `security-reports/product-ready-final-gate/20260609-182917-579-59772/missing-evidence.md`
    es `security-reports/product-ready-final-gate/20260609-182917-579-59772/missing-evidence.json`.
    A hianyok szekciok szerint: acceptance 5, approvals 4, compliance 6, DR restore 10,
    final decision 6, installer 13, monitoring 6, top-level metadata 3. A manifest
    strukturaja `npm run product-ready:missing-evidence:verify` alatt 288/288 PASS
    (`security-reports/product-ready-missing-evidence/20260609-183240-404-45700/summary.json`);
    `npm run product-ready:missing-evidence:closed` elvart modon FAIL, mert 53 hiany meg nyitott
    (`security-reports/product-ready-missing-evidence/20260609-183349-224-54312/summary.json`);
    repo evidence preflight 343/343 PASS
    (`security-reports/product-ready-evidence/20260609-183240-404-54524/summary.json`).
  - 2026-06-09 tovabbi fail-closed pontositas: a manifest complete modban is letrejon akkor,
    ha az external verifier `-RequireComplete` miatt FAIL eredmenyt ad, de a verifier summary
    elkeszul. Bizonyitek: `npm run product-ready:final-gate:complete` elvart modon 1-es koddal
    allt meg, de a futas 3 PASS / 1 FAIL eredmenye mellett a `missing_evidence_manifest` lepes
    PASS volt (`security-reports/product-ready-final-gate/20260609-183555-945-43932/summary.json`).
    Ugyanennek a complete futasnak a manifestje:
    `security-reports/product-ready-final-gate/20260609-183555-945-43932/missing-evidence.json`;
    explicit manifest verifikacio 288/288 PASS
    (`security-reports/product-ready-missing-evidence/20260609-183929-864-22876/summary.json`);
    repo evidence preflight 344/344 PASS
    (`security-reports/product-ready-evidence/20260609-184108-751-60020/summary.json`).
  - 2026-06-09 operator runbook pontositas: `scripts/product-ready-external-evidence-runbook.ps1`
    alapertelmezetten mar a legfrissebb final-gate-scoped `missing-evidence.json` handoffot
    preferalja, es csak fallbackkent hasznalja a regi `product-ready-external-evidence-pack`
    manifestet. A friss runbook `sourceHandoffType=final-gate`, az evidence path a complete
    fail-closed futas `external-evidence.final-gate.json` fajljara mutat, es ugyanazt az 53
    hianyzo external evidence tetelt tartalmazza.
    Bizonyitek: `npm run product-ready:external-evidence:runbook` PASS
    (`security-reports/product-ready-external-evidence-runbook/20260609-184350-570-65420/summary.json`);
    operator runbook:
    `security-reports/product-ready-external-evidence-runbook/20260609-184350-570-65420/operator-runbook.md`;
    repo evidence preflight 347/347 PASS
    (`security-reports/product-ready-evidence/20260609-184410-868-63968/summary.json`).
  - 2026-06-09 final-gate automatikus operator runbook bekotes: a complete final gate mar nem
    kulon, kezi runbook-generalo lepesre tamaszkodik, hanem a sajat run directoryjet adja at a
    `scripts/product-ready-external-evidence-runbook.ps1 -SourceHandoffDirectory ...` hivasnak.
    Igy a runbook a final gate `summary.json` elkeszulte elott is az aktualis
    `missing-evidence.json` manifestbol keszul, majd a final gate summary/report
    `operatorRunbookSummary` mezoben visszalinkeli.
    Bizonyitek: `npm run product-ready:evidence:preflight` 351/351 PASS
    (`security-reports/product-ready-evidence/20260609-190323-923-55672/summary.json`);
    `npm run product-ready:final-gate:complete` elvart modon FAIL, de 4 PASS / 1 FAIL
    eredmennyel futott (`security-reports/product-ready-final-gate/20260609-185826-707-49328/summary.json`).
    Ebben a futasban `operator_runbook` PASS, a linkelt operator runbook:
    `security-reports/product-ready-external-evidence-runbook/20260609-190141-863-51272/operator-runbook.md`,
    source handoff:
    `security-reports/product-ready-final-gate/20260609-185826-707-49328`,
    hianyzo external evidence: 53.
  - 2026-06-09 evidence intake csomag: `scripts/product-ready-evidence-intake.ps1` letrehozva,
    es `product-ready:evidence:intake` root npm scripthez kotve. A script a final-gate
    `missing-evidence.json` manifestbol operatori kitoltesi csomagot keszit:
    `evidence-intake.json`, `operator-intake-checklist.md`, valamint szakaszonkenti
    checklist fajlok. A final gate automatikusan futtatja az `evidence_intake` lepest is,
    es `evidenceIntakeSummary` mezoben linkeli. Ez nem kulso bizonyitek, hanem a valos
    staging/production evidence begyujtesenek kontrollalt intake csomagja.
    Bizonyitek: `npm run product-ready:evidence:intake` PASS
    (`security-reports/product-ready-evidence-intake/20260609-190744-797-11440/summary.json`);
    `npm run product-ready:evidence:preflight` 358/358 PASS
    (`security-reports/product-ready-evidence/20260609-190752-774-65768/summary.json`);
    `npm run product-ready:final-gate:complete` elvart modon FAIL, de 5 PASS / 1 FAIL
    eredmennyel futott
    (`security-reports/product-ready-final-gate/20260609-190802-172-63056/summary.json`).
    Ebben a futasban az `evidence_intake` lepes PASS; a linkelt intake JSON:
    `security-reports/product-ready-evidence-intake/20260609-191108-342-53716/evidence-intake.json`,
    operator checklist:
    `security-reports/product-ready-evidence-intake/20260609-191108-342-53716/operator-intake-checklist.md`,
    source manifest:
    `security-reports/product-ready-final-gate/20260609-190802-172-63056/missing-evidence.json`,
    hianyzo external evidence: 53 check, 8 szakaszban.
  - 2026-06-09 staging/monitoring anti-local evidence kontroll: a strukturalt staging
    acceptance es monitoring verifier mar nem elegszik meg azzal, hogy a source mezok
    formailag ki vannak toltve. A `source.baseUrl`, illetve a Prometheus/Grafana/Alertmanager
    URL-ek HTTP(S) deployed URL-ek kell legyenek, es nem lehetnek localhost/loopback
    hivatkozasok; a deployment/dataset referenciak sem lehetnek synthetic/local/mock jelleguek.
    Az external evidence verifier ezeket a belso checkeket is elvarja, ha strukturalt
    `reportRef` van csatolva.
    Bizonyitek: `npm run product-ready:evidence:preflight` 362/362 PASS
    (`security-reports/product-ready-evidence/20260609-191801-282-50372/summary.json`);
    `npm run product-ready:external-evidence:preflight` 24 PASS / 0 FAIL / 54 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-191801-283-63960/summary.json`);
    negativ verifier tesztben a localhost-os acceptance es monitoring minta `-RequirePass`
    modban egyarant a megfelelo deployed-url checken bukott.
  - 2026-06-09 owner approval anti-placeholder kontroll: a strukturalt Product Ready owner
    approval verifier mar nem fogad el completed evidence hivatkozaskent template/draft
    placeholdert, es az egyes product/operations/compliance owner `evidenceRef` mezoknel is
    elutasitja a template/draft vagy synthetic/local/mock jellegu artifactokat. Az external
    evidence verifier ezeket a belso approval checkeket is elvarja, ha strukturalt
    `approvals.reportRef` van csatolva.
    Bizonyitek: `npm run product-ready:approvals:preflight` REVIEW, 12 PASS / 0 FAIL /
    25 REVIEW (`security-reports/product-ready-approvals/20260609-192508-611-53392/summary.json`);
    `npm run product-ready:evidence:preflight` 366/366 PASS
    (`security-reports/product-ready-evidence/20260609-192508-647-2016/summary.json`);
    `npm run product-ready:external-evidence:preflight` 24 PASS / 0 FAIL / 54 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-192517-384-42616/summary.json`);
    negativ verifier tesztben a template/draft `completedEvidenceRef` es a template owner
    approval artifact is `-RequirePass` modban FAIL lett.
  - 2026-06-09 DR restore evidence-kind kontroll: `scripts/dr-restore-drill.ps1` most
    gepileg olvashatoan rogziti, hogy a riport `plan-only`, `synthetic-tooling-smoke`
    vagy `real-backup-drill` tipusbol szarmazik-e, es kulon `isolatedScratchTargetConfirmed`
    mezoben tarolja az operator explicit izolalt scratch target megerositeset. A synthetic
    Docker drill tovabbra is lefuthat lokalis tooling smoke-kent, de a Product Ready external
    verifier strukturalt DR riportkent csak `real-backup-drill` evidence kindet es megerositett
    izolalt scratch targetet fogad el.
    Bizonyitek: `npm run dr:restore:preflight` PASS, plan-only summary
    (`security-reports/dr-restore-drills/20260609-192818-327-60576/summary.json`);
    `npm run dr:restore:synthetic` PASS, `evidenceKind=synthetic-tooling-smoke`
    (`security-reports/dr-restore-drills/20260609-192838-452-66120/summary.json`);
    `npm run product-ready:evidence:preflight` 371/371 PASS
    (`security-reports/product-ready-evidence/20260609-192920-756-58152/summary.json`);
    `npm run product-ready:external-evidence:preflight` 24 PASS / 0 FAIL / 54 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-192830-707-56204/summary.json`);
    negativ external-verifier tesztben egy minden mas DR belso checkben PASS-nak tuno,
    de `synthetic-tooling-smoke` summary final evidencekent FAIL lett a
    `drRestore report evidence kind` checken.
  - 2026-06-09 clean VM installer explicit kornyezet-kontroll: `scripts/installer-clean-vm-smoke.ps1`
    mar kulon `-ConfirmDisposableCleanVm` kapcsolot ker a tenyleges install/launch/uninstall
    futtatashoz, es ezt `confirmDisposableCleanVm` mezoben rogziti a summaryben. Az external
    Product Ready verifier a clean VM riportot csak `executeInstall=true`, `acceptVmMutation=true`,
    `confirmDisposableCleanVm=true`, valamint PASS environment checkek mellett fogadja el.
    Az operatori parancsok a final-gate missing-evidence handoffban, az external evidence packban
    es az installer security checklistben is frissultek az uj kapcsolora.
    Bizonyitek: `npm run installer:smoke:clean-vm` preflight PASS, 9 PASS / 0 FAIL / 3 SKIP
    (`security-reports/installer-clean-vm-smoke/20260609-193253-387-8012/summary.json`);
    `npm run product-ready:evidence:preflight` 375/375 PASS
    (`security-reports/product-ready-evidence/20260609-193507-286-56180/summary.json`);
    `npm run product-ready:external-evidence:preflight` 24 PASS / 0 FAIL / 54 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-193319-148-36280/summary.json`);
    negativ external-verifier tesztben egy belso clean VM checkjeiben PASS-nak tuno, de
    `confirmDisposableCleanVm=false` summary final evidencekent FAIL lett az
    `installer clean VM confirmDisposableCleanVm` checken.
  - 2026-06-09 monitoring observation-window konzisztencia: a strukturalt monitoring
    evidence verifier mar nem csak kulon ellenorzi az `observedFrom`, `observedTo` es
    `observationHours` mezoket, hanem ossze is veti oket. Product Ready monitoring
    bizonyiteknal `observedTo` kesobbi kell legyen, mint `observedFrom`, es a tenyleges
    idoablak oraszama legalabb a deklaralt `observationHours`, amelynek minimum 168 ora.
    Az external evidence verifier ezt a belso `observation window consistency` checket is
    elvarja strukturalt monitoring riport eseten.
    Bizonyitek: `npm run product-ready:monitoring-evidence:preflight` REVIEW,
    9 PASS / 0 FAIL / 32 REVIEW
    (`security-reports/product-ready-monitoring-evidence/20260609-193659-421-57668/summary.json`);
    `npm run product-ready:evidence:preflight` 377/377 PASS
    (`security-reports/product-ready-evidence/20260609-193733-996-4004/summary.json`);
    `npm run product-ready:external-evidence:preflight` 24 PASS / 0 FAIL / 54 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-193707-658-32068/summary.json`);
    negativ monitoring verifier tesztben a 168 orat deklaralo, de csak 24 oras
    `observedFrom`/`observedTo` ablak `-RequirePass` modban FAIL lett az
    `observation window consistency` checken.
  - 2026-06-09 acceptance flow evidenceRef anti-placeholder kontroll: a strukturalt
    staging/production acceptance verifier mar minden kritikus flow `evidenceRef` mezojere
    ellenorzi, hogy az letezo/HTTPS hivatkozas mellett ne legyen template/draft placeholder
    es ne legyen synthetic/local/mock jellegu bizonyitek. Az external evidence verifier a
    strukturalt acceptance summaryben ezeket a flow-szintu belso checkeket is elvarja.
    Bizonyitek: `npm run product-ready:staging-acceptance:preflight` REVIEW,
    26 PASS / 0 FAIL / 60 REVIEW
    (`security-reports/product-ready-staging-acceptance/20260609-193924-076-26272/summary.json`);
    `npm run product-ready:evidence:preflight` 381/381 PASS
    (`security-reports/product-ready-evidence/20260609-194002-404-56468/summary.json`);
    `npm run product-ready:external-evidence:preflight` 24 PASS / 0 FAIL / 54 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-193936-913-62100/summary.json`);
    negativ acceptance verifier tesztben a flow-k PASS statusza mellett template-re mutato
    `flows.buy.evidenceRef` `-RequirePass` modban FAIL lett a
    `flows.buy.evidenceRef not template/draft` checken.
  - 2026-06-09 final decision temporal consistency kontroll: az external Product Ready
    evidence verifier mar ellenorzi, hogy a `finalDecision.decidedAt` ne legyen korabbi,
    mint a top-level `generatedAt`, az acceptance/DR idopontok, illetve a strukturalt
    approvals, compliance, monitoring es installer riportokbol kiolvashato bizonyitek-idopontok.
    Ez megakadalyozza, hogy a vegso Product Ready dontes idoben a bizonyitekok elottre
    legyen datalva.
    Bizonyitek: celzott negativ external-verifier tesztben egy 2026-06-09-i final decision
    es 2026-06-10-i generated/acceptance/DR evidence `-RequireComplete` modban FAIL lett a
    `finalDecision temporal consistency` checken; `npm run product-ready:evidence:preflight`
    382/382 PASS
    (`security-reports/product-ready-evidence/20260609-194419-447-54656/summary.json`);
    `npm run product-ready:external-evidence:preflight` 24 PASS / 0 FAIL / 55 REVIEW
    (`security-reports/product-ready-external-evidence/20260609-194419-431-54724/summary.json`).
  - 2026-06-09 missing-evidence manifest check-szintu szekcio: a final-gate altal generalt
    `missing-evidence.json` manifestben mar nemcsak a szulo section objektum hordozza a
    szekcio nevet, hanem minden nested `checks[]` elem is. A
    `scripts/product-ready-missing-evidence-verify.ps1` ezt kulon ellenorzi, igy egy check
    szulo kontextusbol kiemelve is gepileg besorolhato.
    Bizonyitek: `npm run product-ready:final-gate:preflight` PASS, 6/6 lepes
    (`security-reports/product-ready-final-gate/20260609-200550-053-44584/summary.json`);
    friss manifest:
    `security-reports/product-ready-final-gate/20260609-200550-053-44584/missing-evidence.json`,
    missing checks: 54; `npm run product-ready:missing-evidence:verify` 346/346 PASS
    (`security-reports/product-ready-missing-evidence/20260609-200941-618-64296/summary.json`);
    `npm run product-ready:evidence:preflight` 390/390 PASS
    (`security-reports/product-ready-evidence/20260609-200941-665-53144/summary.json`).
  - 2026-06-09 evidence-intake check-szintu forras-kovethetoseg: a
    `scripts/product-ready-evidence-intake.ps1` altal generalt `evidence-intake.json`
    mar minden `checks[]` elemre kiirja a `section`, `sourceCheckName` es `sourceStatus`
    mezoket is. Igy az operatori checklistbol kiemelt egyedi teendo gepileg visszakotheto
    a final-gate scoped `missing-evidence.json` forrasmanifest megfelelo szekciojahoz.
    Bizonyitek: `npm run product-ready:evidence:intake` PASS,
    `security-reports/product-ready-evidence-intake/20260609-201904-909-39164/evidence-intake.json`;
    az elso check tenylegesen tartalmazta:
    `section=acceptance`, `sourceCheckName=acceptance.status`, `sourceStatus=FAIL`.
    `npm run product-ready:evidence:preflight` 393/393 PASS
    (`security-reports/product-ready-evidence/20260609-201932-307-14660/summary.json`).
  - 2026-06-09 external evidence pack check-szintu szekcio: az onallo
    `scripts/product-ready-external-evidence-pack.ps1` altal generalt `missing-evidence.json`
    manifest is ugyanazt a traceability szerzodest adja, mint a final-gate scoped handoff:
    minden `checks[]` elem tartalmazza a szulo `section` nevet. Igy a final gate es az
    external evidence pack utvonal kozos formatumban adja at a hianyzo Product Ready
    bizonyitekokat.
    Bizonyitek: `npm run product-ready:external-evidence:pack` PASS,
    `security-reports/product-ready-external-evidence-pack/20260609-202308-465-53760/missing-evidence.json`;
    az elso check tenylegesen tartalmazta: `section=acceptance`.
    Explicit manifest verifier: 344/344 PASS
    (`security-reports/product-ready-missing-evidence/20260609-202320-497-61356/summary.json`);
    `npm run product-ready:evidence:preflight` 394/394 PASS
    (`security-reports/product-ready-evidence/20260609-202320-736-60884/summary.json`).
  - 2026-06-09 operator runbook machine-readable handoff guard: a
    `scripts/product-ready-external-evidence-runbook.ps1` external-evidence-pack forrast
    mar csak akkor fogad el, ha a packban a `missing-evidence.md` mellett a gepileg
    olvashato `missing-evidence.json` is letezik. Igy az operator runbook nem tud visszaesni
    csak emberi Markdown hianylistara, ha nincs strukturalt manifest.
    Bizonyitek: `npm run product-ready:external-evidence:runbook` PASS,
    `security-reports/product-ready-external-evidence-runbook/20260609-202521-137-27708/summary.json`;
    friss operator runbook:
    `security-reports/product-ready-external-evidence-runbook/20260609-202521-137-27708/operator-runbook.md`;
    `npm run product-ready:evidence:preflight` 395/395 PASS
    (`security-reports/product-ready-evidence/20260609-202521-153-19384/summary.json`).
  - 2026-06-09 evidence-intake verifier: `scripts/product-ready-evidence-intake-verify.ps1`
    letrehozva es `product-ready:evidence-intake:verify` root npm parancshoz kotve. A verifier
    a generalt `evidence-intake.json` fajlt osszeveti a forras `missing-evidence.json`
    manifeszttel: szekcio, owner/template/notes, missing darabszam, check nev, check section,
    `sourceCheckName`, `sourceStatus`, status, currentEvidence/evidence es expected mezok
    szintjen. A generator most altalanos `sourceEvidencePath` mezot is ad, igy final-gate
    es external-evidence-pack forrasbol is ellenorizheto, nem csak final-gate handoffbol.
    Bizonyitek: `npm run product-ready:evidence:intake` PASS,
    `security-reports/product-ready-evidence-intake/20260609-202936-063-54464/evidence-intake.json`;
    ez a pack forrasu intake `sourceManifestPath` mezoje:
    `security-reports/product-ready-external-evidence-pack/20260609-202308-465-53760/missing-evidence.json`,
    `sourceEvidencePath` mezoje:
    `security-reports/product-ready-external-evidence-pack/20260609-202308-465-53760/external-evidence.draft.json`.
    `npm run product-ready:evidence-intake:verify` 736/736 PASS
    (`security-reports/product-ready-evidence-intake-verify/20260609-202944-655-60952/summary.json`);
    `npm run product-ready:evidence:preflight` 404/404 PASS
    (`security-reports/product-ready-evidence/20260609-202944-650-63064/summary.json`).
  - 2026-06-09 final-gate evidence-intake verifier bekotes: a `scripts/product-ready-final-gate.ps1`
    mar nemcsak generalja es linkeli a final-gate scoped `evidence_intake` csomagot, hanem rogton
    futtatja ra az `evidence_intake_verify` lepest is. A final gate summary/report kulon
    `evidenceIntakeVerifySummary` mezoben linkeli a strukturaverifier eredmenyet, igy a final gate
    operatori intake csomagja sem marad verifikalatlan.
    Bizonyitek: `npm run product-ready:final-gate:preflight` 7/7 PASS
    (`security-reports/product-ready-final-gate/20260609-203331-224-38700/summary.json`);
    ugyanebben a futasban az external verifier preflight 196 PASS / 0 FAIL / 54 REVIEW,
    az `evidence_intake_verify` 757/757 PASS
    (`security-reports/product-ready-evidence-intake-verify/20260609-203645-587-26612/summary.json`).
    `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL
    (`security-reports/product-ready-final-gate/20260609-203719-066-56120/summary.json`);
    az egyetlen FAIL tovabbra is az `external_evidence_gate`, mikozben az `evidence_intake_verify`
    757/757 PASS
    (`security-reports/product-ready-evidence-intake-verify/20260609-204135-034-42588/summary.json`).
    `npm run product-ready:evidence:preflight` 407/407 PASS
    (`security-reports/product-ready-evidence/20260609-203321-015-63680/summary.json`).

## Aktualis verdikt

**Lokalis repo allapot:** jo es futtathato; a legfrissebb repo-local evidence preflight
407/407 PASS
(`security-reports/product-ready-evidence/20260609-203321-015-63680/summary.json`).
A legfrissebb `npm run product-ready:final-gate:preflight` futas 7/7 PASS eredmenyt adott
(`security-reports/product-ready-final-gate/20260609-203331-224-38700/summary.json`), es
friss, check-szintu section mezokkel ellatott `missing-evidence.json` manifestet, operator
runbookot, evidence intake csomagot es evidence-intake verifier summaryt general/linkel:
`security-reports/product-ready-final-gate/20260609-203331-224-38700/missing-evidence.json`.
Ebben preflight/REVIEW modban 54 kulso/dontesi evidence check marad nyitva.
A legfrissebb `npm run product-ready:final-gate:complete` futas elvart modon FAIL lett,
de a helyi kapu, local evidence bundle, operator runbook, evidence intake es evidence-intake verifier lepesek PASS
allapotban futottak
(`security-reports/product-ready-final-gate/20260609-203719-066-56120/summary.json`).
Az ugyanebben a futasban keszult final-gate scoped external verifier complete modban
196 PASS / 54 FAIL / 0 REVIEW eredmenyt adott,
es friss missing-evidence handoffot hagyott:
`security-reports/product-ready-final-gate/20260609-203719-066-56120/missing-evidence.json`.

**Product Ready allapot:** meg nem bizonyithato. Nem kod-osszeomlas miatt, hanem mert hianyzik az
eles acceptance, DR restore, monitoring idoszak, compliance go-live dontes es felhasznaloi/installer
validacio bizonyiteka, valamint a strukturalt product/operations/compliance owner approval riport.

**Fail-closed final gate kontroll:** `npm run product-ready:final-gate:complete`
2026-06-09 20:37-kor elvart modon FAIL lett, mert a final-gate scoped external evidence meg
hianyos (`security-reports/product-ready-final-gate/20260609-203719-066-56120/summary.json`).
A local gate, a local evidence bundle, a `missing_evidence_manifest`, az automatikus
`operator_runbook`, az automatikus `evidence_intake` es az `evidence_intake_verify` lepes PASS volt; az
`external_evidence_gate` FAIL. Az external verifier
complete modban 196 PASS / 54 FAIL / 0 REVIEW eredmenyt adott,
tehat nem enged Product Ready allitast draft vagy hianyos external evidence mellett. A complete
futas ugyanebben a run directoryben friss `missing-evidence.md` es `missing-evidence.json`
handoffot is hagy:
`security-reports/product-ready-final-gate/20260609-203719-066-56120/missing-evidence.json`.
Az evidence intake verifier ezen a complete futason 757/757 PASS eredmenyt adott:
`security-reports/product-ready-evidence-intake-verify/20260609-204135-034-42588/summary.json`.
Az aktualis operator runbook ezt a final-gate handoffot hasznalja forraskent, es a final gate
summary `operatorRunbookSummary` mezoben is linkeli:
`security-reports/product-ready-external-evidence-runbook/20260609-204132-950-66188/operator-runbook.md`.
A final-gate futas sajat evidence intake csomagja tovabbra is a final-gate scoped manifestbol
keszult, es `evidence_intake_verify` alatt 757/757 PASS eredmenyt adott:
`security-reports/product-ready-evidence-intake/20260609-204133-988-60396/operator-intake-checklist.md`.
A preflight final gate kozben tovabbra is PASS/REVIEW modban hasznalhato, mert ott a hianyos kulso
bizonyitekok REVIEW-kent latszanak, nem final approvalkent.

**Napzaras-kimaradas P0 alert - lokalis kod/evidence javitas:**
2026-06-09 20:50-kor a compliance gap-listaban szereplo
`Napzaras-kimaradas daily cron alert` lokalis kodoldali resze implementalva lett.
Uj backend elemek:
`backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingMissedAlertService.java`,
`backend/src/main/java/hu/puzzleir/valuta/config/DailyClosingMissedAlertScheduler.java`,
`backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingMissedAlertServiceTest.java`.
A scheduler minden nap 08:30-kor Europe/Budapest idozonaval az elozo naptari nap nyitva levo,
aktiv, zarasra kotelezett irodait ellenorzi; hianyzo vagy nem kesz `dailyClosingDone` eseten
company-szintu supervisor/manager/admin ertesitest kuld, es
`DAILY_CLOSING_MISSED_ALERT` audit logot ir. A service company+date audit referenciaval idempotens,
igy ugyanarra a napra nem spameli ujra a cimzetteket.

Ellenorzes:
- `cd backend; .\mvnw.cmd -Dtest=DailyClosingMissedAlertServiceTest test` PASS,
  4 teszt, 0 hiba.
- `npm run product-ready:acceptance-coverage` PASS, 162/162
  (`security-reports/product-ready-acceptance-coverage/20260609-204956-434-61120/summary.json`).
- `npm run product-ready:evidence:preflight` PASS, 417/417
  (`security-reports/product-ready-evidence/20260609-205002-460-50788/summary.json`).

Korlatozas: ez lokalis kod-, teszt- es kapu-bekotesi bizonyitek. Product Ready final allitashoz
tovabbra is production/staging scheduler futasi log, alert delivery es operator/DPO visszaigazolas kell
az external evidence csomagban.

**Customer PEP es adatkezelesi tajekoztato UI kontroll - lokalis kod/evidence javitas:**
2026-06-09 21:05-kor a compliance gap-listaban szereplo
`Customer.isPep UI required field` P1 es az `Adatkezelesi tajekoztato UI-on` P0 lokalis kodoldali
resze erositesre kerult. A backend customer create/update DTO es response DTO mar explicit
`isPep` mezot visz, a mapper es `CustomerService` perzisztalja. A frontend dedikalt
ugyfelrogzites oldala kotelezo PEP valasztot es kotelezo adatkezelesi tajekoztato checkboxot kapott;
a tranzakcios kezi ugyfelrogzitesi panel is kotelezo adatkezelesi acknowledge-et ker, es a payload
`notes` mezobe audit-barathoz `ADATKEZELESI_TAJEKOZTATO_ACK v2026-06-09` markert ir.

Ellenorzes:
- `cd backend; .\mvnw.cmd -Dtest=CustomerServiceTest test` PASS,
  9 teszt, 0 hiba.
- `npm --prefix frontend-react test -- --run src/pages/customers/CustomerCreatePage.test.tsx src/pages/transactions/components/CustomerPanel.test.tsx`
  PASS, 13 teszt, 0 hiba.
- `npm --prefix frontend-react run typecheck` PASS.
- `npm run product-ready:evidence:preflight` PASS, 431/431
  (`security-reports/product-ready-evidence/20260609-210412-519-62220/summary.json`).
- `npm run product-ready:final-gate:preflight` PASS, 7/7; a preflight external evidence tovabbra is
  196 PASS / 0 FAIL / 54 REVIEW
  (`security-reports/product-ready-final-gate/20260609-210425-808-53552/summary.json`).

Korlatozas: ez lokalis UI/API/teszt bizonyitek. A Product Ready external evidence-ben tovabbra is
valos staging acceptance, DPO/legal adatkezelesi tajekoztato verzio-joavahagyas, valamint a bizonylat
vegso adatkezelesi labjegyzet/nyomtatasi proof szukseges.

**V304 Flyway, security gate es synthetic evidence tooling javitas - 2026-06-09 21:45:**
Ujabb Product Ready kapufutas kozben ket lokalis, javithato hiba jott elo:

- A lokalis DB preflight elbukott, mert a dev DB a repo migracioihoz kepest V163-on allt, es
  a V304 migracio PostgreSQL-en `DROP INDEX`-et probalt futtatni olyan objektumra, amelyet table
  constraint tartott. Javitas: `V304__shipment_request_serial_prefix.sql` elobb constraintkent,
  majd indexkent takaritja a regi globalis `request_number` egyediseget; a `ShipmentRequest` entity
  mapping is a company-scoped `idx_shipment_request_company_number` szerzodesre lett igazitva.
- A security gate Python dangerous API scan false positive-ot adott a
  `scripts/dev-tools/electron-security-scan.py` dokumentacios szovegere. Javitas: a futokodban
  hasznalt regex marad, de a scanner sajat leiro szovege nem tartalmazza a tiltott mintat.
- A `scripts/dev-db.mjs` Windows shell-es Docker inditasa Node deprecation/security warningot adott.
  Javitas: Docker inditas argumentumlistaval, shell nelkul.
- A `scripts/compliance-golive-synthetic-export.ps1` egyszeri Postgres seedje transient
  `database system is shutting down` allapotnal bukhatott. Javitas: seed retry es hiba eseten
  container state + docker log diagnosztika.
- A V304-ben talalt constraint/index drift hibat a Flyway content audit is megtanulta:
  `scripts/dev-tools/flyway-content-audit.py` most `DROP-INDEX` LOW findingot ad, es a
  `product-ready:evidence:preflight` kulon ellenorzi, hogy ez a kontroll bekotve maradjon.

Lokalis DB helyreallitas: a dev DB `valuta-postgres` kontener elinditva, lokalis Flyway history
V33 checksum repair lefutott, majd a repo migracioi V304-ig sikeresen felmentek. Ez csak lokalis
dev DB rendezese; production/remote repair vagy migrate nem tortent.

Ellenorzes:
- `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1` PASS,
  overall `PASSED` (`security-reports/20260609-212551-259-49024`, `security-reports/latest`).
- `cd backend; .\mvnw.cmd test` PASS, 1996 teszt, 0 failure, 0 error.
- `npm --prefix frontend-react test -- --run` PASS, 106 test file, 1249 teszt.
- `npm --prefix penztar-client test` PASS, 10 test file, 207 teszt.
- `npm run lint` PASS, 0 error; 845 i18n warning megmaradt.
- `npm run build:all` PASS; Vite chunk/dynamic-import warningok megmaradtak.
- `npm run migration:flyway:content-audit:product-ready` PASS; a DROP INDEX sorok LOW findingkent
  latszanak, de a Product Ready MEDIUM kuszobot nem bukjak.
- `npm run product-ready:evidence:preflight` PASS, 432/432
  (`security-reports/product-ready-evidence/20260609-214804-201-46336/summary.json`).
- `npm run product-ready:local-gate` PASS, 23/23
  (`security-reports/product-ready-local-gate/20260609-214832-700-68136/summary.json` es friss
  final-gate alatti local gate: `security-reports/product-ready-local-gate/20260609-215155-233-9824/summary.json`).
- `npm run product-ready:final-gate:preflight` PASS, 7/7
  (`security-reports/product-ready-final-gate/20260609-213226-755-47152/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  a local gate, local evidence bundle, missing-evidence manifest, operator runbook, evidence intake
  es evidence-intake verifier PASS; csak az `external_evidence_gate` FAIL, mert 54 valos kulso
  evidence check hianyzik
  (`security-reports/product-ready-final-gate/20260609-215154-776-37472/summary.json`).

**Kovetkezo legjobb konkret munka:** a legfrissebb final-gate-scoped
`security-reports/product-ready-final-gate/20260609-215154-776-37472/missing-evidence.md`
es `security-reports/product-ready-final-gate/20260609-215154-776-37472/missing-evidence.json`
54 tetelet kell valos staging/production acceptance, compliance export/dontes, DR restore, 168 oras
monitoring, alairt artifact, clean VM installer smoke riportokkal es owner approval summaryvel
lezarni, majd a kitoltott external evidence JSON-ra
`PRODUCT_READY_EXTERNAL_EVIDENCE_PATH=<path>` mellett
`npm run product-ready:final-gate:complete` futtatasa. Enelkul Product Ready allapot tovabbra sem
allithato tenyszeruen.

**Product Ready security gate bekotes a helyi gate/bundle lancba - 2026-06-09 22:08:**
A korabbi allapotban a teljes security gate ugyan kulon PASS bizonyitekkent lefutott, de nem volt
kotelezo lepese a `product-ready:local-gate` aggregalt kapunak. Ez Product Ready/release jellegu
dontesnel gyenge bizonyiteklanc volt, mert a helyi bundle csak a local gate riportjait hitelesitette.

Javitas:
- `scripts/product-ready-local-gate.ps1`: uj kotelezo `security_gate` lepes futtatja a
  `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1` parancsot.
- `scripts/product-ready-local-evidence-bundle.ps1`: a `security_gate` local gate lepes kotelezo,
  PASS allapotu es letezo loggal rendelkezo bizonyitek lett; a log SHA-256 hash bekerul a bundle-be.
- `scripts/product-ready-evidence-preflight.ps1`: statikus szerzodes-ellenorzes biztosítja, hogy
  a local gate futtatja a security gate-et, es a bundle ellenorzi a security gate lepeslogot.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 435/435
  (`security-reports/product-ready-evidence/20260609-215931-412-48248/summary.json`).
- `npm run product-ready:local-gate` PASS, 24/24; a `security_gate` lepes PASS
  (`security-reports/product-ready-local-gate/20260609-215938-181-56232/summary.json`).
- `npm run product-ready:local-evidence-bundle` PASS, 95/95; a bundle tartalmazza a
  `security_gate` local gate lepeslog hash-et
  (`security-reports/product-ready-local-evidence-bundle/20260609-220348-042-56024/bundle.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  a final gate altal inditott friss local gate 24/24 PASS, a friss local evidence bundle 95/95 PASS,
  az `external_evidence_gate` tovabbra is FAIL a valos kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260609-220355-983-42364/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260609-220752-010-23088/summary.json`).

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a repo oldali P0/P1 es talalt lokalis gate/bizonyiteklanc hibak javitva es
celzottan ellenorizve vannak, de Product Ready allapot tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260609-220355-983-42364/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezárva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Staging/monitoring deployed URL loopback hardening - 2026-06-09 22:20:**
Ujabb verifier self-review kozben a Product Ready acceptance es monitoring bizonyitek verifierekben
talaltam egy repo-oldali kockazatot: a `Test-DeployedHttpUrl` kontroll string-alapon tiltott
localhost/loopback hostokat. A `127.*` IPv4 tartomany mar tiltva volt, de az IPv6 literalok es az
IPv4-mapped IPv6 forma (`[::1]`, `[::ffff:127.0.0.1]`) ellenorzese nem volt eleg robusztus.

Javitas:
- `scripts/product-ready-staging-acceptance-verify.ps1`: a deployed URL kontroll most
  `System.Net.IPAddress` parszolassal tiltja a localhostot, minden loopback IP-t, IPv4-mapped IPv6
  loopback cimet, valamint wildcard bind hostokat.
- `scripts/product-ready-monitoring-evidence-verify.ps1`: ugyanez a hardening bekerult a
  Prometheus/Grafana/Alertmanager URL-ekre is.
- `scripts/product-ready-evidence-preflight.ps1`: uj statikus kontrollok orzik a
  `Test-LoopbackOrWildcardHost`, `IsLoopback` es `IsIPv4MappedToIPv6` bekotest.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 441/441
  (`security-reports/product-ready-evidence/20260609-221129-639-52228/summary.json`).
- Negativ staging acceptance verifier proba: egy egyebkent PASS-ra kitoltott acceptance evidence
  `source.baseUrl=http://[::ffff:127.0.0.1]` ertekkel `-RequirePass` modban FAIL lett a
  `source.baseUrl deployed-url` checken
  (`security-reports/product-ready-staging-acceptance/20260609-221211-916-18252/summary.json`).
- Negativ monitoring verifier proba: egy egyebkent PASS-ra kitoltott monitoring evidence
  `source.prometheusBaseUrl=http://[::1]` ertekkel `-RequirePass` modban FAIL lett a
  `source.prometheusBaseUrl deployed-url` checken
  (`security-reports/product-ready-monitoring-evidence/20260609-221212-310-64560/summary.json`).
- `npm run product-ready:staging-acceptance:preflight` PASS/REVIEW elvart sablonmodban:
  26 PASS / 0 FAIL / 60 REVIEW
  (`security-reports/product-ready-staging-acceptance/20260609-221225-829-35864/summary.json`).
- `npm run product-ready:monitoring-evidence:preflight` PASS/REVIEW elvart sablonmodban:
  9 PASS / 0 FAIL / 32 REVIEW
  (`security-reports/product-ready-monitoring-evidence/20260609-221225-830-46708/summary.json`).
- `npm run product-ready:local-gate` PASS, 24/24
  (`security-reports/product-ready-local-gate/20260609-221234-491-56340/summary.json`).
- `npm run product-ready:local-evidence-bundle` PASS, 95/95
  (`security-reports/product-ready-local-evidence-bundle/20260609-221626-205-62188/bundle.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  local gate es local evidence bundle PASS, csak az `external_evidence_gate` FAIL a valos kulso
  evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260609-221635-280-61072/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260609-222031-198-59408/summary.json`).

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a hamis deployed URL bizonyitek elleni verifier hardening javitva es negativ
teszttel bizonyitva van. Product Ready allapot tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260609-221635-280-61072/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Approval/staging/monitoring evidence-ref loopback hardening - 2026-06-09 22:33:**
A deployed URL mezok hardeningje utan tovabbi repo-oldali verifier rest talaltam: az approval
artifact, staging flow artifact es monitoring deployment hivatkozasok `not synthetic/local`
ellenorzese eddig szoveges tiltolistara epult. Ez elutasitotta a nyilvanvalo `localhost` es
`127.0.0.1` mintakat, de egy `https://127.1.2.3/...`, `https://[::1]/...` vagy
`https://0.0.0.0/...` jellegu hamis evidence hivatkozas atcsuszhatott volna.

Javitas:
- `scripts/product-ready-approvals-verify.ps1`: uj `Test-LoopbackOrWildcardHost` es
  `Test-TextContainsLoopbackOrWildcardUrl` kontroll szuri az approval `completedEvidenceRef` es
  owner `evidenceRef` hivatkozasokat.
- `scripts/product-ready-staging-acceptance-verify.ps1`: ugyanez a szoveges URL/IP szures bekerult
  a flow `evidenceRef` ellenorzesbe is.
- `scripts/product-ready-monitoring-evidence-verify.ps1`: ugyanez bekerult a monitoring
  `deploymentRef` ellenorzesbe.
- `scripts/product-ready-evidence-preflight.ps1`: statikus kontrollok orzik az evidence-ref
  loopback/wildcard szurok jelenletet.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 445/445
  (`security-reports/product-ready-evidence/20260609-222332-483-69040/summary.json`).
- Negativ approvals verifier proba: egy egyebkent APPROVED/PASS jellegu approvals evidence
  `approvals.operationsOwner.evidenceRef=https://127.1.2.3/approval.png` ertekkel `-RequirePass`
  modban FAIL lett az `approvals.operationsOwner.evidenceRef not synthetic/local` checken
  (`security-reports/product-ready-approvals/20260609-222417-923-57788/summary.json`).
- Negativ staging acceptance verifier proba: egy egyebkent PASS-ra kitoltott staging evidence
  `flows.transfer.evidenceRef=https://[::1]/transfer-proof.png` ertekkel `-RequirePass` modban FAIL
  lett a `flows.transfer.evidenceRef not synthetic/local` checken
  (`security-reports/product-ready-staging-acceptance/20260609-222418-313-58056/summary.json`).
- Negativ monitoring verifier proba: egy egyebkent PASS-ra kitoltott monitoring evidence
  `source.deploymentRef=... https://0.0.0.0/deploy` ertekkel `-RequirePass` modban FAIL lett a
  `source.deploymentRef not synthetic/local` checken
  (`security-reports/product-ready-monitoring-evidence/20260609-222418-691-68376/summary.json`).
- Normal preflight modok: approvals 12 PASS / 0 FAIL / 25 REVIEW
  (`security-reports/product-ready-approvals/20260609-222433-663-8824/summary.json`),
  staging 26 PASS / 0 FAIL / 60 REVIEW
  (`security-reports/product-ready-staging-acceptance/20260609-222433-713-61120/summary.json`),
  monitoring 9 PASS / 0 FAIL / 32 REVIEW
  (`security-reports/product-ready-monitoring-evidence/20260609-222433-663-25592/summary.json`).
- `npm run product-ready:local-gate` PASS, 24/24
  (`security-reports/product-ready-local-gate/20260609-222447-558-49524/summary.json`).
- `npm run product-ready:local-evidence-bundle` PASS, 95/95
  (`security-reports/product-ready-local-evidence-bundle/20260609-222855-070-14556/bundle.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  local gate es local evidence bundle PASS, csak az `external_evidence_gate` FAIL a valos kulso
  evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260609-222900-706-39128/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260609-223259-153-23036/summary.json`).

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: az evidence-ref hivatkozasok hamis local/loopback bizonyitek elleni szurese
javitva es negativ tesztekkel bizonyitva van. Product Ready allapot tovabbra sem allithato ki,
amig a friss `security-reports/product-ready-final-gate/20260609-222900-706-39128/missing-evidence.md`
es `missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Structured evidence contract version es Spring Framework CVE fix - 2026-06-10 02:34:**
Ujabb final-gate futas kozben ket Product Ready-t erinto repo-oldali hibat talaltam:

- A structured approvals / staging acceptance / monitoring summaryk check-nev es PASS statusz alapjan
  voltak validalva az external verifierben. Ez azt jelentette, hogy egy regi, gyengebb verifierrel
  keszult PASS summary azonos check-nevekkel atcsuszhatott volna. Javitas: a harom structured
  verifier most `verifierContractVersion=2026-06-09-evidence-ref-loopback-hardening` mezot ir, az
  `scripts/product-ready-external-evidence-verify.ps1` pedig ezt kotelezoen ellenorzi.
- A security gate uj NVD adatok alapjan `spring-core-7.0.7` CVE-ket jelzett
  (`CVE-2026-41842`, `CVE-2026-41850`, `CVE-2026-41851`). Javitas:
  `backend/pom.xml` `spring-framework.version=7.0.8` override-ot kapott. Ez azonos Spring
  Framework 7.0.x patch line, a Spring hivatalos 2026-06-08-i security release-e.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 451/451
  (`security-reports/product-ready-evidence/20260609-223540-711-62736/summary.json`).
- Negativ stale-summary external verifier proba: contract-version nelkuli, de minden regi required
  checket PASS-ra allito approvals / acceptance / monitoring summary `-RequireComplete` modban FAIL
  lett az `approvals report verifier contract version`, `acceptance report verifier contract version`
  es `monitoring report verifier contract version` checkeken
  (`security-reports/product-ready-external-evidence/20260609-223628-436-67368/summary.json`).
- Normal structured preflightok a contract version bevezetese utan:
  approvals 12 PASS / 0 FAIL / 25 REVIEW
  (`security-reports/product-ready-approvals/20260609-223638-531-49524/summary.json`),
  staging 26 PASS / 0 FAIL / 60 REVIEW
  (`security-reports/product-ready-staging-acceptance/20260609-223638-537-46436/summary.json`),
  monitoring 9 PASS / 0 FAIL / 32 REVIEW
  (`security-reports/product-ready-monitoring-evidence/20260609-223638-531-20332/summary.json`).
- Dependency tree bizonyitek: `spring-core`, `spring-web`, `spring-webmvc` 7.0.8-ra oldodott.
- `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1` PASS,
  backend dependency-check PASS
  (`security-reports/20260610-022735-797-50240`, `security-reports/latest`).
- `cd backend; .\mvnw.cmd test` PASS, 1996 teszt, 0 failure, 0 error.
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  local gate PASS, local evidence bundle PASS, missing-evidence manifest PASS, operator runbook PASS,
  evidence intake PASS, evidence-intake verifier PASS; csak az `external_evidence_gate` FAIL a valos
  kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-022923-916-34672/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-023340-488-19432/summary.json`).

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a structured evidence stale-summary res es a Spring Framework 7.0.7 CVE gate
hiba javitva, celzottan es teljes backend teszttel ellenorizve van. Product Ready allapot tovabbra
sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-022923-916-34672/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Final gate stale local bundle vedekezes - 2026-06-10 02:42:**
Az elozo Spring CVE miatti local gate bukas megmutatott egy tovabbi bizonyiteklanc-hibat:
`scripts/product-ready-final-gate.ps1` a `local_product_ready_gate` FAIL utan is lefuttatta a
`local_evidence_bundle` lepest. A final gate osszverdiktje ugyan FAIL maradt, de a bundle lepes
korabbi zold riportokbol PASS csomagot tudott generalni, ami felrevezeto stale local evidence
handoffot hagyhatott a reportban.

Javitas:
- A final gate most csak akkor futtatja a `local_evidence_bundle` lepest, ha az aktualis
  `local_product_ready_gate` PASS.
- Ha az aktualis local gate bukik, a bundle lepes explicit SKIP/FAIL eredmenyt kap:
  `current local_product_ready_gate failed; refusing to build a bundle from stale previous reports`.
- A final gate summary csak akkor linkel `latestReports.localEvidenceBundle` erteket, ha a jelenlegi
  bundle lepes PASS, es csak akkor linkel external evidence reportot, ha az external evidence lepes
  tenylegesen futott.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollokkal orzi ezt a fail-closed
  fuggoseget.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 454/454
  (`security-reports/product-ready-evidence/20260610-023653-778-32772/summary.json`).
- Negativ final-gate skip proba temp script-masolattal: kenyszeritett local gate FAIL utan
  `local_evidence_bundle` SKIP lett, `latestReports.localEvidenceBundle` es
  `latestReports.externalEvidence` ures maradt
  (`C:\Temp\vv-final-gate-skip-20260610023710674\final-gate-output\20260610-023711-387-51832\summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  local gate PASS, local evidence bundle PASS, missing-evidence manifest PASS, operator runbook PASS,
  evidence intake PASS, evidence-intake verifier PASS; csak az `external_evidence_gate` FAIL a valos
  kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-023721-156-51076/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-024200-718-52900/summary.json`).

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a final gate stale local evidence bundle kockazata javitva es negativ probaval
bizonyitva van. Product Ready allapot tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-023721-156-51076/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Structured summary replay hardening - 2026-06-10 02:50:**
Ujabb external verifier self-review kozben egy tovabbi bizonyiteklanc-res derult ki: az approvals,
staging acceptance es monitoring structured summaryk contract versiont es PASS checkeket tartalmaztak,
de az external verifier nem futtatta ujra a jelenlegi repo-verifiert a summary `evidencePath`
mezoben hivatkozott eredeti evidence JSON-ra. Emiatt egy kezzel fabrikalt PASS summary megkerulhette
volna a valodi evidence ujraellenorzeset.

Javitas:
- `scripts/product-ready-external-evidence-verify.ps1`: uj `Add-StructuredReportReverification`
  kontroll `-RequireComplete` modban ujrafuttatja a megfelelo structured verifiert:
  - approvals: `scripts/product-ready-approvals-verify.ps1 -RequirePass`;
  - acceptance: `scripts/product-ready-staging-acceptance-verify.ps1 -RequirePass`;
  - monitoring: `scripts/product-ready-monitoring-evidence-verify.ps1 -RequirePass`.
- A replay az adott summary `evidencePath` mezojere fut, es csak akkor PASS, ha a jelenlegi verifier
  a valodi evidence JSON-t is PASS-ra hozza.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollokkal orzi az approvals,
  acceptance es monitoring replay hivasokat.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 457/457
  (`security-reports/product-ready-evidence/20260610-024518-741-66280/summary.json`).
- Negativ spoof-summary proba: contract-versionnel ellatott, minden approvals checket PASS-ra
  hamisito summary `evidencePath=docs/PRODUCT_READY_APPROVALS_TEMPLATE_2026-06-09.json` mellett
  `-RequireComplete` modban FAIL lett az `approvals report replay with current verifier` checken
  (`security-reports/product-ready-external-evidence/20260610-024547-627-64196/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  local gate PASS, local evidence bundle PASS, missing-evidence manifest PASS, operator runbook PASS,
  evidence intake PASS, evidence-intake verifier PASS; csak az `external_evidence_gate` FAIL a valos
  kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-024556-087-42816/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-025001-322-55312/summary.json`).

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a structured summary spoofing elleni replay vedekezes javitva es negativ
teszttel bizonyitva van. Product Ready allapot tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-024556-087-42816/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Compliance decision es signed installer replay hardening - 2026-06-10 03:04:**
Az approvals/acceptance/monitoring replay javitas utan ujabb external verifier self-review
kovetkezett. Ket tovabbi structured summary-ag biztonsagosan ujrajatszhato, de eddig csak a
summary mezoi es PASS check nevei alapjan volt elfogadva:
- compliance approved decision summary;
- signed installer artifact summary.

Javitas:
- `scripts/product-ready-external-evidence-verify.ps1`: uj `Add-StructuredCommandReplay`
  helper `-RequireComplete` modban ujrafuttatja a nem-mutativen ujraellenorizheto verifier
  parancsokat.
- Compliance decision: a summary `decisionPath` mezojeben hivatkozott dontesi JSON-t a jelenlegi
  `scripts/compliance-golive-decision-verify.ps1 -RequireApprovedDecision` ellenorzi ujra.
- Signed installer artifact: a jelenlegi
  `scripts/installer-smoke-preflight.ps1 -CheckArtifacts -RequireSignature` fut ujra, igy egy
  kezzel hamisitott signed-artifact summary nem eleg Product Ready complete bizonyiteknak.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollokkal orzi mindket replay
  hivas jelenletet.
- DR restore es clean Windows VM installer smoke replay nincs vakon bekotve, mert ezek
  adatbazis-restore/install/uninstall mutaciot indithatnanak; ezeknel tovabbra is valos, kulso
  operatori evidence es riport kell.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 459/459
  (`security-reports/product-ready-evidence/20260610-025431-098-55308/summary.json`).
- Negativ forged-summary proba: hamisitott compliance decision summary es hamisitott signed
  installer artifact summary mellett `-RequireComplete` modban FAIL lett a
  `compliance decision replay with current verifier` es az
  `installer signed artifact replay with current verifier` check
  (`security-reports/product-ready-external-evidence/20260610-025508-016-59312/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-030017-831-56660/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  local gate PASS, local evidence bundle PASS, operator runbook PASS, evidence intake PASS,
  evidence-intake verifier PASS; csak az `external_evidence_gate` FAIL a valos kulso evidence
  hianya miatt
  (`security-reports/product-ready-final-gate/20260610-030024-059-21872/summary.json`).
- `git diff --check -- scripts/product-ready-external-evidence-verify.ps1
  scripts/product-ready-evidence-preflight.ps1 docs/PRODUCT_READY_AUDIT_2026-06-09.md` PASS.

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a compliance decision es signed installer artifact summary spoofing elleni
replay vedekezes javitva es negativ teszttel bizonyitva van. Product Ready allapot tovabbra sem
allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-030024-059-21872/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Compliance export raw TSV cross-check - 2026-06-10 03:12:**
A compliance export structured summary tovabbi self-review-ja egy uj, nem-mutativ bizonyitaserositesi
pontot adott: a query-mode summary `flags` mezoi eddig elfogadhatoak voltak akkor is, ha a mellette
keletkezo nyers DB export (`system_parameter.tsv`) nem volt jelen vagy nem tartalmazta a kotelezo
flag sorokat. Ez summary-spoofing es stale artifact kockazatot hagyott a compliance evidence agban.

Javitas:
- `scripts/product-ready-external-evidence-verify.ps1`: a
  `Add-StructuredComplianceExportReportChecks` most megkoveteli, hogy a compliance export
  `summary.json` mellett letezzen `system_parameter.tsv`.
- Minden kotelezo go-live flagre kulon `compliance export raw query row:<FLAG>` check fut, amely
  a raw TSV-bol varja a tab-szeparalt flag sort.
- `scripts/product-ready-evidence-preflight.ps1` ket uj statikus kontrollal orzi a raw query output
  es flag-row cross-check jelenletet.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 461/461
  (`security-reports/product-ready-evidence/20260610-030605-402-60264/summary.json`).
- Negativ forged export proba: query-mode-nak hamisitott compliance export summary `system_parameter.tsv`
  nelkul `-RequireComplete` modban FAIL lett a `compliance export raw query output exists` es az osszes
  `compliance export raw query row:<FLAG>` checken
  (`security-reports/product-ready-external-evidence/20260610-030631-116-65684/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  local gate PASS, local evidence bundle PASS, missing-evidence manifest PASS, operator runbook PASS,
  evidence intake PASS, evidence-intake verifier PASS; csak az `external_evidence_gate` FAIL a valos
  kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-030644-774-27032/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-031114-289-53972/summary.json`).

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a compliance export raw query cross-check javitva es negativ teszttel bizonyitva
van. Product Ready allapot tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-030644-774-27032/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Current local gate summary bundle binding - 2026-06-10 03:22:**
A final gate es local evidence bundle kapcsolataban ujabb stale-evidence kockazat derult ki:
a final gate lefuttatta a `local_product_ready_gate` lepest, de a bundle script onalloan a
legfrissebbnek latszo local gate riportot valasztotta. Egy regi vagy kezzel elore datumozott
riport igy elmeletben bekerulhetett volna a local evidence bundle-be akkor is, ha nem a mostani
final-gate futas local gate eredmenye volt.

Javitas:
- `scripts/product-ready-local-evidence-bundle.ps1`: uj `-RequiredLocalGateSummaryPath`
  parameter. Ha meg van adva, a `product_ready_local_gate` artifact csak akkor PASS, ha a bundle
  pontosan ezt a summary-t tartalmazza.
- `scripts/product-ready-final-gate.ps1`: a local gate lepes logjabol kinyeri a friss
  `[product-ready-local-gate] summary:` utvonalat, es a bundle-t ezzel inditja:
  `scripts\product-ready-local-evidence-bundle.ps1 -RequiredLocalGateSummaryPath <current-summary>`.
- Ha a current local gate summary utvonal nem oldhato fel, a final gate nem epit bundle-t, hanem
  fail-closed SKIP/FAIL eredmenyt ad: `current local_product_ready_gate summary path could not be
  resolved; refusing to build a bundle from ambiguous latest reports`.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollokkal orzi a current-summary
  bindinget.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 465/465
  (`security-reports/product-ready-evidence/20260610-031534-502-55764/summary.json`).
- Negativ bundle proba rossz `-RequiredLocalGateSummaryPath` ertekkel FAIL lett a
  `product_ready_local_gate current summary path` checken
  (`security-reports/product-ready-local-evidence-bundle/20260610-031541-300-56596/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  a `local_evidence_bundle` lepes mar az aktualis
  `security-reports/product-ready-local-gate/20260610-031558-424-58204/summary.json` utvonallal
  futott es PASS lett; csak az `external_evidence_gate` FAIL a valos kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-031557-493-59204/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-032012-870-63048/summary.json`).
- `git diff --check -- scripts/product-ready-final-gate.ps1
  scripts/product-ready-local-evidence-bundle.ps1 scripts/product-ready-evidence-preflight.ps1
  docs/PRODUCT_READY_AUDIT_2026-06-09.md` PASS.

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a local evidence bundle most mar a current final-gate local gate summary-hoz van
kotve, es negativ probaval bizonyitottan elutasitja a rossz/stale summary utvonalat. Product Ready
allapot tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-031557-493-59204/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Local bundle artifact summary content hardening - 2026-06-10 03:28:**
A local evidence bundle external verifier oldali ellenorzeseben ujabb summary-spoofing kockazat
derult ki. Az external verifier ellenorizte a bundle artifact report/summary fajlok letezeset es
SHA-256 hash-et, de a bundled summary fajlok tenyleges `failed` erteket nem olvasta vissza kulon.
Egy kezzel hamisitott bundle igy elmeletben `failed=0` bundle metadata mellett olyan artifact
summary-ra mutathatott volna, amelynek a hash-e stimmel, de a sajat tartalma szerint bukott.

Javitas:
- `scripts/product-ready-external-evidence-verify.ps1`: az `Add-LocalEvidenceBundleChecks` most
  minden bundlolt `summary` artifactet JSON-kent ujraolvas.
- Minden required local evidence artifactre uj check fut:
  - `local evidence bundle <area> summary content json parse`;
  - `local evidence bundle <area> summary failed`;
  - `local evidence bundle <area> summary failed metadata`.
- A summary csak akkor elfogadhato, ha a tenyleges summary `failed` erteke 0, es egyezik a bundle
  artifact metadata `failed` ertekevel.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollokkal orzi a summary content parse
  es failed-metadata cross-check jelenletet.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 467/467
  (`security-reports/product-ready-evidence/20260610-032258-770-64372/summary.json`).
- Negativ spoof bundle proba: a bundle hash-e es metadata-ja egy hamisitott
  `product_ready_evidence_preflight` artifact summary-ra mutatott, amelynek a tenyleges `failed`
  erteke 1 volt. `-RequireComplete` modban FAIL lett a
  `local evidence bundle product_ready_evidence_preflight summary failed` es
  `summary failed metadata` checkeken
  (`security-reports/product-ready-external-evidence/20260610-032344-595-54588/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  local gate PASS, local evidence bundle PASS, missing-evidence manifest PASS, operator runbook PASS,
  evidence intake PASS, evidence-intake verifier PASS; csak az `external_evidence_gate` FAIL a valos
  kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-032358-582-54952/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-032808-284-63796/summary.json`).
- `git diff --check -- scripts/product-ready-external-evidence-verify.ps1
  scripts/product-ready-evidence-preflight.ps1 docs/PRODUCT_READY_AUDIT_2026-06-09.md` PASS.

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a local evidence bundle artifact summary tartalmi ellenorzese javitva es negativ
teszttel bizonyitva van. Product Ready allapot tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-032358-582-54952/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Final decision self-reference hardening - 2026-06-10 03:35:**
A finalDecision ag self-review-ja kozben ujabb bizonyiteklanc-res derult ki: a verifier ellenorizte,
hogy a `finalDecision.externalEvidenceRef` letezik es egy completed external evidence JSON-ra mutat,
de nem kovetelte meg kulon, hogy ez pontosan az eppen verifikalt evidence artifact legyen. Igy egy
hibasan vagy szandekosan masik evidence JSON-ra mutato final decision is tovabbjuthatott volna a
self-reference ellenorzes nelkul.

Javitas:
- `scripts/product-ready-external-evidence-verify.ps1`: uj
  `finalDecision external evidence ref matches current evidence` check.
- A check a `finalDecision.externalEvidenceRef` feloldott abszolut utvonalat hasonlitja az aktualis
  `-EvidencePath` feloldott abszolut utvonalhoz.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollal orzi ezt a finalDecision
  self-reference szerzodest.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 468/468
  (`security-reports/product-ready-evidence/20260610-033017-714-58260/summary.json`).
- Negativ finalDecision self-reference proba: a final decision szandekosan egy masik external
  evidence JSON-ra mutatott. `-RequireComplete` modban FAIL lett a
  `finalDecision external evidence ref matches current evidence` check
  (`security-reports/product-ready-external-evidence/20260610-033041-113-66524/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  a final gate altal eloallitott scoped evidence-ben a
  `finalDecision external evidence ref matches current evidence` check PASS lett; csak az
  `external_evidence_gate` FAIL a valos kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-033056-717-26924/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-033505-515-53972/summary.json`).
- `git diff --check -- scripts/product-ready-external-evidence-verify.ps1
  scripts/product-ready-evidence-preflight.ps1 docs/PRODUCT_READY_AUDIT_2026-06-09.md` PASS.

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a finalDecision most mar csak akkor fogadhato el, ha az aktualisan ellenorzott
external evidence JSON-ra hivatkozik vissza. Product Ready allapot tovabbra sem allithato ki,
amig a friss
`security-reports/product-ready-final-gate/20260610-033056-717-26924/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Security gate stepLog bundle verification - 2026-06-10 03:42:**
A local evidence bundle es external verifier osszeveteseben ujabb mismatch derult ki: a bundle
keszito script mar kotelezonek vette es hash-elte a `security_gate` local gate step logot, de az
external evidence verifier oldali `Add-LocalEvidenceBundleChecks` required stepLog listajabol ez a
lepes hianyzott. Igy egy kezzel hamisitott bundle elhagyhatta volna a security gate log hash
bizonyitekat ugy, hogy a tobbi local gate stepLog meg atment.

Javitas:
- `scripts/product-ready-external-evidence-verify.ps1`: a
  `product_ready_local_gate` stepLog required listaja most tartalmazza a `security_gate` lepest.
- Az external verifier ezentul ellenorzi:
  - `local evidence bundle product_ready_local_gate stepLog:security_gate`;
  - `stepLog:security_gate exitCode`;
  - `stepLog:security_gate exists`;
  - `stepLog:security_gate sha256`.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollal orzi, hogy az external verifier
  source-ban is jelen legyen a `security_gate` required step.

Ellenorzes:
- Elso preflight futas szandekosan FAIL lett egy tul konkret statikus minta miatt, majd a minta
  javitasa utan `npm run product-ready:evidence:preflight` PASS, 469/469
  (`security-reports/product-ready-evidence/20260610-033713-475-14804/summary.json`).
- Negativ spoof bundle proba: valid bundle-bol eltavolitott `security_gate` stepLog mellett
  `-RequireComplete` modban FAIL lett a
  `local evidence bundle product_ready_local_gate stepLog:security_gate` check
  (`security-reports/product-ready-external-evidence/20260610-033737-766-60024/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  normal final-gate bundle-ben a `security_gate` stepLog, exitCode, log exists es sha256 checkek
  PASS lettek; csak az `external_evidence_gate` FAIL a valos kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-033751-045-10672/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-034200-222-57176/summary.json`).
- `git diff --check -- scripts/product-ready-external-evidence-verify.ps1
  scripts/product-ready-evidence-preflight.ps1 docs/PRODUCT_READY_AUDIT_2026-06-09.md` PASS.

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a security gate local step log bizonyiteka mar az external evidence verifier
oldalan is kotelezo, hash-ellenorzott bundle artifact. Product Ready allapot tovabbra sem allithato
ki, amig a friss
`security-reports/product-ready-final-gate/20260610-033751-045-10672/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**Full default local gate stepLog bundle coverage - 2026-06-10 03:50:**
A `security_gate` stepLog mismatch javitasa utan teljes step-list drift audit kovetkezett. Kiderult,
hogy a local gate default profilja 24 lepest futtat, de a local evidence bundle es az external
verifier korabban csak egy kisebb reszhalmaz step logjait tette kotelezove. Ez gyengitette a local
evidence handoffot, mert tobb fontos default gate lepes log hash bizonyiteka opcionálisan hianyozhatott
volna a bundle-bol.

Javitas:
- `scripts/product-ready-local-evidence-bundle.ps1`: a `product_ready_local_gate` artifact most a
  teljes default local gate step listat kotelezoen gyujti, beleertve:
  staging/approval/compliance/audit/security/installer/DR/monitoring/evidence preflight lepeseket.
- Az installer ag dinamikus: ha a local gate `installer_smoke_artifacts` lepest futtatta, azt keri;
  kulonben `installer_smoke_synthetic` lepest ker.
- `scripts/product-ready-external-evidence-verify.ps1`: az external verifier ugyanezt a teljes
  required stepLog listat koveteli meg, es minden stepLogra exitCode/log exists/SHA-256 ellenorzest fut.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollokkal orzi, hogy a bovitett stepLog
  szerzodes mind a bundle keszito, mind az external verifier oldalon jelen legyen.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 475/475
  (`security-reports/product-ready-evidence/20260610-034408-923-19144/summary.json`).
- Celozott bundle futas a friss local gate summary-val PASS, 144/144; a bundle
  `product_ready_local_gate.stepLogs` listaja 24 elemet tartalmazott
  (`security-reports/product-ready-local-evidence-bundle/20260610-034418-903-21644/bundle.json`).
- Negativ spoof bundle proba: a `monitoring_synthetic` stepLog eltavolitasa utan `-RequireComplete`
  modban FAIL lett a `local evidence bundle product_ready_local_gate stepLog:monitoring_synthetic`
  check
  (`security-reports/product-ready-external-evidence/20260610-034450-686-14276/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  az external verifierben mind a 24 default local gate stepLog requirement PASS lett; csak az
  `external_evidence_gate` FAIL a valos kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-034505-016-50432/summary.json`).
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-034913-933-56128/summary.json`).
- `git diff --check -- scripts/product-ready-local-evidence-bundle.ps1
  scripts/product-ready-external-evidence-verify.ps1 scripts/product-ready-evidence-preflight.ps1
  docs/PRODUCT_READY_AUDIT_2026-06-09.md` PASS.

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a local evidence bundle most mar a teljes default local gate futas log-hash
bizonyitekat hordozza, es az external verifier ezt teljes listaval ellenorzi. Product Ready allapot
tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-034505-016-50432/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.

**External verifier summary current-log binding - 2026-06-10 03:58:**
A final gate summary-link audit ujabb stale-summary kockazatot talalt. A final gate az
`external_evidence_gate` futtatasa utan korabban a `security-reports/product-ready-external-evidence`
konyvtarban kereste a legfrissebb, ugyanarra az evidence path-ra mutato summary-t. Ez egy elore
letrehozott vagy kezzel datumozott summary-val felrevezeto missing-evidence handoffot okozhatott,
meg akkor is, ha maga az external verifier lepes exit code alapjan FAIL maradt.

Javitas:
- `scripts/product-ready-final-gate.ps1`: uj `Get-ExternalEvidenceSummaryFromStepLog` helper.
- A final gate most az `external_evidence_gate.log` `[product-ready-external-evidence] summary:`
  sorabol veszi a current external verifier summary utvonalat.
- A helper validalja, hogy a summary letezik, mellette van `report.md`, es a summary `evidencePath`
  pontosan a final-gate-scoped evidence JSON-ra mutat.
- Ha az external evidence step futott, de a sajat logjabol nem oldhato fel a summary, a final gate
  explicit `external_evidence_summary_link` FAIL lepesben zar.
- `scripts/product-ready-evidence-preflight.ps1` statikus kontrollokkal orzi a current-log bindinget.

Ellenorzes:
- `npm run product-ready:evidence:preflight` PASS, 477/477
  (`security-reports/product-ready-evidence/20260610-035150-247-48176/summary.json`).
- `npm run product-ready:final-gate:complete` elvart modon FAIL, 6 PASS / 1 FAIL:
  a final gate summary `externalEvidenceGateSummary.summary` erteke pontosan megegyezett az
  `external_evidence_gate.log` summary soraval, es `source=external_evidence_gate.log` lett;
  csak az `external_evidence_gate` FAIL a valos kulso evidence hianya miatt
  (`security-reports/product-ready-final-gate/20260610-035157-710-23148/summary.json`).
- Negativ stale-summary proba: egy mesterségesen legujabbnak latszo
  `99991231-235959-999-stale-spoof` external summary ugyanarra a final-gate evidence path-ra mutatott.
  A regi latest-scan logika ezt valasztotta volna, de a javitott final gate tovabbra is a log-bound
  current summary-t linkelte. A hamis latest konyvtar a proba utan el lett tavolitva, a bizonyitek:
  `security-reports/product-ready-negative-stale-summary/20260610-035157-710-23148/proof.json`.
- `npm run product-ready:missing-evidence:verify` PASS, 346/346
  (`security-reports/product-ready-missing-evidence/20260610-035608-964-47192/summary.json`).
- `git diff --check -- scripts/product-ready-final-gate.ps1
  scripts/product-ready-evidence-preflight.ps1 docs/PRODUCT_READY_AUDIT_2026-06-09.md` PASS.

Friss final-gate hianylista:
- acceptance: 5
- approvals: 4
- compliance: 6
- drRestore: 10
- finalDecision: 7
- installer: 13
- monitoring: 6
- topLevel: 3

Aktualis verdikt: a final gate external verifier summary linkje most mar a current step loghoz van
kotve, nem a legfrissebbnek latszo external-evidence report konyvtarhoz. Product Ready allapot
tovabbra sem allithato ki, amig a friss
`security-reports/product-ready-final-gate/20260610-035157-710-23148/missing-evidence.md` es
`missing-evidence.json` 54 valos kulso bizonyitekpontja nincs lezarva es a
`product-ready:final-gate:complete` nem fut zoldre.
