# ADS Architecture Adaptation Guide

Reference for `.claude/skills/ads-architecture/SKILL.md`.

## When to Use the ADS Graph

Use the declarative workflow graph when **two or more** of the following apply:

- The task touches 3+ modules or files with non-trivial dependencies.
- A database migration is involved.
- Auth, payment, or financial logic is affected.
- Multiple agent roles would benefit from explicit handoffs.
- The task has a review or approval gate before a destructive step.
- The user asked for a durable, re-runnable workflow configuration.

For single-file bug fixes or simple one-module features, the TDFlow pipeline (see `tdflow-opus`) is sufficient without a full graph definition.

## How to Decompose into Phases

1. **Identify outputs** — what artifact does each node produce? Contract, tests, repo map, patch, validation result, audit result.
2. **Identify gates** — where does a human need to approve before the next node runs? Mark these as `gates` in the graph.
3. **Keep nodes narrow** — one responsibility per node; if a node does two things, split it.
4. **Name inputs and outputs explicitly** — every edge in the graph must have a named artifact; avoid implicit state passing.
5. **Split large graphs** — if the graph exceeds ~8 nodes, consider splitting into Phase 1 (contract → freeze) and Phase 2 (patch → deploy).

## Gate Triggers

Always add a gate node before:

- `human_approval_for_migration` — any Flyway or schema change
- `human_approval_for_auth_or_payment` — auth, session, JWT, payment, invoicing
- `human_approval_for_public_api_break` — removing or renaming a public endpoint
- `human_approval_for_production_deploy` — any step that writes to production

## Minimal Example (single feature)

```yaml
workflow:
  name: add-cashier-fee-config
  goal: Add configurable handling fee per branch
  nodes:
    - id: contract
      role: ContractAgent
      inputs: [user_request]
      outputs: [technical_contract]
    - id: tests
      role: TestAuthorAgent
      inputs: [technical_contract]
      outputs: [frozen_tests]
    - id: patch
      role: PatchAgent
      inputs: [technical_contract, frozen_tests]
      outputs: [patch]
    - id: validation
      role: ValidationAgent
      inputs: [patch]
      outputs: [validation_result]
  gates:
    - name: human_approval_for_migration
```
