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

## 3. Kapcsolódó meglévő szabályok

- `CLAUDE.md` — célzott olvasás, nem teljes vault-betöltés (cache- és token-barát).
- `FEJLESZTESI_IRANY_AUDIT.md` §9 token-ökonómia — ez a mandate annak technikai kiegészítése.
