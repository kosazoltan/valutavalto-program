# FK-096 + FK-097 — Iroda-szintű kezelési díj (döntésnapló + üzemeltetői kézikönyv)

> Pipeline job: `20260826-fk096-fk097-branch-fee`, base `76bb1188`, branch `pipeline/20260826-fk096-fk097-branch-fee`.
> Spec-ek: FK-096 (14 FR), FK-097 (8 FR). Terv: `.hermes/pipeline/20260826-fk096-fk097-branch-fee/round-1/10-plan.md`.
> Ebben a batchben a frontend-változás a közös `frontend-react` bundle-t érinti, ezért **MINDKÉT telepítőbe**
> (Pénztár + Központi Munkaállomás) belekerül (a kozponti-client csak Electron-main kód).

## 1. Mit csinál

A kezelési díj (sávos vagy ezrelékes) eddig kizárólag cégszinten (`system_parameter`) volt
állítható. Mostantól **irodánként** állítható a meglévő „Kezelési költség beállítások"
(`/handling-fee-config`) felületen, piszkozat + jóváhagyás (publikálás) mechanizmussal,
és a pénztári kliens offline is a **saját irodájának élő** értékével számol.

## 2. Végpont-szerződés (D11)

| Végpont | Mód | RBAC | Visszaad |
|---|---|---|---|
| `GET /api/v1/branch-fee-config` | admin lista | UGYVEZETO / FOERTEKTAR / ADMIN | `BranchFeeConfigListDto` |
| `POST /api/v1/branch-fee-config/{branchId}/draft` | piszkozat upsert | UGYVEZETO / FOERTEKTAR / ADMIN | `BranchFeeConfigRowDto` (sor-alakú) |
| `POST /api/v1/branch-fee-config/{branchId}/publish` | DRAFT→LIVE | UGYVEZETO / FOERTEKTAR / ADMIN | `BranchFeeConfigRowDto` (sor-alakú) |
| `GET /api/v1/branch-fee-config/own` | saját iroda LIVE | isAuthenticated | `BranchFeeConfigLiveDto` |
| `GET /api/v1/branch-fee-config/{branchId}/live` | LIVE olvasás | isAuthenticated, csak saját iroda, különben 404 | `BranchFeeConfigLiveDto` |
| `GET /api/v1/handling-fee-bracket` | közös sávtábla | UGYVEZETO / FOERTEKTAR / ADMIN | `BracketSetDto {live[],draft[]}` |
| `POST /api/v1/handling-fee-bracket/draft` | sáv-piszkozat | UGYVEZETO / FOERTEKTAR / ADMIN | `BracketSetDto` |
| `POST /api/v1/handling-fee-bracket/publish` | sávok LIVE-cseréje | UGYVEZETO / FOERTEKTAR / ADMIN | `BracketSetDto` |

Round 2 (ITEM 5): a `draft` és `publish` végpontok **sor-alakú**
`BranchFeeConfigRowDto`-val térnek vissza (`branchId, branchCode, branchName,
region, liveFeeMode, livePerMilleRate, livePerMilleCap, hasDraft, draftFeeMode,
draftPerMilleRate, draftPerMilleCap, version`) — pontosan azzal az alakkal, amit
az admin tábla renderel. Így publikálás után a LIVE oszlopok az új értéket
mutatják teljes újratöltés/refetch nélkül; a korábbi `BranchFeeConfigDto`
(élő oszlopok nélkül) hazug kontraktus volt, ezért törölve.

A publish body-ja **kötelezően** tartalmazza az optimistic-lock verziót:

```json
POST /api/v1/branch-fee-config/{branchId}/publish
{ "expectedVersion": 0 }
```

- `expectedVersion` **`@NotNull` — és a `0` érvényes érték**: a V383 seed minden sort
  `version DEFAULT 0`-val tölt fel, így ~90 iroda **első** publikálása 0-t küld.
  `@Positive`/`@Min(1)` validáció az első publikálást 400-zal öldökölné (B2/N9 csapda).
- `null` → 400; elavult nem-null verzió → **409** (optimistic lock, `OptimisticLockingFailureException`).
- A modal a betöltött verziót küldi vissza — sosem hardkódoltat, és a 0-t nem kezeli „hiányzó"-ként.
- A közös sávtábla publishja nem aggregate, hanem halmaz-művelet: **szigorúan soros írási út**,
  `@Lock(PESSIMISTIC_WRITE)` a cég sávsorain a tranzakción belül (D8).

