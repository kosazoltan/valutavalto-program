---
name: counter-review
description: Adversarial review of a completed patch.
---

# Counter Review Skill

## Goal

Try to prove the patch is wrong.

## Look for

- hidden edge case
- regression
- race condition
- data loss
- auth/security flaw
- input validation gap
- bad abstraction
- public API break
- test-only behavior
- hardcoded logic
- performance regression
- concurrency issue
- migration risk
- error handling breakage

## Rules

- Do not rewrite patch during review.
- Do not accept "tests pass" as enough.
- Compare against technical contract.
- Cite files/functions.
- Mark uncertainty explicitly.

## Output

```text
COUNTER-REVIEW RESULT: PASS / FAIL / NEEDS HUMAN REVIEW
TOP RISKS:
EDGE CASES NOT COVERED:
REGRESSION RISK:
SECURITY RISK:
DATA RISK:
PERFORMANCE RISK:
RECOMMENDED ACTION:
```
