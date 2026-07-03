# Terv: FK-052 — Értéktári készlet panel (Mobil készlet-riportok) integrálása a vault/currency_stock modellre

Dátum: 2026-07-03 · Orchestrator: Fable 5 · Coder: gpt-5.5 · Reviewer: glm-5.2
Branch: `feat/fk052-inventory-vault-integration`
Döntés (user, 2026-07-03): B) INTEGRÁCIÓ — a panelt megtartjuk és rendesen bekötjük; nem vezetjük ki.

## Kontextus (kód-evidencia)

- `InventoryService.java` 4 write-op (bank-kivét L34-83, bank-befizetés L89-126, transfer L133-174, korrekció) KIZÁRÓLAG `cash_balance`-t ír. Vault branch-eknek V334 óta NINCS cash_balance sora → minden művelet "Nincs kassza egyenleg" hibával hal el vault-kontextusban.
- `approveMovement` (L182-216) / `receiveMovement` (L222-281) szintén `updateCashBalance`-t hív — vault-oldalon ez is halott.
- A záró készlet blokk (`/inventory/vault-stock`, `getVaultStockFlow` L646-740) HELYES: currency_stock VAULT sorokat olvas, amit a `ShipmentStockBookingService` (d499a650) ír. NEM nyúlunk hozzá.
- A "Cél telephely" mező (InventoryPage.tsx L742, submitInventoryOperation L532) nyers UUID-t vár szabad szövegként — nincs választó.
- A mozgásnapló vault-nézetben üres, mert vault-fiókról soha nem születhetett inventory_movement (a write-opok elhalnak).
- A 218M Ft: a currency_stock VAULT HUF sor V159/V332 base_capital seed-értéke. Ez ADAT-kérdés (lásd "Nem-cél / follow-up").

## Cél

Vault-kontextusban (worker branch-e is_vault=TRUE) a panel 4 művelete a currency_stock-ot mozgassa (a Shipment-oldali WAC-könyvelő mintájára), a mozgások inventory_movement-be íródjanak (napló élővé válik), és a Cél telephely mező igazi választó legyen. Nem-vault (pénztári) kontextus viselkedése VÁLTOZATLAN marad.

## Feladatok (TDD, mind a coder-é)

### Task 1 (BE): Vault-aware balance-elérés kiszervezése — `InventoryStockAccessor`
Új osztály: `backend/src/main/java/hu/puzzleir/valuta/service/InventoryStockAccessor.java`
- API: `BigDecimal getBalance(Branch, Currency)`, `void adjust(Branch, Currency, BigDecimal delta)`, `boolean isVaultContext(Branch)`.
- Nem-vault ág: pontosan a mai `cashBalanceRepository` viselkedés (elmozgatás az InventoryService-ből, változatlan szemantika).
- Vault ág: `currency_stock` (entityType='VAULT', entity_id = branch.vaultTerritoryId::TEXT) — a `ShipmentStockBookingService` L236-283 mintája szerint (ugyanaz a lookup + save; WAC unit_cost-ot NEM módosítjuk, csak quantity-t). Ha a vault branch-nek nincs vaultTerritoryId-ja → ValidationException (fail-closed, magyar hibaüzenettel).
- Multi-tenant: companyId minden lekérdezésben.

### Task 2 (BE): A 4 write-op + approve/receive átkötése az accessorra
`InventoryService.java`:
- `withdrawFromBank`, `depositToBank`, `transferBetweenBranches`, `correctStock` + `approveMovement`/`receiveMovement` balance-olvasás/írás → accessor.
- Elégségesség-ellenőrzés vault-ágon a currency_stock quantity ellen.
- Transfer szabályok: vault→vault (két territory közti currency_stock mozgás), vault→pénztár (vault quantity csökken, cél cash_balance nő), pénztár→vault (fordítva). A meglévő PENDING→APPROVED/IN_TRANSIT→RECEIVED státuszgép és a receivedAmount/difference audit VÁLTOZATLAN.
- A mozgásnapló (inventory_movement) minden vault-műveletre ugyanúgy íródik, mint eddig pénztárira.

### Task 3 (BE): Transfer-cél választó endpoint
`InventoryController`: `GET /inventory/transfer-targets` → `[{branchId, code, name, isVault}]`.
- Scope: companyId + aktív branch-ek + territory-scoped role esetén a TerritoryScopeResolver szerinti szűkítés; a hívó saját branch-e kizárva; VAULT_COUNTERPARTY virtuális partnerek kizárva (FK-032 minta).
- @PreAuthorize: ugyanaz a role-halmaz, mint a /inventory/transfer-é.

### Task 4 (FE): Cél telephely dropdown
`InventoryPage.tsx`: a szabad szöveges input helyett `<select>`, a /inventory/transfer-targets-ből töltve (lazy: transfer művelet kiválasztásakor). Formátum: `KÓD — Név`. A submit a kiválasztott branchId-t küldi. Ha a lista üres → disabled select + magyarázó szöveg. i18n kulcsokkal.

### Task 5 (FE): Vault-kontextus jelzés
A "Backend: inventory + inventory-movements / saját telephely" alcím vault-worker esetén egészüljön ki: "értéktári (currency_stock) könyvelés" — hogy látszódjon, melyik rezsim él. (Worker branch isVault flag már elérhető a bootstrapból; ha nincs, a vault-stock válasz nem-ürességéből következtethető — a coder ellenőrizze és a valós forrást használja.)

### Task 6 (tesztek — RED először)
- BE: `InventoryStockAccessorTest` (vault/nem-vault ág, fail-closed, tenant-szűrés), `InventoryServiceVaultTest` (vault bank-kivét/befizetés/transfer/korrekció happy path + elégtelen készlet + vault→pénztár átadás mindkét oldala jóváírva/terhelve + mozgásnapló-sor születik). Meglévő InventoryService tesztek VÁLTOZATLANUL zöldek (pénztári rezsim nem változott).
- FE: InventoryPage.test.tsx bővítés — transfer-cél dropdown render + üres-lista ág; meglévő tesztek zöldek.

## Nem-cél / follow-up (ITT ÁLLJ MEG, ne implementáld)
- A 218M Ft seed-érték számszerű korrekciója: DATA-ONLY — élő diag + üzleti jóváhagyás kell hozzá (base_capital vs. valós leltár). Külön menet.
- A vault-stock olvasó útvonal (getVaultStockFlow) refaktora.
- Shipment/Transfer alrendszer bárminemű módosítása.

## Verifikáció (coder futtatja, jelenti)
- `cd backend && ./mvnw -q test -Dtest='Inventory*Test'` → PASS
- `cd backend && ./mvnw -q compile` → PASS
- `cd frontend-react && npx vitest run src/pages/inventory` → PASS
- `cd frontend-react && npx tsc --noEmit` → PASS

## Kényszerek
- ⛔ Teszt gyengítése/törlése TILOS. Meglévő viselkedés (pénztári rezsim) bit-azonos.
- Pénzmozgás-kód: minden ág tranzakcióban, fail-closed, magyar hibaüzenetek, BigDecimal (soha double).
- Diff-fegyelem: CSAK a fenti fájlok + tesztek. Semmi lockfile, semmi verzió-bump.
