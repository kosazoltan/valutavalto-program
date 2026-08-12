# V380 éles hotfix — oszlop-agnosztikus tiltott-érme inaktiválás (2026-08-12)

**Súlyosság:** P0, éles kiesés. **Időtartam:** ~01:24–01:5x UTC (2026-08-12).
**Érintett:** `excvaluta.com` backend — nem indult el, minden endpoint 502.

## Mi történt

Az FK-080 release (`37960493`) main-re pusholása automatikusan indította a
`deploy-hetzner.yml`-t. A V379 (HUF-seed) sikeresen lefutott, a V380 elbukott:

```
Migrating schema "public" to version "379 - fk080 denomination allowed huf seed"
Migrating schema "public" to version "380 - fk080 tiltott erme sorok inaktivalasa"
ERROR: column d.active does not exist
  Hint: Perhaps you meant to reference the column "d.is_active".
SQL State: 42703 — Location: V380__...sql line 43
Migration of schema "public" to version "380 ..." failed! Changes successfully rolled back.
```

A Flyway-hiba a Spring context indulását akasztotta meg
(`flywayInitializer` → `entityManagerFactory` → `jwtAuthenticationFilter` lánc),
így a `valuta-backend.service` `status=1/FAILURE`-rel kilépett, és a rendszer 502-t adott.

## Gyökérok

A `denomination` tábla aktív-oszlopa **környezetfüggő**:

| Környezet | `active` | `is_active` |
|---|---|---|
| Friss séma (Testcontainers, V3 DDL + V3_7/V109 guard) | van | van |
| **Éles Hetzner DB** | **NINCS** | van |

A V3 DDL `active`-ot hoz létre, a V3_7/V109 guard pedig `is_active`-ot ad hozzá ott,
ahol csak `active` van. Az éles séma valamikor eltért ettől (csak `is_active` maradt).
A V380 statikus `SET active = false, is_active = false ... WHERE d.active = true`
utasítása ezért éles környezetben nem fordult le.

**Miért nem fogta meg egyetlen kapu sem:** a Testcontainers-tesztek a teljes migráció-láncot
friss sémán futtatják, ahol MINDKÉT oszlop létezik. A csonka éles séma nem volt reprodukálva
egyetlen tesztben sem — ez a tesztlefedettség valódi hiánya volt, nem véletlen.

## A javítás

Oszlop-agnosztikus dinamikus SQL: a migráció futásidőben az `information_schema.columns`
alapján dönti el, melyik aktív-oszlop létezik, és csak azokat írja. Ha egyik sem létezik,
explicit `RAISE EXCEPTION` (nem csendes no-op). A predikátum, a multi-tenant szűrés és a
NOT EXISTS pozitív lista változatlan — a migráció üzleti viselkedése nem módosult.

## Miért módosítható a V380 (F15 lint whitelist)

**Nincs checksum mismatch kockázat.** A V380 tranzakcionálisan visszagördült
("Changes successfully rolled back"), és a `deploy-hetzner.yml` failed-history-cleanup
lépése törli a `success = false` rekordokat minden deploy elején. Ezért a V380 checksumja
SOHA nem került be a `flyway_schema_history`-ba — a javított fájl friss pending
migrációként fut le. Pontosan a **V249 precedens** (2026-05-21).

A V379 ezzel szemben **sikeresen alkalmazva** van: azt tilos módosítani, és nem is módosult.

## Verifikáció

- `V380AgainstLegacySchemaPostgresTest` — a hibát reprodukáló regressziós teszt:
  eldobja az `active` oszlopot (csonka éles séma), majd futtatja a V380 logikáját.
  **Mutációval igazolva:** a javítás előtti statikus SQL-lel ez a teszt pontosan az éles
  hibával (`ERROR: column d.active does not exist`) bukik; visszaállítás után zöld.
- Teljes backend suite XML-aggregációval: **487 suite, 3758 teszt, 0 hiba**.

## Helyreállítás — mért eredmény (2026-08-12 01:52 UTC)

Hotfix commit: `6e3dfaf7`. A deploy MINDEN job-ja sikeres:

| Job | Eredmény |
|---|---|
| Gate A — Hetzner LOKÁLIS DB migration (BLOKKOLÓ) | success |
| Deploy to Hetzner | success |
| Gate B — Neon backup DB | success |
| Sync JAR to Scaleway standby (hot) | success |

```
Hetzner LOKÁLIS Flyway max = V380 | repo max = V380 | failed sorok = 0
OK — a lokális (szolgáló) Hetzner DB a repo max verzión (V380).
FK-080 V380: 0 tiltott COIN denomination sor inaktivalva (active=f, is_active=t)   [Neon]
```

Az `active=f, is_active=t` naplósor bizonyítja, hogy a dinamikus oszlop-felismerés
pontosan úgy működik, ahogy tervezve volt: a csonka sémán csak az `is_active` oszlopot írja.

**Éles állapot a javítás után:** `GET /api/v1/auth/bootstrap-status` → **HTTP 200**,
`/api/v1/version` → `2.28.76` (buildTime `2026-08-12T01:51:37Z`).
Kiesés hossza: ~01:24 → ~01:52 UTC (≈28 perc, éjszakai időszak).

## Tanulság (követő feladat)

Az éles és a friss séma eltérése nem csak ezt a migrációt fenyegeti. Érdemes egy
séma-drift ellenőrzést futtatni (éles `information_schema` vs. friss Flyway-lánc),
és a jövőbeli adat-korrekciós migrációkat oszlop-agnosztikusra írni ott, ahol
`active`/`is_active` kettősség érinti őket.
