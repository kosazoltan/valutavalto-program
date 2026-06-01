---
name: agents-md-generator
description: Use when creating or syncing AGENTS.md, AI_CONTRACT.md, CLAUDE.md, CODEX.md, GEMINI.md, or copilot-instructions.md. Keeps AGENTS.md as the single concise source of truth.
---

# agents-md-generator skill

Generate or sync a simple agent instruction system.

## Source of truth

`AGENTS.md` is the only operative workflow source.

## Target roles

| File | Role |
|---|---|
| `AGENTS.md` | Short model-neutral workflow and risk-based verification |
| `AI_CONTRACT.md` | Hard prohibitions and PR-size guidance |
| `AI_CONSTITUTION.md` | Short behavior principles |
| `CLAUDE.md` | Project/domain context and command reference |
| `CODEX.md`, `GEMINI.md`, `.github/copilot-instructions.md` | Platform indexes only |

## Rules

- Do not reintroduce always-on full gates.
- Do not require loading the full vault or mandate archive at session start.
- Do not require long self-review templates for normal tasks.
- Full security/deploy gates are mandatory before deploy/release and for
  security-sensitive changes.

## Validation

- Files exist.
- Platform files point to `AGENTS.md`.
- `.cursor/rules/*.mdc` use targeted descriptions and `alwaysApply: false`.