---
title: Vault evolution — gap-analízis a 2026 SOTA-hoz képest
type: reference
created: 2026-05-02
companion: 2026-memory-architecture-sota.md
---

# Vault gap-analízis (2026-05-02)

## TL;DR

A jelenlegi `D:\valutavalto-vault\` egy egyszerű **fájlrendszeres fact-store**: `sessions/`, `feedback/`, `references/`. Erős a kronologikus naplózásban (timestamping), de **3 SOTA képességből 2-t hiányol** és 1-et csak részlegesen valósít meg.

## Képességmátrix (jelenlegi vs SOTA)

| SOTA képesség | Jelenlegi vault | Gap | Prioritás |
|---|---|---|---|
| **Bi-temporal validity** (Zep `valid_at`/`invalid_at`) | ❌ csak `created` dátum, nincs `valid_until` / `superseded_by` | Régi session-ek elavult állítások közé keverednek (pl. "v2.3.7 az aktuális" amikor már v2.5.2 a current) | **HIGH** |
| **Multi-tier memória** (Letta core/recall/archival) | 🟡 részleges: `CLAUDE.md` = "core" (always-loaded), vault = "archival" | Nincs explicit `recall` (recent session search), nincs proaktív core ↔ archival pressure management | **MEDIUM** |
| **Procedurális memória** (Mem0 `memory_type`) | 🟡 részleges: `feedback/` tartalmaz workflow-kat, de **nincs trigger + steps + verify formátum** | A workflow-k szövegfolyamként élnek a feedback-ben, nem strukturált eljárásokként | **HIGH** |
| **Knowledge graph** (entitás-relacio) | ❌ nincs | Nincs query: "minden PR ami a v2.5.x-hez tartozik" vagy "ki adott direktívát az AML-re" | **LOW** (manuális grep elég ennek a méretnek) |
| **Memory consolidation** (LinkedIn pattern) | ❌ nincs | A session-jegyzetek lezárásukor nem distillálnak közös tanulságot | **MEDIUM** |

## Konkrét probléma-példák a jelenlegi vault-ban

### 1. Stale facts (temporal gap)

A `CLAUDE.md` "Aktuális release-állapot" szekciója még mindig a `v2.3.7` és a `Penztar-Setup-2.3.7-20260429.exe` telepítőt említi P0-ként, **miközben a 2026-05-01-i atomi sprint (PR #338-#343) a v2.5.1-et és v2.5.2-t deploy-olta**, és a 2026-05-02-i v2.5.3 sprint a frontend kompaktálást hozta. **A "current" tény elavult**, de még mindig a CLAUDE.md-ben van.

**SOTA megoldás**: minden fact-nak legyen `valid_at` és `invalid_at` mezője. Amikor v2.5.2-re frissítettük a state-et, a v2.3.7 record `invalid_at` set lenne, és a query "current installer version at 2026-05-02" csak a v2.5.2-t adná vissza.

### 2. Workflow-k szövegfolyamként

A `feedback/ai-review-mandate-zero-tolerance.md` egy **igazi procedurális workflow**:
1. Várj 1-2 percet az admin-merge után
2. `gh api pulls/{N}/reviews` + `comments` lekérés
3. Minden P0/P1/P2 javítás
4. Új follow-up PR + cikluson újra
5. Léphetsz a következő feladatra ha tiszta

De ez **prózaként** van, nem strukturált formátumban. Ha az ügynök automatikusan akarná futtatni, nehezebb extrahálni a step-eket. Ha frissül egy lépés, nehezebb lokalizálni.

**SOTA megoldás**: külön `procedures/` mappa, YAML frontmatter-rel + strukturált step-ek + verify-block.

### 3. Nincs "superseded-by" linking

A v2.4.6 (B6 privilege escalation fix) feedback **felülírta** a v2.4.5-ös naív backward-compat fallback-et. De a vault-ban nincs explicit link arra, hogy "ez a tény a régit felülírja". Egy AI-ügynök, ha a v2.4.5-ös feedback-et találja meg először, hibás döntést hozhat.

**SOTA megoldás**: minden feedback YAML frontmatter-jébe `supersedes:` és `superseded_by:` mező, ahogy a Zep `invalidated_by` éleket épít.

## Mit hagyjunk meg

- ✅ A **fájlrendszeres approach** jó kis-közepes projektre (10-100 dokumentum). Nem kell Neo4j vagy vector DB.
- ✅ Az **Obsidian-kompatibilitás** előnyös: a felhasználó vizuálisan navigálhat, backlinkek működnek, kereséshez Obsidian elég.
- ✅ A **markdown frontmatter** elegendő strukturáltsághoz.
- ✅ A **napló-pattern** (sessions/YYYY-MM-DD-name) jó episodic memory implementáció.

## Javasolt fejlesztések (priority-sorrendben)

### P0 — Temporal validity (Zep pattern adoption)
- Minden session-jegyzet frontmatter-ébe: `valid_until: <ISO date or "current">`. Ha session-ben state változik, az előző session-jegyzet `valid_until` set-je az aktuális dátumra.
- Új helper: `references/temporal-state-tracker.md` — egy "current state" fájl, amit minden session frissít (nem 11 helyen szétszórt info, mint most).

### P0 — Procedurális memória (új `procedures/` mappa)
- Új mappa: `procedures/`
- Per-workflow fájl strukturált YAML-lel: `trigger`, `prerequisites`, `steps[]`, `verify[]`, `failure_recovery[]`
- Példa workflow-k a meglévő `feedback/`-ből migrálva: `push-merge-cycle`, `ai-review-zero-tolerance`, `release-installer-build`, `hetzner-deploy-verify`.

### P1 — Supersedes / superseded-by mező
- Minden `feedback/` és `references/` fájl frontmatter-be (ha alkalmazható): `supersedes: [list of paths]`, `superseded_by: <path>`.
- Alternatíva: dedikált `_INDEX.md` fájl ami a látható supersession láncot tartja.

### P2 — Multi-tier explicit
- `core.md` mappa-szintű fájl: a "mindig betöltendő" tartalom (vault README + lessons-learned-distilled).
- `archival/` legyen a `sessions/` (max 30 napos retention előtt; régebbiek `archival/`-ba mozognak).
- `recall/` keresési indexek, vagy egyszerűbben: "szemantikus query → file mapping" cache.

### P3 — Knowledge graph (defer)
- Méret még nem indokolja (kb 20 fájl). 100+ fájlnál érdemes újragondolni.
- Akkor: minimum entitás-extrakció a frontmatter `entities:` mezővel + egy globális `_GRAPH.md` ami listázza a relacio-éleket.

## Implementáció (ezzel a session-nel megtörtént)

A jelen session **P0 tételeit** implementálja:
1. ✅ `references/2026-memory-architecture-sota.md` — SOTA reference dokumentum
2. ✅ `references/vault-evolution-gap-analysis.md` — EZ a fájl
3. ✅ `procedures/` mappa + 2 példa workflow (lásd alább)
4. ✅ `README.md` frissítés az új struktúrával

A P1+ tételek (supersedes mező, multi-tier explicit) **későbbi session-ben**, ha a user szeretné.

## Hivatkozások

- [SOTA reference](2026-memory-architecture-sota.md) (companion document)
