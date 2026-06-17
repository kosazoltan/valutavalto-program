---
name: context-budget
description: Manage context window usage in large repositories and long tasks.
---

# Context Budget Skill

## Goal

Avoid losing important details in long tasks.

## Strategy

1. externalize durable state to files
2. keep memory concise
3. load only relevant files
4. summarize before switching phase
5. write intermediate artifacts
6. validate from files, not memory

## Rules

- Do not paste huge logs into final answer.
- Store long findings in `.claude/memory/` or `.claude/references/`.
- Use file maps instead of full source copies.
- Mark stale assumptions.
- Re-read critical files before editing.

## Phase checkpoints

After each phase, write concise state:
- contract
- tests
- frozen paths
- repo map
- patch plan
- validation result
- audit result

## Output

```text
CONTEXT STATUS:
CURRENT PHASE:
FILES LOADED:
STATE WRITTEN:
RISKS OF CONTEXT LOSS:
NEXT FILES TO READ:
```
