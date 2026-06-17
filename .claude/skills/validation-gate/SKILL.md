---
name: validation-gate
description: Determine and run the correct validation commands before finalizing a coding task.
---

# Validation Gate Skill

## Goal

Prove with commands, not claims.

## Command discovery

Inspect:
- `package.json`
- lockfiles
- CI workflows
- Makefile
- task runner files
- pyproject/pytest/tox
- Docker/compose files
- framework configs

## Validation order

1. targeted test
2. related suite
3. lint
4. typecheck
5. build
6. full suite if feasible
7. CI-equivalent command if available

## Output

```text
DETECTED STACK:
COMMANDS FOUND:
COMMANDS RUN:
RESULTS:
FAILURES:
NOT RUN:
WHY NOT RUN:
FINAL STATUS:
```

## Rule

Never claim success without command evidence.

If a command cannot be run, say:
- NOT RUN
- why not
- risk
- suggested human command
