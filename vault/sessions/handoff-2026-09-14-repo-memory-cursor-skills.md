# Handoff — 2026-09-14 — repo memory rebuild + Cursor skills (#1768, #1770)

Base `a75601a4` (FK13). Merged: **#1768 → main `4593db3f`**. Follow-up **#1770** open at write time.

## What shipped (#1768)

Docs and generated artifacts only — no application code, no version bump, no installer.

- `.agent/memory/*` regenerated on current main: **1107 sources**, `memory:stale-check ok=true`.
- Three `vault/sessions` handoffs put under version control (they were hidden only by a local
  `.git/info/exclude`, while the repo tracks 130+ others). Without them a fresh clone rebuilds
  1104 sources and reports 3 as removed.
- New `.cursor` operating rule + 3 skills (memory-pipeline-kanban, platform-architecture,
  spec-driven-feature-delivery) next to the already-tracked `.cursor` rules.

## Review defects found and fixed (4 threads, all resolved)

1. `sources.json` referenced untracked handoffs → tracked them.
2. Memory claimed FKH-070 "unmerged" while `10a8122f` is its merge commit → corrected the handoff
   and regenerated. A stale claim like this can trigger a duplicate pipeline.
3. Cursor skills hard-coded one developer's absolute paths → resolved from `$HERMES_HOME`, repo-root
   cwd, explicit no-Hermes fallback.
4. "The ticket governs" could have overridden business rules → scoped to stale repo facts only;
   a ticket may never override an EXCMD/felmérési rule (money, day close, AML, KKTG, rounding).

## Follow-up (#1770)

After merge, `memory:stale-check` reported `changed: 2`. Cause: `core.autocrlf=true` — the two new
files were hashed from LF bytes pre-commit, every other source from the CRLF working tree.
Rebuilt on merged main: 1107 sources, `ok=true`, semantic diff = exactly those 2 sha256 values.

**Rule:** `git add` new sources FIRST, then `memory:build`.

## Verification

`npm run lint` green on both branches (four-area-alignment OK, agentward 5/5, secret-scan clean,
frontend + penztar eslint exit 0). #1768: all 12 required checks SUCCESS before merge.

## Gotchas recorded in `.hermes.md`

`verify-required-checks.sh` lives in `.git/`, not `scripts/`. `gh pr merge` reporting
"base branch policy prohibits the merge" usually means unresolved review threads, not a failing
check — query `reviewThreads` via GraphQL.
