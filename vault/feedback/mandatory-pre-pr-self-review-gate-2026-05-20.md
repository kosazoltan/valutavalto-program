---
title: "KÖTELEZŐ pre-PR önellenőrzési gate — minden PR ELŐTT (C.25)"
status: superseded
superseded_by: "AGENTS.md agentic-qa review-evidencia + two-rounds-*-mandatory-2026-05-19.md (merge/deploy előtt, nem always-on)"
priority: P0
hatály: 2026-05-20+ CEST
forrás: Kósa Zoltán user-direktíva (2026-05-20 03:40 CEST) — "még mindig nagyon sok a CI/Copilot/Sourcery/Codex hibatalálat"
related:
  - vault/feedback/two-rounds-self-subagent-review-mandatory-2026-05-19.md (C.23)

superseded_note: >
  2026-06-08: Ez a C.25 gate superseded. A 10-tételes checklist domain-specifikus elemei
  (JPQL customerId != '', financialEffective=TRUE, Flyway UNIQUE, 4-area verzió-szinkron,
  BigDecimal, multi-tenant scope) beépültek az AGENTS.md agentic-qa review-evidencia
  szabályába + a Valutaváltó domain-fókuszba (lásd security-audit-mandate-2026-06-15.md §6).
  A "2-kör subagent" megközelítés felváltotta az adverzariális bot-panel (Codex+Sourcery+Copilot
  párhuzamos szerepjáték push előtt). Archivált, NEM töltendő be session-indításkor.
  - vault/feedback/two-rounds-before-merge-mandatory-2026-05-19.md (C.22)
research: GitHub Blog "Agent PRs", ClackyAI "Code Review Checklist AI-Generated", Qodo 2026
---

# KÖTELEZŐ pre-PR önellenőrzési gate (C.25)

## A probléma (2026-05-20 user-direktíva)

> "még mindig nagyon sok a CI github copilot sourcery codex hibatalálat a
> munkáddal kapcsolatban!!! javítsd a saját önellenörző mechanizmusodat, a
> saját alügynökkel futtatot belső ellenőrzését a kódnak, MIELŐTT PR-t csinálsz"

**Root cause**: a C.23 (2-kör subagent review) mandate létezett, DE a gyors PR-eknél
KIHAGYTAM (pl. PR #711 DiscountApprovalController — egyenesen PR, subagent-review
nélkül → Copilot 3 finding: null-role fallback, 15% cap inkonzisztencia, test gap).

## Iparági best practice (kutatás 2026-05-20)

1. **Automated tools FUTNAK ELŐSZÖR, prerequisite NEM replacement** (GitHub Blog)
2. **Self-review checklist clear criteria-val** (inputs/outputs/security) (ClackyAI)
3. **Lokális: unit + integration teszt + compile + static analysis a push ELŐTT** (Qodo)
4. **Block on**: high-severity security, failing tests, missing migrations

## A KÖTELEZŐ pre-PR gate (MINDEN PR ELŐTT, NINCS kivétel)

### 1. fázis — Lokális minőségkapuk (BLOCKING)
```
✅ ./mvnw compile                    (backend)
✅ ./mvnw test -Dtest=<új teszt>     (célzott)
✅ ./mvnw test                       (TELJES regresszió, NEM csak célzott!)
✅ frontend: npm run lint && npm run typecheck (ha frontend érintett)
```

### 2. fázis — Pre-PR checklist (önellenőrzés, MINDEN új kódra)

A visszatérő finding-kategóriák (a Copilot/Codex/Sourcery által ismételten
talált hibák alapján) — MINDEN ÚJ metódus/endpoint/query-nél ellenőrizni:

