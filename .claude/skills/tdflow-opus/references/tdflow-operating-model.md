# TDFlow Operating Model

Reference for `.claude/skills/tdflow-opus/SKILL.md`.

## The 13-Step Pipeline

TDFlow separates every software task into ordered, auditable phases. No phase may skip ahead.

1. **Interpret request** — read the user's message, identify the task type (feature / bug / refactor / migration).
2. **Convert to technical contract** — use the `prompt-contract` skill; produce TASK, GOAL, NON-GOALS, ACCEPTANCE CRITERIA before any code.
3. **Write or identify tests** — use the `isolated-test-driven-opus` skill; reproduction + regression + edge-case tests written first.
4. **Freeze tests** — after human or implicit approval, the test files are locked; record frozen paths explicitly.
5. **Map repository** — use the `repo-map` skill; read-only exploration; output: stack, commands, affected modules, data flow, patch plan.
6. **Propose minimal patch** — describe the change before writing it; surface risks; get approval for high-risk areas (migration, auth, payment).
7. **Implement patch** — production files only; follow existing style; smallest practical surface.
8. **Run targeted validation** — run the single failing test first to confirm the fix; record exact command and output.
9. **Debug One per failing test** — if any test still fails, use the `debug-one` skill; one test at a time; root cause required before each fix.
10. **Revise patch** — apply minimal fix from Debug One; no test edits; no unrelated changes.
11. **Run validation gate** — use `validation-gate` skill; full sequence: targeted → related suite → lint → typecheck → build → full suite if feasible.
12. **Run anti-test-hacking audit** — use `anti-test-hacking-audit` skill; inspect diff for any of the 20 forbidden patterns.
13. **Run counter-review** — use `counter-review` skill; adversarial pass to find hidden defects before merge.
14. **Final report** — evidence-first summary with files changed, commands run, results, remaining risks, unverified assumptions.

## Agent Separation

Each phase has a designated agent role. Do not blend responsibilities across roles in a single agent turn.

| Phase | Agent Role |
|-------|-----------|
| 1–2 | Contract Agent |
| 3 | Test Author Agent |
| 4 | (freeze declaration, no agent action) |
| 5 | Repo Map Agent |
| 6–7 | Patch Agent |
| 8–10 | Debug One Agent |
| 11 | Validation Agent |
| 12 | Audit Agent |
| 13 | Counter Review Agent |

## Key Invariants

- Tests are never modified after freeze.
- Production code is never written before test freeze.
- No phase claims success without command evidence.
- Human approval gates apply before: migration, auth change, payment logic, public API break, production deploy.
