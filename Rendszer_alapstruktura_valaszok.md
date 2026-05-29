# Rendszer alapstruktúra – válaszok (AI-ügynöknek átadható specifikáció)

**Dátum:** 2026. május 29.
**Kérdező:** Kasza Helga – Főértéktár
**Válaszadó:** Claude (Valutaváltó ERP repo alapján)
**Repo-horgony:** v2.27.26, legutolsó Flyway-migráció: `V277__vault_counterparty_branches.sql`

> **Mire való ez a dokumentum?**
> Ez nem csak emberi olvasásra készült leírás. Úgy van megszerkesztve, hogy **közvetlenül átadható egy Mesterséges Intelligencia (AI) ügynöknek**, amely ez alapján a saját működését korlátozza/szabályozza. Ezért minden kérdésnél négy blokk van:
> - **Kérdés** – a kolléga eredeti kérdése szó szerint
> - **Válasz** – a repo tényei alapján, fájlhivatkozásokkal
> - **AI-ügynök utasítás** – kötelező MUST/TILOS direktívák, amiket az ügynöknek be kell tartania
> - **Kódminta** – konkrét, kicsi kódrészlet, ami megmutatja, hogyan kell helyesen csinálni
>
> A válaszok **kizárólag a repo tényein** alapulnak. Ahol a repo nem ad egyértelmű választ, ott ez expliciten szerepel.

---

## Globális ügynök-irányelvek (nem-alkuképes)

Az AI-ügynöknek MINDEN feladatnál be kell tartania az alábbiakat. Forrás: `AI_CONSTITUTION.md`, `AGENTS.md`, `AI_CONTRACT.md`, `CLAUDE.md`.

1. **Multi-tenant izoláció (IDOR-védelem):** MINDEN lekérdezésnek `companyId`-ra kell szűrnie (`SecurityUtils.getCurrentCompanyId()`). Egyedi rekord betöltése után ellenőrizni kell a tulajdonost; idegen tenant esetén **404** (nem 403, az id-enumeráció ellen). Hiányzó szűrés = biztonsági hiba.
2. **OSIV kikapcsolva** (`spring.jpa.open-in-view=false`): ha a mapper lazy asszociációt olvas a controller-rétegben → `LazyInitializationException` 500. Megoldás: `JOIN FETCH` a repo-query-ben, VAGY `Hibernate.initialize(...)` a `@Transactional` metóduson belül.
3. **HUF 5 Ft-os kerekítés:** minden HUF összegnél (`roundHuf` / `HungarianRounding` a backenden, `roundFin` a kliensen). TILOS kerekítés nélkül HUF összeget tárolni/megjeleníteni.
4. **AML/Pmt.:** azonosítási küszöbök 100 000 Ft (SIMPLIFIED) / 300 000 Ft (FULL); árfolyam 24h TTL — lejárt rátával **nincs tranzakció**. AML-ellenőrzés MINDIG a tranzakció előtt.
5. **Security gate:** `@PreAuthorize` minden védett controlleren; CORS nem wildcard; secret SOHA kódba/chatbe/commitba.
6. **Audit:** `audit_log` immutable (UPDATE/DELETE tiltott triggerrel). Minden `LOG.error()` KÖTELEZŐ `error_code`-dal (`VV-<KAT>-<3jegy>`), előbb `packages/shared-logging/error-codes.yaml`-be felvenni.
7. **Séma csak Flyway-jal:** új tábla/oszlop/seed CSAK `backend/src/main/resources/db/migration/V{N}__{name}.sql` migrációval. Lokál DB-seed és kézi `psql INSERT` TILOS a produktum-DB-be.
8. **Folyamatos tesztelés:** célzott teszt írása+futtatása kódolás közben. TILOS: teszt skip/törlés a zöldért, assertion-gyengítés, „működik" teszt nélkül.
9. **300 LOC plafon / fájl-diff** (`AI_CONTRACT.md`), test-manipuláció tilos.
10. **Research-first:** javítás csak bizonyított root cause alapján (forrás → diagnózis → minimális fix → ellenőrzés). Próba-szerencse TILOS.

> ⚠️ **NULLADIK PRIORITÁS:** a végfelhasználó kollégák NEM informatikusok. TILOS nekik parancssort/manuális konfigot küldeni; minden automatizált.

---

## 1. Az adatbázis struktúrája

**Kérdés:** Hogyan épül fel jelenleg az adatbázis struktúrája?

