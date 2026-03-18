# Antigravity Security Integration

Ez a repository Antigravity agentekhez is tartalmaz kotelezo security policy-t.

## Rule

- `.antigravity/rules/mandatory-security-gate.md`

## Skill

- `.antigravity/skills/security-deploy-gate/SKILL.md`

## Tool

- `.antigravity/tools/security-gate.tool.json`
- Futtatando parancs: `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1`

## Kotelezo gate

- `FAILED` vagy `BLOCKED` gate status eseten deploy tiltott.
- Eredmenyeket `security-reports/latest/` alapjan kell jelenteni.
