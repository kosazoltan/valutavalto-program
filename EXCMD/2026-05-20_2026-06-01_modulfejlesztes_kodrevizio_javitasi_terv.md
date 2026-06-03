# 2026.05.20-2026.06.01 modulfejlesztes kodrevizio es javitasi terv

Keszult: 2026-06-01. Cel: a 2026.05.20 es 2026.06.01 kozotti modulfejlesztesek tenyalapu ujraellenorzese, kulonosen az arfolyamkeszito/FK02-FK04, FK013-FK014, shipment, backend API, frontend TS/TSX, adatbazis schema/index es memoria/ledger allitasok alapjan.

Fontos korlat: ez dokumentacios audit es javitasi utasitas. Uzleti kod nem lett modositva.

## Forrasok es ellenorzesi alap

- Git idoszak: `git log --since="2026-05-20 00:00" --until="2026-06-01 23:59"`.
- Meret: 303 commit az idoszakban.
- Napi commit eloszlas: 2026-05-20: 55, 05-21: 20, 05-22: 32, 05-23: 18, 05-24: 23, 05-25: 15, 05-26: 21, 05-27: 15, 05-28: 18, 05-29: 34, 05-31: 20, 06-01: 32.
- Leginkabb erintett kodteruletek: `backend/src/main` 239 fajl, `frontend-react/src/pages` 104 fajl, `backend/src/test` 98 fajl, `frontend-react/src/services` 17 fajl, `frontend-react/src/utils` 13 fajl.
- Ledger/memoria: `vault/sessions/2026-05-28-full-day-development-ledger.md`, `vault/sessions/2026-05-28-fk04-ce-formula-protection-pr-series.md`, `vault/sessions/2026-05-29-fk-batch-merge-deploy-installer.md`, `vault/references/audit-2026-05-31-confirmed-findings.md`, `vault/feedback/audit-2026-05-29-triage-and-defers.md`.
- Celzott LSP diagnosztika: `RateCreationPage.tsx`, `RateGrid.tsx`, `workgroupSheetStorage.ts`, `exchange-rates.ts`, `arfolyam-keszito-client/electron/local-first.ts`, `main.ts`, `preload.ts`, `RateCreationService.java`, `LocalRateMakerController.java`, `BranchRepository.java`, `RateCreationServiceTest.java`.
- Celzott tesztek: frontend rate tesztek es backend `RateCreationServiceTest`.

## Ellenorzott teszteredmenyek

- `frontend-react`: `npm test -- --run src/pages/rates/deviationCheck.test.ts src/pages/rates/fillHelpers.test.ts src/pages/rates/workgroupSheetStorage.test.ts src/pages/rates/rfmRules.test.ts` -> 4 fajl, 38 teszt, mind zold.
- `backend`: `./mvnw.cmd -Dtest=RateCreationServiceTest test` -> 7 teszt, mind zold.
- Backend Maven figyelmeztetesek voltak de a celzott teszt build zold: JDK native access/deprecated warningok, test-kod deprecation es egy unreachable catch warning mas tesztfajlban.

## Tenyalapu allapotkep

### FK02-C: irodak listaja csak penztar

Allapot: tenylegesen implementalt.

Kodtenyek:

- `backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java` tartalmazza a `findRateCreationAssignableCashierBranches(companyId)` JPQL metodust: `branchType.code = 'PENZTAR'`, `is_active = true`, `is_vault IS NULL OR false`, company scope.
- `backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java` `getAllBranchesForWorkgroup()` mar ezt a repository metodust hasznalja, nem a teljes aktiv branch listat.
- `RateCreationService.updateWorkgroupBranches()` POST oldalon is validal: company, active, `PENZTAR`, nem `isVault=true`.
- `backend/src/test/java/hu/puzzleir/valuta/service/RateCreationServiceTest.java` tartalmaz regressziot a penztar-only listara, `VAULT_COUNTERPARTY`, `ERTEKTAR`, `isVault=true` elutasitasra es aktiv penztar elfogadasra.

