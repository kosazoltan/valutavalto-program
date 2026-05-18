# EBC Hangsegéd — Frontend modul (developer docs)

> **Verzió:** 0.1 · 2026-05-18 · **Felépítés:** 10 PR, ~3220 LOC, AI_CONTRACT alatt
> **Doku:** `vault/architecture/voice-assistant-implementation-summary-2026-05-18.md`

## Mappastruktúra

```
frontend-react/src/modules/voice-assistant/
├── components/
│   ├── VoiceAssistantPanel.tsx   (Phase 3) — lebego panel jobb also sarokban
│   └── ExportButton.tsx          (Phase 5) — Markdown letoltes gomb
├── context/
│   └── VoiceAssistantProvider.tsx (Phase 3) — Context provider
├── hooks/
│   └── useVoiceMode.ts            (Phase 3) — VoiceMode allapot hook
├── realtime/
│   └── realtimeClient.ts          (Phase 3) — WebRTC + OpenAI Realtime
├── prompts/
│   ├── systemPrompt.install.md    (Phase 6)
│   ├── systemPrompt.test.md       (Phase 6)
│   ├── systemPrompt.support.md    (Phase 6)
│   └── loader.ts                  (Phase 6) — getSystemPrompt(mode, moduleKnowledge?)
├── store/
│   ├── issueTypes.ts              (Phase 4) — IssueRecord + tipusok
│   ├── issueDb.ts                 (Phase 4) — Dexie IndexedDB
│   ├── issueStore.ts              (Phase 4) — CRUD helper-ek
│   └── index.ts                   (Phase 4) — publikus API
├── export/
│   ├── markdownExporter.ts        (Phase 5) — renderIssueAsMarkdown + downloadMarkdown
│   ├── filenameNormalizer.ts      (Phase 5) — ASCII-csak filename
│   ├── index.ts                   (Phase 5)
│   └── filenameNormalizer.test.ts (Phase 5) — 8 vitest PASS
├── tools/
│   ├── toolDefinitions.ts         (Phase 7) — 8 OpenAI tool schema
│   ├── toolHandlers.ts            (Phase 7) — dispatchToolCall + ToolContext
│   ├── toolHandlers.test.ts       (Phase 7) — 8 vitest PASS
│   └── index.ts                   (Phase 7)
├── rag/
│   ├── textSearch.ts              (Phase 8) — token-overlap kereses
│   ├── knowledgeLoader.ts         (Phase 8) — js-yaml + Vite ?raw
│   ├── textSearch.test.ts         (Phase 8) — 10 vitest PASS
│   └── index.ts                   (Phase 8)
├── install/
│   ├── installSteps.ts            (Phase 9) — 7-step default workflow
│   ├── installStateMachine.ts     (Phase 9) — createInstallStateMachine
│   ├── useFirstRun.ts             (Phase 9) — React hook + localStorage
│   ├── installStateMachine.test.ts (Phase 9) — 6 vitest PASS
│   └── index.ts                   (Phase 9)
├── knowledge/
│   ├── modules.yaml               (Phase 1)
│   ├── faq.yaml                   (Phase 1)
│   ├── workflows.yaml             (Phase 1)
│   └── error-codes.yaml           (Phase 1)
├── prompts/moduleKnowledge.md     (Phase 1)
├── index.ts                       (Phase 3) — modul-szintu publikus API
└── README.md                      (this file)
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

## Test coverage

```bash
$ npx vitest run src/modules/voice-assistant/

✓ export/filenameNormalizer.test.ts (8)
✓ tools/toolHandlers.test.ts (8)
✓ rag/textSearch.test.ts (10)
✓ install/installStateMachine.test.ts (6)

Total: 32/32 tests passing
```

## Backend dependency

Spring Boot endpoint `POST /api/v1/voice/token` (Phase 2 PR #659).

Env vars az `application.properties`-ben:

```properties
voice.openai.enabled=${VOICE_OPENAI_ENABLED:false}
voice.openai.api-key=${OPENAI_API_KEY:}
```

## OpenAI modell

`gpt-realtime-2` (GA 2026-05-07, ~$0.06-0.08/min audio).
- voice: `shimmer`
- transcription: `gpt-realtime-whisper`
- reasoning effort: `medium` (test mode), `low` (install/support)

## Adatvedelmi alapelvek

- **Master API-kulcs:** csak backend env, NEM commit-olt.
- **Ephemeral session:** ~60s elet, csak az adott Realtime-hoz.
- **Issue rekord:** lokalis IndexedDB, NEM kerul backendre.
- **Tudasbazis YAML-ok:** generikus szovegek, NEM tartalmaznak PII-t.

## Tovabbi olvasmanyok

- [Implementation summary](../../../../vault/architecture/voice-assistant-implementation-summary-2026-05-18.md)
- [Implementation plan](../../../../vault/architecture/voice-assistant-implementation-plan-2026-05-18.md)
- [Kollegai utmutato (1 oldal)](../../../../vault/operations/voice-assistant-kollegai-utmutato-2026-05-18.md)
- [Forras direktiva](../../../../C:/Users/Kósa%20Zoltán/Downloads/EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md) (user-private)
