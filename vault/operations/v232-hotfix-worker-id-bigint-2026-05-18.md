# V232 Hotfix Runbook — worker.id UUID → BIGINT

**Dátum:** 2026-05-18 03:00 — 05:15 CEST
**Érintett migration:** `V232__remove_juhasz_norbert_exz_cross_project.sql`
**Hotfix PR:** [#645](https://github.com/kosazoltan/valutavalto-program/pull/645)
**Allowlist PR:** [#647](https://github.com/kosazoltan/valutavalto-program/pull/647)

---

## Probléma

A V232 ([PR #643](https://github.com/kosazoltan/valutavalto-program/pull/643)) Flyway migration `DECLARE v_juhasz_id UUID` változót használt:

```sql
DO $$
DECLARE
    v_ebc_id UUID;
    v_juhasz_id UUID;  -- ❌ HIBÁS
BEGIN
    ...
    SELECT id INTO v_juhasz_id FROM worker WHERE code = 'G_JUHASZ_NORBERT';
    ...
```

DE a `worker.id` típusa **`BIGSERIAL/BIGINT`** (lásd `V2__create_worker_tables.sql`). Juhász Norbert `worker.id = 664`.

A `SELECT id INTO v_juhasz_id` művelet megpróbálta a 664 BIGINT-et UUID-ba cast-olni:

```
Caused by: org.postgresql.util.PSQLException: ERROR: invalid input syntax for type uuid: "664"
Where: PL/pgSQL function inline_code_block line 12 at SQL statement
```

## Production state (bizonyíték)

Hetzner deploy 2026-05-17 20:55:52 — `valuta-backend.service` Main process exited code=1.

```bash
# Bizonyítás (manuálisan futtatva a Hetzner-en):
sudo -u postgres psql -d valuta -c "SELECT version, success, installed_on FROM flyway_schema_history WHERE version='232';"
# Várt eredmény: success=false, ÉS a deploy workflow DELETE-zte minden deploy elején.
```

**Tény: a V232 SOHA NEM completed=true állapotban volt production-on**, mert minden próbálkozás failed-szel végződött + a deploy workflow `DELETE FROM flyway_schema_history WHERE success=false` lépés (`.github/workflows/deploy-hetzner.yml:120`) automatikusan törölte a failed bejegyzéseket minden deploy elején.

## Repair eljárás

### Automatikus (megfelelő minden környezetben ahol V232 success=false)

A `.github/workflows/deploy-hetzner.yml:120` lépés automatikusan elvégzi:

```sh
sudo -u postgres psql -d "$DB_NAME" -c "DELETE FROM flyway_schema_history WHERE success = false;"
```

Ezután a Flyway a JAVÍTOTT V232 SQL-t (most már `v_juhasz_id BIGINT`-tel) megpróbálja újra futtatni. Sikeres = új sor a history-ban success=true.

### Manuális (csak ha az automatikus repair nem fut)

```sh
# 1. SSH a Hetzner-re:
ssh valuta@<hetzner-ip>

# 2. Verifikáld a state-et:
sudo -u postgres psql -d valuta -c "SELECT version, success FROM flyway_schema_history WHERE version='232';"

# 3. Ha success=false, töröld:
sudo -u postgres psql -d valuta -c "DELETE FROM flyway_schema_history WHERE version='232' AND success=false;"

# 4. Restart backend (újra próbálja V232-t):
sudo systemctl restart valuta-backend
```

## Risk Assessment (per environment)

| Környezet | Kockázat | Ok |
|---|---|---|
| **Hetzner production** | **Minimális** | V232 sosem completed=true (csak failed) → checksum-mismatch nem keletkezhet. Automatikus repair lépés a workflow-ban. |
| **Scaleway standby** | **Minimális** | Replikációs slave, V232-t a Hetzner-től örökli. |
| **CI/test environment** | **Nincs** | Tesztben minden V<n> új-deployon kezdődik (nincs persistent history). |
| **Lokális dev DB** | **Alacsony** | Ha a fejlesztő DB-jén V232 valamilyen okból `success=true` lenne (pl. üres worker tábla, ahol Juhász Norbert nem létezik), a JAVÍTOTT V232 (most BIGINT) **eltér** a régi (UUID) checksum-tól. Flyway checksum-mismatch hibát ad. **Megoldás:** `flyway repair` parancs vagy `FLYWAY_REPAIR_ON_MIGRATE=true` env változó. |

**NEM állítjuk hogy "kockázat: NULLA"** — a fenti táblázatban a lokális dev DB-n elméletileg keletkezhet checksum-mismatch, de a megoldás (Flyway repair) standard és gyors.

## Lessons learned

1. **`worker.id` BIGINT, NEM UUID** — a séma vegyes:
   - `company.id`, `branch.id`, `dictionary.id`, `worker_role_def.id` = **UUID**
   - `worker.id`, `transaction.id`, sokvalami `bank_*` = **BIGINT** (BIGSERIAL)
   - Új PL/pgSQL `DECLARE` változónál mindig verifikálni a worker tábla séma típusát.

2. **F15 allowlist requirements** — a `.flyway-lint-allowed-modifications` fájl tetejének követelményei:
   - **(1)** konkrét repair eljárás dokumentálva → MEG VAN ebben a runbookban (lásd "Repair eljárás" szekció)
   - **(2)** vault jegyzet linkje → EZ A FÁJL
   - Az allowlist-bejegyzés most már megfelel.

3. **Migration testing** — a `mvn test` és helyi integration test SQL-szintaxis-szinten validál, de NEM futtatja le production-realista DB állapoton. A `DO $$ ... $$` blokkok típushibák csak runtime-ban derülnek ki.

## Hivatkozások

- **Eredeti PR:** [#643 (V232 mergelve 2026-05-17 22:39)](https://github.com/kosazoltan/valutavalto-program/pull/643)
- **Hotfix PR:** [#645 (V232 worker.id BIGINT, mergelve 2026-05-18 03:12 + Hetzner deploy success 2m19s)](https://github.com/kosazoltan/valutavalto-program/pull/645)
- **Allowlist PR:** [#647 (V232 entry hozzáadva, mergelve 2026-05-18 03:08)](https://github.com/kosazoltan/valutavalto-program/pull/647)
- **Flyway repair lépés:** `.github/workflows/deploy-hetzner.yml:120`
- **Bizonyíték — production endpoint:** `curl https://excvaluta.com/api/v1/auth/bootstrap-status` → HTTP 200 `{"completed":true}`

---

🤖 *Generálva: Claude Code (claude-opus-4-7) — V232 hotfix runbook 2026-05-18*