Kovetkeztetes: az FK02-C javitas jelen allapotban nem csak dokumentalva, hanem backend szinten is bent van.

### FK02-B / FK04-C-E: csoport arfolyamlap

Allapot: reszben implementalt, de nem teljesen kesz.

Kodtenyek:

- `frontend-react/src/pages/rates/deviationCheck.ts` letezik, 10%-os kulonbseget szamol, tesztelve.
- `frontend-react/src/pages/rates/fillHelpers.ts` es `RateGrid.tsx` alapjan az Excel-szeru kijeloles/kitoltes helper oldala tesztelt.
- `frontend-react/src/pages/rates/workgroupSheetStorage.ts` tovabbra is `localStorage`-ra epul a csoport fix ertekekhez es kepletekhez.
- `arfolyam-keszito-client/electron/local-first.ts` inicializal egy `rate-maker.db` sql.js adatbazist, de a komment es a kod szerint a sync engine nincs inditva, es a renderer nem hasznal `lf:*` draft IPC-t.
- `packages/local-first-core/src/schema.ts` schema nem tartalmaz `group_rates` tablat; csak `lf_config`, `lf_outbox`, `lf_tombstone`, `lf_sync_state`, `lf_conflict_log`, `lf_cached_entities` es inventory helper tabla lathato.
- `frontend-react/src/services/api/exchange-rates.ts` rate-maker flavor eseten `publishGroupRate()` REST csomagot kuld `/local-rate-maker/packages/publish` utvonalra, nem SQLite draftbol olvas.

Kovetkeztetes: a csoportlap funkcionalitas logikai magja es REST publikacioja reszben mukodik, de az a korabbi kovetelmeny, hogy az onBlur/fix ertekek SQLite `group_rates` szeru helyi perzisztenciaba menjenek, a kod jelenlegi tenyei alapjan nincs kesz. A jelenlegi perzisztencia `localStorage`.

### Local rate-maker REST API

Allapot: reszben implementalt.

Kodtenyek:

- `backend/src/main/java/hu/puzzleir/valuta/controller/LocalRateMakerController.java` letezik: `GET /api/v1/local-rate-maker/bootstrap`, `POST /api/v1/local-rate-maker/packages/publish`.
- Controller RBAC: `FOERTEKTAR`, `UGYVEZETO`, `ADMIN`.
- Publish endpoint hasznal `IdempotencyGuard`-ot es `Idempotency-Key` / `X-Idempotency-Key` headert.
- `backend/src/main/resources/db/migration/V205__rate_publication_local_rate_maker_audit.sql` hozzaadja a `rate_publication` audit mezoket es a `(company_id, client_package_id)` partial unique indexet.
- `RateCreationService.publishLocalRatePackage()` explicit `groupId`-t ker, duplikalt packageId-t ellenoriz, server hash-t szamol es `publishGroupRateInternal()`-t hiv.

Kockazat:

- `publishLocalRatePackage()` a publikacio utan kulon `rateWorkgroupRepository.findById(packageDto.getGroupId())` hivassal olvassa vissza a workgroupot a branch kodokhoz. Ez a visszaolvasas onmagaban nem tartalmaz explicit tenant checket, de a korabbi `publishGroupRateInternal()` es a `RatePublishService.publish()` jelenlegi audit szerint mar reszben vedheti. A biztonsagosabb minta: minden `findById(groupId)` utan explicit `workgroup.company.id == currentCompanyId` check, vagy repository-level `findByIdAndCompanyId`.
- A hash strict ellenorzes alapertelmezetten kikapcsolt (`RATE_PACKAGE_HASH_STRICT=false`), mert a JS-Java canonical paritas nincs e2e bizonyitva. Ez nem kodhiba onmagaban, de integritasi garancia jelenleg audit-only.

### Frontend LSP / i18n / literal string allapot

Allapot: nem tiszta.

Kodtenyek a celzott LSP diagnosztikabol:

