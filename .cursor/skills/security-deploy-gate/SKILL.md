---
name: security-deploy-gate
description: Use for deploy, release, dependency/security/auth/CI changes, or explicit security audit. Not a default step for ordinary local edits.
---

# Security Deploy Gate

## Purpose

Run the repository security gate when risk requires it, especially before deploy
or release. Do not use it as a default loop for unrelated coding tasks.

## Full gate

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

Reports: `security-reports/latest/`.

Decision:

- `PASS`: security gate passed for the checked scope.
- `FAILED` or `BLOCKED`: no deploy-ready claim.

## Remediation

- Fix critical/high findings first.
- Keep changes minimal.
- Re-run the relevant failed check, not every unrelated gate.

## Reporting

Report only:

- command run;
- result;
- report path;
- remaining blocker, if any.