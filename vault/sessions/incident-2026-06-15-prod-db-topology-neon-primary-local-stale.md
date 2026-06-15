# Incidens-jegyzet — 2026-06-15 — Prod DB-topológia: a backend a Neont szolgálja, a lokális Hetzner 'valuta' elavult

## Kiváltó kontextus
A RUB-visszaállítás (PR #1147: V327–V329, RUB `is_active=true` + címlet + currency_stock) után a
deploy **Gate A (Hetzner lokális 'valuta' DB)** pirosat adott: `V326 != repo V329`. A diagnózis
(read-only, `hetzner-db-check.yml` bővítve a `chore/prod-flyway-diagnose` branchen) az alábbit tárta fel.

## Megállapítások (read-only bizonyítékkal)

1. **A migrációim helyesek és élnek.** A backend Flyway-e a deploy-restartkor (2026-06-15 10:42:18)
   lefuttatta: „Successfully applied 3 migrations … now at version v329"; V328 1079 címletsor, V329 9
   készletsor. A **Neon** DB: V329, **RUB `is_active=true`**. (Gate B is zöld volt.)

2. **A backend a NEON-t használja futásidejű @Primary datasource-ként.**
   - A backend startup-JDBC logja KIZÁRÓLAG a Neont mutatja (`…ep-polished-morning-…neon.tech/neondb`).
   - A Flyway a Neonra vitte fel a migrációkat (csak a Neon van V329-en).

3. **A lokális Hetzner 'valuta' DB (5432, PgBouncer 6432) elavult maradék.**
   - V326, RUB **inaktív**, 0 RUB-címlet. `postmaster start: 2026-06-11` (nem indult újra).
   - **Nulla írás-aktivitás (0 checkpoint) 03:31 óta** — üzleti időben egy élő ERP folyamatosan írna.
   - `pg_stat_activity`: gyakorlatilag csak a diagnosztikai psql kapcsolódik; nincs élő Hikari-pool.
   - A `.env DATABASE_URL=jdbc:postgresql://localhost:6432/valuta` (PgBouncer → 5432 lokális) — úgy tűnik,
     felülírva/nem-effektív; a tényleges datasource a Neon.

4. **Két külön, NEM RUB-jellegű prod-infra probléma:**
   - **Gate A / HA-standby (Scaleway) / B2-backup mind a lokális 'valuta' DB-t célozza** — vagyis a
     házi HA-replikáció és a napi backup egy elavult, nem-szolgáló DB-t tükröz/ment, miközben az éles
     adat a Neonon van. **Adatbiztonsági kockázat:** az éles Neon-adat lehet, hogy nincs a házi backup-láncban.
   - **A Hetzner↔Scaleway streaming replikáció 2026-06-14 15:00 óta törött** (a standby befagyott;
     `last replay ts = 2026-06-14 15:00:30`). A `primary-watchdog` auto-failovere 14:47–14:49 között
     lag miatt ABORTÁLT (424→563 s > 300 s max).

## Mit tettünk ebben a sessionben
- **RUB**: élesüzemben (Neon) aktív — a feladat teljesült. (Ground-truth: a Főlapon látszik-e a RUB.)
- **Gate A**: BLOKKOLÓ → **INFORMÁLIS** (PR `fix/gate-a-target-actual-serving-db`), mert a lokális DB
  nem a szolgáló DB; a valódi gate a Gate B (Neon). A hamis deploy-pirosodás megszűnik.

## Nyitott kérdés az ops/fejlesztő számára (NEM RUB)
- **Szándékolt topológia?** Neon-primary (akkor a HA-standby + B2-backup + Gate A célját a Neonra kell
  igazítani, és a lokális 'valuta'-t kivezetni), VAGY lokális-primary (akkor a backend Neon-ra-kötése
  HIBA, amit javítani kell — és a RUB a lokálison még inaktív).
- **Replikáció helyreállítása** (2026-06-14 15:00 óta törött) — standby újraépítés `pg_basebackup`-pal,
  watchdog újraindítás. Külön, nagyobb feladat.

## Diagnosztikai eszköz
A `chore/prod-flyway-diagnose` branchen a `hetzner-db-check.yml` ki van bővítve read-only HA/replikáció +
datasource-azonosító próbákkal (újrafuttatható `workflow_dispatch`-csal). Konszolidálandó vagy törlendő.