- `frontend-react/src/pages/rates/RateCreationPage.tsx` tobb helyen `disallow literal string` hibas.
- Erintett reszek: csempes nezet gombok, `FOLAP`, `Aktualis fuggveny`, `Kitoltesi segitseg`, ures allapot szovegek, `VEDELEM`, `Szerk.`, `Torles`, `iroda` feliratok.
- `RateGrid.tsx`, `workgroupSheetStorage.ts`, `exchange-rates.ts` celzott LSP szerint hibatlan.
- Electron local-first fajlok celzott LSP szerint hibatlanok.
- Backend FK02-C fajlok celzott LSP szerint hibatlanok.

Kovetkeztetes: a modulfejlesztes frontend oldala nem felel meg teljesen a repo i18n/literal-string szabalyainak. Ez a type/lint gate-ben bukhat, akkor is, ha a logikai unit tesztek zoldek.

### Adatbazis schema/index

Allapot: vannak jo indexek/constraint-ek, de nem minden lokalis perzisztencia kovetelmeny fedett.

Kodtenyek:

- `V205__rate_publication_local_rate_maker_audit.sql`: rate publication local-rate-maker audit mezok + unique package index kesz.
- `V242__branch_workgroup_exclusivity_unique_constraint.sql`: `rate_workgroup_branch.branch_id` unique constraint kesz, tehat egy branch csak egy workgroupban lehet.
- `V277__vault_counterparty_branches.sql` a ledger szerint 10 fix `VAULT_COUNTERPARTY` partnert seedel.
- `V281__shipment_request_reject_fields.sql`, `V282__vault_workers_branch_assignment.sql` az idoszak vegen ujabb moduladatokat ad.
- SQLite oldalon nincs explicit `group_rates` schema a local-first core-ban; az arfolyamkeszito csoportlap fix ertekei nem adatbazis tablan perzisztalnak.

Kockazat:

- A `localStorage`-alapu csoportlap allapot bongeszo/kliens cache jellegu. Nem ad ugyanazt az audit, backup, migration es recovery garanciat, mint egy verziozott SQLite tabla.

### Ledger allitasok kontra kod

Ellenorzott allitasok:

- 2026-05-28 ledger szerint FK-03 formula motor eloszor nem volt bekotve; a kesobbi 2026-05-29 ledger szerint #906 UI bekotes megtortent. A jelenlegi kodban a `RateCreationPage.tsx` importalja es hasznalja a storage/compute/protection modulokat, tehat a bekotes legalabb reszben igazolt.
- 2026-05-28 ledger szerint FK-04/E backend protection elveszett volt, majd #899 helyreallitotta. A jelenlegi `RateCreationService.publishGroupRateInternal()` hivja a `RateSpreadGate.enforce(...)`-ot; a 2026-05-31 audit viszont kulon jelzi, hogy mas publish utvonal (`RateManagementController.publishBatch`) megkerulhet spread kaput.
- 2026-05-31 audit maradek findingjei tovabbra is relevansak, ha az erintett kodreszek nem valtoztak: RateTemplate LazyInit, Inventory receivedAmount mismatch, AML highRiskFlag dead write, tautologikus teszt, TTL, publishBatch RateSpreadGate megkerules, outbox effektivrata null/divergencia, lokalis package tenant check szigoritas.

## Findingek

### P1-01: RateCreationPage LSP/i18n hibak miatt a frontend modul nem tiszta

Bizonyitek: celzott `get_errors` szerint `frontend-react/src/pages/rates/RateCreationPage.tsx` tobb literal string diagnosztikat ad a csempes/toolbar/vedelem UI reszeken.

Hatasa: lint/typecheck vagy CI gate bukhat, es a repo i18n konvencio serul. Ez nem csak stilus: a felulet magyar szovegei hard-code-oltak a TSX-ben, igy a forditasi rendszer es a `i18next/no-literal-string` szabaly megkerulodik.

Javitas:

