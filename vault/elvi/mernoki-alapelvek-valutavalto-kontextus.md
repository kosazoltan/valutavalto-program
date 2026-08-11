---
title: Mérnöki alapelvek a Valutaváltó ERP kontextusában (Clean Architecture, SOLID, DDD, REST, konkurencia, DORA)
type: long-term-reference
tags: architecture, clean-architecture, solid, ddd, rest, concurrency, dora, devops, modernizacio, backend, java, electron
areas: database, security, riport, tenant, penztar, frontend, deploy
created: 2026-08-11
status: active
---

# Mérnöki alapelvek a Valutaváltó ERP kontextusában

Ez a dokumentum **nem tankönyv**. Az általános mérnöki alapelveket (Clean
Architecture, SOLID, DDD, REST-tervezés, konkurencia, DORA/DevOps-teljesítmény,
LLM-alapú legacy-modernizáció) **ennek a repónak a mért valóságához** köti.
Minden szakasz végén ott van, hogy a Valutaváltóban **mi a helyzet ma**, és
**mi a szabály holnaptól**.

Az elvek forrása kettős: (1) DevOps-teljesítménykutatás — a magas IT-teljesítmény
és a bizalmi kultúra közvetlenül hat a jövedelmezőségre; (2) LLM-alapú
legacy→CQRS modernizációs eszközök (Airchitect-osztály) tapasztalata — az
automatizált, strukturált folyamat drasztikusan csökkenti a technikai adósságot,
de a **siker feltétele az automatizáció és az emberi szakértelem egyensúlya**.

---

## 0. Mért kiindulóállapot (2026-08-11, `backend/src/main/java/hu/puzzleir/valuta`)

| Metrika | Érték | Parancs |
|---|---|---|
| `@RestController`/`@Controller` osztály | 199 | `grep -rl "@RestController\|@Controller" --include=*.java .` |
| `@Service` osztály | 278 | `grep -rl "@Service" --include=*.java .` |
| Repository | 223 | `grep -rl "@Repository\|extends JpaRepository" --include=*.java .` |
| `@Entity` | 231 (300 fájl az `entity/` alatt) | `grep -rl "@Entity" --include=*.java .` |
| **Controller → Repository közvetlen injektálás** | **23 fájl / 39 találat** | `python scripts/dev-tools/layer-violation-scan.py` |
| Controller importál `entity`-t | 98 fájl | `grep -rl "import hu.puzzleir.valuta.entity" controller/` |
| Entity → service/repository import | **0** | `grep -rl "import hu.puzzleir.valuta.service\|...repository" entity/` |

**Olvasat:**
- A **függőségi irány alapvetően helyes**: a domain (`entity/`) nem függ kifelé
  (0 találat). Ez a legfontosabb Clean Architecture invariáns, és **áll**.
- A hiba a **másik végén** van: 23 controller átugorja a service-réteget, és
  98 controller nyers entitást lát. Ez a technikai adósság mérhető magja.
- A mérőeszköz **létezett, de nem blokkolt** (`layer-violation-scan.py` exit 0) —
  ez a „write-only audit" antipattern: mérünk, de a mérés nem hat vissza a
  folyamatra. **Az automatizáció csak akkor csökkenti az adósságot, ha kapu is.**

---

## 1. Clean Architecture — a függőségi szabály

**Elv.** Rétegek befelé: `Frameworks & Drivers` → `Interface Adapters` →
`Application` → `Domain`. A függőségek **kizárólag befelé** mutatnak. A mag
független adatbázistól, UI-tól, keretrendszertől.

**Leképezés a Valutaváltóra:**

| Clean réteg | Valutaváltó megfelelő |
|---|---|
| Frameworks & Drivers | Spring Boot, JPA/Hibernate, Flyway, PostgreSQL, Electron main-process, `packages/electron-platform` |
| Interface Adapters | `controller/`, `dto/`, `mapper/`, `packages/shared-api` (generált TS típusok), `packages/shared-ipc` |
| Application | `service/` — használati esetek, tranzakcióhatár, orkesztráció |
| Domain | `entity/` + üzleti invariánsok (HUF 5 Ft kerekítés, dekád, göngyölés, companyId) |