**Válasz:**
A központi adatbázis **PostgreSQL**, a séma-verziózás **Flyway**-jal történik. A migrációk a `backend/src/main/resources/db/migration/` mappában vannak, `V1` → **`V277__vault_counterparty_branches.sql`** sorszámmal (ez a jelenlegi legfrissebb).

- A séma kb. **260 JPA entity**-ből áll (`backend/src/main/java/hu/puzzleir/valuta/entity/`). Ezek lefedik a teljes domaint: `Transaction`, `TransactionLine`, `TransactionBanknote`, `ExchangeRate` / `ExchangeRateMaster`, `Denomination` / `DenominationCount`, `Customer`, `Worker`, `Branch`, `Company`, `VaultTerritory`, `DailySession`, `EveningClosing`, AML (`AmlReport`, `AmlThreshold`), audit (`AuditLog`, `CurrencyAuditLog`) stb.
- **Multi-tenant alap:** a törzs-entitások kötelező `company_id` oszloppal rendelkeznek. Pl. `Worker` (`backend/.../entity/Worker.java:48-50`) `@ManyToOne ... company_id nullable=false`, egyedi kulcs `(company_id, code)`.
- **Audit/időbélyeg:** az entitások `@CreatedDate` / `@LastModifiedDate` mezőkkel követik a létrehozást/módosítást (Spring Data auditing).
- A modell **legacy-leképezést** is tartalmaz (pl. a `Worker` kommentje a `prosbe.dll` PtarosKod/PtarosNev mezőkre hivatkozik), tehát egy korábbi rendszer adatszerkezetét örökölte.

> A teljes táblalista a Flyway-migrációkból és az entity-fájlokból olvasható ki; nincs külön „minden tábla egy fájlban" sémadokumentum a repóban.

**AI-ügynök utasítás:**
- A séma **aktuális igazsága mindig a Flyway-migrációk + az entity-osztályok**, NEM az AI emlékezete vagy korábbi leírás.
- Új tábla/oszlop kizárólag **új Flyway-migrációval** (`V278__...sql`), a meglévők (`V1..V277`) **soha nem módosíthatók**.
- Minden új törzs-entitásra KÖTELEZŐ a `company_id` oszlop + index, kivéve a valóban globális szótár-táblákat (pl. `Dictionary`, országkódok) — ezt esetenként indokolni kell.
- Schema-kérdésnél ELŐSZÖR `grep`/olvasás a `db/migration/`-ben és `entity/`-ben, csak utána válasz.

**Kódminta** – új tábla helyesen, Flyway-migrációval, multi-tenant oszloppal:
```sql
-- backend/src/main/resources/db/migration/V278__add_example_master.sql
CREATE TABLE example_master (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id  UUID NOT NULL REFERENCES company(id),
    code        VARCHAR(20) NOT NULL,
    name        VARCHAR(200) NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP,
    CONSTRAINT uq_example_master_company_code UNIQUE (company_id, code)
);
CREATE INDEX idx_example_master_company ON example_master (company_id);
```

---

## 2. Közös központi adatbázis a három program között

**Kérdés:** A három program (pénztári, értéktári, központi munkaállomás) ugyanabból a központi adatbázisból olvassa-e a törzsadatokat?

