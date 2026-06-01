---
name: security-deploy-gate
description: Use for deploy, release, dependency/security/auth/CI changes, or explicit security audit. Not a default step for ordinary local edits.
---

# Security Deploy Gate

Use this skill only when the task risk justifies it.

## Run full gate before deploy/release

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

Evidence: `security-reports/latest/`.

`FAILED` or `BLOCKED` means no deploy-ready claim.

## Normal coding task

Apply the security prohibitions in `AGENTS.md`, then run targeted tests/checks.