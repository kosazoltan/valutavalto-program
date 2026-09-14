---
name: valutavalto-memory-pipeline-kanban
description: >-
  Use before non-trivial Valutavalto work and after every completed slice.
  Covers area-tagged memory read/write, repo-local kanban.mjs, and when
  Cursor may implement directly versus handing off to the Hermes six-souls
  pipeline. Also use when job.yaml status looks stale or a pipeline job might
  be relaunched.
---

# Memory, kanban, and the program-creation pipeline

This repo's living memory is `.agent/memory/` (qmd + yaml + cognee +
vector + obsidian). **Do not** create a parallel `memory/` tree.

## 1. Kanban — ticket first

The board tool ships with Hermes, not with this repo, so its path is
**machine-local and configurable**. Resolve it from the environment
rather than copying one developer's path:

```bash
# HERMES_HOME defaults to the per-user Hermes install
KANBAN="${HERMES_HOME:?set HERMES_HOME to your Hermes install}/skills/software-development/hermes-kanban-workflow/scripts/kanban.mjs"
node --no-warnings "$KANBAN" list
```

Run it from the repository root (`git rev-parse --show-toplevel`);
worktrees have no `.hermes/`. If Hermes is not installed, this section
does not apply — use GitHub issues directly and say so in the report.

`add` → `start` → work → `review` + evidence note → `done`.
Illegal transitions exit 1. Opening the row after the work is a
**process violation** — record it in the note, do not hide it.

External tracker for this repo is GitHub issues, not Jira. Leave
`--ticket` empty rather than inventing a key.

## 2. Memory read-gate / write-gate

```
npm run memory:query -- "<kw>" --area <area> --limit 8
npm run memory:areas
npm run memory:symbol -- "<feature>"   # Delphi 8304-file index
npm run memory:build
npm run memory:stale-check              # exit 1 = do not close
```

Never bulk-read `vault/**`. Durable facts only: verified root cause,
reusable command, corrected stale knowledge. No secrets.

`.git/info/exclude` lists generated memory layers — they are still
**tracked**. After `memory:build`, the diff belongs in a dedicated
memory PR (see #1736), not mixed into a product PR.

Live Cognee/Obsidian ingest needs Docker MCP (`localhost:8820/8821`).
If `docker ps` is empty, the repo-local bundle is the truth; say so.

## 3. Six-souls pipeline (Hermes) vs Cursor

Pipeline layout (gitignored): `.hermes/pipeline/<YYYYMMDD-slug>/`
with `job.yaml` + `round-N/` artifacts. Launcher:
`.hermes/pipeline/launch_soul.sh` (Hermes profiles, HKCU keys).
**Cursor must not launch souls** and must not source a repo `.env`.

| Cursor may | Cursor must not |
|---|---|
| Trivial 1–2 file fix + test | Start a second job while one is `status: planning/coding` |
| Write the ticket + claim ledger | Copy `launch_soul.sh` per job |
| Fix `job.yaml` bookkeeping | Relaunch from a stale ping or stale `planning` status without `git log` |
| Implement if the user asked Cursor to code | Invent a parallel review pipeline |

Trivial = obvious cause, not money / tenant / contract / DB / sync /
installer. Everything else: Hermes six-souls (planner → coder →
blind dual review → judge) **or** Cursor prompt-contract + frozen tests
with the same evidence bar (call-path file:line).

Gold sample: job `20260913-fkh070-handling-fee-expected` — Phase 0
ledger, plan-gate, 4 WU commits, smoke 89 tests, judge PASS, merged
`#1756` / `10a8122f`. Copy that artifact shape.

## 4. Bookkeeping defects (measured 2026-09-13)

A job whose product is **already on main** but `job.yaml` still says
`planning` or `coding` will cause a duplicate pipeline. Before any
relaunch:

```
git log --oneline --grep="<FKH-nnn>" -5
git branch -a --list "*<slug>*"
```

If merged: set `status: pass`, write a close history line, do not
relaunch. Fixed this session: FKH-061 (`planning` → pass, PRs #1739+#1740)
and FKH-063 (`coding` → pass, PR #1743).

`.hermes.md` version line is a CLAIM — bump it when `package.json` moves
(was stale at v2.28.109 while repo was v2.28.113).

## 5. After the work

Hungarian user report: files, checks PASS/FAIL, what was not run.
Handoff: `vault/sessions/handoff-YYYY-MM-DD-<slug>.md` (≤30 lines).
Kanban note with SHA / PR / commands. `memory:build`.