**Repo-specifikus szabályok (kötelező):**

1. **Controller SOHA nem injektál Repository-t.** A vétel/eladás/sztornó,
   napzárás, értéktár-mozgás mind pénzmozgás — a tranzakcióhatárnak a
   service-rétegben kell lennie, mert az **OSIV ki van kapcsolva** (lazy
   asszociáció csak service-tranzakción belül él) és mert a
   **CashLockOrdering** lock-sorrend csak ott kényszeríthető ki.
   Controllerből hívott repository = tranzakció nélküli olvasás = lazy-hiba
   vagy deadlock-kockázat.
2. **Az API-határon DTO megy, nem entitás.** A 98 entity-importáló controller
   nemcsak stílushiba: az entitás szerializálása kiszivárogtathat
   más tenant adatára mutató lazy asszociációt, és az entitás minden
   séma-változása azonnali **breaking API change** lesz a 4 kliensen
   (`packages/shared-api` 746 endpoint).
3. **A domain-mag keretrendszer-független marad.** Az `entity/` alatt
   0 service/repository import van — ez az állapot **regresszió-védett**
   (`layer-violation-scan.py` Entity→Service szabály).

**Tolerált kivétel (indoklással):** tisztán olvasó, tenant-független
referencia-végpont (pl. `TeaorController`, `DictionaryController`) — de a
kivétel **nevesítve** kerül a baseline-ba, nem csendben.

---

## 2. SOLID — hol fáj ez konkrétan itt

| Elv | Valutaváltó-kockázat, ha sérül | Mérőeszköz |
|---|---|---|
| **SRP** — egy osztály, egy változási ok | Isten-service: a `TransactionService`-be épített riport-formázás miatt egy NAV-riport formátumváltozás pénzmozgás-kódot módosít | `scripts/dev-tools/god-class-scan.py`, `complexity-scan.py` |
| **OCP** — bővítésre nyitott, módosításra zárt | Új valutanem / új cég (4 tenant) hozzáadása meglévő `switch`-ek átírását igényli → regresszió a többi cégnél | `magic-values-scan.py` |
| **LSP** — altípus helyettesíthető | Sztornó-tranzakció altípus, ami az ős invariánsát (előjel, `financialEffective`) megszegi → hibás napi aggregáció | pénzügyi unit-tesztek |
| **ISP** — kicsi, célzott interfészek | Kövér sync-interfész, amit a pénztár- és az értéktár-kliens is kényszerből implementál, felében no-op metódusokkal | `packages/shared-ipc` IpcRoutes review |
| **DIP** — absztrakcióra függés | Service közvetlenül `RestTemplate`-tel hívja az MNB-t → az árfolyam-logika nem tesztelhető hálózat nélkül | `dep-map.py`, `import-cycle-detect.py` |

**Kiemelt DIP-példa a repóban:** az MNB-árfolyam kötelező (törvény), a
lekérés viszont hálózati I/O. A helyes irány: a service egy
`ExchangeRateSource` absztrakcióra függ, a HTTP-implementáció az
infrastruktúra-rétegben van — így az árfolyamváltozás-kori kötelező nyomtatás
logikája hálózat nélkül is tesztelhető.

**Fontos korlát (a források egyensúly-tanulsága):** SOLID-refaktor egy élő
pénzügyi rendszerben **csak mérésre** indul. A „hasonló, de nem azonos" kód
összevonása regressziós kockázat, nem nyereség — lásd a tudatosan NEM
egyesített `api-proxy` három változatát (`.hermes.md`, platform-szakasz).
Refaktor előtt: `codebase-duplication-and-refactor-scoping` skill.

---

## 3. Domain-Driven Design — mi itt az Entity és mi a Value Object

