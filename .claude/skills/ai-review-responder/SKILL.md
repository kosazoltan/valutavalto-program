---
name: ai-review-responder
description: Use when Sourcery, Codex, Dependabot or CodeQL posts review feedback on a PR. Queries reviews and inline comments via gh api, categorizes findings (P0/P1/P2/style), and applies fixes in a cumulative follow-up PR. Replaces the legacy pattern of the user copy-pasting review emails.
---

# ai-review-responder skill

Replaces the legacy workflow where the user copy-pastes Sourcery/Codex review emails into chat. Now the agent queries them directly.

## Trigger

When:
- A PR is pushed and Sourcery/Codex run automatically
- A PR has unresolved bot review comments
- `@sourcery-ai review` or `@codex review` was triggered

## Query commands

### Codex reviews

```bash
gh api "/repos/$OWNER/$REPO/pulls/$PR/reviews" \
  --jq '.[] | select(.user.login | ascii_downcase | contains("codex")) | {state, body, submitted_at}'

gh api "/repos/$OWNER/$REPO/pulls/$PR/comments" \
  --jq '.[] | select(.user.login | ascii_downcase | contains("codex")) | {path, line, body}'
```

### Sourcery reviews

```bash
gh api "/repos/$OWNER/$REPO/pulls/$PR/reviews" \
  --jq '.[] | select(.user.login | ascii_downcase | contains("sourcery")) | {state, body}'

gh api "/repos/$OWNER/$REPO/pulls/$PR/comments" \
  --jq '.[] | select(.user.login | ascii_downcase | contains("sourcery")) | {path, line, body}'
```

## Classification

Each finding categorize:

- **P0/P1 / bug_risk / security / Badge**: MUST fix before merge
- **P2 / style / readability**: fix preferred, dismiss with documented reason allowed
- **P3 / nit**: fix optional

## Fix workflow

1. Read the finding (file + line + message)
2. Apply fix in the same branch or cumulative follow-up branch `fix/ai-review-pr<N>-cumulative`
3. Run pre-push-quality-gate.ps1 before pushing
4. Push + check that Sourcery/Codex re-run and new findings are resolved
5. Merge via `gh pr merge --squash --auto --delete-branch`

## Never dismiss without

- documented reason in commit message
- human maintainer approval for `@sourcery-ai dismiss` / `@codex dismiss`

## Output in final self-review

Include in AGENTS.md section 4 self-review:
- Codex findings: list of P0/P1 resolved/open
- Sourcery findings: list of security/test/complexity resolved/open
