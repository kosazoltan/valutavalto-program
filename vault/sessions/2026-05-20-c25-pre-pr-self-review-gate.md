---
title: "C.25 — Pre-PR önellenőrzési gate implementáció + PR #711 demonstráció"
date: 2026-05-20
mandate_uj: C.25
forrás: Kósa Zoltán user-direktíva (2026-05-20 03:40 — "még mindig sok a CI/Copilot/Codex hibatalálat")
---

# C.25 — Pre-PR önellenőrzési gate

## A probléma
A user jelezte: a CI/Copilot/Sourcery/Codex MÉG MINDIG sok hibát talál a PR-eken.
Root cause: a C.23 (2-kör subagent review) mandate LÉTEZETT, de a gyors PR-eknél
KIHAGYTAM. Pl. PR #711 (DiscountApprovalController) — egyenesen PR subagent-review
nélkül → Copilot 3 finding (null-role fallback, 15% cap inkonzisztencia, test gap).

## A megoldás (internetes kutatás alapján)
Kutatás: GitHub Blog "Agent PRs", ClackyAI "Code Review Checklist AI-Generated",
Qodo 2026. Tanulság: automated tools FUTNAK ELŐSZÖR (prerequisite) + self-review
checklist + lokális teszt/compile/static-analysis a push ELŐTT.

**C.25 mandate — KÖTELEZŐ 4-fázisú pre-PR gate, NINCS gyors-PR kivétel:**
1. Lokális minőségkapuk (compile + TELJES regresszió + lint/typecheck)
2. 10-pontos pre-PR checklist (visszatérő finding-kategóriák)
3. 2-kör SAJÁT subagent review (checklist EXPLICIT a promptban)
4. push + PR + GitHub AI gate

## Demonstráció — PR #711-re alkalmazva
A C.25-öt AZONNAL alkalmaztam a #711-re (ahol kihagytam):
- C.25 Round 1 subagent: a 3 Copilot round-1 fix verifikálva + talált 1 P3
  javadoc-inkonzisztenciát (resolveRole() doc "néma CASHIER degrade"-et sugall,
  de getCurrentRole() valójában 400-at dob auth nélkül)
- A P3-at MERGE ELŐTT javítottam → pre-empt-elte a Copilot/Codex finding-et
- 6/6 teszt PASS, CI 14 green, admin-merged e2be4d72e

**Ez a C.25 értéke: a finding NEM jut el a GitHub AI gate-re, mert a saját
subagent review elkapja a push előtt.**

## Mérés
Következő 10 PR: cél ≤1 finding/PR (jelenlegi ~3-4 helyett).

## Mandate-ek (ma összesen)
- C.22 — 2-kör merge gate (CI + AI)
- C.23 — 2-kör SAJÁT subagent review
- C.24 — proaktív CI/AI poll + NEM megállás
- C.25 — KÖTELEZŐ pre-PR 4-fázis gate (NINCS gyors-PR kivétel)
