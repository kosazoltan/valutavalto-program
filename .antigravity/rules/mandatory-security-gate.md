# Mandatory Security Gate Rule

This rule is always-on for Antigravity agents in this repository.

1. Load security skill: `.antigravity/skills/security-deploy-gate/SKILL.md`
2. Run tool before deploy: `.antigravity/tools/security-gate.tool.json`
3. Block deploy on gate status `FAILED` or `BLOCKED`.
4. Report evidence from `security-reports/latest/`.
