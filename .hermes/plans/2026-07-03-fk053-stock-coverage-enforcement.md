# Terv: FK-053 — Készlet-fedezet kényszer (fail-closed) minden pénzmozgási útvonalon

Dátum: 2026-07-03 · Orchestrator: Fable 5 · Coder: gpt-5.5 · Reviewer: glm-5.2 (high)
Branch: `fix/v338-vault-stock-anomaly-repair` (a V338-cal együtt megy, egy PR)
User-direktíva: "nulla készletből nem lehet eladni... minden készletnél tilos a készleten
túl vásárolni, eladni, forgalmazni." Alaplogika: FEDEZET NÉLKÜL NINCS PÉNZMOZGÁS — sehol.

## Gyökérok (élő bizonyíték)
T938 transfer (2026-06-01): Szeged Értéktár (vault) → BR035, 5000 EUR COMPLETED úgy, hogy
a vault könyvelt EUR-készlete 0 volt. A `VaultStockFlowService.applyGenericVaultStock`
(L167-172) elégtelen készletnél WARN + FOLYTATÁS + negatív stock. Emellett a transfer
LÉTREHOZÁSAKOR a vault-oldalon csak a cash_balance-t ellenőrzi a kód (decreaseCashBalance),
a currency_stock fedezetet SOHA.

## A védelmi elv (minden taskra érvényes)
- ELÖL ellenőrzünk (művelet-indításkor, pessimistic lockkal), és fail-closed dobunk
  magyar hibaüzenettel — a felhasználó felé a UI a hibaüzenetet mutatja (meglévő minta).
- A "mirror" (utólagos könyvelő) útvonalak SOHA nem vihetik negatívba a stockot: ha
  mégis elégtelen (nem szabadna előfordulnia az elülső kapu után), ValidationException —
  a tranzakció visszagördül, a pénzmozgás nem jön létre félig.

## Task 1 (BE): applyGenericVaultStock fail-closed
`VaultStockFlowService.java` L167-172: a WARN+folytatás ág helyett:
```java
} else if (stock.getQuantity().compareTo(amount) < 0) {
    throw new ValidationException(String.format(
        "Nincs elegendő értéktári %s készlet! Elérhető: %s, szükséges: %s (territory: %s). "
        + "A művelet nem hajtható végre — készleten túli forgalmazás tiltva.",
        currencyCode, stock.getQuantity().toPlainString(), amount.toPlainString(), territoryId));
}
```
A régi komment ("a pénz fizikailag már mozgott") a mirror-útvonal utólagosságára épült —
az elülső kapuk (Task 2-3) bevezetése után ez az állapot nem állhat elő legálisan; ha mégis,
az adathiba, amit blokkolni kell, nem elkönyvelni.

## Task 2 (BE): Transfer-létrehozás vault-fedezet kapu
`TransferService` create/receive útvonalain: ahol a FORRÁS branch vault (isVault=TRUE),
a cash_balance ellenőrzés MELLETT a currency_stock fedezetet is ellenőrizni kell
(territoryId + currencyCode, FOR UPDATE lock, quantity >= amount, különben ValidationException
a Task 1 üzenet-mintájával). Multi-line transfernél soronként. A sztornó-visszaforgató ág
(increase) változatlan.

## Task 3 (BE): Tranzakciós (pénztári adás-vétel) útvonal audit + vault-ág
`TransactionService.validateCurrencyStock` MÁR fail-closed a cash_balance-ra (SELL: deviza-
készlet, BUY: HUF-készlet — L341/L529 hívások). Ellenőrizd: (a) vault-branchen futó tranzakció
esetén a currency_stock fedezet IS ellenőrzendő (ha vault-branchen egyáltalán lehet pénztári
tranzakció — ha nem lehet, dokumentáld kommentben és assert-eld tesztben); (b) NINCS más
útvonal, ami updateCashBalance-t hív validateCurrencyStock nélkül — grep-audit az összes
cash_balance-írásra (updateBalance hívók), és ahol nincs elülső fedezet-kapu és csökkentés
történik, tedd be. A lelet-listát írd a jelentésedbe.

## Task 4 (tesztek — RED először)
- `VaultStockFlowServiceTest`: elégtelen vault-készlet → ValidationException (nem WARN),
  pontos üzenet-assert; elegendő készlet → issueStock fut; increase-ág változatlan.
- `TransferServiceVaultCoverageTest` (új): vault-forrású transfer 0 stockkal → exception,
  a cash_balance NEM változik (rollback-assert); fedezettel → lefut, stock csökken.
- Meglévő tesztek: ha volt olyan teszt, amely a régi "folytatva" viselkedést kódolta,
  az a RÉGI HIBÁS spec-et rögzítette — ezt a tervi döntést idézve (user-direktíva
  2026-07-03: készleten túli forgalmazás tiltva) írd át a fail-closed elvárásra, és
  jelezd a jelentésben (ez dokumentált spec-változás, nem teszt-gyengítés: SZIGORÍTÁS).

## Verifikáció
- `cd backend && ./mvnw -q test -Dtest='VaultStockFlow*Test,Transfer*Test,Transaction*Test,Inventory*Test'` → PASS
- `cd backend && ./mvnw -q compile` → PASS

## Nem-cél
- FE-módosítás (a hibaüzenet-megjelenítés meglévő mintán fut).
- A V338 migráció (külön terv, ugyanezen a branchen már készül).
- Shipment-útvonal: a ShipmentStockBookingService már fail-closed mintájú — csak ellenőrizd
  és a jelentésben erősítsd meg (ha mégsem, jelezd, NE javítsd engedély nélkül).
