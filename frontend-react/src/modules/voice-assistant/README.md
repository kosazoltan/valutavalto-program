# EBC Hangsegéd — Frontend modul (developer docs)

> **Verzió:** 0.1 · 2026-05-18 · **Felépítés:** 10 stacked PR
> **Doku:** `vault/architecture/voice-assistant-implementation-summary-2026-05-18.md`
> **Állapot:** STACKED PR-EK NYITVA — a leírt modul-fa CSAK a 10 PR mergelése után létezik a main-en.

## Status

A Hangsegéd feature 10 stacked PR-en keresztül érkezik a main-re ([#654](https://github.com/kosazoltan/valutavalto-program/pull/654), [#659](https://github.com/kosazoltan/valutavalto-program/pull/659), [#660-#667](https://github.com/kosazoltan/valutavalto-program/pulls)). A dokumentum írásakor egy PR sincs mergelve, így ez a README **FORWARD-LOOKING**: az alább leírt struktúra és teszt-summary csak a teljes merge után tükrözi a main-állapotot.

## Mappastruktúra (post-merge)

```
frontend-react/src/modules/voice-assistant/
├── components/
│   ├── VoiceAssistantPanel.tsx   (Phase 3 — PR #660) — lebego panel jobb also sarokban
│   └── ExportButton.tsx          (Phase 5 — PR #662) — Markdown letoltes gomb
├── context/
│   └── VoiceAssistantProvider.tsx (Phase 3 — PR #660) — Context provider
├── hooks/
│   └── useVoiceMode.ts            (Phase 3 — PR #660) — VoiceMode allapot hook
├── realtime/
│   ├── realtimeClient.ts          (Phase 3 — PR #660) — WebRTC + OpenAI Realtime
│   └── realtimeClient.test.ts     (Phase 3 Round-2 — PR #660) — 4 vitest
├── prompts/
│   ├── systemPrompt.install.md    (Phase 6 — PR #663)
│   ├── systemPrompt.test.md       (Phase 6 — PR #663)
│   ├── systemPrompt.support.md    (Phase 6 — PR #663)
│   └── loader.ts                  (Phase 6 — PR #663) — getSystemPrompt(mode, moduleKnowledge?)
├── store/
│   ├── issueTypes.ts              (Phase 4 — PR #661) — IssueRecord + tipusok
│   ├── issueDb.ts                 (Phase 4 — PR #661) — Dexie IndexedDB
│   ├── issueStore.ts              (Phase 4 — PR #661) — CRUD helper-ek
│   ├── issueStore.test.ts         (Phase 4 Round-2 — PR #661) — 7 vitest (fake-indexeddb)
│   └── index.ts                   (Phase 4 — PR #661)
├── export/
│   ├── markdownExporter.ts        (Phase 5 — PR #662)
│   ├── filenameNormalizer.ts      (Phase 5 — PR #662)
│   ├── filenameNormalizer.test.ts (Phase 5 — PR #662) — 8 vitest
│   └── index.ts                   (Phase 5 — PR #662)
├── tools/
│   ├── toolDefinitions.ts         (Phase 7 — PR #664) — 8 OpenAI tool schema
│   ├── toolHandlers.ts            (Phase 7 — PR #664) — dispatchToolCall + ToolContext
│   ├── toolHandlers.test.ts       (Phase 7 — PR #664) — 10 vitest
│   └── index.ts                   (Phase 7 — PR #664)
├── rag/
│   ├── textSearch.ts              (Phase 8 — PR #665) — token-overlap kereses
│   ├── knowledgeLoader.ts         (Phase 8 — PR #665) — js-yaml + Vite ?raw
│   ├── textSearch.test.ts         (Phase 8 — PR #665) — 10 vitest
│   ├── knowledgeLoader.test.ts    (Phase 8 Round-3 — PR #665) — 6 vitest smoke
│   └── index.ts                   (Phase 8 — PR #665)
├── install/
│   ├── installSteps.ts            (Phase 9 — PR #666) — 7-step default workflow
│   ├── installStateMachine.ts     (Phase 9 — PR #666) — createInstallStateMachine
│   ├── useFirstRun.ts             (Phase 9 — PR #666) — React hook + localStorage
│   ├── installStateMachine.test.ts (Phase 9 — PR #666) — 8 vitest
│   └── index.ts                   (Phase 9 — PR #666)
├── knowledge/
│   ├── modules.yaml               (Phase 1 — PR #654)
│   ├── faq.yaml                   (Phase 1 — PR #654)
│   ├── workflows.yaml             (Phase 1 — PR #654)
│   └── error-codes.yaml           (Phase 1 — PR #654)
├── prompts/moduleKnowledge.md     (Phase 1 — PR #654)
├── index.ts                       (Phase 3 — PR #660) — modul-szintu publikus API
└── README.md                      (this file — Phase 10 — PR #667)
```

## Hasznalat (Phase 9.5 utan)

```tsx
import {
  VoiceAssistantProvider,
  VoiceAssistantPanel,
} from '@/modules/voice-assistant'

function App() {
  return (
    <VoiceAssistantProvider>
      {/* app content */}
      <VoiceAssistantPanel />
    </VoiceAssistantProvider>
  )
}
```

## Test coverage (post-merge)

A teljes 10-PR merge utan futtathato lesz:

```bash
$ npx vitest run src/modules/voice-assistant/

# Varhato: 51 tests passing
# - export/filenameNormalizer.test.ts (8)
# - tools/toolHandlers.test.ts (10)
# - rag/textSearch.test.ts (10)
# - rag/knowledgeLoader.test.ts (6)
# - install/installStateMachine.test.ts (8)
# - realtime/realtimeClient.test.ts (4)
# - store/issueStore.test.ts (7)
```

A dokumentum írásakor (PR #667) ez a parancs CSAK a README-t talalja a main-en —
a teszt-fajlok a megfelelo fazis-PR-ekben elnek.

## Backend dependency

Spring Boot endpoint `POST /api/v1/voice/token` (Phase 2 PR #659).

Env vars az `application.properties`-ben (default OFF):

```properties
voice.openai.enabled=${VOICE_OPENAI_ENABLED:false}
voice.openai.api-key=${OPENAI_API_KEY:}
voice.openai.rate-limit.max-per-hour=${VOICE_OPENAI_RATE_LIMIT_PER_HOUR:10}
voice.openai.rate-limit.window-seconds=${VOICE_OPENAI_RATE_LIMIT_WINDOW_SEC:3600}
```

## OpenAI modell

`gpt-realtime-2` (GA 2026-05-07, ~$0.06-0.08/min audio).
- voice: `shimmer`
- transcription: `gpt-realtime-whisper`
- reasoning effort: `medium` (test mode), `low` (install/support)

## Adatvedelmi alapelvek

- **Master API-kulcs:** csak backend env-var, NEM commit-olt.
- **Ephemeral session:** ~60s elet, csak az adott Realtime-hoz.
- **Issue rekord:** lokalis IndexedDB, NEM kerul backendre.
- **Tudasbazis YAML-ok:** generikus szovegek, NEM tartalmaznak PII-t.
- **Per-worker rate-limit:** max 10 token-keres / ora / worker (PR #659 Round-2).

## Tovabbi olvasmanyok

- [Implementation summary](../../../../vault/architecture/voice-assistant-implementation-summary-2026-05-18.md)
- [Kollegai utmutato (1 oldal)](../../../../vault/operations/voice-assistant-kollegai-utmutato-2026-05-18.md)

A forras-direktiva (`EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md`, 1625 sor)
**user-private**, NEM commit-olt a repoba.
