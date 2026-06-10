# Handoff — 2026-06-08 — Mandate cleanup + módszertani frissítések

## Elvégzett munka

### Új kötelező munkamódszerek (minden jövőbeli sessionre érvényes)
1. **Kettős terv** — minden változtatás előtt: (1) impl terv + (2) lokális ellenőrzési terv (Python/Bash script, bemenet/kimenet, token-ROI igazolás)
2. **Globális hatásvizsgálat** — minden kódmódosítás után grep minden hívóra + teljes modul teszt + typecheck mind 4 kliensen + mentális végpont-audit
3. **Session handoff** — major task (merge/feature/telepítő/outage) után handoff fájl + session-váltás jelzése

### Vault + memory tisztítás
- **Törölve**: `digicert_call_booking_2026_05_29.md`, `digicert_status_2026_05_30.md`, `OPUS_GITHUB_QUALITY_MANDATE_APPLIED.md`
- **Archivált/deprecated**: `OPUS_GITHUB_QUALITY_MANDATE.md`, `MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md`, `feedback_pre_pr_self_review_gate.md`
- **Frissítve**: `AI_CONSTITUTION_LOCAL.md` (L2→L3 maturity), `opus48-munkamod-mandate` (branding fix), `_active_mandates.md` (új mandátumok)
- **Bővítve**: `feedback_strong_self_review_before_pr.md` — Valutaváltó domain addon (JPQL, Flyway, 4-area szinkron, BigDecimal, multi-tenant)
- **MEMORY.md index**: `feedback_no_stop_autonomous_finding_poll` + `feedback_cost_discipline_model_routing` hozzáadva; archivált szekció létrehozva

### Haladó ügynök-programozási útmutató implementáció (A–H, 2026-06-08)

| # | Feladat | Fájl | Státusz |
|---|---|---|---|
| A | Handoff 5-pont struktúra | `feedback_local_sandbox_handoff_protocol.md` | ✅ KÉSZ |
| B | CI token-hatékony olvasás (`gh run watch` TILOS) | `feedback_ai_review_query_methodology.md` | ✅ KÉSZ |
| C | Progressive Disclosure + skill konvenció | `reference_skill_development_convention.md` | ✅ KÉSZ |
| D | Exponenciális backoff (1→2→4→8 perc) | `feedback_proactive_ci_ai_review_polling.md` | ✅ KÉSZ |
| E | `DISABLE_AUTOUPDATER=1` Windows env var | `CLAUDE.md` globális | ✅ KÉSZ |
| F | Negyedéves settings.json audit | `vault/procedures/quarterly-settings-audit.md` | ✅ KÉSZ |
| G | Formális delegációs mátrix | `feedback_cost_discipline_model_routing.md` | ✅ KÉSZ |
| H | 3× szabály MEMORY.md indexelése | `MEMORY.md` (reference_skill_development_convention) | ✅ KÉSZ |

## Nyitott szálak

- FK02-E részletes hibalista még nem érkezett a usertől (tartalom nincs repóban)
- Blast-radius toolkészlet (`scripts/dev-tools/blast-radius.py`, `typecheck-all.ps1`, `test-summary.ps1`) még NEM implementált — csak tervezés folyt; kettős terv szükséges az implementáció előtt

## Következő lépések

1. Ha a user megadja az FK02-E hibalistát → részletes elemzés + javítás
2. Blast-radius helper scriptek létrehozása `scripts/dev-tools/` mappában (kettős terv után)
3. Session-váltás szükséges (context window tele): `cat vault/README.md` + ezt a handoff-fájlt olvasd el kontextusként

## Verziók / referenciák

- Jelenlegi model config: `opusplan` (tervezés=Opus, végrehajtás=Sonnet)
- Backend prod: v2.27.96 (Hetzner 95.216.191.162)
- Aktív feedback fájlok: `feedback_strong_self_review_before_pr.md`, `feedback_global_impact_check_after_changes.md`, `feedback_local_sandbox_handoff_protocol.md`, `reference_skill_development_convention.md`, `feedback_cost_discipline_model_routing.md`
