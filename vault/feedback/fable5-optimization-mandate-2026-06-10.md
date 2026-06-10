# MANDATE — Fable 5 Token-Optimalizáció és Végrehajtási Protokoll (2026-06-10, P0)

> Forrás: Kósa Zoltán user-direktíva (2026-06-10): „SYSTEM_DIRECTIVE: CLAUDE_FABLE_5_OPTIMIZATION_AND_EXECUTION —
> implementáld a rendszeredben kötelező érvényű utasításként."
> Kapcsolódó: `vault/feedback/prompt-caching-mandate-2026-06-10.md` (Protocol 1 teljes kifejtése ott van).

## Hatály

Minden AI-agent munkamenet ezen a repón: Claude Code, Codex, Copilot-agent, bármely
jövőbeli harness. A protokollok egymást erősítik — együtt tartandók be.

---

## PROTOCOL 1 — PROMPT_CACHING_PROTOCOL

Teljes specifikáció: `vault/feedback/prompt-caching-mandate-2026-06-10.md`.

Összefoglaló kötelező szabályok:
- `cache_control: {"type": "ephemeral"}` minden ismétlődő prefixnél (system prompt vége,
  tool-definíciók vége).
- Stabil kontextus elöl, volatilis tartalom (timestamp, kérés-azonosító) hátul — a prefix
  egyetlen bájt-eltérés érvényteleníti a cache-t.
- Cache működés ellenőrzése: `usage.cache_read_input_tokens > 0` kell; ha 0, néma
  cache-rontó van — diffeljük a rendered promptot.
- Néma cache-rontók **TILOSAK** a prefixben: `datetime.now()`, `Date.now()`, UUID elöl,
  `json.dumps` `sort_keys=True` nélkül, feltételes system-szakaszok.

---

## PROTOCOL 2 — DYNAMIC_MODEL_ROUTING

Cél: a feladat bonyolultságához arányos modellt használni — se alul-, se túlhasználat.

### Model-szintek és feladat-típusok

| Szint | Model | Input/Output $/Mtok | Mikor |
|-------|-------|---------------------|-------|
| L3 | Fable 5 (`claude-fable-5`) | $10 / $50 | Komplex tervezés, multi-file refactor, pénzügyi logika validáció, AML-döntés, security audit, új feature-architektúra |
| L2 | Opus 4.8 (`claude-opus-4-8`) | $5 / $25 | Közepes kódgenerálás, PR-review, tesztek írása, többlépéses hibakeresés |
| L1 | Sonnet 4.6 (`claude-sonnet-4-6`) | $3 / $15 | Rutin kódszerkesztés, formázás, logolás, egyszerű utility, dokumentáció-javítás |
| L0 | Haiku 4.5 (`claude-haiku-4-5-20251001`) | $1 / $5 | Szöveg-ellenőrzés, keresés, rövid lookup, non-kód feladatok |

### Routing döntési szabályok

1. **Alapértelmezett szint ebben a sessionben:** az aktuális munkamenet modellje (jelen
   esetben Fable 5). Lefelé-routing csak explicit döntéssel.
2. **Fable 5 kötelező** (L3): pénzügyi tranzakciós logika változtatása, árfolyam/kerekítés/
   AML-küszöb, Flyway migráció (oszlop-törlés, constraint), Electron-telepítő, security-gate.
3. **Opus 4.8 ajánlott** (L2): önálló PR-ek normál kód-review köre, 3-5 fájlt érintő
   refactor, integrációs teszt generálás.
4. **Sonnet/Haiku elég** (L1/L0): egysoros javítás, README/komment szerkesztés, keresés,
   formázás, log-string csere.
5. **Subagent-routing:** Explore-subagent mindig L1/L0-on futhat (olvasás, nem döntés).
   Adversariális review-subagent L2+ (minőség-kritikus).

---

## PROTOCOL 3 — CONTEXT_WINDOW_MANAGEMENT

Cél: a fő kontextus-ablak tisztaságának fenntartása — a cache hatékonyságát rontó
felesleges betöltés elkerülése.

### Kötelező szabályok

- **Célzott olvasás:** soha ne tölts be teljes `vault/**` könyvtárat session-startkor.
  Konkrét fájlt olvasunk, konkrét okkal (összhangban: CLAUDE.md + prompt-caching mandate).