**Elv.** Entitás = saját identitás + életciklus. Value Object = identitás
nélküli, **immutable**. Aggregátum = egy gyökérentitás által összefogott
konzisztencia-határ. Az anémiás modell (adat az entitásban, minden logika a
service-ben) kerülendő.

**Leképezés:**

| DDD fogalom | Valutaváltó példa |
|---|---|
| Entitás | `Transaction`, `Worker`, `Branch`, `CashBalance`, `VaultTransfer` |
| Value Object (jelölt) | pénzösszeg (deviza + összeg + kerekítési szabály), címletbontás (`denomination_balance` kulcs), dekád-intervallum, árfolyam-pár |
| Aggregátum-gyökér | `Transaction` (a hozzá tartozó `TransactionBanknote` sorokkal), napzárás-fej a lépéseivel, értéktár-`Transfer` a tételeivel |
| Konzisztencia-határ | **a companyId minden aggregátumon belül azonos** — tenant-keveredés aggregátumon belül tiltott |

**Repo-specifikus DDD-szabályok:**

1. **A pénzösszeg Value Object-jelölt, nem nyers `BigDecimal`.** A HUF 5 Ft-os
   kerekítés ma szétszórt szabály; VO-ba zárva egy helyen kényszeríthető ki, és
   a kerekítés nem felejthető el egy új aggregációban.
2. **Az invariáns az aggregátumban él, nem a controllerben.** A
   `financialEffective=TRUE` szűrés, a dekád-határ (naptári nap: 1-10, 11-20,
   21-hó vége), a KKTG-elkülönítés — ezek domain-szabályok. Ha ezek
   controllerbe vagy frontendbe szivárognak, a másik kliens megszegi őket.
3. **A Ubiquitous Language magyar.** `napzaras`, `cimletezes`, `gongyolites`,
   `ertektar` — ezek a valós üzleti fogalmak. A repo-memória
   területcímkéi (`npm run memory:areas`) **ezt a nyelvet kódolják**;
   a kód angol, de a fogalomhatárok a magyar domain-nyelvet követik.
4. **Legacy-lookup kötelező DDD előtt.** Az eredeti Delphi program 331 modulja
   és 212 DB-táblája már modellezte ezt a domaint. Új aggregátum tervezése előtt:
   `npm run memory:query -- "<fogalom>" --area legacy` és `--area specifikacio`,
   valamint `npm run memory:symbol -- <fogalom>`. Az eltérést **indokolni kell** —
   ez az „emberi szakértelem" oldala az egyensúlyban.

---

## 4. REST API tervezés — a 746 endpoint kontraktusa

**Elv.** Főnevek, nem igék. HTTP-metódus hordozza az akciót. Konzisztens
hibaobjektum. Pagináció nagy halmazokon. Verziózás előre megtervezve.

**Leképezés — kötelező szabályok:**

1. **Erőforrás-alapú útvonal.** `GET /api/transactions`, nem `GET /api/getTransactions`.
   Meglévő eltérő végpontot **nem nevezünk át visszamenőleg** (4 kliens
   fogyasztja), de újat csak így hozunk létre.
2. **Metódus-szemantika pénzmozgásnál kritikus.**
   - `POST` = új tranzakció (nem idempotens) → **offline sync mellett
     idempotencia-kulcs kötelező**, különben a `penztar-client` retry-ja
     duplikált vételt hoz létre. Ez nem elméleti: a sync-engine offline
     outbox-szal dolgozik.
   - `PUT` = teljes csere, idempotens. `PATCH` = részleges.
   - **Sztornó nem `DELETE`.** A sztornó üzleti esemény, auditált, nyoma marad:
     `POST /api/transactions/{id}/reversal`. Pénzügyi rekord soha nem törlődik.
3. **Egységes hibaobjektum**: kód + ember-olvasható üzenet + részletek.
   A validációs hibák **egyszerre, tömbben** jönnek vissza — a pénztáros
   végfelhasználó nem informatikus, nem javíthat iteratívan mezőnként.
