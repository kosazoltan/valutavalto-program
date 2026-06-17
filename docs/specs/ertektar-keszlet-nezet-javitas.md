# Spec: Értéktári készlet nézet javítása (FR-1..6)

Forrás: `Downloads/fejlesztesi-keres-ertektar-keszlet-nezet-javitas (1).md` (interjú-alapú kérés).
Branch: `feature/ertektar-keszlet-nezet-javitas`.

## Cél
Az "Értéktári készlet" nézet (`/inventory`, `InventoryPage.tsx`) megjelenítés- és viselkedés-javítása.

## Nem-cél (OUT)
- `currency_stock.quantity` adathibák javítása (TBD-1, külön).
- NYITÓKÉSZLET snapshot-táblából (marad a visszaszámolt logika).
- Pénztári készletek nézet, offline cache.

## TBD-feloldások (verifikált)
- **TBD-3 (DTO-mező eltávolítás más klienst tör-e):** NEM. Explore-audit: a `GET /api/v1/inventory/vault-stock`
  egyetlen fogyasztója az `InventoryPage.tsx:46`. Sem kozponti-client, sem CentralWorkstationPage, sem más
  kliens nem hívja → `difference`/`lastUpdated` eltávolítása biztonságos.
- **TBD-2 (auto-frissítés mechanizmus):** felhasználói döntés → **WebSocket/STOMP push (frontend+backend)**.

## FR → megvalósítás
- **FR-1/FR-2** (KÜLÖNBSÉG + FRISSÍTVE oszlop el): FE `InventoryPage.tsx` oszlopok + `VaultStockRow` mezők el;
  BE `VaultStockRowDto` `difference`+`lastUpdated` mező el; `InventoryService.getVaultStockFlow()` builder
  `.difference(ZERO)`/`.lastUpdated(...)` sorok el.
- **FR-4** (zebra) / **FR-5** (pozitív egyenleg kiemelés): FE, meglévő Tailwind design-tokenek; `closing > 0` →
  enyhe tónus, a 0-egyenlegtől elkülönítve.
- **FR-6** (nyomtatás): FE "Nyomtatás" gomb + `@media print` (csak a tábla 6 oszlopa + fejléc telephely+dátum;
  gombok/nav/HUF-kártya/megjegyzés elrejtve).
- **FR-3** (auto-frissítés átadás/átvétel COMPLETED-nél): WebSocket/STOMP.

## FR-3 design (contract — pénzmozgás-út side-effect)
- **Topic:** `/topic/vault-stock/{companyId}` (a frontend a `worker.companyId`-t ismeri; territoryId-t nem).
- **Publish hely:** `VaultStockFlowService` — minden vault `currency_stock` mentés után
  (`applyCollection`, `applyDistributionLine`, `applyGenericVaultStock`). `applyTransfer` NEM (csak cash_balance).
- **Payload:** minimális jelzés — `VaultStockChangedMessage{ companyId, territoryId, at }`. **Tilos** összeg/egyenleg
  (WS SUBSCRIBE nincs topic-szinten korlátozva; a tényleges adat a szerver-oldalon authorizált, territory-scope-olt
  `GET /vault-stock` re-fetchből jön).
- **Invariáns (KÖTELEZŐ):** a publish **NEM** befolyásolhatja a tranzakció kimenetét:
  - `TransactionSynchronization.afterCommit` — csak sikeres commit után publikál (rollbacknél nem).
  - fail-safe: a publish bármely hibája elnyelve (log), a COMPLETED tranzakció nem bukhat el miatta.
- **Frontend viselkedés:** `InventoryPage` STOMP feliratkozás a company-topicra; üzenetre **change-detection**-nel
  re-fetch (`GET /inventory/vault-stock`), és csak akkor `setState`, ha a (territory-scope-olt) válasz ténylegesen
  változott → **"más iroda/értéktár tranzakciója NEM triggereli a látható frissítést"** (a scope-olt válasz nem
  változik más territory mozgására). Auto-frissítés hibája: **silent fail** (NFR-5).

## Acceptance → teszt
- FR-1/2: vitest `InventoryPage` render → nincs KÜLÖNBSÉG/FRISSÍTVE oszlop; JUnit: `VaultStockRowDto`-nak nincs
  `difference`/`lastUpdated` mezője (reflection/builder).
- FR-3: JUnit `VaultStockFlowServiceTest` → `applyCollection/Distribution/GenericVaultStock` után
  `SimpMessagingTemplate.convertAndSend("/topic/vault-stock/{companyId}", …)` afterCommit meghívódik;
  `applyTransfer` után NEM. vitest: STOMP üzenetre change-detection (változatlan válasz → nincs re-render).
- FR-6: vitest → "Nyomtatás" gomb létezik és `window.print`-et hív.

## Multi-tenant / security
- Meglévő `@PreAuthorize` a `/vault-stock`-on változatlan. WS-topic companyId-scope; payload nem tartalmaz üzleti
  adatot. Cross-tenant: a re-fetch szerver-oldalon company+territory-scope-olt (változatlan védelem).
