---
name: github-quality-gate
description: Use when the user asks to push, commit, merge, open a PR, or deploy. Runs the relevant local checks and GitHub signal checks before merge/deploy decisions.
---

# github-quality-gate skill

Use this skill only for git publication or deployment workflows, not for every
local edit.

## Push/PR workflow

1. Run the relevant local checks for the touched stack.
2. Push a feature branch, never directly to protected main.
3. If a PR exists, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/github-signal-check.ps1 <PR_NUM>
```

4. Fix blocking CI/review/security findings or document a verified false positive.

## Deploy/release workflow

Run the deploy/security gate required by `AGENTS.md` and report the evidence path.

## Reporting

Keep output concise: changed files, commands, pass/fail/blocker, remaining risk.