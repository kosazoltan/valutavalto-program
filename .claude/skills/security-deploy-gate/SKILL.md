---
name: security-deploy-gate
description: Mandatory security audit and hardening flow for this repository. Apply by default on every coding task and always before deploy.
---

# Claude Security Deploy Gate

## Mandatory

1. Minden coding taskban alkalmazd ezt a skillt.
2. Deploy/release elott kotelezo futtatni:
   - `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1`
3. `FAILED` vagy `BLOCKED` gate status = deploy blokk.
4. Eredmenyt bizonyitekkal kell jelenteni: `security-reports/latest/`.

## Source of truth

- `.cursor/skills/security-deploy-gate/SECURITY_BASELINE_V3.md`
- `.cursor/skills/security-deploy-gate/SKILL.md`