**Válasz:**
**Igen — a törzsadat egyetlen központi forrásból származik.** A produktum a Hetzner HA klaszteren futó backend (**https://excvaluta.com**, Scaleway warm standby), mögötte egy központi **PostgreSQL** (`CLAUDE.md` – „Production-first fejlesztés"). A három Electron-kliens:
- `penztar-client/` (pénztáros),
- `kozponti-client/` (központi + árfolyamkészítő, mód-választóval),
- `arfolyam-keszito-client/` (árfolyamkészítő),

mind ugyanazt a backend REST API-t hívják (`/api/v1/...`), így a **törzsadatok (árfolyam, fiók, címlet, dolgozó stb.) ugyanabból a központi adatbázisból** származnak.

**Fontos árnyalat (offline-képesség):** a kliensek **local-first** működésűek: van helyi **SQLite** gyorsítótáruk (`penztar-client/electron/sqlite.ts`), amelybe a törzsadatokat letöltik (`cached_rates`, `cached_branch_status`, `cached_cash_desks`, `cached_workers` táblák), hogy hálózat nélkül is működjenek. Ez **másolat/cache**, az egyetlen igazságforrás (SSOT) a központi PostgreSQL. (Részletek az 5. kérdésnél.)

**AI-ügynök utasítás:**
- A törzsadat egyetlen igazságforrása a **központi PostgreSQL a backend mögött**; a kliens-SQLite csak cache. TILOS a klienst önálló igazságforrásként kezelni.
- A kliensek nem érik el közvetlenül az adatbázist — **csak a backend `/api/v1` (illetve a központi kliens `/central/sync/...`) API-n keresztül**. TILOS bármelyik kliensből direkt DB-kapcsolatot nyitni a központi PostgreSQL-re.
- A három kliens közötti viselkedés-eltérés **mód/szerepkör** alapján van (lásd `penztar-client/electron/setup-app-mode-roles.ts`), nem külön adatbázissal.
- Új törzsadat-igény esetén a forrás a backend; a kliens csak letölti és cache-eli.

**Kódminta** – kliens a központi API-ból olvas (nem közvetlen DB), és lokálba cache-el:
```ts
// minden kliens a központi backend API-t hívja (SSOT), majd lokál SQLite-ba ír
const rates = await fetch(`${API_BASE}/api/v1/exchange-rates?companyCode=EBC`, {
  headers: { Authorization: `Bearer ${jwt}` },
}).then(r => r.json());

// lokál cache frissítés (offline működéshez) – cached_rates tábla
const upsert = db.prepare(`
  INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, updated_at)
  VALUES (@currency_code, @buy_rate, @sell_rate, @updated_at)
  ON CONFLICT(currency_code) DO UPDATE SET
    buy_rate=excluded.buy_rate, sell_rate=excluded.sell_rate, updated_at=excluded.updated_at
`);
const tx = db.transaction((rows) => rows.forEach(r => upsert.run(r)));
tx(rates);
```

---

## 3. Területi hierarchia és felhasználók területhez rendelése

**Kérdés:** Hogyan van jelenleg kezelve a területi hierarchia és a felhasználók területhez rendelése?

**Válasz:**
A területi hierarchia a következő szintekből áll (forrás: entity-k):

1. **`Company` (cég / tenant)** — `entity/Company.java`. A multi-tenant gyökér; minden törzsadat ehhez tartozik (`company_id`). Egyedi `code` (pl. „BEST", „EXKSZER").
2. **`VaultTerritory` (értéktári terület)** — `entity/VaultTerritory.java`. „Területi szervezés: pénztárak (branch) területi értéktárakhoz rendelése." Egyedi `(company_id, name)`, van alaptőkéje (`base_capital`).
3. **`Branch` (fiók: pénztár vagy értéktár)** — `entity/Branch.java`:
   - `company_id` (kötelező) — melyik céghez tartozik,
   - `parent_branch_id` — **önhivatkozó** fiók-hierarchia (fiók alá rendelt fiók),
   - `vault_territory_id` — melyik értéktári területhez tartozik (V60 migráció),
   - `is_vault` — **TRUE = értéktári fiók, FALSE = pénztár** (V174 migráció),
   - `region` / `region_code` — régió-csoportosítás (pl. SZEGED, DEBRECEN, PECS… és legacy KESZLEX körzetkódok).
4. **`BranchGroup`** — fiók-csoportosítás (`entity/BranchGroup.java`).

**Felhasználók (dolgozók) területhez rendelése** (`entity/Worker.java`):
- `company_id` — kötelező tenant-kötés,
- `branch_id` — a dolgozó alapértelmezett **munkahelye** (iroda/fiók),
- `region` — régió-azonosító (login-prefillhez),
- **Multi-branch hozzáférés:** `WorkerBranchAccess` (`entity/WorkerBranchAccess.java`) egy **M:N** kapcsolótábla `(worker_id, branch_id)` kulccsal: pontosan mely fiókokban dolgozhat a felhasználó. **Default-deny** elv (OWASP A01): explicit rekord nélkül nincs hozzáférés; audit-mezők: `granted_at`, `granted_by_worker_id` (V173 seed 1:1-ben minden meglévő dolgozóra).

Tehát: **Company → VaultTerritory → Branch (pénztár/értéktár, parent_branch hierarchiával) → Worker**, a tényleges hozzáférést a `WorkerBranchAccess` ACL szabályozza.

