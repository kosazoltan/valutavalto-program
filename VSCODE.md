# VS Code Security Integration

Ez a repository VS Code-ban is kotelezo security gate-re van beallitva.

## Rule

- Kotelezo policy: `.cursor/rules/mandatory-security-gate.mdc`
- Kotelezo leiras: `AGENTS.md` es `CLAUDE.md` security gate szekciok

## Skill

- Kotelezo skill baseline: `.cursor/skills/security-deploy-gate/SKILL.md`
- Kotelezo policy baseline: `.cursor/skills/security-deploy-gate/SECURITY_BASELINE_V3.md`
- Rovid referencia: `.claude/skills/security-deploy-gate/SKILL.md`

## Tool

- VS Code task: `.vscode/tasks.json` -> `Security Gate: Mandatory Audit`
- Auto-futtatas mappanyitasnal: `.vscode/settings.json` + task `runOn: folderOpen`
- Futtatott tool: `scripts/security/run-security-gate.ps1`
