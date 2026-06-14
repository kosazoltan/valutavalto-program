# Mandate: Prompt Caching kötelező használata (2026-06-10)

**Forrás:** Kósa Zoltán user-direktíva (2026-06-10): „Használd a munkád során a Prompt
Caching technológiát! Mentsd el a mandate fájlodban, hogy eszerint kell végezned a munkát."
Technikai tényalap: Anthropic prompt-caching dokumentáció (claude-api skill, 2026-06-10).

## Hatály

Minden AI-agent munkamenet ezen a repón + minden Claude API-integráció a kódbázisban
(jelenleg a main-en nincs ilyen; a voice-assistant feature-branchek és minden jövőbeli
integráció e mandate alá esik).

## 1. Agent-munkamenetek (Claude Code / Codex / egyéb harness)

- A Claude Code harness a prompt cache-t automatikusan kezeli — az agent feladata a
  **cache-barát viselkedés**, mert a cache prefix-egyezésen alapul (egyetlen bájt-eltérés
  a prefixben érvényteleníti az utána lévő cache-t):
  - Stabil kontextus elöl, volatilis tartalom (időbélyeg, futás-azonosító) hátul.
  - Session-startkor NEM töltünk be feleslegesen nagy, változékony fájlokat a kontextus
    elejére (összhangban a CLAUDE.md „ne tölts be minden vault/** fájlt" szabályával).
  - Hosszú munkamenetben nem szerkesztjük visszamenőleg a korábbi kontextust, ha
    elkerülhető — az appendelő munkamód cache-hatékony.

## 2. Claude API-integrációk a kódban (kötelező szabályok)

Minden `messages.create` hívásnál, ahol a prompt ismétlődő részt tartalmaz:

- **`cache_control: {"type": "ephemeral"}`** a stabil prefix utolsó blokkján (system
  prompt vége vagy az utolsó tool-definíció). Render-sorrend: `tools` → `system` →
  `messages` — a system-végi breakpoint a tools+system párost együtt cache-eli.
- **Max 4 breakpoint** kérésenként; többfordulós beszélgetésben az utolsó user-turn
  utolsó blokkjára is kerül breakpoint (inkrementális cache-bővülés).
- **Minimum cache-elhető prefix** modellfüggő (alatta némán nem cache-el):
  4096 token (Opus 4.5–4.8, Haiku 4.5) / 2048 (Fable 5, Sonnet 4.6) / 1024 (Sonnet 4.5).
- **TTL:** alap 5 perc (write-költség 1,25×); `{"ttl": "1h"}` 1 óra (write 2×).
  Cache-olvasás ~0,1× input-ár. 5 perces TTL-nél már 2 kérésnél megtérül.
- **Néma cache-rontók TILOSAK a prefixben:** `datetime.now()`/`Date.now()` a system
  promptban; UUID/kérés-azonosító elöl; `json.dumps` `sort_keys=True` nélkül;
  felhasználónként változó tool-lista; feltételes system-szakaszok. Dinamikus adat a
  messages végére kerül, nem a system promptba.
- **Verifikáció kötelező** (no-hallucináció elv): a cache működését a válasz
  `usage.cache_read_input_tokens` mezőjével kell igazolni. Ha ismételt, azonos prefixű
  kéréseknél ez 0, néma cache-rontó van — a rendered promptot kell diffelni, nem találgatni.
- Code-review szempont: új/módosított Claude API-hívásnál a reviewer ellenőrzi a fenti
  pontokat (breakpoint-elhelyezés + invalidátor-mentes prefix + usage-verifikáció tesztben
  vagy logban).

## 3. Agent-harness cache-drop okok és ellenintézkedések

A Claude Code / Codex / egyéb harness munkamenetekben a cache prefix-egyezésen alapul;
az alábbiak a leggyakoribb harness-szintű cache-rontók. (Az org tényleges forgalma
jelenleg ~egy modell — Sonnet 4.6 —, ezért a modellváltás-pont most **preventív**; a
többi aktív kockázat. Háttér: `vault/feedback/cache-hit-rate-drop-2026-06-14.md`.)

| Cache-rontó | Miért üti a cache-t | Ellenintézkedés |
|---|---|---|
| **CLAUDE.md / AGENTS.md / mandate-fájl szerkesztése** | A system-prompt szintű kontextus a prefix elején van → minden utána lévő cache érvénytelen a következő sessionökre | Szerkesztéseket **kötegelve** (egy commit), lehetőleg munkavégzési ablakon kívül; ne csepegtetve több session alatt |
| **MCP-szerverkészlet / sorrend változása** | A tool-definíciók a render-sorrend 0. pozícióján vannak; más készlet/sorrend → teljes cache elvész | Determinisztikus, stabil MCP-lista; ne kapcsolgassunk szervereket sessionönként |
| **Munkameneten belüli modellváltás** (preventív) | A cache modell-scoped | Hibrid routing: fő loop egy modellen; olcsóbb modell csak subagentben vagy `/clear` utáni új taskban (ld. fable5-optimization PROTOCOL 2) |
| **`--continue` / session-resume** | Dokumentáltan kiütheti a teljes prompt cache prefixet | Hosszú feladatnál append-elő munkamód; resume után számolj cold-write-tal |
| **Dátum/időbélyeg/azonosító a korai kontextusban** | Naponta/kérésenként változó prefix | Dinamikus adat a kontextus végére, ne a system promptba |
| **20-blokk lookback túllépése agentic loopban** | A breakpoint max 20 blokkot néz vissza; sok tool_use/tool_result pár után néma miss | Hosszú fordulóban köztes breakpoint ~15 blokkonként |
| **Fork (összegzés/compaction/subagent) eltérő prefixe** | A fork külön API-hívás; ha más a system/tools/model, nem éri be a szülő cache-ét | A fork a szülő `system`/`tools`/`model` értékét **bájtra** újrahasználja, a fork-specifikus rész a végére |
| **Párhuzamos fan-out azonos prefixszel** | A cache csak az első válasz streamelése után olvasható; N párhuzamos hívás mind teljes árat fizet | 1 hívás → első streamelt token bevárása → a maradék N−1 indítása |

## 4. Invalidációs hierarchia és verifikáció

- **3 tier (csak a saját szintjét és alatta üti):** tool-definíció vagy modellváltás →
  tools+system+messages mind elvész; system-prompt tartalom → system+messages;
  message-tartalom → csak messages. A `tool_choice` / `thinking` ki-be kapcsolás a
  tools+system cache-t **nem** üti.
- **`input_tokens` = csak a nem-cache-elt maradék.** Teljes prompt = `input_tokens +
  cache_creation_input_tokens + cache_read_input_tokens`. Az összeget nézd, ne az egy mezőt.
- **TTL-megtérülés:** 5 perces TTL — már 2 kérésnél (1,25× write + 0,1× read = 1,35× < 2×);
  1 órás TTL — ≥3 kérésnél (2× + 0,2× = 2,2× < 3×). Bursty, hosszú szünetes forgalomra 1h.

## 5. Megelőző technikák

- **Mid-conversation `role:"system"`** (beta `mid-conversation-system-2026-04-07`, támogatott
  modellen): operátori utasítást a `messages[]` végére appendelünk, NEM a top-level `system`-et
  szerkesztjük — így a cache-elt előzmény-prefix sértetlen marad. Nem támogatott modellnél
  `<system-reminder>` fallback a user-turnben.
- **Pre-warming** (`max_tokens: 0`): interaktív felületnél a nagy, megosztott prefix cache-ét
  startkor előre megírathatjuk; háttér-jobnál vagy folyamatos forgalomnál felesleges.
- **Subagent olcsóbb modellre** routinghoz — önálló kontextus, a fő cache-t nem rontja.

## 6. Diagnosztikai protokoll Console cache-alertre

Ha „prompt cache hit rate dropped" értesítés érkezik (no-hallucináció: mérünk, nem találgatunk):

1. **Console `platform.claude.com/usage/cache`** → szűrés Workspace / Model / Range szerint.
   Nézd: **Cache read ratio**, **Missed tokens by reason**, **Requests by miss reason**.
2. A miss-okból azonnal látszik a mechanizmus: `System changed` (CLAUDE.md/mandate edit),
   `Tools changed` (MCP-készlet), `Model changed` (routing), `Messages changed`.
3. **Token vs. request:** ha a *missed token* elhanyagolható, a hatás kicsi (rövid kéréseken
   van a miss); a nagy kontextus cache-e működik.
4. **Korreláció:** a dip napját vesd össze a git-loggal (CLAUDE.md/AGENTS.md/mandate/MCP commitok).
5. Programozott ellenőrzés API-integrációnál: `usage.cache_read_input_tokens` ismételt,
   azonos prefixű kéréseknél > 0 legyen.

> Megjegyzés: az org-szintű, heti aggregált hit-rate-et az **API nem adja vissza** — az csak a
> Console dashboardon látható; az API per-kérés `usage`-mezőket ad.

## 7. Kapcsolódó meglévő szabályok

- `CLAUDE.md` — célzott olvasás, nem teljes vault-betöltés (cache- és token-barát).
- `FEJLESZTESI_IRANY_AUDIT.md` §9 token-ökonómia — ez a mandate annak technikai kiegészítése.
- `vault/feedback/fable5-optimization-mandate-2026-06-10.md` PROTOCOL 2 — hibrid cache-biztos routing.
- `vault/feedback/cache-hit-rate-drop-2026-06-14.md` — incidens-elemzés és e bővítés indoka.
