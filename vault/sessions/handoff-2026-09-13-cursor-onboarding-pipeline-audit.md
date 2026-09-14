# Handoff — 2026-09-13 — Cursor onboarding + pipeline bookkeeping

Date: 2026-09-13. Main: `10a8122f` (v2.28.113). Kanban #48.

## Intent

Make Cursor work on this repo the same way Hermes does: living memory,
ticket-first kanban, spec Phase 0, platform rule, and an honest
pipeline status. Schema remains `.agent/memory` only.

## What landed (local / committed-path)

- `.cursor.md` (untracked, like `.hermes.md`) — product briefing + MCP inventory
- `.cursor/rules/valutavalto-cursor-operating.mdc` (alwaysApply)
- Skills: `valutavalto-platform-architecture`,
  `valutavalto-spec-driven-feature-delivery`,
  `valutavalto-memory-pipeline-kanban`
- `.hermes.md` version line corrected: v2.28.109/`8e4ae6c2` → **v2.28.113** / `10a8122f`
- Stale `job.yaml`: FKH-061 `planning` → pass (PRs #1739+#1740);
  FKH-063 `coding` → pass (PR #1743); FK-080 and FK-087 leftover
  `PASS-awaiting-user-merge-decision` after they were already on main.

## Pipeline (verified)

FKH-070 is the quality bar: ticket ledger, plan-gate, judge PASS,
merged #1756, `DenominationBalanceService` HANDLING_FEE Expected =
`Transaction.handlingFee` (legacy KK SUM was empty). Docker MCP stack
was down (`docker ps` empty). Open PR #1755 (KAN-15) untouched.

## Not done

No product money-path change this session. No commit/push (not asked).
Live Cognee ingest NOT RUN (Docker down).
