# 2026-05-25 — RFM Valutakezelő-fix + vékony-kliens↔szerver e2e + v2.27.1 release

## Kontextus
A felhasználó jelezte: a Valutakezelő (Currency Manager) létrehozáskor hibát dob, az
Aktivál/Inaktivál gombok némán nem csinálnak semmit. Plusz kérdés: a rate-maker főlap
formula/navigáció követelményei működnek-e ("így működik?"). Majd: a vékony-kliens →
szerver árfolyam-publikálás + szétküldés valós működésének ellenőrzése.

## Mit csináltunk (PR #832, admin-merged `5e1272f88`, v2.27.1)

### 1. Valutakezelő 403 — gyökérok + fix
- `CurrencyController` POST `/currencies` + PATCH `/{id}/active` `@PreAuthorize` csak
  ADMIN/MANAGER-t engedett → a **főértéktáros** (`CHIEF_VAULT`→`ROLE_FOERTEKTAR`) **403**-at
  kapott. Létrehozáskor ez a hibaüzenet; aktiválásnál a frontend csendben elnyelte.
- Fix: `hasAnyRole('ADMIN','MANAGER','FOERTEKTAR','UGYVEZETO')` mindkét végponton.
- **Backend, szerver-served** → Hetzner deploy után azonnal él (igazolva: `/local-rate-maker/bootstrap` 401 auth-kapu, prod 200).

### 2. "Így működik?" — mind a 8 RFM főlap-követelmény igazolva (kód + 18 unit teszt)
- Fix számérték (`commitCell` parseFloat vessző/szóköz toleráns), `=` formula (HyperFormula),
  D oszlop védett (`EDITABLE_ORDER`/`FORMULA_COLUMNS`-ból kihagyva + keydown-guard),
  G/H kereszt-logika kézzel nem írható (commit `null`-t ad G-re), A felülírható
  (`settlementManual`), reaktív újraszámítás (`useEffect`→HyperFormula), nyíl-navigáció
  (`nextEditableCell` D/G átugorva), Enter belép/jóváhagy + lefelé, Escape elvet.
- Tesztek: `sheetNavigation.test.ts` + `mainSheetRules.test.ts` 18/18.

### 3. Vékony-kliens ↔ szerver publikálás/szétküldés — e2e teszt (HIÁNY pótlása)
- **Eddig 0 integrációs teszt** fedte a `local-rate-maker` flow-t.
- Új `LocalRateMakerPublishTest` 7/7 a tényleges `RateCreationService.publishLocalRatePackage`
  kódúton: happy-path (elfogadás + `RatePublishService.publish()` szétküldés-hívás + 2 érintett
  fiók + szerver-hash + rendezett fiók-kódok), LOCAL_RATE_MAKER metaadat, duplikátum-védelem,
  hiányzó munkacsoport, hash STRICT KI (nem-blokkoló) / BE (elutasít), spread-kapu (5%).

