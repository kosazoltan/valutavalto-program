---
name: github-quality-gate
description: Use when the user asks to push, commit, merge, or deploy. Runs scripts/pre-push-quality-gate.ps1 (lint+typecheck+test+build) and scripts/github-signal-check.ps1 to verify all 10 AGENTS.md gates before approving merge-ready state.
---

# github-quality-gate skill

Implements the 10-gate mandate from AGENTS.md / MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md.

## Required invocation for every push/merge/deploy

### Step 1: Local pre-push gate

```bash
powershell -ExecutionPolicy Bypass -File scripts/pre-push-quality-gate.ps1
```

Expected: exit=0 (all of lint+typecheck+test+build pass). If exit=1, TILOS push.

### Step 2: git push feature branch

```bash
git checkout -b fix/<desc> main
git add <specific files>
git commit -m 'msg'
git push -u origin <branch>
```

NEVER push directly to main/master/release/prod.

### Step 3: GitHub signal check (after push)

```bash
powershell -ExecutionPolicy Bypass -File scripts/github-signal-check.ps1 <PR_NUM>
```

Queries 20 sources: PR info, required checks, check-runs+annotations, Codex/Sourcery reviews+comments, Dependabot, CodeQL, secret scanning, workflow logs, reviewDecision+threads, branch protection/rulesets.

### Step 4: Blocker resolution

If signal-check finds blockers:
- required check fail/pending -> wait or fix
- Codex P0/P1 -> fix or documented false positive
- Sourcery bug_risk/security/complexity -> fix
- Dependabot high/critical -> upgrade or remove
- CodeQL high/critical -> fix vulnerability
- CHANGES_REQUESTED review -> address and re-request

### Step 5: Merge only after all signals GREEN

```bash
gh pr merge <PR> --squash --auto --delete-branch
```

## Output format

Every response must include the 16-field self-review from AGENTS.md section 4.

## Files used

- scripts/pre-push-quality-gate.ps1
- scripts/github-signal-check.ps1
- AGENTS.md (10 gates)
- AI_CONTRACT.md (hard limits)
- REVIEW.md (checklist)
