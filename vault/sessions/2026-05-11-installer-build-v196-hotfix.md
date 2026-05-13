# 2026-05-11: Installer build v2.5.40 + V196 NOT NULL hotfix

## Kontextus
Az előző session (2026-05-09) után a user kérte a v2.5.39/v2.5.40 installer buildet, mert nem volt meg neki. A build közben kiderült, hogy a V196 migration productionban FAILELT.

## Elvégzett munka

### PR #539 — Version bump 2.5.39 → 2.5.40
- 4-way sync: root package.json, frontend-react, penztar-client, backend/pom.xml
- Auto-patch a build-installer.ps1 által
- CI 16/16 PASS, Sourcery: csak P3 informatív
- ✅ merged

### Installer build v2.5.40
- `Penztar-Setup-2.5.40-20260511.exe` — 280.9 MB (ALLOW_UNSIGNED_BUILD=1)
- `Penztar-Eltavolito-2.5.40-20260511.exe` — 0.1 MB
- Mindkettő másolva: `%USERPROFILE%\Downloads\` + `installer/build/`
- Tartalmazza PR #538 humanizeIpcError + V196 seed password fix kliensoldali változásait

### PR #540 — V196 NOT NULL hotfix (PRODUCTION DOWN!)
**Root cause:** A V196 migration (`UPDATE worker SET password_hash = NULL`) failelt productionban:
```
ERROR: null value in column "password_hash" of relation "worker" violates not-null constraint
Detail: Failing row contains (89, t, W-S012, ..., Borsi Tamás, ...)
```
A `worker.password_hash` kolonna NOT NULL constrainttel volt létrehozva, és a V196 UPDATE SET NULL ütközött vele.

**Fix:**
1. V197 NEW: `ALTER TABLE worker ALTER COLUMN password_hash DROP NOT NULL;`
2. Worker.java: `@Column(nullable = true)` a passwordHash-en
3. `hotfix-flyway-repair-v196.yml` workflow: törli a failed V196 entry-t, futtatja az ALTER TABLE-t psql-lel, restartol
4. V196 eredeti formában maradt (F15 migration-lint betartva)

**Eredeti terv (blocked):** V196 közvetlen módosítása — de az F15 migration-lint jogosan tiltotta a merged migráció módosítását.

**Repair folyamat:**
1. PR #540 merged (CI 16/16 PASS + migration-lint PASS)
2. Deploy FAILED (V196 still broken)
3. Manually triggered "Hotfix - Flyway Repair V196" workflow ("REPAIR-V196")
4. Workflow: V196 deleted from flyway_schema_history + ALTER TABLE ran via psql + restart
5. Production restored: bootstrap-status 200 ✅

### Tanulság
- **MINDIG ellenőrizni kell a kolonna constraintjeit** mielőtt NULL-ra SET-elünk egy migációban
- A Worker entity `@Column(nullable = false)` nem elég jelzés — a tényleges DB schema dönt
- Flyway checksum-védelem (F15 lint) fontos biztonsági háló — NE módosítsunk merged migrációt

## Teszteredmények
- Backend: BUILD SUCCESS (1239+ tests) a nullable=true módosítással
- CI: minden PR 16/16 PASS

## Állapot
- **Main HEAD:** `76d628bf`
- **Production:** UP (bootstrap-status 200)
- **Open PRs:** 0
- **Verzió:** 2.5.40

## Következő teendők
- **P1:** BALI jelszó állapot ellenőrzése (V196 clearelte-e)
- **P1:** Tesztrendszer bővítés (200-300 teszt/flow)
- **P2:** Stale remote branch cleanup
- **P2:** Jackson 3 migráció (39 fájl)
