---
name: prompt-contract
description: Convert user requests into precise technical contracts before tests or code. Use for every non-trivial development task.
---

# Prompt Contract Skill

## Goal

Convert human prose into a technical contract.

Do not write code in this skill.

## Required output

```text
TASK:
GOAL:
NON-GOALS:
INPUT:
OUTPUT:
PRECONDITIONS:
POSTCONDITIONS:
EDGE CASES:
ERROR HANDLING:
SECURITY:
PERFORMANCE:
AFFECTED AREAS:
FORBIDDEN CHANGES:
ACCEPTANCE CRITERIA:
UNKNOWN QUESTIONS:
HUMAN APPROVAL NEEDED:
```

## Rules

- Remove narrative prose.
- Do not invent requirements.
- Mark uncertainty as UNKNOWN.
- Mark unverified claims as UNVERIFIED.
- Prefer measurable acceptance criteria.
- Detect hidden risks: auth, data, payment, migrations, public API.
- If requirements conflict, stop and report.
- If the task is destructive, require human approval.
- If user asks to code immediately, still produce the contract first.

## Good acceptance criteria

Good:
- `POST /api/orders rejects unauthenticated users with 401`
- `Existing invoice generation tests still pass`
- `Currency conversion uses Decimal and rounds only at output boundary`

Bad:
- `Make it better`
- `Improve quality`
- `Handle all cases`

## Output discipline

Keep it short.
No implementation until test phase.
