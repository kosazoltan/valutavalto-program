---
name: security-deploy-gate
description: Use for deploy, release, dependency/security/auth/CI changes, or explicit security audit. Not for every ordinary coding task.
---

# Antigravity Security Deploy Gate

Run the tool only when the task risk requires it:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

Report evidence from `security-reports/latest/`. `FAILED` or `BLOCKED` means
no deploy-ready claim.