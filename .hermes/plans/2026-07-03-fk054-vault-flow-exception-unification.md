# Terv: FK-054 — Vault-flow elégtelen-készlet hibák egységesítése (ValidationException, magyar üzenet)

Dátum: 2026-07-03 · Orchestrator: Fable 5 · Coder: gpt-5.5 · Reviewer: glm-5.2 (high)
Branch: `fix/fk054-vault-flow-exception-unification`
Eredet: GLM-5.2 reviewer #1 Medium finding a PR #1279 review-ban (pre-existing, scope-on kívül volt).

## Gyökérok

`CurrencyStock.issueStock()` (entity, L91-94) elégtelen készletnél `IllegalStateException`-t dob.
A `GlobalExceptionHandler` ezt NEM kezeli (csak ValidationException → 400) → a hívó felé
**HTTP 500 + technikai üzenet** megy, miközben az FK-053 fedezet-kapuk ugyanerre az esetre
**ValidationException → HTTP 400 + magyar, felhasználóbarát üzenet**-et adnak. Következetlen UX
és hibás szemantika (az 500 szerver-hibát jelez, pedig üzleti elutasítás).

## A megoldási elv

Az entity (`issueStock`) marad utolsó védvonalnak IllegalStateException-nel (belső invariáns).
A SZERVIZ-rétegben minden issueStock-hívás ELÉ fedezet-ellenőrzés kerül, amely elégtelen
készletnél `ValidationException`-t dob az FK-053 üzenet-mintájával — így az entity-kivétel
legálisan soha nem érhető el, csak valódi programhiba esetén.

## Task 1 (BE): előzetes fedezet-kapu minden szerviz-rétegű issueStock-hívás elé

Érintett hívási helyek (grep-audit 2026-07-03, mindegyikhez ELLENŐRIZD, van-e már elülső kapu):
1. `VaultStockFlowService.applyDistributionLine` (L97) — NINCS kapu → betenni.
2. `MaterialReceiptService` (L162) — ellenőrizd; ha nincs kapu, betenni.
3. `VaultBankTransactionService` (L113, L121) — ellenőrizd; ha nincs, betenni (bank-kivét ág).
4. `VaultTransferService` (L212) — ellenőrizd; ha nincs, betenni.
5. `ShipmentStockBookingService` (L257) — a d499a650 mintája valószínűleg már fail-closed; csak igazold.
6. `WacService.issueStock` (L83) — wrapper; a hívóit auditáld, ne duplázz kaput.

A kapu mintája (az FK-053-ban bevezetett `validateVaultStockCoverage` / azonos üzenetformátum):
"Nincs elegendő értéktári %s készlet! Elérhető: %s, szükséges: %s (…). A művelet nem hajtható
végre — készleten túli forgalmazás tiltva."
Ahol már van FK-053-kapu, NE duplázd — csak jelentsd.

## Task 2 (BE): GlobalExceptionHandler védőháló

Új handler: `IllegalStateException` a currency_stock kontextusból NEM kezelhető vaktában
(túl generikus típus) — ehelyett az entity üzenetére NEM támaszkodunk. DÖNTÉS: nem adunk
generikus IllegalStateException-handlert (az valódi 500-akat maszkolna); a védelem a Task 1
elülső kapuiból jön. Ezt kommentben dokumentáld a handlerben (miért nincs ISE-handler).

## Task 3 (tesztek — RED először)

- Minden Task 1-ben kapuzott útvonalra: elégtelen készlet → ValidationException (üzenet-assert,
  magyar), stock változatlan; elegendő készlet → művelet lefut.
- Regressziós: a meglévő happy-path tesztek zöldek maradnak.
- FIGYELEM (a mai tanulság): a teljes érintett tesztkör futtatása kötelező, nem csak targeted —
  az új mock-dependency-k miatt a régi fixture-öket is pótolni kell, ahol az érintett szervizekbe
  új függőség kerül.

## Verifikáció (coder futtatja, valós számokkal jelent)
- `cd backend && ./mvnw -q test` (TELJES suite) → 0 fail 0 error
- `cd backend && ./mvnw -q compile` → exit 0

## Nem-cél
- Az entity `issueStock` viselkedésének megváltoztatása (marad belső invariáns).
- FE-módosítás.
- A V338/FK-053 kód érintése.