- [ ] **Null-safety**: minden új paraméter null-check VAGY dokumentált non-null garancia
- [ ] **Multi-tenant**: minden új query company-scope-olt (B.3 mandate) — `SecurityUtils.getCurrentCompanyId()` vagy Branch FK
- [ ] **Sibling-konzisztencia (metódus)**: ha 2+ kapcsolódó metódus/endpoint van (pl. required-level + validate), MINDEGYIK ugyanazt a szabályt alkalmazza (cap, threshold, role-mapping)
- [ ] **Sibling-konzisztencia (QUERY)** ⭐ÚJ (PR #712): MINDEN új JPQL/SQL query-nél `grep` a meglévő hasonló query-kre (pl. AML/riport query-k a `TransactionRepository`-ban) — keresd az EXTRA szűrőket amiket ott alkalmaznak (`customerId <> ''`, `status = COMPLETED`, `financialEffective = TRUE`). A `IS NOT NULL` ÖNMAGÁBAN nem elég, ha a sibling `<> ''`-t is tesz.
- [ ] **Hard cap / threshold**: ha van rendszer-szintű limit (pl. 15% discount cap), MINDEN releváns út enforce-olja
- [ ] **Test coverage**: MINDEN új code-branch (if/else, switch-ág, exception path) van teszttel fedve
- [ ] **BigDecimal**: scale/null/precision (HUF 5 Ft kerekítés)
- [ ] **Version sync (TELJES set)** ⭐ÚJ (PR #712): NEM csak a 4 kliens! A `check-four-area-alignment.mjs` a **ROOT `package.json`**-t is olvassa. Bumpold: ROOT package.json + ROOT package-lock.json + backend/pom.xml (artifact `<version>` a ~20. sor) + 4 kliens package.json + 4 kliens lockfile. Majd `node scripts/check-four-area-alignment.mjs` LOKÁLISAN (exit 0 kell) MIELŐTT pusholsz.
- [ ] **Flyway**: új migration version UNIQUE (a V234-collision outage után!)
- [ ] **CodeQL log-injection**: user-input a logban → sanitizeForLog
- [ ] **financial_effective**: riport/aggregáció query-ben `financialEffective=TRUE` (CONVERSION parent kizárás)

### 3. fázis — 2-kör SAJÁT subagent review (C.23, KÖTELEZŐ, NINCS kihagyás)

- **Round 1**: general-purpose subagent — a 2. fázis checklist-jét EXPLICIT átadva
  a prompt-ban, hogy a subagent pontosan ezeket a kategóriákat vizsgálja
- **Round 2**: fresh subagent — Round 1 findingek verify + új issue keresés
- **CSAK ha mindkettő SAFE TO MERGE** → push + PR

⭐ÚJ (PR #713 tanulság): **NE utasítsd el a subagent findingjét "sibling-consistency"
vagy "informational" ürüggyel, ha az VALÓS (akár apró) korrektségi hiba.** A #713-nál
a Round 1 subagent flag-elte az `isoDate()` UTC-bug-ot, de én "minden sibling így
csinálja" alapon hagytam → Codex P2 + Copilot IS flag-elte a PR-en. Ha valós bug:
javítsd PR ELŐTT (és ha a sibling-ök is hibásak, azt külön follow-up-ban). A
"konzisztencia" NEM mentség egy reprodukálható hibára.

### 4. fázis — push + PR + GitHub AI gate (C.22)

## A kulcs-szabály

> **NINCS "gyors PR" kivétel.** Minden PR — még a 1-soros fix is — végigmegy a
> 4 fázison. A user-direktíva egyértelmű: a CI/Copilot/Codex/Sourcery hibatalálat
> SOK, tehát a pre-PR gate-et SZIGORÚAN be kell tartani, NEM kihagyni időnyerésért.

## Mérés

A következő 10 PR-en mérni: hány Copilot/Codex/Sourcery finding jön a round 1
után. Cél: **≤1 finding per PR** (a jelenlegi ~3-4 helyett). Ha továbbra is sok,
a checklist-et bővíteni az új finding-kategóriákkal.

## Új mandate-szám

C.25 — KÖTELEZŐ pre-PR önellenőrzési gate (4 fázis, NINCS gyors-PR kivétel).
