---
name: security-deploy-gate
description: Mandatory repository security audit flow. Run on every coding task and always before deploy.
---

# Antigravity Security Deploy Gate

## Mandatory steps

1. Read baseline: `.cursor/skills/security-deploy-gate/SECURITY_BASELINE_V3.md`
2. Execute tool: `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1`
3. Evaluate findings:
   - `FAILED` or `BLOCKED` => `NO-GO`
4. Report evidence from `security-reports/latest/`.
