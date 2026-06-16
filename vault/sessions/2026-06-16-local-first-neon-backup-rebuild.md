# 2026-06-16 — Local-First végállapot megerősítve + Neon-backup 3-bug javítás + teljes újraépítés

## Kontextus

A 2026-06-15-ös incidens-note azt sejtette, hogy a backend a Neont szolgálja (split-brain).
A 2026-06-16-os prod-probe (SSH `root@95.216.191.162`, kulcs `~/.ssh/hetzner_ed25519`) ezt cáfolta.

## Prod-topológia (bizonyított, 2026-06-16)

| Réteg | Mi | Státusz |
|---|---|---|
| **Élő adatbázis** | Hetzner lokális `valuta` DB (PgBouncer 6432 → 127.0.0.1:5432) | ✅ SZOLGÁL |
| **Streaming standby** | Scaleway 163.172.152.234 (WAL-replikáció, sync_state=sync, ≈0 lag) | ✅ ÉL |
| **Neon backup** | Egyirányú app-szintű szinkron (NeonReplicationService) | ✅ most helyes, addig hiányos volt |
| **B2 napi dump** | pg_dump → Backblaze B2 | ✅ a lokális DB-ből megy |

A 2026-06-15-ös `DATABASE_URL=jdbc:postgresql://localhost:6432/valuta` hivatkozás helyes volt;
a korábban a Neon-re mutató `spring.datasource.url` a `NeonDataSourceConfig` JdbcTemplate-hijackja miatt
tűnt elsődlegesnek. Az éles adat végig a lokális Hetzner DB-n volt.

## Három javított hiba (PR-ek élesben deployolva)

### Bug 1 — JdbcTemplate-hijack (PR #1190, MERGED+DEPLOYED)

**Gyökér:** `NeonDataSourceConfig` létrehozta a `neonJdbcTemplate` bean-t.
Spring Boot `JdbcTemplateAutoConfiguration` `@ConditionalOnMissingBean(JdbcOperations.class)`
visszalépett → a `NeonReplicationService.primaryJdbc` (qualifier nélküli mező) a **Neonra kötődött**
→ a fullSync a Neonról olvasott és önmagába írt vissza. Tünete: `neon_sync_log` minden táblára
`SUCCESS`, de a Neon tartalma 0 változás (önmásolás).

**Fix:**
- `PrimaryDataSourceConfig`: explicit `@Primary JdbcTemplate` bean neve `primaryJdbcTemplate`
- `NeonReplicationService` konstruktor: `@Qualifier("primaryJdbcTemplate")`
- Új teszt: `DataSourceWiringTest` — strukturális kontraktus, hogy a `@Primary` JdbcTemplate
  a Hetzner lokális DB-re mutat

**Ugyanaz a hijack-minta** mint a #1175 DataSource-szinten (precedens volt).

### Bug 2 — Törzs-táblák hiányoztak a sync-ből (PR #1191, MERGED+DEPLOYED)

**Gyökér:** `SYNC_TABLES` / `FULL_SYNC_TABLES` csak üzleti táblákat tartalmazott; a referencia-táblák
(`company`, `currency`, `dictionary`, `denomination`, `branch`, `vault_territory`, `worker`,
`data_collection`) NEM szerepeltek → a Neonon ezek elavultak → az üzleti táblák FK-ja rájuk bukott
(pl. `worker_id=271`, `currency_id=31` hiányzott a Neonon) → az all-or-nothing batch miatt
a TELJES üzleti tábla szinkron elbukott (pl. `transaction` 36/134).

**Fix:**
- Törzs-táblák a `SYNC_TABLES`/`FULL_SYNC_TABLES` **elejére** kerültek, FK-sorrendben
- `upsertToNeon` reziliencia: batch-bukásnál soronkénti fallback (a jó sorok átmennek)

**GOTCHA (follow-up):** `denomination` MÉG a `branch` ELŐTT van a sorrendben (FK: denomination→branch
irányban fügés nincs, de az adatoknál cross-ref lehetséges) — a reziliencia kezeli, de pontosabb
sorrend: `branch` a `denomination` elé.

**GOTCHA:** Neon menedzselt DB-n `session_replication_role=replica` NEM engedélyezett
(`ERROR: permission denied`) → FK-trigger letiltás fallback nem működik → csak a sorrend + reziliencia számít.

