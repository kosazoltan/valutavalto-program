# MANDATE — Hibavédelmi Protokoll v2 (KANONIKUS, 2026-05-31, P0)

> Forrás: user-átadott `AI_agent_hibavedelmi_protokoll_2026_v2.md` (teljes, 180 sor, 2026-os módszerek).
> Hatály: minden feladat, minden session, minden ágens (Claude Code, Codex, Gemini).
> Kiegészíti az opus48-munkamódot (C.26) és az univerzális protokollt (C.27) — nem írja felül.
> Index: `_active_mandates.md` C.28.

## PROJEKT-PRECEDENCIA / TANULSÁG (2026-05-31)
- **Párhuzamos ügynök TILOS, ha a user nem kérte.** Egy korábban (általam) spawnolt háttér-ügynök
  ugyanabban a working tree-ben dolgozott → ütközés + suite-bukás. **Egy szál = egy feladat = egy
  working tree.** Loop helyett rotáció; elakadásnál emberi döntés (5.5).
- A vault a tartós szabály helye (NEM a beszélgetés, NEM `.memory` SQLite).

---

# Programozó ügynök — hibavédelmi protokoll (2026. májusi módszerek) — v2

**Cél:** megelőzni/megszakítani a 2026-ban feltárt AI-kódoló hibatípusokat: gondolati hurok
(„doom loop"), ugyanabban a hibában való helybenjárás, kontextus-romlás — kiemelten az, hogy az
ügynök UGYANANNAK a megközelítésnek a VARIÁCIÓIVAL próbálkozik tovább. **Új v2:** STRATÉGIA-ROTÁCIÓ
(4. szakasz) — bukáskor NE finomíts ugyanazon, hanem válts gyökeresen más, akár ELLENTÉTES megközelítésre.

## 0. Alaptörvény
Tényalapú, visszaellenőrzött, hamis haladás nélküli munka. „Kész/működik/zöld" CSAK ha a parancs ÉS a
kimenet bizonyítja. A helybenjárás zöme onnan fakad, hogy az ügynök HISZI, hogy halad, miközben ismétel.

## 1. 2026-ban azonosított fő hibatípusok (ismerd fel)
Gyökerok: az ügynöknek egy feladaton belül NINCS implicit emlékezete a saját korábbi próbálkozásairól.
1. **Gondolati hurok / „doom loop":** sikertelen válasz után közel azonos üzenet/kód ismétlése.
2. **Variáció-csapda:** ugyanannak a megközelítésnek apró változatai — látszólag halad, körben jár.
3. **Recurrent generation:** folyamatosan nagyon hasonló tartalom (aktivációs mintából ~95% észlelhető).
4. **Kontextus-romlás („context rot"):** a kontextus telésével romlik a teljesítmény; ismételt fájl-olvasás.
5. **Hosszútávú leromlás:** ~35 perc után romlás; az idő duplázása ~4× hibaarány.
6. **Munkamenetek közti amnézia.**
7. **Hallucinált szignatúra, félreolvasott fájl, megoldhatatlan tesztre ragadás** (nyom-szintű).
8. **Célsodródás / „echoing":** 7+ kör után elveszhet a cél; strukturált válaszformával csökken.

## 2. Megelőzés
- **2.1 Kísérlet-napló:** megközelítés | hipotézis | parancs | eredmény | hibaüzenet. Új lépés előtt
  VISSZAOLVASNI. Bukott megoldást VAGY variációját SOHA nem ismételni.
- **2.2 Hipotézis-diverzitás induláskor:** 2–3 EGYMÁSTÓL ELTÉRŐ hipotézis, jelölve a legvalószínűbbet.
- **2.3 Context engineering:** legkevesebb, legnagyobb jelértékű token; fill% szerint, ~60% felett
  proaktív tömörítés; tartós szabály a rules-fájlba; nagy eszköz-kimenet szűkítve.
- **2.4 Explicit fókuszcél (SWE-Pruner):** nagy fájl előtt fókuszcél, csak a releváns sorok megtartva.
- **2.5 Strukturált válaszforma + teljes dok-olvasás** (lásd lent).

## 3. Észlelés — ÁLLJ MEG, ha BÁRMELYIK igaz:
- ugyanaz a parancs/teszt 2× változatlan eredménnyel;
- ugyanaz a fájl 3× szerkesztve, a hiba marad;
- a mostani lépés egy már bukott megközelítés variációja (lásd napló);
- ugyanaz a hibaüzenet 2×;
- magas kontextus-töltöttség + a már ismert fájlok „újra-felfedezése".

## 4. STRATÉGIA-ROTÁCIÓ (a v2 lényege) — ne finomíts, VÁLTS (más, akár ortogonális/ellentétes tengely)
Friss kutatás: egy elakadt feladatot TÖBB, egymástól FÜGGETLEN beavatkozás is külön-külön megjavíthat —
nem azt kell csiszolni, hanem MÁSIK utat választani. Tengelyek (mindig MÁST, mint amin elbuktál):
1. **Hipotézist válts, ne javítást** — feltételezz MÁS gyökérokot (pl. nem a függvény, hanem a bemenet/adat).
2. **Réteget válts** — kód helyett spec / adat / konfig / környezet.
3. **Fordítsd meg a feltételezést** — tételezd fel az ellenkezőjét, igazold/cáfold.
4. **Irányt válts** — fentről-le ↔ alulról-fel; általánosítás ↔ minimal repró; „javítsuk" ↔ „izoláljuk".
5. **Hagyd el az utat** — 2–3 sikertelen variáció után független új próbálkozás friss kontextusból, MÁS hipotézissel.
- **Verifikáció KÖTELEZŐ:** minden új megközelítést AZONNAL igazolj/cáfolj kicsi célzott teszttel; a cél
  nem „ki a hibás", hanem hogy a hiba megszűnt-e / mérhetően közelebb-e. A cáfolt hipotézist a naplóba.
- **Anti-minta (TILOS):** ugyanaz a javítás más sorrendben/megfogalmazásban; teszt-babrálás okváltozás
  nélkül; „hátha most összejön" ismétlés.

## 5. Kitörés és helyreállítás (sorrendben)
- **5.1 Drop a gear:** kisebb hatókör/lépésméret, ellenőrizhető részfeladat, egyszerűsítés.
- **5.2 Friss-kontextus újraindítás:** 2–3 sikertelen korrekció után tiszta kontextus; átadva: módosított
  fájlok + git-történet + utolsó hibakimenet + kísérlet-napló; az új próba MÁS tengelyen. Befejezési jel csak valódi készültségnél.
- **5.3 Replan a bukás pontjától** — más hipotézissel; ne foltozz elromlott tervet.
- **5.4 Hurok-korlátok:** kemény felső korlát azonos típusú próbára; állapot-ellenőrzés, hogy változott-e valami.
- **5.5 Szelektív feladás + eszkaláció:** ha minden út hibás/kockázatos, ÁLLJ LE és kérj emberi döntést.
  „Nem tudom megbízhatóan megoldani" érvényes válasz — kiemelten pénzügyi/visszafordíthatatlan műveletnél.

## 6. Önellenőrzés friss kontextusban
Befejezés előtt FRISS kontextusú példány/alügynök nézze át a diffet (csak változás + követelmény, indoklás
nélkül); csak helyességet/követelményt érintő hiányt jelez. Implementáló ≠ ellenőrző (ne ugyanaz az elfogult szál).

## 7. Strukturált válaszforma (MINDEN körben)
**AKTUÁLIS CÉL: ... | MÁR PRÓBÁLTAM: ... | KÖVETKEZŐ LÉPÉS (mely tengelyen): ...**

## Befejezés előtt
- Futtatott teszt/build + KIMUTATOTT kimenet. Friss kontextusú diff-review (más szál), csak helyesség/követelmény.

## Források (2026, ellenőrizve)
DoVer (arxiv 2512.06749) · AI-Scientist-v2 (sakanaai) · ISYE IOS2026 program-book · syn-cause debug-skills ·
codemanship „drop a gear" · markaicode agent-looping · recurrent generation (arxiv 2503.00416) ·
leanware Ralph-loop · szelektív feladás (arxiv 2510.16492) · fundesk + digitalapplied context-engineering ·
SWE-Pruner (arxiv 2601.16746) · célsodródás/echoing (arxiv 2511.09710).