- **Aszinkron subagent nagy olvasásokhoz:** ha egy feladathoz 5+ fájlt kell végigolvasni,
  `Explore`-subagent csinálja — csak az összefoglalót hozza vissza a fő kontextusba.
- **Token-napló küszöb:** ha a munkamenet token-felhasználása megközelíti a kontextus-ablak
  80%-át, proaktívan jelzünk a usernek, hogy érdemes-e `/clear`-rel friss sessiont nyitni a
  következő független feladathoz.
- **Stabil → volatilis sorrend minden válaszban:** előzmények, invariánsok, spec elöl;
  aktuális task-specifikus adat hátul. Ez cache-barát és „lost-in-the-middle" ellenes.
- **Nem-szükséges historikus mandate betöltése TILOS** — on-demand, csak ha a task
  konkrétan érinti (ld. `_active_mandates.md` on-demand lista).

---

## PROTOCOL 4 — TASK_COMPLETION_VS_TOKEN_LIMITS

Cél: a feladat minden esetben teljesen és bizonyítottan lezárul — token-korlát nem
okozhat csonka deliverable-t.

### Kötelező szabályok

- **`max_tokens` explicit** minden Claude API-hívásban (kódban): soha ne hagyjuk a
  default értéken, ha a várható kimenet mérete előre ismert.
- **Continuation mechanism:** ha a generálás `stop_reason: "max_tokens"` miatt csonkul,
  az agent automatikusan folytatja a generálást (follow-up kérés az eddigi kimenettel
  prefixelve), amíg `stop_reason: "end_turn"`.
- **Deliverable-ellenőrzés küszöb:** minden feladat lezárásakor a megigért deliverable-ek
  listáját el kell ellenőrizni. Csonka feladat (`// TODO`, `... ide jön a többi`, hiányzó
  fájl) TILOS leadni — vagy fejeziük be, vagy jelzünk a usernek mi hiányzik és miért.
- **Session-határon átívelő feladat:** a context-compaction mechanizmus megőrzi a session
  folytonosságát; ne kezdjük újra a feladatot, hanem folytatjuk a compaction utáni
  összefoglalóból.
- **Nagy feladat = bontás:** ha egy feladat nyilvánvalóan nem fér el egy menetben
  (5+ komponens, 500+ sor új kód), bontsuk részfeladatokra és jelezzük a sorrendet,
  nem hagyjuk implicit-ként.

---

## PROTOCOL 5 — FALLBACK_SIGNALING

Cél: átlátható jelzés, ha az agent nem a legmegfelelőbb modell-szinten dolgozik,
vagy ha model-regresszió történik.

### Vizuális jelzések

```
[WARNING: MODEL_REGRESS_DETECTED]
```
Ezt a taget az agent a válasz elejére írja, ha:
- A feladat L3-as (Fable 5) szintet igényelne, de az aktuális session L2 vagy alacsonyabb.
- Pénzügyi-kritikus logika változtatás történik, de a session Sonnet vagy alacsonyabb szinten fut.

```
[INFO: SUBAGENT_DELEGATED — <szint>]
```
Ezt a taget az agent a válaszba írja, ha aktívan delegált egy subagent-re a feldolgozás egy részét.

```
[INFO: CONTEXT_PRESSURE — <becsült %> — /clear ajánlott]
```
Ha a token-napló azt mutatja, hogy a kontextus >80%-ban telített.

### Mikor NEM kell jelzés

- Rutinfeladatnál nincs regresszió.
- Subagent delegálás explicit user-kérésre történik.
- A kontextus jól belül van a limiteken.

---

## Összhang a meglévő mandate-ekkel

Ez a mandate kiegészíti (nem írja felül):
- `vault/feedback/prompt-caching-mandate-2026-06-10.md` (Protocol 1 teljes részletezése)
- `vault/feedback/opus48-munkamod-mandate-2026-05-31.md` (bizonyíték-kényszer, hallucináció-tiltás)
- `CLAUDE.md` — célzott olvasás, domén-invariánsok, security gate feltételrendszer
- `AI_CONTRACT.md` — hard tiltások (secret, teszt-integritás)