Hiba-objektum: a meglévő `ErrorResponse` (`GlobalExceptionHandler`), `@Valid` mezőhibák batchelve.
Lista-végpontok pagináció nélkül — a cég irodaszáma (~70–90) korlátos, tudatos döntés.

## 3. C7 döntés: minden hívó branch-aware és fail-closed (D2/D3)

A díjszámítás egyetlen helye sem marad cégszintű. Az 1-argumentumos
`calculateHandlingFee(hufAmount)` overload **törölve** — a fail-closed így compile-time garancia.

| Hívó | branchId forrása | Fail-closed? |
|---|---|---|
| `HandlingFeeCalculator.calculate(huf, type, clientFee, branchId)` → `TransactionService:288,535`, `TransactionMultiLineService:138,368`, `TransactionConversionService:160` | a hívó meglévő lokális `branchId`-ja, **explicit paraméterként** átadva (nincs rejtett statikus olvasás a kalkulátorban — DIP, SecurityContext nélkül tesztelhető) | IGEN — 400, tranzakció nem könyvelhető |
| `CurrencyCalculatorService:194` (árajánlat commission) | a `calculateWithHuf(...)` `branchId` metódusparamétere | IGEN |
| `ShipmentHandlingFeeService:62` | `saved.getFromBranchId()` — a feladó iroda viseli a KK-díjat | IGEN |

Ha egy irodának **nincs saját aktív LIVE sora**, a tranzakció 400-zal elutasítva,
egyértelmű hibaüzenettel — **nem könyvelődik csendben 0 Ft** (FR-5).

## 4. FR-2 vs NFR-2 feloldása (D5)

FR-2 megköveteli, hogy a bevezetés pillanatában egyetlen iroda számítása se változzon.
A cap ma nyersen hasonlítódik (`HandlingFeeService:147-152`), ezért a migráció a
`HANDLING_FEE_PER_MILLE_MAX` értéket **szóról szóra** (verbatim) seedeli — kerekítés nélkül,
különben egy élő díj akár 2 Ft-tal elmozdulna. A `roundHuf` (5 Ft) kerekítés a **írási úton**
érvényesül (piszkozat-mentés validáció + service normalizáció + kliens-tükör): minden ezután
beírt érték 5 többszöröse lesz. Migrációs teszt igazolja a verbatim seedet, service-teszt a
write-path kerekítést.

## 5. Audit (D9, NFR-4)

Új KAT-kategória **nem** készül — a KAT szabad szöveg a `changes` JSON-ban, és az
audit-böngésző az **action név** szerint szűr/színez (`AuditLogPage.tsx:134-141`), nem KAT szerint;
egy új `FEE` kategória láthatatlan lenne. A specificitást az action-nevek hordozzák:

- `BRANCH_FEE_CONFIG_PUBLISHED` — iroda-szintű publikálás (ki, mikor, előtte/utána értékek)
- `HANDLING_FEE_BRACKET_PUBLISHED` — közös sávtábla publikálása
- `BRANCH_FEE_CONFIG_ACCESS_DENIED` — RBAC/cross-tenant megtagadás (FR-12/FR-13);
  round 2 (ITEM 2) óta **mindkét 404-helyen** ténylegesen íródik: a
  `findBranchInCompany` tenant-guard miss-nél (`reason: CROSS_TENANT_BRANCH`)
  és a `/live` saját-iroda guardnál (`reason: FOREIGN_BRANCH_LIVE_READ`),
  `REQUIRES_NEW` tranzakcióban a hívó tenantjába — túléli a rollbacket.
  Payload: `KAT:AUTH`, `error_code: VV-AUTH-001`, `reason`, `branch_id`, `company_id`.

Minden publikálás auditálva, előtte/utána értékkel (NFR-4, NFR-5: egyetlen DB-tranzakció).

## 6. RBAC-mátrix (D10, spec §3)

| Szerep | olvas | piszkozat | publikál |
|---|---|---|---|
| Főértéktáros (`FOERTEKTAR`) | ✓ | ✓ | ✓ |
| Ügyvezető (`UGYVEZETO`) | ✓ | ✓ | ✓ |
| Pénztáros (`PENZTAR`) | ✓ — **csak saját iroda, read-only** (`/own`) | – | – |
| Irodavezető (`IRODAVEZETO`) | – (deny-by-default) | – | – |
| Belső ellenőr (`BELSO_ELLENOR`) | – (deny-by-default) | – | – |
| Egyéb | – | – | – |