1. Minden jelzett literal stringet vigyel `frontend-react/src/i18n/hu.json` megfelelo `rates.*` kulcsai ala.
2. `RateCreationPage.tsx` komponenseiben hasznalj `const { t } = useTranslation()` mintat.
3. Dinamikus szovegeknel hasznalj interpolaciot: `t('rates.workgroup.branchCount', { count })`.
4. Ne `eslint-disable`-lal kezeld, mert a diagnosztika valos.
5. Futtasd: `npm run typecheck`, `npm test -- --run src/pages/rates/...` es ha van lint script, `npm run lint`.

### P1-02: FK02-B lokalis perzisztencia nem SQLite-alapu, hanem localStorage

Bizonyitek: `workgroupSheetStorage.ts` minden csoportlap fix erteket es kepletet `localStorage`-ba ment; `local-first.ts` csak generikus lf cache/outbox IPC-t ad; renderer oldalon nincs `lf:save-rate-draft` hasznalat; `packages/local-first-core/src/schema.ts` nem tartalmaz `group_rates` tablat.

Hatasa: a csoport arfolyamlap offline/ujrainditas/backup/audit szempontbol gyengebb, mint a kovetelmeny szerinti SQLite perzisztencia. Bongeszoadat torles, quota, profilvaltas vagy Electron cache migracio adatvesztest okozhat.

Javitas:

1. Hozz letre arfolyamkeszito-specifikus SQLite migraciot a local-first DB-ben, peldaul `group_rates` es `group_rate_formulas` tablakra.
2. Minima schema: `company_id`, `workgroup_id`, `currency_id`, `field`, `raw_value`, `formula`, `updated_at`, `version`, unique `(workgroup_id, currency_id, field)`.
3. `arfolyam-keszito-client/electron/local-first.ts` kapjon dedikalt IPC-ket: `rate-maker:load-group-sheet`, `rate-maker:save-group-cell`, `rate-maker:save-group-formula`, `rate-maker:clear-group-overrides`.
4. `workgroupSheetStorage.ts` legyen adapteres: Electronben IPC/SQLite, web fallbackkent localStorage csak explicit fallback.
5. `RateCreationPage.tsx` onBlur commit utan az adaptert hivja, ne csak localStorage helperrel irjon.
6. Tesztek: storage adapter unit, Electron IPC test, ujrainditas utani reload e2e.

### P1-03: Local rate-maker package integritas strict mod nincs bizonyitva es alapbol nem blokkol

Bizonyitek: `RateCreationService.publishLocalRatePackage()` hash mismatch eseten csak akkor dob, ha `RATE_PACKAGE_HASH_STRICT=true`; komment szerint JS-Java canonical paritas nincs e2e igazolva.

Hatasa: jelenleg a hash forensics/audit jellegu, nem kemeny integritasi kapu. Ez tudatos kompatibilitasi dontes, de nem nevezheto teljes integritasi megvalositasnak.

Javitas:

1. Hozz letre canonical JSON serializer paritastesztet JS es Java oldalon ugyanazzal a fixture-rel.
2. A `rates` BigDecimal mezoket string canonical formara normalizald mindket oldalon.
3. `createdAt` formatumot es pontossagot rogzitett ISO stringkent kezeld.
4. E2E teszt utan kapcsold be prod defaultkent a `RATE_PACKAGE_HASH_STRICT=true`-t.
5. A mismatch logban hash/ID maradjon safeAuditValue-val, user payload ne keruljon nyersen logba.

### P1-04: Local rate-maker groupId visszaolvasas legyen explicit tenant-scoped

Bizonyitek: `publishLocalRatePackage()` publikacio utan `rateWorkgroupRepository.findById(packageDto.getGroupId())` hivassal olvassa a branch kodokat. Ez a szakasz onmagaban nem tartalmaz explicit `companyId` ellenorzest.

