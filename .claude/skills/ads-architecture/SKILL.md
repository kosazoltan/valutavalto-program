---
name: ads-architecture
description: Use for decomposing complex development tasks into declarative graph-like agent workflows.
---

# ADS Architecture Skill

## Goal

Represent complex coding work as a declarative workflow graph.

## Use when

- feature touches multiple modules
- migration is involved
- multiple agents are useful
- task requires planning, execution, review
- user wants durable workflow configuration

## Graph format

```yaml
workflow:
  name: string
  goal: string
  nodes:
    - id: contract
      role: ContractAgent
      inputs: [user_request]
      outputs: [technical_contract]
    - id: tests
      role: TestAuthorAgent
      inputs: [technical_contract]
      outputs: [frozen_tests]
    - id: repo_map
      role: RepoMapAgent
      inputs: [technical_contract, frozen_tests]
      outputs: [repo_map]
    - id: patch
      role: PatchAgent
      inputs: [technical_contract, frozen_tests, repo_map]
      outputs: [patch]
    - id: validation
      role: ValidationAgent
      inputs: [patch]
      outputs: [validation_result]
    - id: audit
      role: AuditAgent
      inputs: [patch, validation_result]
      outputs: [audit_result]
    - id: counter_review
      role: CounterReviewAgent
      inputs: [patch, technical_contract]
      outputs: [counter_review_result]
  gates:
    - name: no_test_modification_after_freeze
    - name: human_approval_for_migration
    - name: human_approval_for_auth_or_payment
```

## Rules

- Keep graph nodes narrow.
- Every node has explicit input and output.
- Use gates before risky actions.
- If graph becomes too large, split workflow into phases.
- Do not implement before graph approval for high-risk changes.

## Reference

See `.claude/skills/ads-architecture/references/ads-adaptation.md` for guidance on when and how to apply this graph format.