**AI-ügynök utasítás:**
- Területi adat lekérdezésekor MINDIG `company_id`-ra szűrj, és vedd figyelembe a `WorkerBranchAccess` ACL-t — TILOS feltételezni, hogy egy dolgozó minden fiókot lát.
- A „pénztár vs. értéktár" megkülönböztetés a `Branch.is_vault` flag — ne a névből/kódból következtess rá.
- Új területi funkciónál tartsd a meglévő szinteket (Company / VaultTerritory / Branch / BranchGroup); ne vezess be párhuzamos hierarchiát.
- Fiók-hozzáférés bővítése csak `WorkerBranchAccess` rekorddal, `granted_by_worker_id` audit-mezővel; default-deny marad.

**Kódminta** – hozzáférés-ellenőrzés a `WorkerBranchAccess` ACL alapján, tenant-szűréssel:
```java
// Csak akkor engedünk műveletet egy fiókon, ha van explicit WorkerBranchAccess rekord
@PreAuthorize("isAuthenticated()")
public void assertBranchAccess(Long workerId, UUID branchId) {
    UUID companyId = SecurityUtils.getCurrentCompanyId();
    // a branch a saját tenant-é? (IDOR ellen) – idegen -> 404
    Branch branch = branchRepository.findByIdAndCompanyId(branchId, companyId)
        .orElseThrow(() -> new ResourceNotFoundException("VV-BRANCH-404"));
    boolean allowed = workerBranchAccessRepository
        .existsByWorkerIdAndBranchId(workerId, branch.getId());
    if (!allowed) {
        throw new AccessDeniedException("VV-ACL-403"); // default-deny
    }
}
```

---

## 4. A „Telephely" mező jelentése a felhasználóknál

**Kérdés:** Mit jelöl pontosan a "Telephely" mező a felhasználóknál, és hogyan kapcsolódik a területi struktúrához?

**Válasz:**
A repo tényei alapján:

