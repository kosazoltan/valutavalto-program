---
name: anti-test-hacking-audit
description: Audit patches for fake passes, modified tests, weak assertions, and unrelated changes.
---

# Anti-Test-Hacking Audit Skill

## Goal

Reject patches that pass by cheating.

## Checklist

Flag or reject if any occur:

1. frozen test file modified
2. assertion weakened
3. test skipped
4. test marked only/todo/flaky/ignored
5. fixture changed to hide failure
6. snapshot updated without approval
7. mock changed to avoid real behavior
8. hardcoded expected output copied from test
9. magic constant copied from test
10. test-only branch
11. environment-specific bypass
12. timeout increased to hide instability
13. unrelated refactor
14. public API changed unnecessarily
15. validation weakened
16. auth/security weakened
17. error handling weakened
18. build/test config excludes failing files
19. coverage/test discovery weakened
20. documentation substituted for working behavior

## Inspect

- git diff
- test file changes
- config file changes
- fixture changes
- snapshot changes
- package scripts
- CI config
- production diff

## Output

```text
AUDIT RESULT: PASS / FAIL / NEEDS HUMAN REVIEW
TEST FILES MODIFIED:
CONFIG FILES MODIFIED:
SUSPICIOUS CHANGES:
SECURITY RISK:
DATA RISK:
PUBLIC API RISK:
REQUIRED ACTION:
```