### 4. Egyéb fixek
- rate-maker sidebar menü (`menuGroups.ts` új „Árfolyamkészítés" csoport `modes:["rate-maker"]`).
- MNB-seed (a főlap a publikálatlan valutákat az MNB hivatalos rátáiból tölti).
- Hash-integritás (#ERR-RATE-01/02) feature-flag mögött + CodeQL log-injection sanitizálás.
- kozponti `sql-wasm.wasm` extraResources (Copilot finding — csomagolt SQLite különben elhasalt volna).
- Beágyazott-mappa upgrade-fix (külön appId `com.bestchange.munkaallomas` + installer-cleanup.nsh).

## Telepítő v2.27.1 (UNSIGNED, Downloads)
- `Kozponti-Munkaallomas-Setup-2.27.1.exe` — 102.63 MB, SHA-256
  `A32DCC43143DF43D3443D30DB7CEE01AA3086CFAFF12B526B76D26B43E8164F4`.
- Csak a merged Munkaallomas épült újra (penztar = szerver-served, build-stratégia szerint nem kell).

## Tanulság
- A frontend `canWriteRateCreation` (foertektar/ugyvezeto/admin) és a backend `@PreAuthorize`
  divergenciája csendes 403-at okoz; aktiválásnál a hiányzó error-toast miatt "nem történik semmi".
- A "valós működés" igazolása ≠ kódolvasás: a local-rate-maker flow-ra 0 teszt volt → service-szintű
  e2e teszt írása a folyamatos-tesztelési protokoll szerint kötelező volt.

## Hátralévő (őszinte)
- A futó EXE-vel végzett éles kézi e2e (rate-maker mód, valódi csomag publikálás, ráta megjelenése
  egy pénztáros gépén) — most már lehetséges a merged telepítő + deploy után; valós ráta-adatot
  írna production-ra, ezért külön felhasználói megerősítéssel.

---

## Follow-up: éles E2E (Computer Use, teszt-DB) + 2 valódi szerver-bug — v2.27.2/v2.27.3

A user engedélyével végigvittük az ÉLES E2E-t a futó merged kliensen (rate-maker mód):
silent telepítés v2.27.1 → régi kliensek cleanup verifikálva → mód-választó → bejelentkezve
(Kosa Zoltan / Tisza Sarok). **Vizuálisan igazolt:** rate-maker sidebar, MNB-seed (összes valuta
értékkel), Valutakezelő létrehozás/inaktiválás/aktiválás (a 403 megszűnt), képlet `=A1*2`→821,
auto-újraszámítás (A:410.50→400 → B:800), D-oszlop védett, G7 árfolyam-irány figyelmeztetés.

**A publish viszont HTTP 500-zal elhasalt** → ezért kellett az éles E2E. Két valódi bug:

### #500 — audit_log jsonb (PR #841, v2.27.2, backend szerver-served)
- Hetzner log: `column "after_state" is of type jsonb but expression is of type character varying`
  → `InvalidDataAccessResourceUsageException` az `audit_log` INSERT-nél (`RATE_APPROVE`).
- Gyökér: `AuditLog.beforeState/afterState` `columnDefinition="jsonb"` DE `@JdbcTypeCode` nélkül →
  Hibernate varchar-ként kötötte a NULL paramétert is → Postgres elutasította → a `@Transactional`
  approve/publish 500-zal visszagördült. A V234 `AuditEventService.appendEvent` is ugyanezt az
  entitást használja → latens ugyanott.
- Fix: `@JdbcTypeCode(SqlTypes.JSON)`. H2 nem reprodukálja (audit-tesztek 14/14 zöld), ezért a
  bizonyíték a prod re-teszt: deploy után EUR v4 + 12 valuta v1 → **73 pénztár, 0 hiba, nincs 500.**

### #404 — rate-maker fölösleges központi sync (PR #842, v2.27.3, Electron)
- `CentralWorkstationSyncEngine` rate-maker módban is indult → `/central/sync/pull` HTTP 404
  30 mp-enként (a végpont szerver-oldalon NEM létezik; a rate-maker közvetlen REST-en publikál).
- Fix: `local-first.ts` — rate-maker módban a sync-motor NEM indul (DB-init marad az offline
  cache-hez). Reinstall után verifikálva: log „központi sync-motor KIHAGYVA", nincs új 404.

### service_version fix (PR #842)
- `logback-spring.xml` `${APP_VERSION:-2.5.57}` elavult hardcode → `spring.application.version`
  (fat-JAR `Implementation-Version`-ből; Sourcery+Copilot bug_risk: a korábbi `@project.version@`
  filtering szűretlen futásnál literált logolt volna). Prod log igazolva: `service_version:"2.27.3"`.

## Tanulság
- A H2-alapú teszt-harness NEM reprodukálja a Postgres jsonb/varchar binding-hibát → a `jsonb`
  String-mezőkhöz KÖTELEZŐ `@JdbcTypeCode(SqlTypes.JSON)` (a `columnDefinition="jsonb"` csak DDL).
- A `service_version`-höz a Spring Boot `spring.application.version` (manifest) a tiszta út, NEM
  property-token filtering (szűretlen futásnál literál-kockázat).
- Az éles, futó-app E2E olyan szerver-oldali hibákat fog meg (publish-500, sync-404), amiket a
  unit/IT tesztek és a kód-olvasás nem.

## Telepítő v2.27.3 (UNSIGNED, Downloads)
- `Kozponti-Munkaallomas-Setup-2.27.3.exe` — 102.63 MB, SHA-256
  `868C1A5C3BF88B5BB649C7A66E3B76F4A8604383626348C8E1235EC2EA5E1EF8`.
