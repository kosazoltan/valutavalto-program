---
name: deployment-gate
description: Safe deployment planning for VPS, Docker, CI/CD, database, and production environments.
---

# Deployment Gate Skill

## Goal

Prevent unsafe production changes.

## Human approval required

Before:
- production deploy
- DB migration
- destructive operation
- environment variable change
- secret rotation
- DNS change
- payment/invoicing change
- auth/session change
- backup/restore operation

## Checklist

Before deploy:
- tests pass
- lint/typecheck/build pass
- migration reviewed
- backup exists
- rollback plan exists
- env vars documented
- secrets not printed
- health check known
- logs checked
- deployment window acceptable

## VPS safety

For VPS:
- never run destructive shell commands without explicit approval
- never overwrite production database
- never expose secrets
- prefer backup before migration
- prefer idempotent deployment scripts
- verify service status after restart

## Output

```text
DEPLOYMENT RESULT: READY / NOT READY / NEEDS HUMAN APPROVAL
TARGET:
CHANGES:
BACKUP:
ROLLBACK:
COMMANDS:
RISKS:
APPROVAL NEEDED:
```
