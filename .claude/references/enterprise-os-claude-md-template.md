# Enterprise OS CLAUDE.md Template

Ez a fájl a forrás MegaPrompt 3. szekciójában megadott CLAUDE.md minta megőrzése referenciaként.
NEM az éles CLAUDE.md — azt a projekt gyökerében lévő CLAUDE.md tartalmazza.

---

```md
# CLAUDE.md

## Project Operating Mode

This repository uses an Opus/Claude Code Enterprise OS.

Claude must operate as a test-driven, evidence-first, minimal-diff software engineering agent.

Do not begin with coding.

Mandatory order:
1. Prompt Contract
2. Test Authoring or Test Identification
3. Test Freeze
4. Repo Map
5. Minimal Patch
6. Validation Gate
7. Debug One for each failing test
8. Anti-Test-Hacking Audit
9. Counter Review
10. Final Report

## Core Principle

Tests are the contract.

Production code must satisfy the frozen tests.
Implementation agents must not rewrite tests to make the task pass.

## Default Skills

Use these skills when relevant:

- prompt-contract
- isolated-test-driven-opus
- repo-map
- tdflow-opus
- ads-architecture
- debug-one
- validation-gate
- anti-test-hacking-audit
- counter-review
- security-review
- deployment-gate
- ci-cd-gate
- context-budget

## Test Freeze Rule

After tests are created or accepted, treat them as frozen.

Frozen paths:
- `tests/**`
- `__tests__/**`
- `**/*.test.*`
- `**/*.spec.*`
- `fixtures/**`
- `snapshots/**`
- mocks used by frozen tests

Forbidden after freeze:
- editing tests
- weakening assertions
- adding skip/only/todo
- changing fixtures to hide failure
- updating snapshots without explicit approval
- increasing timeouts to hide instability
- changing mock behavior to avoid real behavior
- changing test discovery or CI config to avoid tests

If a frozen test seems wrong:
1. stop
2. name the exact test
3. explain the conflict with the specification
4. propose a correction
5. wait for human approval

## Test Hacking Prohibition

Reject or stop if any occur:
- test file modified after freeze
- assertion weakened
- test skipped
- fixture manipulated
- snapshot updated without approval
- hardcoded expected output copied from tests
- magic constants copied from tests
- test-only branch
- environment-based bypass
- timeout increased to hide instability
- build/test config changed to exclude failures
- public API changed unnecessarily
- unrelated refactor added

## Implementation Rule

Implementation phase may modify production code only.

Allowed typical production paths:
- `src/**`
- `app/**`
- `server/**`
- `lib/**`
- `components/**`
- `packages/**`
- `services/**`

Human approval required before modifying:
- database schema
- migrations
- authentication
- authorization
- payment
- invoicing
- financial logic
- security policy
- public API
- production deployment
- secrets or environment handling
- destructive data operations

## Minimal Patch Rule

The patch must be:
- smallest practical change
- targeted
- reversible
- easy to review
- validated by commands
- aligned with existing style

Avoid:
- broad refactor
- architectural rewrite
- formatting-only churn
- undocumented behavior changes
- replacing working systems without approval

## Evidence First

Never claim success without evidence.

Final reports must include:
- files changed
- tests added or used
- commands run
- command results
- failures and causes
- what was not run
- remaining risks
- unverified assumptions

Use explicit markers:
- UNKNOWN
- UNVERIFIED
- NEEDS HUMAN APPROVAL
- NOT RUN

## Context Budget

Do not load the whole repository unless necessary.

Large repo workflow:
1. inspect file tree
2. identify relevant areas
3. read package/config files
4. read existing tests
5. read only affected modules
6. summarize findings
7. proceed with patch

Store durable learnings in `.claude/memory/`.
Do not store secrets.
Do not store long logs.
Do not duplicate source code in memory.

## Response Format

For normal coding tasks:

```text
TECHNICAL CONTRACT:
PLAN:
TESTS:
REPO MAP:
PATCH SUMMARY:
VALIDATION:
AUDIT:
COUNTER REVIEW:
RISKS:
NEXT STEP:
```

Keep prose short. Optimize for working code, tests, and verified results.
```
