---
title: "EBC Hangsegéd — Implementáció összefoglaló (Phase 1–10)"
date: 2026-05-18
type: architecture
status: in-progress
source_directive: "EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md (1625 sor) — user-private, NEM commit-olt"
---

# EBC Hangsegéd — Implementáció összefoglaló (Phase 1–10)

> **Hatály:** 2026-05-18 · **Forrás:** felhasználói direktíva (1625 sor, user-private, repo-on kívüli)
> **Állapot:** STACKED PR-EK NYITVA — minden fázis FEATURE branch-en, a main-be MÉG NEM mergelve

## Mit szállítunk (10 fázis, mind FEATURE branch-en)

A Hangsegéd feature implementációja **10 stacked PR-en keresztül**. Az
egyes fázisok többsége az AI_CONTRACT 5-file/300-LOC limit alatt van;
néhány PR (Phase 3, 7, 8) néhány sorral túllép, ez minden esetben
explicit indoklással + a soron lévő AI review-kban dokumentálva.
**A dokumentum írásakor egy PR sincs még a main-en.**

| Fázis | PR | Cél | Fájl | LOC | Status |
|---|---|---|---|---|---|
| 1 | [#654](https://github.com/kosazoltan/valutavalto-program/pull/654) | Knowledge base (4 YAML + moduleKnowledge) | 5 | ~600 | OPEN |
| 2 | [#659](https://github.com/kosazoltan/valutavalto-program/pull/659) | Spring Boot backend `/api/v1/voice/token` | 6 | ~180 | OPEN |
| 3 | [#660](https://github.com/kosazoltan/valutavalto-program/pull/660) | Frontend modul skeleton (Provider+Panel+WebRTC) | 5 | 325 | OPEN |
| 4 | [#661](https://github.com/kosazoltan/valutavalto-program/pull/661) | IndexedDB issueStore (Dexie 4) | 4 | 253 | OPEN |
| 5 | [#662](https://github.com/kosazoltan/valutavalto-program/pull/662) | Markdown exporter + ExportButton | 5 | 286 | OPEN (stack on #661) |
| 6 | [#663](https://github.com/kosazoltan/valutavalto-program/pull/663) | System prompts (install/test/support) | 4 | 187 | OPEN (stack on #660) |
| 7 | [#664](https://github.com/kosazoltan/valutavalto-program/pull/664) | Function-calling tools (8 OpenAI tool) | 4 | 469 | OPEN (stack on #661) |
| 8 | [#665](https://github.com/kosazoltan/valutavalto-program/pull/665) | RAG Layer 1 (YAML text search) | 4 | 416 | OPEN (stack on #654) |
| 9 | [#666](https://github.com/kosazoltan/valutavalto-program/pull/666) | Install state machine + first-run hook | 5 | 256 | OPEN (stack on #664) |
| 10 | (this PR) | Dokumentáció (kollegai útmutató + summary + README) | 3 | 314 | OPEN |

**Tesztek (a PR-ek implementacios + Round-1/2/3 javitas commit-jaiban):**
- Frontend vitest: a 10 PR mergelese utan **51/51 PASS**:
  - 8 filename normalizer (Phase 5)
  - 10 toolHandlers (Phase 7 + Round-2 category regress)
  - 10 textSearch (Phase 8)
  - 8 installStateMachine (Phase 9 + Round-3 state-machine regress)
  - 4 realtimeClient (Phase 3 Round-2)
  - 7 issueStore CRUD (Phase 4 Round-2 fake-indexeddb)
  - 4 toolHandlers category regress (Phase 7 Round-2)
  - 6 knowledgeLoader smoke (Phase 8 Round-3)
- Backend mvn: **7/7 PASS** (VoiceTokenService, beleertve a Round-2 rate-limit tesztet)
- BUILD SUCCESS Spring Boot 4.0.6 + Java 21.

> **MEGJEGYZÉS:** ez a dokumentum FORWARD-LOOKING — a `voice-assistant/` modul-fa
> dokumentálása a tényleges merge után válik valósággá. A `frontend-react/src/modules/voice-assistant/README.md`
> file is csak Phase 9.5 integration utan TUKROZI a tenyleges main-állapotot.

## Backend → Frontend → Electron stack

```
Felhasznalo  (Penztar / Kozponti / Arfolyamkeszito Electron kliens)
    |
    |  click "Telepites" / "Tesztelos" / "Hibajelzes"
    v
[VoiceAssistantPanel.tsx]  (Phase 3)
    |
    v
[VoiceAssistantProvider]  (Phase 3 Context)
    |   start(mode)
    v
[realtimeClient.openRealtimeSession]
    |
    |  1. POST /api/v1/voice/token  -> Spring Boot (Phase 2)
    |        |
    |        v
    |     [VoiceTokenService]  -- master OPENAI_API_KEY (csak backend env-var)
    |        |
    |        v
    |     OpenAI POST /v1/realtime/sessions  -> ephemeral client_secret
    |        |
    |        v
    |     {client_secret, model: gpt-realtime-2, mode}
    |
    |  2. POST https://api.openai.com/v1/realtime?model=gpt-realtime-2
    |       Authorization: Bearer <ephemeral>
    |       Body: SDP offer
    |
    |  3. <- SDP answer  -> RTCPeerConnection.setRemoteDescription
    |  4. <- remote audio track (autoplay)
    |  5. <- oai-events datachannel
    v
[onEvent handler]
    |   tool_call event
    v
[dispatchToolCall(name, args, ctx)]  (Phase 7)
    |  --> issueStore.createIssue   (Phase 4)  --> IndexedDB
    |  --> rag.searchKnowledgeBase  (Phase 8)  --> 4 YAML
    |  --> install.next(...)        (Phase 9)  --> InstallStep
    v
[ExportButton]  (Phase 5)
    |
    v
2026-05-18-hibajegyzet_<title>.md  --> letoltes a gepre
```

## Integration (Phase 9.5 — kovetkezo PR)

A 10 PR mind FEATURE branch-en van. Mergelés után egyetlen kicsi PR egészíti
ki a `frontend-react/src/App.tsx`-et:

```tsx
import { VoiceAssistantProvider, VoiceAssistantPanel } from './modules/voice-assistant'
import { useFirstRun } from './modules/voice-assistant/install'

function App() {
  const { isFirstRun } = useFirstRun()
  return (
    <VoiceAssistantProvider autoStartMode={isFirstRun ? 'install' : undefined}>
      {/* ...existing routes... */}
      <VoiceAssistantPanel />
    </VoiceAssistantProvider>
  )
}
```

A backend-en **KIZÁRÓLAG env-var alapú konfigurációval** (Copilot PR #667
finding: NE `voice.openai.enabled=true` direkt a properties-be, mert az
committed default-é teszi):

```bash
# Hetzner systemd unit / Cloudflare Worker secret / .env
export OPENAI_API_KEY="sk-..."          # master, NEM commit-olt
export VOICE_OPENAI_ENABLED="true"
# Opcionalis: rate-limit override
export VOICE_OPENAI_RATE_LIMIT_PER_HOUR="10"
```

A `backend/src/main/resources/application.properties` a Phase 2 PR-ben mar
helyesen `${VOICE_OPENAI_ENABLED:false}` placeholder-rel hivatkozik —
**DEFAULT OFF, explicit env-var nélkül NEM aktivalodik.**

## Biztonsag

- **Master `OPENAI_API_KEY`:** **csak a backend-en él**, env-var, gitignore-olt.
- **Ephemeral client_secret:** ~60s életű, csak az adott Realtime session-höz.
- **`@PreAuthorize("isAuthenticated()")`** a `/api/v1/voice/token`-en — kizárólag bejelentkezett worker.
- **Per-worker rate-limit:** max 10 token-keres / ora / worker (PR #659 Round-2 fix-up).
- **IndexedDB lokális:** a hibajegyek (worker-szovegek + transcript-resz) a felhasználó gépén tárolódnak, NEM kerülnek backend-re.
- **Pmt./AML PII:** a YAML-ok generikus szovegek; konkrét ügyfél-adat (név, kártya, lakcím) NEM kerül a tudásbázisba.

### Amit az OpenAI Realtime API LÁT (transparenz — Copilot PR #667 finding)

A kollegai utmutatoban EZ a fontosabb informacio:

- **Audio stream IDE**: a kollega beszéde (mikrofon) ELHAGYJA a gepet,
  az OpenAI Realtime servereinek megy WebRTC-n.
- **Audio stream VISSZA**: a Hangsegéd valasza is OpenAI-tol jön WebRTC-n.
- **Transcript**: a `gpt-realtime-whisper` model szovegge alakitja az audio
  bemenetet, ez ELJUT az OpenAI servereire.
- **Function-call argumentumok**: a `report_issue` tool altal kuldott
  cim/leiras szoveg is OpenAI-on at megy (ez az LLM kimenet, NEM ugyfel-adat).

Csak az IndexedDB-be tarolt vegerertekek + a downloadolt `.md` riport
maradnak helyileg — az audio + transcript az OpenAI-on megy at.

## Kovetkezo lepesek (post-merge)

1. **Phase 9.5 (1-line App.tsx + Electron mic permission):** kismértékű mount + env-flag guard
2. **Phase 8.5 (transformers.js vektoros RAG):** Layer 2 — `@xenova/transformers` Wasm + `Xenova/all-MiniLM-L6-v2` model lazy-load
3. **Phase 10.5 (E2E Playwright):** integráció utáni teljes flow teszt mockolt mikrofon-permission-nel és mockolt SDP-cserékkel
4. **Phase 11 (telemetria, opcionális):** ha a kollégák hozzájárulnak, anonimizált tool-call-statisztika a fejlesztő számára
5. **Phase 12 (képernyőkép-elemzés, opcionális):** OpenAI Vision-nel screenshot-alapú hibajelzés

## Költségvonzat (becslés)

- **OpenAI Realtime API 2 (`gpt-realtime-2`):** ~$0.06-0.08/perc (audio in+out, GA 2026-05-07)
- **30-50 kolléga × ~5 perc/nap × 22 munkanap:** ~$200-300/hó
- **Hetzner backend:** existing, no incremental cost (a Phase 2 token endpoint a meglevo Spring Boot-on fut)

A jelenlegi arhitektura **NEM** hasznal Cloudflare Worker proxy-t
(Copilot PR #667 finding) — a frontend direkt a Hetzner-en futó Spring Boot
backend-hez beszél, az pedig direkt az OpenAI Realtime API-hoz. Egy esetleges
jövobeli Worker proxy (ha pl. Cloudflare-en akarunk DDOS-vedelmet vagy
globalis CDN-t) csak akkor jonne a kepbe, ha az implementacio is megszuletik
— addig **NEM listalhato koltsegtetelkent.**
