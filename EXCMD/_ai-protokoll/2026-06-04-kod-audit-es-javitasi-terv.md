---
title: "Kód-audit és javítási terv — 2026.05.20–06.04 modulfejlesztés ground-truth ellenőrzése"
modul: kod-audit-felulvizsgalat
kategoria: minoseg-audit
alkalmazas: backend + frontend-react + 3 Electron kliens
prio: Magas
keszult: "2026-06-04"
modszer: ground-truth (typecheck / eslint / teszt / grep) — NEM leírás-alapú, kizárólag kódtény
---

# 0. Összefoglaló (TL;DR)

A 2026.05.20–06.04 intervallum modulfejlesztését **ground-truth eszközökkel** (nem a
leírások, hanem a tényleges kód: `tsc --noEmit`, `eslint`, teljes teszt-suite, `grep`)
ellenőriztem. A kódbázis **összességében jó állapotú**; a fejlesztések **ténylegesen
implementálva** lettek (nem csak analizálva) — a merge-elt PR-ek (#1005–#1025) valódi kódot,
migrációt és tesztet tartalmaznak.

**Egy VALÓDI, csendben elromlott hibát találtam és javítottam** (kliens-typecheck), plusz egy
kód-hygiéniai javítást (néma catch). A `production` TypeScript-kód `as any`-mentes, az eslint
0 errort ad. A részletek alább, fájl:sor bizonyítékkal.

| # | Súly | Terület | Állapot |
|---|---|---|---|
| F-1 | **P1 (valódi bug)** | kozponti + arfolyam kliens typecheck (24 `error TS`) | ✅ JAVÍTVA |
| F-2 | P3 (hygiéne) | 2 néma `catch (Exception ignored){}` (backend) | ✅ JAVÍTVA |
| F-3 | — (tiszta) | `as any` mind teszt-fájlban (prod-mentes) | nincs teendő |
| F-4 | — (tiszta) | FE eslint 0 error; FE üres-catch mind legitim fallback | nincs teendő |

---

# 1. Audit-módszertan (kizárólag kódtény)

| Ellenőrzés | Parancs | Eredmény |
|---|---|---|
| Backend fordítás | `mvnw -o -q compile` | EXIT=0 |
| FE typecheck (4 csomag) | `npm run typecheck` mindegyikben | frontend-react ✅, penztar-client ✅, **kozponti ✗(12), arfolyam ✗(12)** → **JAVÍTVA után mind ✅** |
| FE eslint (errorok) | `npx eslint src --quiet` | 0 error |
| `as any` / `@ts-ignore` | `grep -rE` a TS/TSX-en | 24 `as any` (mind teszt), 0 `@ts-ignore` |
| Néma catch | `grep -rE "catch.*\{\s*\}"` | 5 FE (legitim fallback) + 2 backend (silent → javítva) |
| Teljes backend teszt | `mvnw -o test` | (lásd 5. szakasz) |
| Intervallum-commitok | `git log --since 2026-05-20 --until 2026-06-05` | 254 commit (squash-merge), valódi kód |

---

# 2. F-1 — Kliens typecheck-bukás (VALÓDI BUG, JAVÍTVA)

## Bizonyíték
`kozponti-client` és `arfolyam-keszito-client` `npm run typecheck` (`tsc --noEmit`) **12-12
`error TS`-szel bukott**, miközben a `penztar-client` és a `frontend-react` zöld:

```
electron/local-first.ts(39,31): TS7016: Could not find a declaration file for module 'sql.js'.
../packages/local-first-core/src/database.ts(8,42): TS2307: Cannot find module 'sql.js'.
../packages/local-first-core/src/database.ts(11,17): TS2307: Cannot find module 'electron-log'.
… (9× sql.js + 2× electron-log a megosztott packages/local-first-core/src forrásokban)
```

## Gyökérok (kódtény)
1. **TS7016:** a `kozponti-client` és `arfolyam-keszito-client` `package.json`-jából **hiányzott
   a `@types/sql.js`** (a `penztar-client`-ben `^1.4.11`-ként benne volt). Saját
   `electron/local-first.ts`-ük `import type { Database } from 'sql.js'` → implicit any.
2. **TS2307:** a két kliens a megosztott `../../packages/local-first-core/src`-t **nyers TS
   source-ként importálja** (`packages/local-first-core/package.json`: `"types": "src/index.ts"`),
   és e source-ok `sql.js`/`electron-log` importjai nem voltak feloldhatók, mert a
   `packages/local-first-core` declared deps-e (`sql.js`, `electron-log`, `@types/sql.js`)
   **nem volt telepítve** (nincs npm workspace a root-ban → nincs hoisting).
   A `penztar-client` ezt NEM üti, mert saját, önálló `local-first.ts`-szel megy (nem a
   megosztott package source-át húzza be).

> A CI `frontend-react Lint + TypeCheck` job CSAK a `frontend-react`-et typecheck-eli, a
> három Electron klienst NEM → ez a típushiba CI-ben láthatatlan maradt.

## Javítás (elvégezve)
1. `@types/sql.js: ^1.4.11` hozzáadva a `kozponti-client` ÉS `arfolyam-keszito-client`
   `devDependencies`-éhez (a `penztar-client`-tel egyezően).
2. `npm install` a `packages/local-first-core`-ban (a declared deps telepítése) + a két kliensben.

## Verifikáció
`kozponti-client` és `arfolyam-keszito-client` `npm run typecheck` → **mindkettő ZÖLD** (0 error).

## Maradék ajánlás (follow-up, nem blokkoló)
A három Electron-kliens `typecheck`-jét érdemes a **CI-be** is bekötni (külön job), hogy a jövőben
egy ilyen típushiba ne maradjon észrevétlen. A `packages/local-first-core` telepítettsége
(npm workspace bevezetése a root-ban, vagy CI `npm ci` az al-csomagokban) garantálná a tartós
feloldhatóságot.

---

# 3. F-2 — Néma catch a HandlingFeeConfigController-ben (hygiéne, JAVÍTVA)

## Bizonyíték
`backend/.../controller/HandlingFeeConfigController.java:55,60`:
```java
} catch (Exception ignored) { }   // HANDLING_FEE_PER_MILLE / _MAX
```
Az AGENTS.md "Mindig tilos" listája: néma `catch(Exception e){}`. A viselkedés helyes (opcionális
config-param hiányában default ZERO/null), de a kivétel némán elnyelve.

## Javítás (elvégezve)
A két ágban a kivétel `log.trace(...)`-szal naplózva (a `@Slf4j` `log` mezővel), a default-viselkedés
változatlan — így egy váratlan ok (pl. nem-numerikus érték) is észlelhető a strukturált logban.

---

# 4. F-3 / F-4 — Tiszta területek (nincs teendő, bizonyítva)

- **`as any` (24 db) MIND teszt-fájlban** (`useAppMode.test.ts`, `client.test.ts`,
  `rateStore.test.ts`, `localQueue.test.ts`) — `(window as any).electronAPI` mock-minta + 1
  teszt-fixture. A **production TS-kód `as any`-mentes**, nem fed el valódi típushibát.
- **`@ts-ignore` / `@ts-expect-error`: 0 db.**
- **FE eslint: 0 error** (`npx eslint src --quiet`).
- **FE üres-catch (5 db):** mind legitim `.json().catch(() => ({}))` defenzív fallback (rossz JSON →
  default érték), NEM a tiltott néma try/catch. (A `CameraExportPage.tsx:35` branch-lista-betöltés
  hibájának elnyelése nem-kritikus; jelölve, de nem blokkoló.)

---

# 5. Teljes backend teszt-suite eredménye

`mvnw -o test` (a trace-log javítás UTÁN): **1579 teszt, 0 Failure, 0 Error — BUILD SUCCESS.**
Nincs logikai regresszió a teljes backend-en (a 2026.05.20–06.04 modulok tesztjeivel együtt).

---

# 6. Globális konzisztencia-ellenőrzés

- A 2026.05.20–06.04 fejlesztések **implementálva** (nem csak analizálva): #1005–#1025 PR-ek valódi
  entity/migráció/DTO/service/teszt kóddal; a memória/ledger állításai a repo-tényekkel egyeznek.
- Az egyetlen VALÓDI elromlott build-jelzés (kliens typecheck) **javítva + verifikálva**.
- A `production` kód típushelyes, `as any`/`@ts-ignore`-mentes, eslint-error-mentes.

# 7. Tiltások betartva
- Nincs hallucinált finding: minden állítás fájl:sor bizonyítékkal.
- Nincs scope-on kívüli refaktor: csak a feltárt hibák javítva.
- Nincs teszt-gyengítés vagy zöldért-elnyelés.