Megjegyzések:
- A spec role-tokenje `FOERTEKTAROS` **nem létezik** a kódbázisban — a kanonikus token
  `FOERTEKTAR` (a spec szerinti @PreAuthorize mindenkit megtagadott volna).
- Az Ügyvezető write-joga **szándékos kivétel** a modul alap-RBAC overlaye fölött
  (TBD-2): itt az Ügyvezető a tényleges jóváhagyó fél.
- Az új végpontok szűkítik a jogosultsági kört a korábbi `HandlingFeeConfigController`
  class-level `@PreAuthorize`-ához képest. Round 2 (ITEM 1): a legacy végpont
  **ratchet** alatt áll — a TBD-4 kompatibilitásért az URL megmarad, de az
  ÉLŐ sáv-írás és a bővített szerepkör-kör írási joga **nem**: a `PUT` és a
  `POST /brackets` method-szintű `@PreAuthorize`-a pontosan
  `UGYVEZETO`/`FOERTEKTAR`/`ADMIN` (`IRODAVEZETO`, `BELSO_ELLENOR` **és**
  `MANAGER` írásból kizárva — a MANAGER-vesztés szándékos: az FR-12 csak a három
  szerepet sorolja, és a legacy alias nem lehet hátsó kapu az élő díjváltáshoz).
  A sáv-fej DRAFT-ként mentődik (`saveBracketDraft` delegáció), élesítés csak
  `POST /api/v1/handling-fee-bracket/publish`-csal. A GET pénztáros read-only
  elérhetősége (FK-KEZDIJ B.1) változatlan. Ez a ratchet csak szigorodhat.
- Cross-tenant: más cég `branch_id`-jével írási kísérlet → **404** (nem 403, ne árulja el a
  létezést) + audit-bejegyzés (FR-13).

## 7. TBD-válaszok

| # | Kérdés | Válasz |
|---|---|---|
| TBD-1 | Belső ellenőr / irodavezető olvasási joga? | **Deny-by-default** mindkettőre (D10); a jövőbeni bővítés külön kérés tárgya. |
| TBD-2 | Ügyvezető write-jog eltérése | **Szándékos kivétel**, dokumentálva (§6). |
| TBD-3 | Audit KAT-kategória | Meglévő `RATE` KAT újrahasznosítva, az action-nevek hordozzák a specificitást (D9). |
| TBD-4 | `system_parameter` HANDLING_FEE_* kulcsok törlése | **Nem ebben a körben.** A kulcsok megmaradnak, de a feloldás már nem olvassa őket; a legacy PUT `@Deprecated` + `log.warn` (D16). |
| TBD-5 | Egyidejű publikálás | **Optimistic locking** `@Version`-nel + `expectedVersion` body (D8); konfliktus → 409. |

## 8. Adatmodell

- **Új tábla:** `branch_handling_fee_config` — `company_id`, `branch_id`, `fee_mode`
  (`NONE`/`BRACKET`/`PER_MILLE`), `per_mille_rate NUMERIC(6,3)`, `per_mille_cap NUMERIC(15,2)`,
  `status` (`DRAFT`/`LIVE`), `is_active`, `version` (optimistic lock), audit-oszlopok.
  Egy iroda egy időben legfeljebb egy LIVE + egy DRAFT sort tarthat
  (`uk_bhfc_branch_live` parciális unique index: `branch_id WHERE status='LIVE' AND is_active`).
- **`handling_fee_bracket`:** új `status` oszlop (`DRAFT`/`LIVE`, DEFAULT 'LIVE'); a meglévő
  sorak LIVE-ra állnak. A tábla **marad cégszintű** — a sávos irodák a közös LIVE sávokat használják.
- **`fee_mode = NONE`** is elfogadott a sémában (D4): ha egy cég `HANDLING_FEE_TYPE=NONE` ma,
  a seedelt LIVE sornak reprodukálnia kell a 0 Ft-ot (FR-2). A szerkesztő csak BRACKET/PER_MILLE-t
  kínál; NONE-LIVE esetén hu-HU banner: *„Jelenleg nincs kezelési díj beállítva (örökölt érték) —
  válassz módot a küldéshez."* — a Publikálás addig tiltott.
