---
name: agents-md-generator
description: Use when setting up AGENTS.md/AI_CONTRACT.md/GEMINI.md/.github/copilot-instructions.md for a new repository, or syncing these files when the source mandate version changes. Ensures AGENTS.md remains the single source of truth (modellfuggetlen igazsagforras) and platform-specific files only extend, never weaken.
---

# agents-md-generator skill

Generates the multi-platform AI agent configuration from a single source mandate.

## Source

`MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md` (global memory) OR `docs/knowledge/memory/YYYY-MM-DD-multi-model-mandate-v2.qmd`

## Target files

Generate (or update) the following in repo root:

| File | Role |
|---|---|
| `AGENTS.md` | Modellfuggetlen igazsagforras (PRIMARY) |
| `AI_CONTRACT.md` | Hard limits + 300 LOC / 5 fajl plafon + security tiltasok |
| `CLAUDE.md` | Claude-specific (symlink to AGENTS.md OR content mirror) |
| `GEMINI.md` | Gemini-specific |
| `.github/copilot-instructions.md` | GitHub Copilot |
| `REVIEW.md` | Push elotti self-review checklist |
| `.claude/skills/*/SKILL.md` | 4 skills (github-quality-gate, ai-review-responder, deploy-verification, agents-md-generator) |

## Generation rule

1. AGENTS.md must contain all 10 gates + 10-step workflow + security tiltolista + zaro self-review format
2. Platform-specific files MUST point back to AGENTS.md as primary
3. AI_CONTRACT.md contains HARD LIMITS (300 LOC, 5 fajl, test manipulation tiltas, --no-verify tiltas, secret leak, Actions hardening)
4. REVIEW.md contains the `scripts/pre-push-quality-gate.ps1` + `scripts/github-signal-check.ps1` invocation sequence

## Sync

When the source mandate changes (e.g., v2.0 -> v2.1):
1. Update global memory (`MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md`)
2. Regenerate all 7 target files from the new source
3. Create YAML + QMD session memory
4. Update Obsidian vault `MANDATE_V2.md` (keep old as `MANDATE_V{N-1}_SUPERSEDED.md`)
5. Commit + PR with title `docs: sync AGENTS.md multi-platform files (mandate v2.X)`

## Validation

After generation:
```bash
# All files must exist
test -f AGENTS.md && test -f AI_CONTRACT.md && test -f CLAUDE.md && test -f GEMINI.md && test -f .github/copilot-instructions.md && test -f REVIEW.md

# AGENTS.md must contain the 10 kapu
grep -q "10 kapu" AGENTS.md || { echo "BLOCKED: AGENTS.md missing 10 kapu"; exit 1; }

# Scripts must exist
test -f scripts/pre-push-quality-gate.ps1 && test -f scripts/github-signal-check.ps1
```
