# Incidens-elemzés — „prompt cache hit rate dropped" Console-alert (2026-06-14)

> Kiváltó: Anthropic Console értesítés (2026-06-14 ~04:59 UTC) az Exclusive Best Change Zrt.
> org-ra: a prompt cache hit rate 43%-kal esett az előző héthez képest.
> Vizsgálat: Kósa Zoltán + agent, 2026-06-14. No-hallucináció: minden alábbi állítás a
> Console `usage/cache` dashboardon vagy a repo git-logján alapul.

## Megállapítások (tényalap)

1. **A repóban nincs élő Claude API-integráció** (0 `messages.create`, 0 `cache_control`,
   0 Anthropic SDK). Az egyetlen külső LLM-integráció OpenAI Realtime (voice assistant) —
   az nem tartozik a Claude prompt-caching alá. Az alert tehát az **org API-forgalmáról**
   szól, ami a gyakorlatban a Claude Code / Managed Agents munkamenetek.

2. **A mandate technikai számai helyesek** — a kanonikus `claude-api` referenciával
   egyeztetve (min-token: Opus 4.8/Haiku 4.5 = 4096, Fable 5/Sonnet 4.6 = 2048,
   Sonnet 4.5 = 1024; TTL 5m 1,25× / 1h 2× / read 0,1×; max 4 breakpoint). Nem hibás
   adatot kellett javítani, hanem a harness-szintű okokkal kiegészíteni.

3. **Console `usage/cache` (Default workspace, All model, Last 7 days, adat Jun 14 3AM):**
   - Cache read ratio: **84,4%** (↑19,0% az előző héthez)
   - Cache read tokens: 171,7M (↑57,2%); Uncached input: 31,8M (↓29,0%)
   - „Cache miss tokens: No miss reasons in this selection"
   - Forgalmi bontás: **Claude Sonnet 4.6 = 644,9M**, Sonnet 4.5 = 5,2K (gyakorlatilag
     egy modell — nincs tényleges multi-model routing ezen a workspace-en)
   - A „Cache read ratio" görbén **átmeneti beesés ~Jun 8–9** (közel 0–50%), utána ~80–100%
   - „Requests by miss reason" kis tüskék: `System changed` / `Tools changed` /
     `Model changed` / `Messages changed`; a *missed token* elhanyagolható

4. **Git-korreláció a Jun 8–9-i dip-pel (root cause):** Jun 8-án system-prompt szintű
   fájlok változtak:
   - `0cd39ea` (Jun 8 20:30) — „trigger-mátrix integráció — **CLAUDE.md** + vault/procedures + memory"
   - `8922e5e` (Jun 8 14:02) — „blast-radius helper scripts + vault cleanup + **mandate frissítések**"
   - `746a7c5` (Jun 8 14:02) — vault reorganizáció
   Ezek pontosan a `System changed` miss-okot és a Jun 8–9-i cache read ratio dip-et
   magyarázzák. Az új prefix újra-cache-elődésével a ratio helyreállt.

## Következtetés

- **Nincs aktív/strukturális cache-probléma.** Az alert egy **lefutott, átmeneti dip**-et
  fogott meg (Jun 8 CLAUDE.md + mandate szerkesztések), ami **azóta helyreállt** (84,4%, +19%).
- A modellváltás-cache-bust kockázat ezen a workspace-en **nem oksági** (gyakorlatilag
  egy modell fut), csak preventív.

## Tett intézkedések (preventív)

- `prompt-caching-mandate-2026-06-10.md` bővítve: §3 harness cache-drop okok + ellenintézkedések,
  §4 invalidációs hierarchia + verifikáció, §5 megelőző technikák, §6 Console diagnosztikai protokoll.
- `fable5-optimization-mandate-2026-06-10.md` PROTOCOL 2: hibrid cache-biztos routing szabály.
- `CLAUDE.md`: cache-biztos routing pointer + „szerkesztéseket kötegelve" elv.

## Nyitott / a user oldalán elvégzendő

- Ha több workspace van, a fenti ellenőrzés a többire is futtatandó (itt csak a Default látszott).
- A CLAUDE.md/AGENTS.md/mandate jövőbeli szerkesztéseit érdemes kötegelni, hogy ne minden
  munkanapon keletkezzen új system-prefix → cold cache.
- Titokkezelés: API-kulcs nem kerül repóba/chatbe (CLAUDE.md invariáns); éles kulcs az
  environment secret-konfigurációjában, nem fájlban.
