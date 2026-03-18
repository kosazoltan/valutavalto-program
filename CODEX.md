# Codex Security Integration

Ez a repository Codex-integracioja kotelezo security gate-re van allitva.

## Rule

- Kotelezo rule: `.cursor/rules/mandatory-security-gate.mdc`
- Kotelezo policy: `AGENTS.md` (Mandatory security gate for all agents szekcio)

## Skill

- Kotelezo skill: `.cursor/skills/security-deploy-gate/SKILL.md`
- Baseline: `.cursor/skills/security-deploy-gate/SECURITY_BASELINE_V3.md`

## Tool

- Kotelezo futtathato gate tool: `scripts/security/run-security-gate.ps1`
- Report output: `security-reports/latest/`

## Deploy gate szabaly

- `FAILED` vagy `BLOCKED` gate status eseten `NO-GO`.
- Evidence nelkul nincs "kesz" allitas.