- **`per_mille_cap = 0` ma „nincs sapka"** (`HandlingFeeService:149`, `maxAmount > 0` őrszem).
  Ez megmarad: a seed `NULL`-t ír a 0 helyett (`NULLIF(...,0)`), a feloldás a `null`-t és a 0-t
  azonosan „nincs sapka"-ként kezeli — különben a 0 sapka 0 Ft díjat jelentene (csendes bevételkiesés).
- **SQLite mirror (FK-097):** `cached_handling_fee_config` a pénztár-kliens lokális DB-jében
  (`branch_id`, `fee_mode`, `per_mille_rate`, `per_mille_cap`, `bracket_json`, `synced_at`).
  Piszkozat **soha** nem szinkronizálódik — a végpontok csak LIVE-t adnak vissza, a cache is csak LIVE sort tárol.

## 9. Operátori szakaszok

### 9.1 Új iroda runbook (D18)

A `BranchService.create` és `createSimpleCashier` által létrehozott irodák **automatikusan**
kapnak LIVE konfigurációt a cég-default öröklésével, **ugyanabban a tranzakcióban**
(`BranchHandlingFeeConfigService.seedDefaultLive(companyId, branchId, createdBy)` — egyetlen
implementáció, két hívási hely, nem tudnak sodródni). A seed ugyanazt a prioritást követi,
mint a V383 (D6): aktív cég-sor → aktív globális sor → kód-default.

**Kézi lépés csak akkor kell**, ha egy iroda közvetlen SQL-inserttel került a DB-be
(az admin API-t megkerülve): annak az irodának nincs LIVE sora, és **minden tranzakciója
400-zal elutasított**, amíg egy admin nem publikál neki konfigurációt:

1. Központi Munkaállomás → Adminisztráció → „Kezelési költség beállítások".
2. Keresd meg az irodát a pénztár-listában (a területi szűrő segít).
3. Kattints a sorra → modal: válaszd a módot (Sávos / Ezrelékes), ezrelékesnél mérték + maximum.
4. **Mentés** (piszkozat — az éles díj ekkor még nem változik).
5. **Küldés** → megerősítő dialógus → a sor LIVE-vá válik, audit-bejegyzés készül.
6. Ellenőrzés: a lista „Mérték/Maximum" oszlopai az új értéket mutatják.

### 9.2 Legacy végpontok (D16 + round 2 ITEM 1)

- `GET /api/v1/handling-fee-config` mostantól **csak LIVE sávokat** ad vissza (a bracket-keresés
  status-szűrőt kapott) — az első DRAFT sáv mentése után sem szivárog ki publikálatlan érték.
  A DTO, a válasz alakja és az RBAC bájt-azonos marad.
- `PUT /api/v1/handling-fee-config` **deprecált**: továbbra is írja a `HANDLING_FEE_*`
  `system_parameter` kulcsokat és 200-zal tér vissza, de **ezek a kulcsok többé nem
  befolyásolják a díjszámítást**. A díj beállításához a `/branch-fee-config` végpontokat
  (illetve az admin felületet) kell használni. Round 2 (ITEM 1) óta a törzsben
  küldött sávok **NEM kerülnek LIVE-ba**: a sáv-fej `saveBracketDraft`-ba delegál,
  vagyis **DRAFT-ként** mentődik, és csak `POST /api/v1/handling-fee-bracket/publish`-csal
  élesíthető. Érvénytelen sáv-lista (null/zero/negatív felső határ vagy díj) az egész
  PUT-ot 400-zal elutasítja — a `system_parameter` upsertök atomikusan visszagörgetnek.
  Az írási RBAC method-szinten pontosan `UGYVEZETO`/`FOERTEKTAR`/`ADMIN`
  (`IRODAVEZETO`, `BELSO_ELLENOR`, `MANAGER` írásból kizárva). A controller két
  feltételes `log.warn` sort ír: a system_parameter-félre mindig, a sáv-félre csak
  akkor, ha a törzs tényleg hozott sávokat (az üzenet így tényeket mond az adott
  requestről).
- `POST /api/v1/handling-fee-config/brackets` **deprecált**: round 2 (ITEM 1) óta
  ez is `saveBracketDraft`-ba delegál — a válasz alakja (`List<HandlingFeeBracketDto>`)
  byte-kompatibilis marad a TBD-4 külső fogyasztónak, de a sorok **DRAFT**-ként
  mentődnek; élesítés kizárólag `POST /api/v1/handling-fee-bracket/publish`.
  Ugyanaz a három szerepkör írhatja; érvénytelen sáv-lista → 400, kötegelt
  hibalistával (minden hibás sor indexszel, egy válaszban).