Hatasa: ha egy kesobbi refaktor vagy publish-service contract valtozik, visszajohet a cross-tenant workgroup olvasasi kockazat. A 2026-05-31 audit is jelzett lokalis package tenant szigoritasi maradekot.

Javitas:

1. `RateWorkgroupRepository` kapjon `findByIdAndCompanyId(UUID id, UUID companyId)` metodust.
2. `publishLocalRatePackage()` minden groupId olvasasa ezt hasznalja.
3. Add regresszios teszt: masik ceg workgroupId-ja `ValidationException`.
4. Ugyanez a minta legyen kotelezo minden `findById(workgroupId)` arfolyam publish utvonalon.

### P1-05: 2026-05-31 audit maradek P1 hibai nincsenek ezzel a modulzarral lezartnak bizonyitva

Bizonyitek: `vault/references/audit-2026-05-31-confirmed-findings.md` 4 P1 maradekot sorol: RateTemplate LazyInit, Inventory receivedAmount mismatch, AML highRiskFlag dead write, tautologikus multitenancy test.

Hatasa: a 2026.05.20-06.01 fejlesztesi idoszak nem zarhato teljesen hibamenteskent, mert a sajat ledger megerositett maradekokat tartalmaz.

Javitas:

1. RateTemplate: DTO vagy `@JsonIgnore` + transient companyId minta, vagy repository join fetch.
2. Inventory receivedAmount: forras/cel konyveles legyen parban audit-difference rekorddal, TransferService mintara.
3. AML highRiskFlag: hivasi pont BUY/SELL/KONVERZIO utan, teszt 300k/10M relevans hatarokra.
4. Tautologikus teszt: service-en atmeno, valodi tenant-IDOR regresszio.

### P2-01: publishBatch megkerulheti a RateSpreadGate-et

Bizonyitek: a 2026-05-31 audit szerint `RateManagementController.publishBatch` mas publish utvonal, mig a spread kapu a `RateCreationService.publishGroupRateInternal()` agban lathato.

Hatasa: tobb publikacios utvonal eltero uzleti invariantot ervenyesithet.

Javitas:

1. A RateSpreadGate-et ne controller/service-aghoz kosd, hanem a kozos publish sablon-validacios pontba.
2. Minden `RateTemplate` publish utvonalon ugyanazt a validatort hivd.
3. Adj tesztet `publishBatch` negativ spread/max spread esetre.

### P2-02: Hook dependency disable-ok es i18n disable-ok auditot igenyelnek

Bizonyitek: `frontend-react/src/pages/rates/RateCreationPage.tsx` tobb `eslint-disable-next-line react-hooks/exhaustive-deps` sort tartalmaz; `RateGrid.tsx` is tartalmaz hook/i18next disable-okat.

Hatasa: nem automatikus hiba, de stale closure es re-render edge case kockazatot hordoz. A 2026-05-31 audit P3-kent stale sheetCtxRef es tizedes-megjelenitesi eltérést is jelzett.

Javitas:

1. Minden disable melle keruljon konkret invariant teszt vagy helperre bontas.
2. Ha a dependencia valoban stabil, `useCallback`/`useMemo` rendezze, ne a szabaly kikapcsolasa.
3. `RateCreationPage` sheet context frissitest kulon teszteld multi-tab/csoportvaltasi edge case-re.

### P2-03: Frontend BranchListItem nem hordoz branch type infot

Bizonyitek: `frontend-react/src/services/api/exchange-rates.ts` `BranchListItem` csak `id`, `code`, `name`, `city`, `assignedToCurrentWorkgroup` mezoket tartalmaz.

Hatasa: FK02-C helyesen backend-szurt, de a frontend nem tud diagnostikai vagy UI jelzest adni, ha a backend contract regresszal. Ez nem kovetelmeny szerinti uj endpointot jelent, csak DTO bovitest opcionalisan.

Javitas:

1. Nem elsodleges fixkent, de regresszio-diagnosztikahoz opcionalisan add hozza `branchTypeCode` es `isVault` mezot a DTO-hoz.
2. Frontend ne szurjon ezekre uzleti forraskent, csak assert/log/test celra.