4. **Pagináció**: minden listavégpont, ami tranzakciót vagy audit-logot ad
   vissza, lapozott. Ellenőrzés: `scripts/dev-tools/endpoint-audit.py`,
   `jpql-perf-scan.py`, `n-plus-one-scan.py`.
5. **Verziózás és kontraktus-kapu.** A típusok generáltak
   (`npm run typegen` → `packages/shared-api`). **Contract-érintő változásnál
   kötelező**: teljes hívó-grep (java + ts + tsx), `npm run typecheck`
   mind az 5 projekten, `frontend-backend-contract-audit.py`. Egy elrontott
   kontraktus 4 klienst tör el, ~72 pénztárgépen.

---

## 5. Konkurencia vs. párhuzamosság — mikor melyik

**Elv.** Konkurencia = átfedő feladatkezelés (I/O-kötött, válaszkészség).
Párhuzamosság = egyidejű végrehajtás több magon (CPU-kötött, átbocsátás).

**Leképezés:**

| Feladat a Valutaváltóban | Jelleg | Eszköz |
|---|---|---|
| MNB-árfolyam lekérés, banki integráció, e-mail | I/O-kötött | `CompletableFuture` láncolás, `@Async` + dedikált `ExecutorService` |
| Offline sync-engine feltöltés (`penztar-client`) | I/O-kötött | outbox + retry, backpressure-rel |
| Napi/dekád riport-aggregáció nagy tranzakcióhalmazon | CPU-kötött | csak mérés után parallel stream / `ForkJoinPool` |
| Pénzmozgás (vétel/eladás/napzárás) | **egyik sem** | **soros, tranzakción belül, CashLockOrdering szerint** |

**Kemény szabályok:**

