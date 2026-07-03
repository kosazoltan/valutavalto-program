# Terv: V338 — vault currency_stock anomália-korrekció a mozgás-alapú levezetett értékre

Dátum: 2026-07-03 · Orchestrator: Fable 5 · Coder: gpt-5.5 · Reviewer: glm-5.2 (high effort)
Branch: `fix/v338-vault-stock-anomaly-repair`
User-döntés (2026-07-03): B) — a stock a DB-ből levezetett VALÓS értékre igazítandó.

## Élő diagnózis (Neon, 2026-07-03, run 28643631686 + kézi D7-levezetés)

Levezetett készlet = vault_territory.base_capital (HUF seed) + lezárt mozgások nettója
(DELIVERED shipmentek + COMPLETED transferek; inventory_movement historikusan 0 sor).

| Territory | Valuta | Stock MOST | Levezetett | Eltérés (stock − levezetett) |
|---|---|---|---|---|
| 1 (Fő Értéktár) | HUF | 99 582 500 | 100 000 000 | **−417 500** |
| 1 (Fő Értéktár) | EUR | 950 | 0 | **+950** |
| 4 (Szeged) | EUR | 0 | −5 000 | **+5 000** (negatívba nem mehet → lásd szabály) |
| minden más sor | | | | 0 (konzisztens, NEM érintendő) |

Értelmezés: a Fő Értéktár eltérései V332 előtti, könyveletlen kézi állítások maradványai;
a Szeged −5000 EUR a transfer #938 (COMPLETED, EUR 5000 kivét) úgy futott le, hogy a
stock-oldalon nem volt EUR fedezet (a régi kód nem a stockot terhelte).

## Korrekciós szabály (KRITIKUS — a coder pontosan ezt implementálja)

1. **Territory 1 HUF: 99 582 500 → 100 000 000** (delta +417 500).
2. **Territory 1 EUR: 950 → 0** (delta −950). A WAC (weighted_avg_cost) NEM módosul.
3. **Territory 4 EUR: marad 0.** A levezetett −5000 fizikailag lehetetlen (nem lehet
   negatív valuta a trezorban) — a helyes könyvelt érték a 0, az eltérést pedig
   DOKUMENTÁLJUK, nem "javítjuk" negatívra. NEGATÍV stock írása TILOS.
4. Minden korrekcióról **inventory_movement sor születik** (movementType=CORRECTION,
   status=RECEIVED, notes='V338 base_capital reconciliation — mozgás-alapú levezetett
   értékre igazítás, diag run 28643631686'), így a mozgásnapló auditálhatóan mutatja.
   FIGYELEM: az inventory_movement sémája szerint kötelező mezőket (reference_number,
   movement_date/time, huf_value) tölteni kell — a coder nézze meg a táblát/entitást.
   A worker-hivatkozás: kód-alapú lookup a legrégebbi aktív admin/ugyvezeto workerre
   VAGY ha a séma engedi a NULL-t, inkább NULL + notes. NE hardcode-olt UUID.

## Kötelező minta (references/data-repair-migration.md + V337 precedens)

- Fájl: `backend/src/main/resources/db/migration/V338__vault_stock_base_capital_reconciliation.sql`
- KÓD-ALAPÚ lookup mindenhol: entity_id a vault_territory névből/id-ból, currency kódból,
  company a meglévő currency_stock sorból — SOHA környezet-specifikus UUID.
- IDEMPOTENS: minden UPDATE guard-olt a JELENLEGI értékre (pl. `AND quantity = 99582500.00`);
  második futásra 0 sort érint. RAISE NOTICE összesítőkkel.
- A pontos deltákra korrigálunk, NEM abszolút SET-tel guard nélkül.
- Tenant-szűrés: company_id a meglévő sorból öröklődik.
- DO $$ blokk, tranzakcionális, fail-closed (ha a guard nem talál sort, NOTICE és tovább).

## Teszt (TDD — TestContainers, V337TiszaOrphanRepairMigrationTest mintájára)

`V338VaultStockReconciliationMigrationTest`:
- Seed: a V338 ELŐTTI állapot reprodukciója (99 582 500 HUF + 950 EUR a t1-en, 0 EUR t4-en).
- Assert a V338 után: t1 HUF = 100 000 000; t1 EUR = 0; t4 EUR = 0 (nem negatív!);
  minden más VAULT sor változatlan; 2 CORRECTION inventory_movement sor létezik a
  V338-notes-szal; WAC változatlan.
- Invariáns-assert: `SELECT COUNT(*) FROM currency_stock WHERE entity_type='VAULT' AND quantity < 0` = 0.
- Idempotencia: (ha a repo mintája engedi a re-run tesztet) második futás no-op.

## Verifikáció (coder futtatja)
- `cd backend && ./mvnw -q test -Dtest='*Migration*Test'` → PASS (V337 és a többi se törhet)
- `cd backend && ./mvnw -q compile` → PASS
- Flyway verzió-lánc: V338 a legmagasabb, nincs ütközés.

## Nem-cél
- base_capital oszlop módosítása (az a seed-referencia, marad).
- Szeged HUF (konzisztens) vagy bármely 0-eltérésű sor érintése.
- A getVaultStockFlow / FE módosítása.
