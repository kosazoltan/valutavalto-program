# Flyway migration notes — defensive guard pattern

> **Cél:** dokumentálni a "fresh-install guard" migration-pattern-t (V3_x előfix-számok), amely a v2.3.6 (PR #252) release-ben került be, és a kapcsolódó "DDL duplikációnak látszó" finding-okat (Sourcery PR #252).

## Áttekintés

A Flyway v10+ + `spring.flyway.baseline-on-migrate=true` + `baseline-version=67` kombinációval a Hetzner production DB **csak V67+** migrációkat futtat (lásd `application-production.properties:36-37`). A fresh installok (új lokális DB, CI test DB, stagining) viszont V1-től kezdik, és **kell** a korábbi schema állapot reprodukciója.

**V3_x guard migrations** (V3_5, V3_7) ezért léteznek: az `IF NOT EXISTS` + `information_schema` introspection mintával **idempotensen** hozzák létre a hiányzó oszlopokat / táblákat, anélkül hogy a meglévő productiont érintenék.

## Sourcery PR #252 P2-A: `inventory_movement` DDL "duplikáció"

**Finding:** *"The `inventory_movement` table DDL is now duplicated in both `V3_5__create_missing_tables_guard.sql` and `V33__inventory_movement_log.sql`; even though both use `IF NOT EXISTS`, it would be safer long-term to centralize the canonical definition in a single migration to avoid the two versions drifting apart."*

**Reális helyzet (NEM duplikáció):**
- **V3_5__create_missing_tables_guard.sql:53-86** — **kanonikus** `CREATE TABLE IF NOT EXISTS inventory_movement (...)` + index-ek. Ez a **definíció**.
- **V33__inventory_movement_log.sql** — explicit komment a fájl tetején: *"A tábla definíciója: V3_5__create_missing_tables_guard.sql (kanonikus, fresh install guard) | Ez a migration csak az ALTER TABLE bővítéseket tartalmazza."*
  - Itt csak `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` (`balance_before`, `balance_after`, `transaction_id`, `worker_id`) van.
  - A 6 `CREATE INDEX IF NOT EXISTS` defenzív duplikáció a V3_5-ből (mindkettő idempotens, nincs drift kockázat).

**Konklúzió:** Defensive duplikáció **szándékos**, V33 explicit cross-ref-fel. Drift kockázata **nincs**, mert a tényleges DDL csak V3_5-ben van, V33 csak ALTER-eket csinál.

**Drift-prevention guideline:** ha egy újabb migration az `inventory_movement` table-t **alapvetően** módosítaná (pl. új CONSTRAINT vagy column-rename), a **V3_5-et NEM módosíthatjuk** (Flyway checksum). Új V### migration kell, ami `ALTER TABLE inventory_movement ADD/DROP/RENAME ...` formában változtatja.

## Sourcery PR #252 P2-B: V3_7 `sync_active_columns()` trigger nélkül

**Finding:** *"The new `sync_active_columns()` function in `V3_7__active_is_active_column_guard.sql` is defined but no triggers are attached in this migration; if the intent is purely to backfill/create `is_active` columns before V109 wires the triggers, consider clarifying that in the header or adding a minimal trigger wiring here to avoid future confusion."*

**Reális helyzet:**

A V3_7 **kettős célja**:
1. **Pre-V109 guard** — ha a V69, V70, V79 stb. seed migrationok az `is_active` oszlopra hivatkoznak (DML `INSERT ... is_active=true`), akkor az oszlopnak már létezni kell. V3_7 hozzáadja `IF NOT EXISTS` mintával.
2. **V109 trigger újrahasználata** — a `sync_active_columns()` function a V109-tel megegyező logikát definiálja `CREATE OR REPLACE`-szel, hogy egy fresh DB-n már a V3_7 után működjön a kétirányú szinkron, MIELŐTT a V109 wire-elné a trigger-eket az összes érintett táblára.

**A trigger wiring (ATTACH) szándékosan a V109-ben** marad, mert:
- A V3_7 lefutásakor még nem létezik az **összes** olyan tábla, amely érintett (pl. `worker`, `currency`, `dictionary`, `company`, `branch`).
- A V109-ben (V67 baseline UTÁN) történik a teljes körű `CREATE TRIGGER ... BEFORE INSERT OR UPDATE` minden táblára.
- A `sync_active_columns()` function `CREATE OR REPLACE` mintával nem ütközik V109-cel.

**Workflow:**

```
V3_5 (fresh install only) → CREATE TABLE inventory_movement, ...
V3_7 (fresh install only) → CREATE FUNCTION sync_active_columns + ADD COLUMN is_active (NULL) + backfill
V67 (baseline production)
V109 (production + fresh install) → CREATE TRIGGER on each table USING sync_active_columns()
V166 (defensive, post V3_7 fix) → UPDATE is_active=active WHERE active=false AND is_active=true
V167 (defensive re-apply, BASE TABLE filter) → idempotent
```

**Konklúzió:** A V3_7 fájl **header magyarázza** ezt a célt (lásd V3_7 sor 1-7). Új migration NEM szükséges. **A jelen `MIGRATION_NOTES.md` cross-ref**-fel rögzítjük a V3_5+V33+V3_7+V109 közötti viszonyt, hogy jövőben ne keletkezzen confusion.

## Migration checksum + módosítás-szabályok

A Flyway `validate-on-migrate=true` (production-ben aktív, lásd `application-production.properties:38`) szigorúan ellenőrzi minden már-lefutott migration **checksum**-ját. Ha egy fájlt módosítunk (akár csak komment-bővítéssel), a `validate` **fail** lesz a meglévő DB-ken.

**Szabály:**
- **NE módosíts** mergelt migration-fájlt (V1-V165 minden lefutott + V166-V167 most lefutott).
- Ha egy korábbi migration hibás vagy hiányos: **új migration**-be a fix.
- Komment-bővítés vagy header-magyarázat: ide, a `MIGRATION_NOTES.md`-be vagy ehhez hasonló külső doc-ba.

## Hivatkozott PR-ek + commit-ok

- **PR #252** — release v2.3.6 + V3_5/V3_7 guard migrations (mergelve `85bb9e24`)
- **PR #253** — V165 branch.denomination_rule_id guard (mergelve `0949a656`)
- **PR #255** — V166 silent reactivation fix (mergelve `f71c1670`)
- **PR #258** — V167 BASE TABLE defensive re-apply (mergelve `6ca3e86b`)
- **Sourcery review** PR #252 (2026-04-28 20:24 UTC) — a 2 P2 finding ezen az MD-n keresztül resolved.
