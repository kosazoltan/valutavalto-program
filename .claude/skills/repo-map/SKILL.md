---
name: repo-map
description: Read-only repository exploration before implementation. Use before editing code.
---

# Repo Map Skill

## Goal

Understand the smallest relevant code area before writing a patch.

## Hard rule

Do not edit files in this skill.

## Required output

```text
DETECTED STACK:
PACKAGE MANAGER:
TEST COMMANDS:
LINT COMMANDS:
TYPECHECK COMMANDS:
BUILD COMMANDS:
ENTRY POINTS:
AFFECTED MODULES:
DATA FLOW:
CALL FLOW:
PUBLIC API BOUNDARIES:
DATABASE TOUCHPOINTS:
AUTH TOUCHPOINTS:
EXISTING TESTS:
CONFIG FILES:
RISKY AREAS:
PATCH PLAN:
FILES TO READ NEXT:
```

## Detection rules

Inspect, where present:
- `package.json`
- `pnpm-lock.yaml`
- `yarn.lock`
- `package-lock.json`
- `pyproject.toml`
- `pytest.ini`
- `requirements.txt`
- `Cargo.toml`
- `go.mod`
- `.github/workflows/**`
- `Dockerfile`
- `docker-compose.yml`
- `tsconfig.json`
- `vite.config.*`
- `next.config.*`
- `.env.example`

## Context discipline

Do:
- start with file tree
- read config files first
- read existing tests
- read affected modules only
- summarize findings

Do not:
- load entire repo
- search blindly
- edit code
- run destructive commands
- inspect secrets

## Stop conditions

Stop for human approval if patch likely affects:
- schema migration
- auth/security
- payment/invoicing
- public API
- irreversible data change
- production deployment
