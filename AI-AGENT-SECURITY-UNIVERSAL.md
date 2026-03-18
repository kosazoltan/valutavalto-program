# AI Agent Security Universal Index

Ez az index osszefoglalja a repository-ben letrehozott platform-specifikus kotelezo security gate integraciokat.

## Claude

- `CLAUDE.md`
- `.claude/skills/security-deploy-gate/SKILL.md`
- `.claude/commands/security-gate.md`

## Codex / Cursor

- `AGENTS.md`
- `.cursor/rules/mandatory-security-gate.mdc`
- `.cursor/skills/security-deploy-gate/SKILL.md`
- `.cursor/skills/security-deploy-gate/SECURITY_BASELINE_V3.md`

## VS Code

- `VSCODE.md`
- `.vscode/tasks.json`
- `.vscode/settings.json`

## Antigravity

- `ANTIGRAVITY.md`
- `.antigravity/rules/mandatory-security-gate.md`
- `.antigravity/skills/security-deploy-gate/SKILL.md`
- `.antigravity/tools/security-gate.tool.json`

## Shared mandatory tool

- `scripts/security/run-security-gate.ps1`
- Report destination: `security-reports/latest/`
- Gate status artifact: `security-reports/latest/gate-status.json`
