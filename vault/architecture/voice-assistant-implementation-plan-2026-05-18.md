---
title: EBC Hangsegéd (Voice Assistant) — implementációs fázisterv
date: 2026-05-18
tags: [architecture, voice-assistant, openai, realtime, rag]
status: planning
source: C:/Users/Kósa Zoltán/Downloads/EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md (v1.2)
---

# EBC Hangsegéd — implementációs fázisterv

## 🎯 Cél
Magyar nyelvű, OpenAI Realtime API 2 (gpt-realtime-2) alapú hangvezérelt asszisztens 3 móddal (Install / Test / Support) a 3 kliens-app (Penztar, Kozponti, Arfolyamkeszito) számára. **Lokálisan fut** a kolléga gépén (Electron renderer), a knowledge base + vector embeddings a kliensen, csak a hangbeszélgetés megy OpenAI felé.

## 🔧 Stack adaptáció a meglévő repo-hoz

| Eredeti spec | Repo-szerinti adaptáció |
|---|---|
| Express backend | **Spring Boot** (`backend/src/main/java/`) — `VoiceTokenController` Java-ban |
| `secrets.json` PowerShell sync | `application.properties` + Hetzner systemd env: `OPENAI_API_KEY=...` |
| Replit deploy | **Hetzner** backend + **Electron** kliens (Penztar/Kozponti/Arfolyamkeszito) |
| `src/server/routes/voice-token.ts` | `backend/src/main/java/hu/puzzleir/valuta/controller/VoiceTokenController.java` |
| `src/App.tsx` integráció | `frontend-react/src/App.tsx` + Electron preload |
| 50 EBC kolléga, 8 régió, 75 pénztár | Tényleges: **EBC = 66 branch**, 8 régió (V145 seed) |

## 📋 9 Fázis (a doku §12 alapján, adaptálva)

### Fázis 0 — Felmérés + dependency-add (~1 óra) **[MOST]**
- ✅ Doku átolvasás 1625 sor
- ✅ Kódbázis-felmérés (NINCS még voice modul)
- npm dependenciák hozzáadása `frontend-react/package.json`-be:
  - `dexie` (IndexedDB wrapper)
  - `@xenova/transformers` (lokális embeddings)
  - `js-yaml` + `@types/js-yaml`

### Fázis 1 — Knowledge base (YAML) — **~4 óra**
Forrás: a repo memóriájából (CLAUDE.md, vault/, session-jegyzetek)
- `knowledge/modules.yaml` — 3 kliens-app + 19/13/4 menüpont
- `knowledge/faq.yaml` — gyakori kérdések (Google login, BALI flow, eltávolító kötelező, telepítő-választás)
- `knowledge/error-codes.yaml` — backend hibakódok (V232 BIGINT, EXZ leak, Cannot read 'length', "Google bejelentkezés sikertelen" stb.)
- `knowledge/workflows.yaml` — telepítés, napnyitás, vétel/eladás, konverzió, napzárás (9 lépés Wizard), árfolyam-szétküldés

### Fázis 2 — Backend Spring Boot endpoint — **~2 óra**
- `VoiceTokenController.java` — `POST /api/v1/voice/token`
- OpenAI Sessions API hívás
- JWT auth middleware
- Spring Boot config: `voice.openai.api-key` (Hetzner env)
- Rate limiting per worker (`@RateLimiter`)

### Fázis 3 — Frontend modul skeleton — **~3 óra**
- `frontend-react/src/modules/voice-assistant/` (15 fájl)
- `VoiceAssistantPanel.tsx` (floating panel jobb alsó sarokban)
- `VoiceAssistantProvider.tsx` (Context)
- `realtimeClient.ts` (WebRTC + OpenAI session)
- `useVoiceMode.ts` ('install' | 'test' | 'support' | 'idle')

### Fázis 4 — IndexedDB issue store — **~2 óra**
- `issueStore.ts` (Dexie wrapper, `IssueDB` osztály)
- TypeScript types
- Vitest unit tesztek