### 9.3 Ismert eltérés: kliens ezrelékes tükör (W7)

A kliens `computeHandlingFee` PER_MILLE ága IEEE-754 double aritmetikával számol, a backend
`BigDecimal`-dal. Egy mért határeset:

| huf | rate ‰ | cap | backend (BigDecimal) | JS mirror |
|---|---|---|---|---|
| 3125 | 18.4 | – | **60** | **55** |

(`3125 × 18.4 = 57499.99999999999` double-ben → /1000 = 57.499… → Math.round 57 → roundHuf 55;
BigDecimal pontosan 57500 → HALF_UP 58 → roundToFive 60.)

**A könyvelt összeg mindig helyes**: a szerver a tranzakció feldolgozásakor újraszámol, és a
`HandlingFeeCalculator` mismatch-log mellett a szerver értéke az autoritatív — a bizonylatra
nyomtatott és a könyvelt díj megegyezik. Csak a képernyő-előnézet térhet el legfeljebb 5 Ft-tal
ezeken a határokon. A pontos javítás (integer-milli aritmetika:
`Math.round(huf * Math.round(rate * 1000) / 1_000_000)`) **külön ticket**, saját corpus-teszttel —
ebben a batchben tudatosan nem szerepel. A teszt a 3125@18.4 sort a **valós** értékén (55)
assertálja, „ismert eltérés, a szerver az autoritatív" kommenttel — sosem „javítva" a kerekített
elvárásra, sosem törölve.

## 10. Szinkron (FK-097)

- A meglévő 30 mp-es `runSync()` ciklus új letöltő ága: `syncHandlingFeeConfig()` a
  `syncRates()` mintájára, `GET /api/v1/branch-fee-config/own` (D12: a pénztár-kliens csak
  `branch_code`-ot tárol, `branch_id`-t nem — ezért az `/own`, JWT-alapú végpont kell).
- Új IPC-csatorna `getCachedHandlingFeeConfig` a `getCachedRates` pontos mintájára
  (D13: nem került a `packages/shared-ipc`-be, mert ott ma nem él egyetlen `get-cached-*`
  útvonal sem — a részleges migráció pénzügyi változásban nagyobb kockázat).
- Kliens-tükör (`handlingFee.ts`): **cache-first** — van Electron IPC és cache-sor → lokális
  olvasás; üres cache → HTTP-fallback (`/own`); mindkettő hibás → `null` (a régi viselkedés).
  A `CashierTransactionPage` config-betöltése ugyanezt hívja: cache-találatnál a díjmező
  **offline is zárt marad** (nem nyílik kézi beírásra, FR-6).
- **Nincs új `packages/electron-platform` modul** (D14): semmi nem bizonyítottan bit-azonos
  duplikátum kliensek között; a közös `computeHandlingFee` már a közös bundle-ben él.

## 11. Teszt- és kapu-besorolás (D15)

- **BLOCKING:** `mvn verify`, `npm test` (mindkét lane), `npm run lint`, `npm run typecheck`,
  `npm run check:platform-boundaries`, `node scripts/check-version-sync.mjs`, Playwright e2e,
  gitleaks, `npm run memory:stale-check` (exit 1 nem merge-elhető, AGENTS §2.1).
- **RATCHET:** Vitest coverage ≥80% az új frontend-fájlokon (fájlonként riportálva, nem regresszálhat).
- **INFORMATIONAL:** `npm run migration:flyway:content-audit`.

## 12. Migráció (V383)

`V383__fk096_branch_handling_fee_config.sql`: új tábla + `handling_fee_bracket.status` +
adatfeltöltés. A seed minden aktív irodának LIVE sort ad a ma érvényes céges alapértékkel
(D6 prioritás: cég-sor → globális sor → kód-default), hogy a bevezetés pillanatában egyetlen
iroda számítása se változzon (FR-2, bit-paritás Postgres IT-vel igazolva). A nem-numerikus
legacy `HANDLING_FEE_PER_MILLE` értékek nem állítják le a migrációt (regex-guard + kód-default,
a `HandlingFeeConfigController:62-74` mintájára).
