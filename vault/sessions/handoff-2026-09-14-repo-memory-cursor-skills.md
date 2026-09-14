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

## Follow-up (#1770 → superseded by #1771)

After merge, `memory:stale-check` reported `changed: 2`. The first attempt (#1770) only
regenerated the two hashes. Both reviewers correctly rejected that: `readText()` returned the
working tree verbatim and `sha()` hashed it, while `.gitattributes` leaves `*.md` as `text=auto`
with no fixed `eol` — so the baseline was specific to the generating checkout and would have
flipped the failure to LF checkouts (Linux/CI).

Root-cause fix in #1771: `readText()` normalizes CRLF pairs to LF before any derived value
(sha256, bytes, summary, keywords) is computed; a lone CR is left untouched. Whole bundle
rebuilt: 1108 sources, `ok=true`.

Proof — `scripts/__tests__/eol-proof.mjs` flips one tracked source between both checkout forms
and re-runs `stale-check`:

```
RED  (fix stashed):     CRLF PASS / LF FAIL changed=1   exit 1
GREEN (fix + rebuild):  CRLF PASS / LF PASS             exit 0
```

**Rule:** fix the hashing, not the hashes. Regenerating a baseline only moves the failure to the
other platform.

## Verification

`npm run lint` green on both branches (four-area-alignment OK, agentward 5/5, secret-scan clean,
frontend + penztar eslint exit 0). #1768: all 12 required checks SUCCESS before merge.

## Gotchas recorded in `.hermes.md`

`verify-required-checks.sh` lives in `.git/`, not `scripts/`. `gh pr merge` reporting
"base branch policy prohibits the merge" usually means unresolved review threads, not a failing
check — query `reviewThreads` via GraphQL.
