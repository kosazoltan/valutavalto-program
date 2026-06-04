# FK02-D — Végrehajtási utasítássor (AI-fejlesztő ügynöknek)

> Forrás: `FK02-D_kepletmotor_es_munkacsoport_javitasok.md` (18 FR, 5 TBD).
> Cél: a csoport árfolyamlap (rate-maker) képletmotorának és munkacsoport-kezelésének bővítése.
> **A rate-maker renderer (`frontend-react/src/pages/rates/`) a `kozponti-client` rate-maker módjában ÉS a standalone `arfolyam-keszito-client`-ben is fut** → minden `lf:*` IPC-t MINDKÉT Electron-hostba be kell kötni (`*/electron/local-first.ts` + `preload.ts` + `sqlite.ts`).

## 0. Kódtény-alapú FR-státusz (research, 2026-06-04)

| FR | Állapot | Hol | Teendő |
|---|---|---|---|
| FR-5/6/7 (E/F/C shorthand) | **Funkcionálisan KÉSZ** | `workgroupSheetFormula.ts` `SHEET0_COLS=['A','B','C','E','F','G','H','I']` → `E/F/C` = `sheet0Self` (aktuális valuta Főlap-értéke) | Csak verifikáló teszt + FR-8 megszorítás |
| FR-8 (csak L/M-ben) | **ÚJ** | a parser minden cellában elfogadja az `E/F/C`-t | Cella-kontextus (mezőnév) átadása + N–S/J oszlopban hibajelzés |
| FR-1..4 (relatív valutakód-csere lehúzáskor) | **ÚJ** | `RateCreationPage.tsx:589 applyBulkCells` + `components/RateGrid.tsx` drag-fill | Új tiszta helper `replaceFormulaCurrency` + bekötés a lehúzásba (TBD-4 szabály) |
| FR-9..13 (cross-csoport másolás) | **ÚJ** | `RateGrid` lebegő toolbar + új csempe-választó modal + `workgroupSheetStorage.ts` | Új UI + másolás + dual-write SQLite + audit |
| FR-14 (csempe-sort) | **ÚJ/ellenőrz.** | csempe-lista komponens (`WorkgroupManager.tsx` / RateCreationPage) | `sort by legacyGroupNumber asc` a render előtt |
| FR-15/16 (duplikált sorszám tiltás) | **ÚJ** | `RateWorkgroupService.create/update` csak `code`-egyediséget néz | `legacyGroupNumber` egyediség (company-scope) + Flyway UNIQUE + 409 `VV-VALID-003` |
| FR-17 (auto-kódgenerálás) | **ÚJ** | `create` a `code`-ot klienstől veszi | Szerver generálja (`GROUP_<seq>`), `DEFAULT` kivétel; FE: kód-mező read-only/rejtett |
| FR-18 (EUA sor) | **MÁR KÉSZ** | `RateCreationPage.tsx:65` hardcode sorrend: `…'RUB','EUA','TRY'…` | Csak verifikáció: a szerver `overview.currencies` nem szűri-e ki; ha igen, a hardcode-rend a forrás |

## TBD-feloldások (kód ellen)