### Bug 3 — Gate A téves BLOKKOLÓ logika (PR #1189, MERGED)

`.github/workflows/deploy-hetzner.yml` Gate A megfordítva Local-First-re:
- **Gate A (lokális Hetzner DB Flyway-verziója):** BLOKKOLÓ (ez a szolgáló DB)
- **Gate B (Neon backup Flyway-verziója):** INFORMÁLIS — `flyway migrate` megmarad, verzió-eltérés
  csak `warning`, `Summary` mutatja a `step.outcome`-ot

## Teljes Neon-újraépítés (manuális, SSH, 2026-06-16)

**Szükség oka:** a darabonkénti sync/refresh elakadt a Neon divergens állapotán:
- `currency`/`dictionary` más `id`-kkel ugyanazon `code` business-key → UNIQUE-ütközés INSERT-nél
- `circular_acknowledgment` tábla hiányzott a Neonon → a `neon-backup-refresh.yml`
  workflow `ON_ERROR_STOP` miatt rollback-elt

**Végrehajtás:**
```bash
# Biztonsági mentés a régi Neonról (csere előtt)
pg_dump "$NEON_URL" > /tmp/neon_before_rebuild.dump

# Dump a lokális (élő) DB-ből
sudo -u postgres pg_dump --clean --if-exists --no-owner --no-privileges -d valuta > /tmp/valuta_local.dump

# Restore a Neonra
docker run --rm postgres:17 psql "$NEON_URL" < /tmp/valuta_local.dump
```

**Eredmény (0 ERROR):**

| Tábla | Lokális | Neon (utána) |
|---|---|---|
| `transaction` | 134 | 134 ✅ |
| `cash_balance` | 1235 | 1235 ✅ |
| `denomination` | 22189 | 22189 ✅ |
| összes tábla | — | egyezik ✅ |

## Adatbiztonsági értékelés

Az éles adat **végig biztonságban volt**:
1. Lokális Hetzner DB (élő, kizárólagos forrás)
2. Scaleway streaming standby (teljes, ≈0 RPO, sync_state=sync)
3. Napi B2 pg_dump (teljes, a lokális DB-ből)
4. Neon (4., redundáns réteg — ez volt hiányos, de a többi 3 teljes volt)

## HA-döntés (elhalasztva)

A felhasználó a streaming HA (Hetzner↔Scaleway) kivezetését fontolgatta (azt hitte, törött).
A probe igazolta: **a streaming-replikáció ÉL** (sync_state=sync, ≈0 lag).
Amíg a Neon hiányos volt, a Scaleway volt az EGYETLEN teljes backup → HA-kivezetés elhalasztva.
Most a Neon teljes → a HA-kivezetés újra megfontolandó (de a Scaleway standby teljes redundancia, érdemes megtartani).

## Kulcstanulságok

1. **`neon_sync_log SUCCESS ≠ teljes backup.** Sorszám-összevetés kell: `SELECT COUNT(*) FROM <tábla>`
   mind a lokálison, mind a Neonon. Divergencia szilens lehet.
2. **`@ConditionalOnMissingBean` csapda:** ha egy custom DataSource-hoz `JdbcTemplate`-t is létrehozol,
   a Boot auto-konfigurációja visszalép, és a qualifier-nélküli mezők a nem-várt bean-re kötnek.
3. **Neon menedzselt DB korlát:** `session_replication_role=replica` tiltott → FK letiltása nem opció
   → sorrend + soronkénti reziliencia az egyetlen megbízható út.
4. **Törzs-táblák szinkronizálása kötelező:** ha az üzleti táblák FK-val hivatkoznak rájuk,
   a törzs-tábláknak is kell a backup-ban lenni, sorrendben előttük.

## Kapcsolódó

- [[reference_local_first_architecture]] — Local-First mandate (Electron kliensek)
- [[reference_production_infrastructure]] — Hetzner + Scaleway HA infra
- [[project_v296_outage_and_standby_gap]] — előzmény: 2026-06-05 outage + Scaleway standby verzió-rés
- Incident: `vault/sessions/incident-2026-06-15-prod-db-topology-neon-primary-local-stale.md`
- PR #1189, #1190, #1191
