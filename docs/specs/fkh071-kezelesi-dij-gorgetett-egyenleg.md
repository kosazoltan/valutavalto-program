# Modul: Pénztári felület – FKH-071: "Kezelési díj címletezése" Elvárt-egyenleg görgetése (napi reset megszüntetése)

> **Claim correction (Phase 0):** Flyway slot V393 is occupied by FK-13; this feature uses `V394__handling_fee_balance.sql`.
>
> **Feltérképező analízis alapja:** Feltérképezés #132 (FKH-070 megvalósulás), #133 (görgetési hipotézis megerősítése), #134 (Claude Code, kizárólag olvasott kódelemzés — technikai beillesztési pontok).
> **Előzmény:** élő megfigyelés (2026-09-14) — az FKH-070 (élesben, PR #1756) helyesen mutatja az aznapi kezelési díjat Elvárt-ként (100 EUR vétel → 290 Ft Elvárt, 0 Ft eltérés). A felhasználó (Értéktáros szerepkör) ugyanakkor megerősítette: a beszedett kezelési díj **fizikailag a pénztárfiókban halmozódik**, amíg az Értéktár ténylegesen el nem kéri/át nem veszi — ez **nem feltétlenül napi** esemény. A Feltérképezés #133 kódszinten megerősítette: a jelenlegi HANDLING_FEE self-check **naponta nullázódik** (`transactionDate = :date`), szemben a HUF/valuta készlettel és a VAT-egyenleggel, amelyek már ma is **görgetett, perzisztens futóegyenlegek**. Ez architekturális aszimmetria és funkcionális hiba: ha egy korábbi napról marad be nem fizetett kezelési díj a fiókban, a következő nap Elvárt-ja alulbecsüli a valós, fizikailag ott lévő összeget.

---

## Összefoglaló a fejlesztőnek

A "Kezelési díj címletezése" oldal Elvárt-ját jelenleg minden nap újraszámolja a rendszer, kizárólag az aznapi tranzakciós kezelési díjból. Ehelyett egy **görgetett, branch-enkénti, perzisztens HUF-egyenleget** kell bevezetni — pontosan úgy, ahogy ma már a HUF/valuta készlet (`CashBalance`) és az ÁFA-ellátmány (`VatSupplyStock`) is működik. Az egyenleg **nő** minden kezelési díjat tartalmazó tranzakciónál, és **azonnal csökken**, amint a Pénztár létrehozza a KK-előtagú kezelésidíj-szállítmányt (nem kell megvárni az Értéktár jóváhagyását). A legközelebbi, ma is működő minta a `VatSupplyStock` (adatmodell) és a `CashBalance` (concurrency-védelem, pesszimista zárolás — ez utóbbi mellett döntött a felhasználó).

---

## 1. Cél

A "Kezelési díj címletezése" oldal Elvárt készlete a pénztárban ténylegesen felhalmozott, még be nem fizetett kezelési díjat tükrözze folyamatosan, napi nullázódás nélkül — mert a fizikai pénz a fiókban marad, amíg az Értéktár el nem kéri.

## 2. Scope

### IN
- Új, branch-enkénti, görgetett HUF-egyenleg entitás bevezetése kezelési díjra (`HandlingFeeBalance`), a `VatSupplyStock` adatmodell-mintáját követve, de `CashBalance`-szintű concurrency-védelemmel (pesszimista sor-zár + `@Version`).
- **Növelés:** minden BUY/SELL tranzakció mentésekor (`TransactionService`), amikor a `serverHandlingFee` > 0, az egyenleg nő ugyanazzal az összeggel, **ugyanabban a `@Transactional` blokkban**, ahol a `cash_balance` frissítés is történik ma (BUY: 456/462-463. sor környéke; SELL: 687. sor környéke).
- **Csökkentés:** amikor a Pénztár létrehozza a KK-előtagú kezelésidíj-szállítmányt (`ShipmentHandlingFeeService.create`), az egyenleg **azonnal**, a create pillanatában csökken a szállítmány HUF-összegével (`hufAmount`, NEM a jóváhagyás/átvétel után).
- **Visszafordítás (szállítmány-visszavonás):** ha a KK-szállítmányt `CANCELLED`-re állítják (`ShipmentService.cancel` → `ShipmentHandlingFeeSyncService.syncFromShipment`), az egyenleg visszanő ugyanazzal az összeggel.
- **Visszafordítás (sztornó):** ha egy kezelési díjat tartalmazó tranzakciót sztornóznak (`StornoService`), az egyenleg csökken a sztornózott tranzakció kezelési díjával (mert az soha nem volt valós, fiókban lévő pénz).
- A `DenominationBalanceService` HANDLING_FEE self-check ága ezt az új görgetett egyenleget olvassa Elvárt-ként, a jelenlegi napi `transactionRepository.sumHandlingFeeForBranchAndDate(...)` hívás helyett.
- Új Flyway migráció (V394) az új tábla létrehozására, `current_balance NUMERIC(18,2) NOT NULL DEFAULT 0`-val — **nincs történeti backfill**, a számláló a bevezetés napjától indul 0-ról (üzleti döntés, ld. 10. szekció).
- Nem-negatív adatbázis-szintű CHECK constraint (`current_balance >= 0`), és alkalmazásszintű validációs hiba, ha egy KK-szállítmány létrehozása negatívba vinné az egyenleget (nem lehet többet elvinni, mint amennyi ténylegesen fel van halmozva).

### OUT
- A "Pillanatnyi pénztárállás" oldal "Beszedett kezelési díj" mezője (`LiveCashPositionService`) — **marad napi**, változatlan; ez egy másik, külön funkció, nem az itt tárgyalt self-check.
- A `ShipmentHandlingFee`/KK-folyamat egyéb működése (UI, díjszámítás, `calculatedFee`) — nem módosul, csak a self-check egyenlegre gyakorolt hatása bővül. A `calculatedFee` (a szállítmány saját, esetleges kezelési díja) **nem** befolyásolja ezt a görgetett egyenleget — külön fogalom, kívül esik a scope-on.
- Történeti/visszamenőleges backfill a bevezetés előtti időszakra — a rendszer jelenleg teszt-üzemben van, a bevezetés előtti adatok nem relevánsak (felhasználói döntés, 2026-09-14).
- A VAT self-check kategória módosítása — az már ma is helyesen görgetett (`VatSupplyStock`), nem érintett.
- Frontend módosítás — a "Kezelési díj címletezése" oldal ugyanazt a self-check választ olvassa ma is; a mögöttes Elvárt-számítás változik, a felület nem.

## 3. Szakterületi szereplők (RBAC mátrix)

Nem alkalmazandó — a self-check megjelenítés és a KK-szállítmány létrehozás jogosultsági köre változatlan; ez a kérés kizárólag a háttérben futó számítási forrást és egy új, csak szerver-oldali adatmodellt érint.

## 4. Funkcionális követelmények (FR)

| ID | Leírás | Forrás | Prioritás | Csomag | Acceptance (Given/When/Then) |
|---|---|---|---|---|---|
| FR-1 | Új `HandlingFeeBalance` görgetett egyenleg nő minden kezelési díjas BUY/SELL tranzakciónál | Interjú (2026-09-14) + Feltérképezés #134 | MUST | backend | Adott: egy pénztárban aznap 290 Ft kezelési díjjal járó vétel történt. Amikor: a tranzakció mentésre kerül. Akkor: a `HandlingFeeBalance.currentBalance` 290 Ft-tal nő. |
| FR-2 | A növelés ugyanabban a `@Transactional` blokkban, pesszimista sor-zárral történik, mint a `cash_balance` frissítés | Feltérképezés #134 (CashBalance-minta) + felhasználói döntés (2026-09-14, "szigorúbb" védelem) | MUST | backend | Adott: két egyidejű tranzakció ugyanabban a pénztárban, mindkettő kezelési díjjal. Amikor: párhuzamosan mentődnek. Akkor: a végső egyenleg mindkét díj összegét helyesen tartalmazza (nincs elveszett frissítés). |
| FR-3 | A `HandlingFeeBalance` az adott napi Elvárt-számítás forrása, görgetve (nem napi reset) | Interjú (2026-09-14) + Feltérképezés #133 | MUST | backend | Adott: X. napon 290 Ft kezelési díj gyűlt, be nem fizetve; X+1. napon újabb 150 Ft. Amikor: X+1. napon megnyílik a "Kezelési díj címletezése" oldal. Akkor: az Elvárt **440 Ft** (nem 150 Ft). |
| FR-4 | A KK-szállítmány létrehozásakor (create pillanatában) az egyenleg azonnal csökken a szállítmány HUF-összegével | Interjú (2026-09-14) + Feltérképezés #134 | MUST | backend | Adott: a `HandlingFeeBalance` 440 Ft. Amikor: a Pénztár egy 440 Ft-os KK-szállítmányt hoz létre. Akkor: az egyenleg azonnal 0 Ft-ra csökken (nem kell megvárni az Értéktár jóváhagyását). |
| FR-5 | Ha a KK-szállítmányt visszavonják (`CANCELLED`), az egyenleg visszanő | Feltérképezés #134 | MUST | backend | Adott: a fenti 440 Ft-os szállítmány létrejött (egyenleg 0 Ft). Amikor: a szállítmányt visszavonják. Akkor: az egyenleg visszaáll 440 Ft-ra. |
| FR-6 | Sztornózott, kezelési díjat tartalmazó tranzakció visszafordítja az egyenleg-növelést | Feltérképezés #134, konzisztencia a self-check meglévő sztornó-szűrésével | MUST | backend | Adott: egy 290 Ft kezelési díjas tranzakciót rögzítettek (egyenleg +290 Ft). Amikor: a tranzakciót sztornózzák. Akkor: az egyenleg visszaáll a sztornó előtti értékre (−290 Ft). |
| FR-7 | Az egyenleg nem mehet negatívba — védelem KK-szállítmány létrehozásakor | Adatintegritás (interjú) | MUST | backend | Adott: a `HandlingFeeBalance` 100 Ft. Amikor: valaki 150 Ft-os KK-szállítmányt próbál létrehozni. Akkor: a művelet elutasításra kerül validációs hibával, az egyenleg nem változik. |
| FR-8 | A "Pillanatnyi pénztárállás" napi "Beszedett kezelési díj" mező változatlan marad (regresszió-védelem) | Feltérképezés #132 (élő teszt, 2026-09-14) | MUST | penztar-client (regresszió-védelem, nincs új fejlesztés) | Adott: a módosítás után egy nap, amikor volt kezelési díj. Amikor: a "Pillanatnyi pénztárállás" oldal betölt. Akkor: a "Beszedett kezelési díj" változatlanul csak az aznapi összeget mutatja. |

## 5. Nem-funkcionális követelmények (NFR)

| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-1 | HUF kerekítés | `HungarianRounding.roundToFive` minden `HandlingFeeBalance`-műveletnél, a `CashBalance`/`VatSupplyStock` mintájával konzisztensen. |
| NFR-2 | Teljesítmény | A pesszimista sor-zár overhead-je elhanyagolható — ugyanaz a minta fut ma is minden BUY/SELL tranzakciónál a `cash_balance` frissítésénél. |
| NFR-3 | Multi-tenant izoláció | `HandlingFeeBalance` egyedisége `(company_id, branch_id)` — cross-tenant teszt kötelező (§1). |
| NFR-4 | Lokalizáció | hu-HU, változatlan — nincs UI-módosítás. |

## 6. Adatmodell-érintettség

- **Új tábla szükséges: IGEN** — `handling_fee_balance`.
- Mezők (a `CashBalance`/`VatSupplyStock` mintája szerint):
  - `id UUID DEFAULT gen_random_uuid() PRIMARY KEY`
  - `company_id UUID NOT NULL`
  - `branch_id UUID NOT NULL`
  - `current_balance NUMERIC(18,2) NOT NULL DEFAULT 0`
  - `version BIGINT NOT NULL DEFAULT 0` (optimista lock, `CashBalance` mintája)
  - `updated_at TIMESTAMP NOT NULL DEFAULT NOW()`
  - `CONSTRAINT chk_hfb_balance_nonnegative CHECK (current_balance >= 0)`
  - `CONSTRAINT ux_hfb_company_branch UNIQUE (company_id, branch_id)`
  - Index: `ix_hfb_company_branch ON handling_fee_balance (company_id, branch_id)`
- **Flyway migráció:** `backend/src/main/resources/db/migration/V394__handling_fee_balance.sql` (V393 occupied by FK-13; Phase 0 claim correction).
- **Kezdőérték:** `DEFAULT 0`, get-or-create az első könyveléskor (nincs backfill-lel számolt kezdőérték — üzleti döntés, 10. szekció).
- **SQLite mirror:** nem szükséges — ez egy szerver-oldali, önellenőrző (self-check) számítási forrás, nem jelenik meg önálló offline entitásként (a self-check válasz maga már ma is szinkronizált mintát követ).

## 6.b Biztonsági érintettség (security-standards.md hivatkozással)

- [ ] Új jogosultság / szerep — nincs (§2 nem érintett)
- [x] PII / pénzügyi adat — igen, pénzügyi egyenleg (§3): a mögöttes tranzakció (BUY/SELL) és a KK-szállítmány már ma is auditált (`TX` KAT); a `HandlingFeeBalance` módosítás ezek származékos, könyvelési hatása — **nem igényel önálló, új audit-eseményt**, de a `HandlingFeeBalanceService` metódusaiban javasolt logolás hibakereséshez (nem kötelező audit_log bejegyzés).
- [x] Cross-tenant teszt szükséges (§1) — igen, ld. NFR-3.
- [ ] Új audit-esemény (§3 KAT) — nem szükséges (ld. fent).
- [ ] Secret / kulcs kezelést érint (§4) — nem.
- [ ] Offline szinkron biztonságát érinti (§5) — nem, szerver-oldali self-check forrás.
- [ ] Új végpont (§2) — nem, meglévő self-check végpont válaszának forrása változik.

## 7. Függőségek

- `TransactionService` (BUY: 400/456/462-463. sor környéke; SELL: 631/687. sor környéke) — növelési hook.
- `ShipmentHandlingFeeService.create(...)` (39-72. sor) — csökkentési hook, `hufAmount` (40. sor).
- `ShipmentService.cancel(...)` (545. sor) → `ShipmentHandlingFeeSyncService.syncFromShipment(...)` (33-54. sor) — visszafordítási hook.
- `StornoService` — sztornó-visszafordítási hook.
- `DenominationBalanceService.selfCheck` HANDLING_FEE ág (385-394. sor) — Elvárt-forrás cseréje.
- Referencia-minták: `CashBalance` / `CashBalanceRepository` (pesszimista zár), `VatSupplyStock` / `ShipmentVatSupplySyncService` (adatmodell, get-or-create, nonneg guard) — mindkettő Feltérképezés #134-ben azonosítva, fájl+sor hivatkozással.

## 8. Domain-szótár

| Fogalom | Magyarázat |
|---|---|
| `HandlingFeeBalance` (kezelésidíj-egyenleg) | Új, branch-enkénti, görgetett HUF-összeg, amely a pénztárban ténylegesen felhalmozott, még az Értéktárnak be nem fizetett kezelési díjat tükrözi. Nem napi, hanem folyamatos futóegyenleg — a HUF/valuta készlet (`CashBalance`) és az ÁFA-ellátmány (`VatSupplyStock`) mintájára. |
| KK-szállítmány (`ShipmentHandlingFee`) | A Pénztár által a felhalmozott kezelési díj Értéktár felé történő átadásakor, kézzel létrehozott, KK-előtagú szállítmány. A create pillanatában (nem jóváhagyáskor) csökkenti a `HandlingFeeBalance`-t. |

## 9. Végrehajtási utasítás az AI-fejlesztő ügynöknek

### 9.1. Előkészítés
1. `cd C:\repo\valutavalto-program`
2. `git pull`
3. `git checkout -b fix/kezelesi-dij-gorgetett-egyenleg`

### 9.2. Fázisok

**Fázis 1 – Adatmodell**
- Flyway: `backend/src/main/resources/db/migration/V394__handling_fee_balance.sql` — a 6. szekcióban megadott séma szerint (mintaként ld. `V382__shipment_vat_supply.sql`).
- Új entitás: `HandlingFeeBalance.java` — mezők a `CashBalance.java` mintájára (`id`, `company`, `branch`, `currentBalance`, `version`, `updatedAt`).
- Új repository: `HandlingFeeBalanceRepository.java` — `findByBranchIdAndCompanyId(...)` (olvasáshoz) és `findByBranchIdAndCompanyIdForUpdate(...)` `@Lock(LockModeType.PESSIMISTIC_WRITE)`-dal (íráshoz), a `CashBalanceRepository.java:66-69` mintájára.
- Új service: `HandlingFeeBalanceService.java` — `increase(branchId, companyId, amount)` és `decrease(branchId, companyId, amount)` metódusok, get-or-create logikával (ha még nincs sor, 0-ról indul), pesszimista zár + `roundToFive`. A `decrease` dobjon `ValidationException`-t (megfelelő `VV-VALID-*` error_code-dal), ha az eredmény negatív lenne (FR-7).
- Acceptance: `mvn -pl backend flyway:migrate` PASS + TestContainers integrációs teszt.

**Fázis 2 – Backend logika**
- `TransactionService`: BUY (kb. 456. sor után) és SELL (kb. 687. sor után) — ha `serverHandlingFee` > 0, hívás: `handlingFeeBalanceService.increase(branchId, companyId, serverHandlingFee)`, ugyanabban a `@Transactional` blokkban, mint a meglévő `updateCashBalance(...)` hívás.
- `ShipmentHandlingFeeService.create(...)`: a `hufAmount` kiszámítása után (kb. 40. sor után) hívás: `handlingFeeBalanceService.decrease(branchId, companyId, hufAmount)`.
- `ShipmentHandlingFeeSyncService.syncFromShipment(...)` (33-54. sor): ha `shipment.getStatus() == CANCELLED` és a fee korábbi státusza nem volt már `CANCELLED`, hívás: `handlingFeeBalanceService.increase(branchId, companyId, fee összege)`.
- `StornoService`: a sztornó-folyamatban, ha a sztornózott tranzakciónak volt `handlingFee`-je, hívás: `handlingFeeBalanceService.decrease(branchId, companyId, handlingFee)`.
- `DenominationBalanceService.java:385-394`: a HANDLING_FEE self-check ág Elvárt-forrása cserélődik `transactionRepository.sumHandlingFeeForBranchAndDate(...)`-ról `handlingFeeBalanceRepository.findByBranchIdAndCompanyId(...).map(HandlingFeeBalance::getCurrentBalance).orElse(BigDecimal.ZERO)`-ra, `roundToFive`-dal.
- Acceptance: `mvn -pl backend test` PASS, coverage ≥80%, JUnit XML artifact.

**Fázis 3 – Frontend**
- Nincs szükséges módosítás — a "Kezelési díj címletezése" oldal ugyanazt a self-check választ olvassa (FR-8, regresszió-védelem).

**Fázis 4 – Tesztek**
- JUnit (backend), min. happy path + edge case-ek:
  - Görgetés két nap között (FR-3: 290 Ft + 150 Ft = 440 Ft).
  - KK-szállítmány csökkentés (FR-4).
  - KK-szállítmány visszavonás → visszafordítás (FR-5).
  - Sztornó → visszafordítás (FR-6).
  - Negatív egyenleg elutasítása (FR-7).
  - Cross-tenant teszt: két tenant `HandlingFeeBalance`-a nem keveredik (NFR-3, §1).
  - Concurrency teszt: párhuzamos tranzakciók pesszimista zárral, nincs elveszett frissítés (FR-2).
- Regresszió: `DenominationBalanceServiceTest`, `DenominationBalanceHandlingFeeExpectedFkh070Test` frissítése az új forrásra.

### 9.3. Pipeline (Definition of Done)
1. `lint` PASS (checkstyle)
2. `mvn verify` PASS
3. `gitleaks` secret-scan PASS (§4)
4. `grep -r "@Disabled\|@Ignore\|skip("` → 0 találat új kódon
5. Code review PR (1 reviewer)
6. `merge` → `push` → `deploy` → új telepítő generálása

## 10. Kockázatok / Nyitott kérdések (TBD)

Nincs nyitott TBD — minden tervezési döntés lezárva a Feltérképezés #132–#134 és az interjú (2026-09-14) alapján:
- Görgetési modell: perzisztens futóegyenleg (nem élő újraszámolás) — felhasználói döntés.
- Elszámolás pillanata: a KK-szállítmány **létrehozásakor**, nem jóváhagyáskor — felhasználói döntés.
- Kezdőérték: 0-ról indul a bevezetés napján, nincs történeti backfill (teszt-üzem) — felhasználói döntés.
- Concurrency-védelem: pesszimista sor-zár, `CashBalance` mintája — felhasználói döntés.

## 11. Kapcsolódó modulok
- [x] Pénztári felület (kezdeményező)
- [x] Értéktári felület (az Értéktár a görgetett összeget nézi, amikor eldönti, mikor kéri el a kezelési díjat)
- [ ] Árfolyamkészítő
- [ ] Központi kliens

## 12. Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás (Interjú / Feltérképezés #132–#134)
- [x] Minden FR-hez Acceptance Given/When/Then
- [x] NFR-ek számszerűsítve, ahol értelmezhető
- [x] Nincs hallucináció — minden állítás a feltérképezések tényeire és a felhasználói döntésekre épül
- [x] TBD-ek külön jelölve (0 db — mind lezárva)
- [x] Adatmodell konkrét (`handling_fee_balance` tábla, mezők, `company_id` + `branch_id`)
- [x] Flyway migráció száma helyes (V394, jelenlegi max V393 / FK-13)
- [x] Pipeline + Definition of Done teljes
- [x] Cross-tenant teszt megírva (§1, NFR-3)
- [x] Audit-érintettség vizsgálva és indokolva (§3 — nem igényel új eseményt)
- [x] Nincs hard-coded secret (§4)
- [x] Regresszió-védelem explicit jelölve (FR-8)

---
FR-ek száma: 8 db
TBD-ek száma: 0 db
Érintett csomagok: backend (kizárólag — a frontend self-check panel már létezik, nincs UI-módosítás)
