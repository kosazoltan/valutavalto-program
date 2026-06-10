# Aktiv agent mandate index

Frissitve: 2026-06-08

Ez az index korabban tul sok always-on szabalyra hivatkozott. Az uj rendben az
agent nem innen indul minden sessionben; ezt csak akkor kell olvasni, ha a
feladat kifejezetten mandate-et vagy agent-mukodest erint.

## Aktiv forrasok

1. `AGENTS.md` - egyetlen operativ agent munkamod es precedence.
2. `AI_CONTRACT.md` - hard tiltasok: secret, teszt-integritas, git hygiene,
   security mintak.
3. `AI_CONSTITUTION.md` - rovid mukodesi alapelvek es tiltott agent-patternok.
4. `CLAUDE.md` - projekt/domain/parancs kontekstus.

## On-demand forrasok

- `vault/feedback/*.md` - csak konkret user-direktiva vagy historikus ok
  vizsgalatakor.
- `vault/feedback/prompt-caching-mandate-2026-06-10.md` - Prompt Caching kotelezo:
  cache-barat agent-munkamod + cache_control szabalyok minden Claude API-integracioban
  (user-direktiva 2026-06-10).
- `vault/feedback/fable5-optimization-mandate-2026-06-10.md` - SYSTEM_DIRECTIVE:
  CLAUDE_FABLE_5_OPTIMIZATION_AND_EXECUTION - 5 protokoll: Prompt Caching (ref.),
  Dynamic Model Routing (L0-L3 szintek), Context Window Management (>80% /clear),
  Task Completion Guarantee (csonka deliverable TILOS), Fallback Signaling
  ([WARNING: MODEL_REGRESS_DETECTED]) (user-direktiva 2026-06-10).
- `docs/knowledge/memory/*` - csak regi dontes vagy release-tortenet kutatasakor.
- `.cursor/rules/*.mdc` - celzott Cursor workflow, `alwaysApply: false`.

## Hatályon kivul helyezett mukodesi mintak

- Minden session elejen teljes mandate/vault beolvasas.
- Minden kodolasi feladatra automatikus full security gate.
- Minden push nelkuli dokumentacio- vagy lokalis kodvaltozasra GitHub/AI polling.
- Kotelezett ketkoros sajat agent-review normal feladatnal.
- 15 perces polling vagy teljes CI-visszaolvasas ott, ahol nem tortent push/PR.
- Kotelezett hosszu zaro audit-template minden valasz vegen.

## Megmarado kemeny szabalyok

- Nincs hallucinalt sikerallitas.
- Nincs secret vagy eles credential fajlban/chatben.
- Nincs teszt/CI/security gyengites a zold eredmenyert.
- Deploy/release elott teljes relevans gate es evidence kell.
- Ha nincs bizonyitek, azt roviden es oszinten kell jelenteni.

## 2026-06-08 uj kotelezo munkammod-mandatumok

### 1. Kettos terv minden valtoztatás elott
Minden fejlesztes/javitas/modositas elott KET terv kotelezo:
- **Implementacios terv** (mit, hol, miert, mellekhatások)
- **Lokalis ellenorzesi terv** (melyik Python/Bash script, bemenet/kimenet, melyik teszt/typecheck/grep)
Csak e ket terv utan kezdodik az implementacio es az ellenorzes.
Referencia: `memory/feedback_local_sandbox_handoff_protocol.md`

### 2. Globalis hatasvizsglat minden kodmodositas utan
Szuk scope NEM mentesit: barmilyen DTO/service/endpoint/mapper valtozas utan:
1. grep -- modositott osztaly/metodus/endpoint minden hivoja (java+ts+tsx)
2. Teljes erintett modul tesztek (NEM csak celzott)
3. TypeCheck mind a 4 kliensen (frontend-react + 3 Electron)
4. Mentalis vegpont-audit (melyik masik endpoint/tenant/flow erinti)
Valutavalto-specifikus csapdak: JPQL customerId != '' (nem IS NOT NULL!),
financialEffective=TRUE, Flyway UNIQUE, 4-area verzio-szinkron, multi-tenant company-scope.
Referencia: `memory/feedback_global_impact_check_after_changes.md`

### 3. Session handoff major task utan
Minden merge-elt PR / lezart feature / telepito-build / outage-fix utan:
- `vault/sessions/handoff-YYYY-MM-DD-<tema>.md` letrehozasa (max 30 sor)
- Jelzem a usernek: "Erdemes uj sessiont nyitni a handoff alapjan."
Referencia: `memory/feedback_local_sandbox_handoff_protocol.md`

### 4. Hatályon kívül helyezett mintak (2026-06-08)
- `mandatory-pre-pr-self-review-gate-2026-05-20.md` (C.25) → superseded, lasd 7-lencsés review
- `OPUS_GITHUB_QUALITY_MANDATE.md` / `MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md` → archivalt
- "Opus 4.8" modell-branding → elavult (tenyleges: opusplan = Opus/Sonnet adaptiv)