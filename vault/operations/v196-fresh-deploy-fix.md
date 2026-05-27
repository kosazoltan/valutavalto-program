# V196 fresh-deploy fix — runbook

**Dátum:** 2026-05-27
**Trigger:** élő-API keresztmetszet-teszt (fresh lokál DB) — a backend nem indult el.
**Migration:** `V196__clear_seed_password_for_unsetup_workers.sql`

## Probléma (root cause)

A V196 a seed-jelszót törli azoknál a dolgozóknál, akik soha nem állítottak be saját jelszót:

```sql
UPDATE worker SET password_hash = NULL
WHERE password_changed_at IS NULL AND password_hash IS NOT NULL;
```

A `worker.password_hash` oszlop azonban **NOT NULL** volt, és ezt a constraintet csak a
**KÉSŐBBI** `V197` ejtette (`ALTER ... DROP NOT NULL`). Fresh-apply sorrendben
(V1 → … → V196 → V197) a V196 hamarabb fut, mint a V197 → a NULL-update a NOT NULL
constraintbe ütközik:

```
ERROR: null value in column "password_hash" of relation "worker" violates not-null constraint
```

→ a Flyway migráció megbukik → a backend **nem indul el**.

### Hol manifesztálódik

- ✅ **Fresh telepítés** (új cég onboarding) — BUKIK
- ✅ **Disaster-recovery** (új DB WAL/dump nélkül) — BUKIK
- ✅ **Lokál-dev fresh DB** — BUKIK
- ❌ **Established production** — NEM manifesztálódik: a dolgozók már `password_changed_at`-tel
  rendelkeznek, így a V196 WHERE 0 sort érint, a NOT NULL violation nem következik be.

## Megoldás

A NOT NULL constraintet **MÁR a V196-ban, az UPDATE ELŐTT** ejtjük (idempotens — ha már
nullable, no-op). A V197 ezután redundáns no-op marad.

```sql
ALTER TABLE worker ALTER COLUMN password_hash DROP NOT NULL;

UPDATE worker SET password_hash = NULL
WHERE password_changed_at IS NULL AND password_hash IS NOT NULL;
```

## Production repair eljárás (KÖTELEZŐ a következő deploy-on)

Established production DB-n a V196 **már `success=t`** a `flyway_schema_history`-ban. A V196
tartalom-módosítása **checksum-változást** okoz → checksum mismatch a következő deploy-on.

Kezelés (a `.github/workflows/deploy-hetzner.yml` már tartalmazza):
1. A deploy failed-history-cleanup lépése + **`FLYWAY_REPAIR_ON_MIGRATE=true`** egyszeri override
   frissíti a tárolt checksumot az új tartalomra.
2. **Adat-hatás: 0 sor** (production-on a WHERE továbbra is 0 sort érint).

Egyéb környezet (lokál/staging): `flyway repair` vagy `FLYWAY_REPAIR_ON_MIGRATE=true`.

## F15 migration-lint

A V196 módosítása az already-merged migration-ök közé tartozik → az F15 lint blokkolja,
hacsak a fájlnév nincs a `backend/src/main/resources/db/migration/.flyway-lint-allowed-modifications`
allowlistben **a PR base revisionjében** (self-bypass védelem).

Ezért a folyamat **két PR**:
1. **Precursor PR** (ez): allowlist entry + jelen runbook hozzáadása main-re.
2. **Fix PR**: a V196 tényleges `DROP NOT NULL` módosítása (a base már tartalmazza az allowlist entryt).