### P2-04: Adatbazis `group_rates` hianya miatt nincs schema-level elfogadasi pont az FK02-B-re

Bizonyitek: a backend Flyway migraciok kozt van `rate_publication` audit es workgroup exclusivity, de nincs arfolyamkeszito helyi SQLite `group_rates` migracio; local-first core schema generikus cache/outbox.

Hatasa: a kovetelmeny ellenorzese csak frontend localStorage teszttel bizonyithato, adatbazis schema/integritas szinten nem.

Javitas:

1. SQLite schema verzio novelese a local-first core vagy rate-maker sajat migracios retegeben.
2. `PRAGMA user_version` migracio teszt.
3. Unikalas es index: `(workgroup_id, currency_id, field)`, `updated_at`, `dirty`/outbox ha kesobb sync kell.

## AI-agent javitasi sorrend

1. Eloszor javitsd a `RateCreationPage.tsx` LSP literal-string hibakat i18n kulcsokra. Ez gyors, egyertelmu, es gate-blokkolo lehet.
2. Utana szigoritott backend tenant scope: `findByIdAndCompanyId` minden local-rate-maker/workgroup publish visszaolvasasra, teszttel.
3. Ezutan valaszd szet a csoportlap storage adaptert: `localStorage` fallback + Electron SQLite primary.
4. Hozd letre a local SQLite schema/migrationt es IPC contractot.
5. Keszits JS-Java canonical hash parity tesztet, majd `RATE_PACKAGE_HASH_STRICT` prod default flipet csak zold e2e utan.
6. Zard a 2026-05-31 audit P1 maradekait kulon PR-okban, mert ezek nem mind arfolyam modulok, de ugyanazon idoszak minosegi zarasahoz tartoznak.
7. Vegul futtasd a teljes relevans gate-et: frontend typecheck/lint/test, backend targeted + erintett service tesztek, majd security gate csak ha push/merge/deploy kovetkezik.

## Elfogadasi kriteriumok

- `get_errors` nem jelez hibat a `RateCreationPage.tsx`, `RateGrid.tsx`, `workgroupSheetStorage.ts`, `exchange-rates.ts` fajlokon.
- `npm run typecheck` es az erintett frontend rate tesztek zoldok.
- `RateCreationServiceTest` bovul tenant-regresszioval es zold.
- Electron rate-maker ujrainditas utan a csoportlap fix ertekek SQLite-bol visszatoltodnek, nem localStorage-bol.
- `group_rates`/adapter teszt bizonyitja: onBlur commit utan durable write tortenik.
- `localStorage` csak web fallback, nem Electron primary storage.
- Hash strict mod e2e fixture-rel bizonyitott; addig ne allitsd, hogy integritas-kapu teljes.
- 2026-05-31 audit P1 maradekai vagy javitva, vagy kulon, aktualis allapottal dokumentaltan deferelve.

## Vegso minosites

Nem igazolhato, hogy a 2026.05.20-2026.06.01 kozotti modulfejlesztes teljes egeszeben hibatlanul es minden kovetelmeny szerint elkeszult.

Igazoltan elkeszult:

- FK02-C backend penztar-only iroda lista es POST oldali vedekezes.
- Rate-maker REST publish alaputvonal idempotenciaval es audit mezokkel.
- FK02-B/FK04 egyes frontend logikai magok: 10% check, fill helper, storage helper, rfm szabalyok celzott unit teszttel.

Igazoltan nem teljes vagy nyitott:

- FK02-B csoportlap SQLite/onBlur durable perzisztencia nincs kesz; localStorage a tenyleges tarolo.
- `RateCreationPage.tsx` LSP/i18n literal-string hibas.
- Local package hash strict integritas nincs prod defaultkent bizonyitva.
- A 2026-05-31 audit P1/P2 maradekai nem tekinthetok automatikusan lezartnak.