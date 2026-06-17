---
name: debug-one
description: Debug exactly one failing test at a time and produce a root-cause report before patching.
---

# Debug One Skill

## Goal

Prevent confused multi-error debugging.

## Input required

- failing test name
- command that reproduces it
- failure output
- relevant files if known

## Hard rules

- one failing test only
- no test edits
- no broad refactor
- no guessing
- root cause before patch
- minimal fix only

## Allowed debugging actions

Use project-appropriate methods:
- run targeted test
- inspect stack trace
- inspect local variables through logs/debugger
- inspect function source
- inspect call path
- inspect arguments
- inspect types
- inspect fixture read-only
- inspect config read-only

## Required output

```text
FAILING TEST:
REPRO COMMAND:
OBSERVED FAILURE:
EXPECTED BEHAVIOR:
ROOT CAUSE:
AFFECTED FILE:
AFFECTED FUNCTION:
MINIMAL FIX:
DO NOT CHANGE:
VALIDATION COMMAND:
```

## Stop if

- test contradicts the contract
- fixture/snapshot change seems required
- public API change seems required
- failure is flaky or timing-dependent
- root cause is not established
