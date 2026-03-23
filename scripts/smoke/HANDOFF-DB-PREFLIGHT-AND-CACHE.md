# Handoff: DB preflight + pénztár cache smoke

## Szándék (másik ügynök / fejlesztő célja)

1. **`mandatory-db-preflight.ps1`** — `psql` elérhetőség, lokális + távoli DB, Flyway paritás.
2. **Gate** — a preflight a `run-security-gate.ps1` része; ha elhasal, a gate piros.
3. **Távoli DB (Neon / Render)** — ha a kapcsolat OK, de **nincs `public.flyway_schema_history`**, az **üres / nem migrált** adatbázis jele, nem szkript-hiba.
4. **SyncEngine** (`penztar-client/electron/sync-engine.ts`) — alap **30 000 ms** intervallum; tokennel fut **árfolyam + cache** (pl. `cached_workers`, `cached_cash_desks`).
5. **`tmp-read-electron-cache.js`** — olvassa a `~/.valuta/local.db` releváns sorait / max `cached_at`-ot (futtatás: `penztar-client` mappából, `sql.js` miatt).

## Egységes env (`.env` a repo gyökérben)

| Változó | Szerep |
|--------|--------|
| `LOCAL_DATABASE_URL` vagy `LOCAL_DB_*` | Lokális PostgreSQL (preflight + backend) |
| `NEON_DATABASE_URL` / `RENDER_DB_URL_EXTERNAL` / `DATABASE_URL` | Távoli DB (nem localhost) |
| **`DB_PREFLIGHT_REMOTE_MODE=optional`** | Ha a távoli DB-n **nincs Flyway tábla**, **WARN** és **PASS** (csak lokális vs repo migrációk). **Éles / szigorú CI:** ne állítsd, vagy `strict`. |

A preflight a futás elején betölti a gyökér `.env`-et (`Import-DotEnv`).

## Parancsok

```powershell
# Preflight önállóan
.\scripts\security\mandatory-db-preflight.ps1

# Gate (örökli a folyamat env-et; a .env-ből a preflight olvassa a módot)
.\scripts\security\run-security-gate.ps1
```

```powershell
# Pénztár fut, bejelentkezve — ~30 mp után cache minta
.\scripts\smoke\run-cache-refresh-check.ps1
```

## Következő lépések (folytatás)

- Távoli DB-n egyszer **`flyway migrate`** (vagy Spring Boot indulás migrációval) → utána **`DB_PREFLIGHT_REMOTE_MODE`** eltávolítása / `strict`.
- **Bootstrap user** + `PENZTAR_BOOTSTRAP_*` env a `run-full-smoke.ps1`-hez — lásd `penztar-client` / `start-penztar.cmd` dokumentáció.
- **Élő 30s teszt** automatizálása: füst után `run-cache-refresh-check.ps1` + JSON assert (pl. `workerTs` nem null).
