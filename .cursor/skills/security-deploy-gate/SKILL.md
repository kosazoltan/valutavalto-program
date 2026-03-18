---
name: security-deploy-gate
description: Enforces a mandatory multi-stack security audit and hardening workflow (Java, Electron, React, Python, Node.js) with deploy blocking gates, evidence collection, and remediation checklist. Use by default on every coding task and always before deploy or release.
---

# Security Deploy Gate

## Purpose

Apply a mandatory, non-optional security workflow for this repository on every task, and run the full gate before deploy.

## Mandatory Execution Policy

1. Use this skill automatically on every coding task.
2. Run the full gate before any deploy/release recommendation.
3. If critical or high-risk findings remain unresolved, deploy is blocked.
4. Never fabricate results. If a check cannot run, report it as `BLOCKED` with reason and recovery steps.

## Source of Truth

- Full baseline and controls: [SECURITY_BASELINE_V3.md](SECURITY_BASELINE_V3.md)
- Automated command runner: `scripts/security/run-security-gate.ps1`

## Default Workflow

### Step 1 - Baseline context and safety

- Read `SECURITY_BASELINE_V3.md`.
- Confirm detected scope from repository files (Java/Node/React/Electron/Python).
- Preserve user changes; do not revert unrelated files.

### Step 2 - Run mandatory automated checks

Run from repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

Expected output location:

- `security-reports/latest/`

### Step 3 - Analyze findings and prioritize

- Prioritize in this order: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `INFO`.
- Immediate remediation required for `CRITICAL` and `HIGH`.
- For issues without patch versions, add compensating controls and document them.

### Step 4 - Implement secure fixes

- Keep fixes minimal and regression-safe.
- Add or update tests for each security-sensitive change.
- Keep sensitive data out of source and logs.

### Step 5 - Verify and produce evidence

- Re-run relevant tests and checks after remediation.
- Provide a concise status table:

```markdown
| Check | Status | Evidence |
|---|---|---|
| Dependency audit | PASS/FAIL/BLOCKED | report path or command result |
| SAST scan | PASS/FAIL/BLOCKED | report path or command result |
| Electron hardening | PASS/FAIL/BLOCKED | file refs |
| API security headers | PASS/FAIL/BLOCKED | test/output |
| Auth/JWT/session | PASS/FAIL/BLOCKED | test/output |
```

### Step 6 - Deploy gate decision

- `GO` only if no unresolved `CRITICAL`/`HIGH` findings, no `FAILED`, and no `BLOCKED`.
- Otherwise `NO-GO` with actionable remediation list.

## Required Reporting Format

Use this structure in responses for security runs:

```markdown
## Security Gate Result
- Decision: GO | NO-GO
- Critical findings: <count>
- High findings: <count>
- Reports: `security-reports/latest/`

## Findings (Top priority first)
- [SEVERITY] <title> - <impact> - <fix plan>

## Verification
- Commands executed: ...
- Tests executed: ...
- Remaining risks: ...
```