### Fázis 5 — Markdown exporter — **~2 óra**
- `markdownExporter.ts` (tisztán funkcionális)
- `ExportButton.tsx`
- ASCII fájlnév normalizáció (`EBC_hibajelentes_YYYY-MM-DD_nev.md`)
- Vitest tesztek

### Fázis 6 — System promptok (3 mód) — **~2 óra**
- `prompts/systemPrompt.install.md`
- `prompts/systemPrompt.test.md`
- `prompts/systemPrompt.support.md`
- `prompts/moduleKnowledge.md` (high-level overview, mindig kontextusban)

### Fázis 7 — Function tools + handler — **~3 óra**
- `functionTools.ts` (9 tool: report_issue, next_install_step, set_user_info, finalize_report, add_quick_note, lookup_module_info, search_knowledge, find_similar_issues, install_step_lookup)
- `handleFunctionCall` (VoiceAssistantProvider-ben)

### Fázis 8 — Vector embeddings (RAG Layer 2) — **~4 óra**
- `memory/vectorStore.ts` (Dexie + transformers.js)
- `memory/embedder.ts` (`Xenova/all-MiniLM-L6-v2`)
- `memory/reindex.ts` (YAML → vektor build)
- Verzió-frissítési mechanizmus

### Fázis 9 — Electron integráció + telepítő-csomagolás — **~3 óra**
- `penztar-client/electron/main.ts` — userData mappa, knowledge YAML kibontás
- `kozponti-client/electron/main.ts` — ugyanaz
- `arfolyam-keszito-client/electron/main.ts` — ugyanaz
- `electron-builder.json` — `extraResources` a knowledge mappához
- Setup Wizard integráció (első indításkor automatikus hangsegéd-onboarding)

### Fázis 10 — Acceptance test + dokumentáció — **~2 óra**
- E2E Playwright forgatókönyv
- README a modulhoz
- 1 oldalas kollegai útmutató PDF

**Összesen: ~28 óra (~3-4 nap dedikált munkával)**

## 🚧 Kockázat + mérséklés

| Kockázat | Mérséklés |
|---|---|
| OpenAI Realtime API drágа ($0.06-0.08/perc) | Per-worker napi limit + session max 30 perc |
| Mikrofon engedély elutasítva Electronban | Fallback: szöveges chat UI (chat.completions) |
| Lokális embedding modell 22 MB letöltés | Egyszeri, első indításkor (progress bar) |
| Hangbeszélgetés GDPR | OpenAI Zero Data Retention + felhasználói beleegyezés |
| AI_CONTRACT.md 5-fájl/300 LOC limit | **10+ PR**, fázisonként 1-2 PR |
| Knowledge YAML karbantartás | Claude Code-tól lehet kérni a `knowledge/*.yaml` bővítését új session-jegyzetekből |

## 📦 Telepítő-csomagolás (Fázis 9)

A doku §17.6 alapján, de Electron-adaptálva:

```
release/Penztar-Setup-2.5.56.exe (NSIS)
└── app.asar (unpacked)
    ├── frontend-react/dist/
    │   └── (a fő frontend)
    └── voice-assistant-resources/
        ├── knowledge/
        │   ├── modules.yaml
        │   ├── faq.yaml
        │   ├── error-codes.yaml
        │   └── workflows.yaml
        ├── models/
        │   └── all-MiniLM-L6-v2/ (22 MB, transformers.js cache)
        └── prompts/
            ├── systemPrompt.install.md
            ├── systemPrompt.test.md
            ├── systemPrompt.support.md
            └── moduleKnowledge.md
```

A `vectorStore.db` (IndexedDB) az első indításkor a `userData` mappába épül.

## 📊 Kezdő knowledge (a repo-memóriából)

A `knowledge/*.yaml`-okba a következőket viszem át:

**modules.yaml** (a 3 kliens × 19+13+4 menüpont):
- Penztar (POS): Pénztáros főmenü, Napnyitás, Valuta vétel/eladás, Konverzió, Kassza/készlet, Címletezés, Ügyfelek, Úton lévő csomagok, Napzárás, Árfolyamok (nézet), Tranzakciólista (11 menüpont)
- Penztar (Vault — főértéktár): Értéktári dashboard, Pénztári készletek, Banki rendelések stb.
- Kozponti: Irányítóközpont, Zárás beérkezés, Beérkezett adatok, Országos dashboard, MNB jelentések, Pénztáros KPI, Országos készlet, Készlet-snapshot, Értéktár leltár, Banki rendelések, Aktuális árfolyamok, Árfolyam történet, Árfolyam kategóriák (13 menüpont)
- Árfolyamkészítő: Főlap (Elszámoló árfolyamok A-I oszlop), Csoportok karbantartása, Árfolyamok szétküldése, KILÉPÉS

**faq.yaml** (a recent user-feedbackből + CLAUDE.md):
- Q: "Hogyan lépek be Google fiókkal?"
- Q: "Miért nem tud Bali Heni Google-lel belépni?"
- Q: "Eltávolító kötelező-e a telepítés előtt?"
- Q: "Melyik telepítőt használjam?"
- Q: "Mi az EBC, EEC, EPC, EXZ közötti különbség?" (lásd faq.yaml#ebc_vs_eec_vs_exz_vs_epc)
- Q: "Hogyan rögzítek 100k+ ügyfelet?"
- Q: "300k+ tranzakciónál mi a PEP-nyilatkozat?"
- Q: "Hogyan zárom le a napot? (9-lépéses Wizard)"
- Q: "Mit csinálok ha lefagy a program?"
- Q: "Hogyan készítek árfolyamot?"

**error-codes.yaml** (a session-jegyzetekből) — az AUTHORITATIVE számozás az `error-codes.yaml` fájl. Itt csak vezetői áttekintés a témákról:
- EBC-001..003: Auth / Google login (HTTP 401, duplikált worker, EXZ leak)
- EBC-004..009: Frontend (Banki rendelések crash, nyomtató, negatív készlet, ügyfél rögzítés, 300k+ adat, Setup Wizard 4→5)
- EBC-010..013: Backend / Deploy (UAC, UUID/BIGINT, Flyway checksum, workgroup exclusivity)
- EBC-014..020: Üzleti / AML (NAV jelentés, MNB API, PEP kérdés, devizastátusz, kezelési költség, átadás-átvétel, 100-300k bizonylat)
- EBC-099: Generikus (lefagyás)

A részletes mappinghez lásd: `frontend-react/src/modules/voice-assistant/knowledge/error-codes.yaml`.

**workflows.yaml**:
- workflow.telepites — 5 lépéses Setup Wizard
- workflow.napnyitas — pénztáros napnyitás
- workflow.vetel — 6-soros vétel + ügyfél azonosítás
- workflow.eladas — eladás + 100k/300k szabályok
- workflow.napzaras — 9-lépéses Wizard (MTCN, Esti pénztár, Kezelési díj, WU, ÁFA, Foglaló, E-kereskedelem, AXA/MoneyGram, NAV)
- workflow.arfolyam_szetkuldes — Árfolyamkészítő → Főlap → Csoportok → Szétküldés
- workflow.google_login — 3 mód (Penztar / Kozponti / Árfolyamkészítő) + Bali Heni 2 emailes flow

## 🚀 Most következő lépés

A user kérése alapján a fázisokat sorban végrehajtjuk. **Most a Fázis 1 (Knowledge YAML)** indul. Ezt 1 PR-be foglalom: a 4 YAML + a `vault/architecture/voice-assistant-implementation-plan-2026-05-18.md` (ez a fájl).

Aztán a Fázis 2 (Backend) külön PR.
Aztán a Fázis 3 (Frontend skeleton) külön PR.
... stb.

🤖 *Készítette: Claude Code (claude-opus-4-7) — 2026-05-18 EBC Hangsegéd implementációs fázisterv*