1. **Pénzmozgást nem párhuzamosítunk.** A cash-balance lock-sorrend
   (`CashLockOrdering`, #947–#953) deadlock-megelőzés; párhuzamosítás
   megszegi. Sebességprobléma esetén a megoldás index/query-optimalizálás,
   nem szálkezelés.
2. **Közös `ForkJoinPool.commonPool()` tiltott** kérés-kiszolgáló úton:
   egy hosszú riport-aggregáció megéheztetné a `parallelStream()`-et
   használó összes többi kérést. Dedikált pool, néven nevezve.
3. **Async metódus nem visz tovább tranzakciót.** `@Async` új szálon fut,
   a `@Transactional` kontextus nem öröklődik — OSIV kikapcsolva mellett ez
   azonnali `LazyInitializationException`. Az async határ **DTO-t kap, nem entitást.**
4. **Ütemezett feladat + több node = duplikált futás.** Hetzner primary +
   Scaleway standby mellett az ütemezett job-oknak lock-olniuk kell.
   Ellenőrzés: `scripts/dev-tools/scheduled-task-audit.py`.

---

## 6. DevOps-teljesítmény — miért kapu, és nem riport

A DevOps-kutatás állítása: a magas IT-teljesítmény (gyakori, kis, visszafordítható
szállítás + rövid helyreállítás) és a **bizalomra épülő kultúra** közvetlenül
javítja a jövedelmezőséget és a dolgozói elégedettséget. A bizalmi kultúra
mérnöki vetülete itt: **a kapuk a folyamatot védik, nem az embert vádolják.**

**Ebből a repóra levezetett működési szabály:**

1. **Kis, atomi PR.** Egy munkaegység = egy fókuszált commit (AGENTS.md
   PR-méret szabály). A nagy PR nem review-zható, és a hibát a `~72` gépes
   flottán a telepítő viszi ki.
2. **A mérés kapu, nem dísz.** Egy audit-szkript, amelynek a kimenetét
   senki nem nézi, technikai adósságot **legitimál**. Minden audit-eszköz
   három állapot egyike:
   - **BLOCKING** — CI-ben bukik (pl. `check:platform-boundaries`),
   - **RATCHET** — baseline rögzítve, romlani nem szabad, javulni igen,
   - **INFORMATIONAL** — kifejezetten megjelölve, tudatos döntés.
   Deklarálatlan állapot nincs.
3. **Ratchet a big-bang refaktor helyett.** 39 rétegsértést nem egy PR-ben
   javítunk (pénzügyi rendszerben ez felmérhetetlen blast radius). Rögzítjük
   baseline-ként, a CI bukik, ha nő, és a szám csak lefelé mozdulhat.
   Ez az „automatizáció csökkenti a technikai adósságot" elv **biztonságos**
   megvalósítása.
4. **Helyreállítás > hibamentesség.** A visszaállíthatóság (aláírt telepítő
   előző verzióval, Flyway-migráció visszaút, Hetzner→Scaleway standby)
   fontosabb metrika, mint a hibaarány.

---

## 7. LLM-alapú modernizáció — mit lehet gépre bízni és mit nem

Az Airchitect-osztályú eszközök tanulsága: az LLM a legacy→modern
architektúra-átültetésben a **mechanikus, sokszorosított munkát** viszi el
(minta-felismerés, réteg-szétválasztás javaslata, DTO/mapper generálás,
hívó-felderítés), az **üzleti helyesség** viszont emberi/verifikációs kérdés
marad.

**Munkamegosztás ebben a rendszerben (multi-agent):**

| Szerep | Mit visz | Mit NEM visz |
|---|---|---|
| **Planner** | architektúra-döntés, réteg-besorolás, munkaegység-bontás, kockázat-sorrend | implementáció |
| **Coder** | mechanikus átültetés a terv szerint, teszt-first | döntés, scope-bővítés |
| **Ellenőr 1** | helyesség: spec vs. kód, réteg- és SOLID-sértés, DDD-invariáns | átírás |
| **Ellenőr 2** | támadó nézőpont: tenant-szivárgás, konkurencia, blast radius, teszt-adekvátság | átírás |
| **Bíró** | evidencia-alapú döntés a leletek felett | harmadik review |
| **Ember (Kósa Zoltán)** | üzleti helyesség, jogi megfelelés, merge/deploy jóváhagyás | — |

**Kemény korlát:** az LLM-generált refaktor pénzügyi magban **csak akkor
mehet át**, ha a viselkedés-azonosság bizonyított (a meglévő teszt zöld ÉS
a változás előtt írt jellemző-teszt is zöld). Az „úgy néz ki, ugyanaz"
nem bizonyíték — ugyanaz a szabály, mint a platform-kiemelésnél.

---

## 8. Munkamenet-integráció (mit kell ténylegesen csinálni)

Nem-triviális változás előtt (3+ fájl / pénzügyi / tenant / kontraktus / DB):

```bash
npm run memory:query -- "<kulcsszavak>" --area <terület>       # kötelező (AGENTS §2.1)
npm run memory:query -- "<fogalom>" --area legacy              # kötelező új funkciónál
npm run memory:query -- "<fogalom>" --area specifikacio        # kötelező új funkciónál
python scripts/dev-tools/layer-violation-scan.py --check-baseline   # réteg-ratchet
python scripts/dev-tools/multi-tenant-audit.py                 # tenant-izoláció
python scripts/dev-tools/blast-radius.py <fájl>                # hatókör
```

Backend-változás után továbbá: `npm run typegen`, `npm run typecheck` (5 projekt),
kontraktus-érintésnél `frontend-backend-contract-audit.py`.

## Kapcsolódó

- `AGENTS.md` §2.1 (repo-memória read-gate), §4 (kockázatarányos ellenőrzés)
- `CLAUDE.md` (domain-kontextus)
- `.hermes.md` (platform-irány, kliens→kliens tilalom)
- `scripts/dev-tools/layer-violation-scan.py` + `.baseline.json`
- Hermes skill: `valutavalto-architecture-quality` (review-szempontrendszer)
