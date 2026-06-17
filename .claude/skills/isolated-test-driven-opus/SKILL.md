---
name: isolated-test-driven-opus
description: Use for implementing features or bug fixes through frozen tests, preventing test hacking.
---

# Isolated Test Driven Opus Skill

## Goal

Make Opus solve the program through tests, not by modifying tests.

## Principle

Tests are the contract.
Production code must satisfy the tests.
Implementation cannot move the goalpost.

## Phase 1: Technical contract

Use prompt-contract first.

## Phase 2: Test authoring

Create or identify:
- reproduction test
- regression test
- edge case test when relevant
- security test when relevant
- negative-path test when relevant

Test rules:
- tests describe behavior
- tests do not encode internal implementation unless the implementation is the public contract
- tests should fail before the fix when feasible
- tests should be deterministic
- tests should avoid external network dependency unless explicitly integration tests
- tests should not depend on wall-clock timing unless controlled
- tests should use stable fixtures

Expected output:
```text
TEST FILES:
TEST PURPOSE:
EXPECTED INITIAL FAILURE:
TARGETED TEST COMMAND:
```

## Phase 3: Test freeze

After creation or approval, freeze:
- `tests/**`
- `__tests__/**`
- `**/*.test.*`
- `**/*.spec.*`
- `fixtures/**`
- `snapshots/**`
- mocks used by the frozen tests

Implementation agents cannot modify frozen files.

## Phase 4: Production implementation

Allowed:
- minimal production code change
- existing style and architecture
- smallest practical surface area

Forbidden:
- test file editing
- assertion weakening
- snapshot updating
- fixture manipulation
- hardcoded expected values
- test-only branches
- environment bypasses
- skipping tests
- broad refactor without approval

## Phase 5: Validation

Run:
1. targeted failing test
2. related suite
3. lint
4. typecheck
5. build
6. full suite if feasible

## Phase 6: Human escalation

If a frozen test is wrong, stop and report:

```text
TEST:
SPEC CONFLICT:
WHY IT IS WRONG:
PROPOSED CORRECTION:
RISK IF UNCHANGED:
NEEDS HUMAN APPROVAL:
```
