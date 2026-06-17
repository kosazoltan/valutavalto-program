---
name: tdflow-opus
description: Test-driven agentic workflow for repo-scale bug fixing, feature repair, and regression repair.
---

# TDFlow Opus Skill

## Goal

Solve software tasks as test-resolution tasks using separated phases.

## Pipeline

1. Interpret request
2. Convert to technical contract
3. Write or identify tests
4. Freeze tests
5. Map repository
6. Propose minimal patch
7. Implement patch
8. Run targeted validation
9. Debug One per failing test
10. Revise patch
11. Run validation gate
12. Run anti-test-hacking audit
13. Run counter-review
14. Final report

## Agent separation

Do not blend all responsibilities.

Use roles:
- Contract Agent
- Test Author Agent
- Repo Map Agent
- Patch Agent
- Debug One Agent
- Validation Agent
- Audit Agent
- Counter Review Agent

## Patch rules

- solve the test-defined behavior
- keep diff small
- avoid unrelated refactor
- no test modifications after freeze
- no public API change unless contract says so
- no migration without approval
- no security behavior weakening

## Debug rules

Each failing test gets:
- exact command
- exact failure
- likely root cause
- minimal fix
- no unrelated changes

## Final output

```text
CONTRACT:
TESTS:
FROZEN PATHS:
REPO MAP:
PATCH:
VALIDATION:
AUDIT:
COUNTER REVIEW:
RISKS:
UNVERIFIED:
```

## Reference

See `.claude/skills/tdflow-opus/references/tdflow-operating-model.md` for the full 13-step pipeline and agent-separation details.