- A **felhasználónál (Worker)** a „Telephely" gyakorlatilag a **munkahely = fiók (`Branch`)**. A `Worker.branch` mező kommentje szó szerint: *„Munkahely (iroda/fiók)"* (`entity/Worker.java:81-85`), kötelező `branch_id` FK-val. Ez köti a felhasználót a területi struktúrához: `Worker.branch_id → Branch → vault_territory_id → VaultTerritory`, illetve `Branch.company_id → Company`. Több fiók esetén a `WorkerBranchAccess` ACL bővíti.
- **Ez vizuálisan is megerősíthető:** a frontend fejléce a felhasználó fiók-nevét írja ki „Telephely" felirattal — `MainLayout`: `Telephely: {user?.branchName || 'Központi'}` (`frontend-react/src/stores/authStore.ts:66-67`). Tehát a UI „Telephely" mezője = a bejelentkezett dolgozó `branchName`-je (a `Branch` neve).
- **Külön, „telephely" nevű önálló törzs-mező a felhasználón (Worker) nincs** a `branch_id`-n túl. A „telephely cím" literál mező csak a **`VatRefundTransaction`** entitáson létezik: `siteAddress` (`entity/VatRefundTransaction.java:156` — „Telephely cím", legacy `TELEPHELYCIM`), ami egy ÁFA-visszatérítési tranzakció-attribútum, **nem a felhasználó törzsadata**.

**Összegzés:** felhasználónál a „Telephely" = a hozzárendelt **`Branch`** (munkahely, a UI-ban `branchName`), amin keresztül kapcsolódik a teljes területi hierarchiához (Branch → VaultTerritory → Company). A `VatRefundTransaction.siteAddress` egy ettől eltérő, VAT-refund-specifikus telephely-cím mező.

> Ha a kérdés egy konkrét UI-beli „Telephely" feliratra vonatkozik egy adott képernyőn, az a `Branch` (`branchName`) megjelenítése. A felhasználóhoz a `branch_id`-n túl nincs külön „telephely" törzs-mező.

**AI-ügynök utasítás:**
- Felhasználó-kontextusban a „Telephely" mezőt **a `Worker.branch` (Branch FK)**-ként kezeld; ne hozz létre új, duplikált „telephely" oszlopot a worker táblán. A UI-felirat (`branchName`) is ezt jeleníti meg.
- A `VatRefundTransaction.siteAddress` (telephely cím) mezőt TILOS összekeverni a felhasználó munkahelyével — az VAT-refund-specifikus.
- Ha terméktulajdonosi tisztázás kell (UI-felirat vs. adatmodell), kérdezz vissza, NE találgass.

**Kódminta** – a felhasználó „telephelye" = a Branch, a teljes hierarchia JOIN FETCH-csel (OSIV=false miatt):
```java
// Worker + branch egy lekérdezésben, LazyInit nélkül
@Query("""
    SELECT w FROM Worker w
    JOIN FETCH w.branch b
    WHERE w.id = :workerId AND w.company.id = :companyId
""")
Optional<Worker> findWithBranch(@Param("workerId") Long workerId,
                                @Param("companyId") UUID companyId);

// használat:
Worker w = workerRepo.findWithBranch(id, SecurityUtils.getCurrentCompanyId())
        .orElseThrow(() -> new ResourceNotFoundException("VV-WORKER-404"));
String telephelyNev = w.getBranch().getName();           // "Telephely" = Branch neve (branchName)
Integer teruletId   = w.getBranch().getVaultTerritoryId(); // kapcsolat a területi struktúrához
```

---

## 5. Szinkronizálás: pénztári Electron kliens (SQLite) ↔ központi PostgreSQL

**Kérdés:** Hogyan működik a szinkronizálás a pénztári Electron kliens (SQLite) és a központi PostgreSQL adatbázis között – különös tekintettel a törzsadatokra?

**Válasz:**
A pénztári kliens **local-first** mintát használ, ~30 mp-es polling push/pull ciklussal a `excvaluta.com` backend felé. Forrás: `penztar-client/electron/sync-engine.ts` (~1938 sor — valódi logika, nem stub), `penztar-client/electron/sqlite.ts` (~2795 sor), `api-proxy.ts`, backend `entity/SyncOutboxEvent.java` / `entity/SyncInboxEvent.java`, `repository/SyncOutboxRepository.java`. A `kozponti-client/electron/local-first.ts` dokumentálja a konfliktus-politikákat.

**A lokál SQLite tábla-típusai (`penztar-client/electron/sqlite.ts`):**

- **`pending_*` (felfelé menő, kliens-oldali outbox):** `pending_transactions`, `pending_conversions`, `pending_bank_transactions`, `pending_stornos`, `pending_handover_operations`, `pending_transfers`, `pending_distributions`, `pending_collections`, `pending_stocktake_items` + `local_audit_events`. Ezek a pénztáros által keletkező műveletek, amelyek várnak a felküldésre.
- **`cached_*` (lefelé jövő törzsadat-cache):** `cached_rates` (árfolyam), `cached_customers`, `cached_branch_status`, `cached_cash_desks` (branch master), `cached_workers`. Ezeket a kliens a backend API-ból tölti le, hogy offline is működjön.
- **`lf_*` (local-first vezérlés):** `lf_sync_state` (checkpoint), `lf_tombstone` (törlés-propagáció), `lf_conflict_log` (minden konfliktus naplózva manuális felülvizsgálatra).

**Két irány:**

1. **Felfelé (kliens → központ): tranzakciók.** A kliens először **lokálba ír** a `pending_*` táblákba (azonnali, offline működés), majd a háttér-szinkron felküldi a backendre. **Idempotency-kulcs** véd a duplikáció ellen hálózati újrapróbálkozásnál — backend oldalon `SyncOutboxEvent.idempotencyKey` (unique) + `SyncInboxEvent` (`payload_hash`, `source_node_id`, `status`) + `IdempotencyRecord`. A `pending_*` rekord `markXxxSynced` után kerül lezárásra; hiba esetén korlátos retry.

2. **Lefelé (központ → kliens): törzsadatok cache-elése.** A `cached_*` táblákat a backend API frissíti (árfolyam, fiók-státusz, cash desk, dolgozó). A szerver az igazságforrás.

**Konfliktus-politika (dokumentált, `kozponti-client/electron/local-first.ts`):**
- `branch_status`, `branch_balance`, `rates` (= **törzsadat**) → **`server_authority`**: szerver nyer, a kliens eldobja a lokál módosítást.
- `transactions` → kliens által keletkező, append-only: kliens nyer, szerver befogadja.
- `daily_closing`, `distribution`, `transfer` → `server_authority` (véglegesítés után immutable / szerver-párosítás).
- `settings` → `last_write_wins` (nem kritikus user-pref).
- Minden konfliktus a `lf_conflict_log`-ba kerül manuális felülvizsgálatra.

**Törzsadatra vonatkozó lényeg:** a törzsadat (árfolyam, fiók, címlet, dolgozó) **iránya a kliens felé egyirányú**, és konfliktusnál **`server_authority`** — a központi PostgreSQL az igazságforrás, a kliens csak cache-eli. A pénztáros által keletkező **tranzakciós adat** megy felfelé (append-only). Árfolyamnál a 24h TTL: **lejárt rátával nincs tranzakció** (`CLAUDE.md`).

**AI-ügynök utasítás:**
- Felfelé szinkronnál MINDIG `idempotency_key`-t használj; a backendnek idempotensnek kell lennie (`SyncOutboxEvent.idempotencyKey` unique / `SyncInboxEvent` / `IdempotencyRecord`). TILOS retry-nál új kulcsot generálni ugyanarra a tranzakcióra.
- Törzsadatot (árfolyam, fiók, címlet, dolgozó) a kliens **csak letölt és `cached_*` táblába cache-el**; konfliktusnál **`server_authority`** (szerver nyer). TILOS lokálból törzsadatot visszaírni a központba.
- Tranzakciós adat append-only — a `pending_*` táblába írj előbb (offline), majd háttérben küldd fel.
- Árfolyam használat előtt ellenőrizd a **24h TTL**-t; lejárt rátával TILOS tranzakciót rögzíteni.
- Konfliktust MINDIG naplózz a `lf_conflict_log`-ba; minden szinkron-hiba kapjon `VV-<KAT>-<3jegy>` error_code-ot. A retry legyen korlátos.
- Offline-first: a felhasználói művelet ELŐSZÖR lokálba ír (azonnali visszajelzés), a hálózati felküldés háttérben (polling), újrapróbálkozással történik.

**Kódminta** – tranzakció lokál `pending_*` táblába, idempotency-kulccsal, majd háttér-felküldés:
```ts
// 1) Lokál-first: a tranzakció azonnal az SQLite pending_transactions táblába kerül (offline is működik)
function enqueueTransaction(payload: TransactionRow) {
  const idempotencyKey = crypto.randomUUID();
  db.prepare(`
    INSERT INTO pending_transactions (client_uuid, currency_code, payload, created_at, idempotency_key)
    VALUES (@client_uuid, @currency_code, @payload, @created_at, @idempotency_key)
  `).run({
    client_uuid: crypto.randomUUID(),
    currency_code: payload.currencyCode,
    payload: JSON.stringify(payload),
    created_at: Date.now(),
    idempotency_key: idempotencyKey,
  });
}

// 2) Háttér-szinkron: felküldés ugyanazzal az idempotency-kulccsal (duplikáció ellen)
async function flushPending() {
  for (const row of getPendingTransactions()) {       // sqlite.ts helper
    try {
      const res = await fetch(`${API_BASE}/api/v1/transactions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json',
                   'Idempotency-Key': row.idempotency_key,
                   Authorization: `Bearer ${jwt}` },
        body: row.payload,
      });
      if (res.ok) markTransactionSynced(row.id);       // lezárás a pending_* táblában
    } catch (e) {
      vvLogger.error('VV-SYNC-001', `pending tx upload failed: ${row.id}`);
    }
  }
}
```

---

## Nyitott kérdések / a repo alapján nem egyértelmű pontok

- **Konfliktus-feloldás (5. kérdés):** a politika **dokumentált** (`kozponti-client/electron/local-first.ts`: `server_authority` a törzsadatra, append-only a tranzakcióra, `last_write_wins` a settings-re, `lf_conflict_log` naplózás). Ami a repóban nincs egy helyen összefoglalva: a **pénztári** kliens (`penztar-client`) és a **központi** kliens szinkron-implementációja eltérő érettségű, és a végpontok (`/central/sync/pull|push` vs. `/api/v1/...`) közti pontos leképezés szétszórt — nagy szinkron-változtatás előtt érdemes terméktulajdonosi/architekt egyeztetés.
- **„Telephely" UI-felirat (4. kérdés):** megerősítve, hogy a `MainLayout` „Telephely" felirata a `branchName`-t mutatja. Ha egy másik képernyőn a „Telephely" mást jelentene, az terméktulajdonosi tisztázást igényel — adatmodell szinten a felhasználónál a `branch_id` az irányadó.
- **Teljes táblalista:** nincs külön „egy fájlban a teljes séma" dokumentum; az igazságforrás a Flyway-migrációk (`V1..V277`) és az entity-osztályok.

> Ezeknél a pontoknál az AI-ügynöknek **vissza kell kérdeznie** (terméktulajdonostól), és TILOS feltételezésre építve kódot írnia.