- **TBD-1** (FK02/FK02-B merge): a main MÁR tartalmazza az FK02/FK02-B-t (a fájlok jelen vannak) → **közös main, nincs külön merge**. Branch a main-ről.
- **TBD-2** (sorszám-egyediség DB-ben): a `RateWorkgroup`-on a `legacy_group_number` mezőn **NINCS** UNIQUE (csak `(company_id, code)` az alkalmazás-szinten) → **Flyway migráció KELL** (`V<next>__workgroup_legacy_number_unique.sql`, `UNIQUE(company_id, legacy_group_number)` WHERE legacy_group_number IS NOT NULL).
- **TBD-3** (cross-csoport másolás backend-végpont): a csoport-cellák **localStorage+SQLite dual-write**-tal mennek (FK02-B, `persistGroupRateValues`), push-only szinkron → **új backend-végpont NEM kell**, a másolás kliens-oldali (a célcsoport `group_rate_values` SQLite-jába írunk). Audit: a meglévő push-szinkronnal megy a szerverre.
- **TBD-4** (relatív csere szabály): **LEZÁRVA** — csere CSAK ha a hivatkozásban lévő kód == a forrássor valutája. `!FEUR` az EUA-sorban marad (EUR≠EUA).
- **TBD-5** (EUA `C` rövidítés): a Főlap EUA-sorának `C` (segéd) értéke ellenőrzendő; ha nincs `C` érték, az EUA-nál a `C` shorthand hibajelzést ad (a meglévő `sheet0Self` „Nincs érték" ágán automatikusan).

## Fázisok (külön PR-enként, mindegyik: teszt + 7-lencsés self-review + codex + merge)

### Fázis 1 — Képletmotor (FR-1..4, FR-8) [pure, jól tesztelhető]
1. **Új tiszta helper** `workgroupSheetFormula.ts`-ben: `replaceFormulaCurrency(formula, fromCode, toCode): string` — a tokenizert újrahasználva: minden `sheet0Cross`(`!`) tokenben, ahol `currency === fromCode`, cserélje `toCode`-ra; a `#NN` (wgCross) kódot NEM tartalmaz (a valuta a sorból jön) → változatlan; nem-`!`/nem-egyező → változatlan. (TBD-4)
2. **Bekötés a lehúzásba**: `RateGrid` drag-fill / `applyBulkCells` — amikor egy forrássorból más sorokba másol, a `raw`-t fusson át `replaceFormulaCurrency(raw, srcCurrencyCode, tgtCurrencyCode)`-on. A forrás- és célsor valutakódja a `rates[row].currencyCode`-ból.
3. **FR-8**: az `E/F/C` shorthand (sheet0Self A–I egybetűs) **csak `L`/`M` mezőben** legyen érvényes a workgroup-lapon. A parser/komputáló kapja meg a cella mezőnevét; ha `E/F/C` egybetűs ref nem-L/M mezőben → `VV-VALID-004` hiba. (A `J`–`S` self- refek és a `!`/`#` változatlanok.)
4. Tesztek: `workgroupSheetFormula.relativeCurrencyReplace.test.ts` (a spec Fázis 5 esetei) + FR-8 megszorítás.

### Fázis 2 — Backend (FR-15, FR-16, FR-17)
1. **Flyway** `V<next>__workgroup_legacy_number_unique.sql`: `ALTER TABLE rate_workgroup ADD CONSTRAINT uq_workgroup_legacynum_per_company UNIQUE (company_id, legacy_group_number);` (parciális, ha NULL megengedett). RLS/tenant ellenőrzés.
2. `RateWorkgroupService.create/update`: `legacyGroupNumber` egyediség company-scope-ban; ütközés → `ValidationException`/409 `VV-VALID-003`. Audit log INSERT.
3. **Kódgenerálás**: a `create` ne fogadjon kliens-`code`-ot; `GROUP_` + sorszám-padding; `DEFAULT` kivétel (nem íródik felül). FE (`WorkgroupManager`/create-modal): a Kód mező rejtett/read-only.
4. Tesztek: `RateWorkgroupServiceTest` / controller — duplicate seq → 409, code auto-gen, cross-tenant → 404, rename duplicate → 409.

### Fázis 3 — Cross-csoport másolás (FR-9..13)
1. `RateGrid` lebegő toolbar: „Másolás más csoportba" gomb kijelölt cellákra.
2. Új modal: csempe-választó (összes workgroup, sorszám+név, aktuális disabled), toggle multi-select, „Véglegesítés" → megerősítő dialog (nevek listája) → Igen.
3. Másolás: a kijelölt cellák tartalma (érték/képlet szövegként) a célcsoport(ok) azonos sor–oszlop `group_rate_values` SQLite-jába (`persistGroupRateValues` célcsoport-id-vel). Cross-tenant tilt (csak saját company workgroupjai). Audit: meglévő push-szinkron.
4. Tesztek: `CrossCsoportMasolas.test.tsx` + Playwright happy path.

### Fázis 4 — Csempe-sort (FR-14) [kicsi]
1. A csempe-lista render előtt `sort((a,b)=>a.legacyGroupNumber-b.legacyGroupNumber)`, függetlenül az API-sorrendtől.

### Fázis 5 — EUA verifikáció (FR-18) [kicsi]
1. Ellenőrizni, hogy a szerver `overview.currencies` nem szűri-e ki az EUA-t; ha a kliens hardcode-rend (`:65`) a forrás, és az EUA ott van → kész; egyébként a renderelt sorlistába a hardcode-rend EUA-ját kell venni.

## Definition of Done (a spec §9.3 szerint)
lint + `mvn verify` (TestContainers, ha migráció) + Vitest ≥80% az érintetteken + Playwright + gitleaks + nincs `@Disabled/skip` új kódon + PR-review + merge + push + **Electron telepítő (mindkét host: penztar/arfolyam-keszito + kozponti)**.
