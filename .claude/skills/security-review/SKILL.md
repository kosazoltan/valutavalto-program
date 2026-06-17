---
name: security-review
description: Security review for auth, permissions, data handling, secrets, APIs, uploads, payments, and deployment changes.
---

# Security Review Skill

## Trigger

Use if task touches:
- authentication
- authorization
- sessions
- tokens
- secrets
- database access
- file upload/download
- payment/invoicing
- admin functions
- external APIs
- deployment
- environment variables

## Checklist

Check:
- auth bypass
- privilege escalation
- insecure direct object reference
- missing tenant/user scope
- unsafe SQL/query construction
- secret leakage
- unsafe logging
- weak validation
- CORS exposure
- SSRF risk
- path traversal
- file upload content-type trust
- rate limiting
- audit logging
- destructive operations

## Output

```text
SECURITY RESULT: PASS / FAIL / NEEDS HUMAN REVIEW
AUTH RISK:
DATA RISK:
SECRET RISK:
INPUT VALIDATION RISK:
EXTERNAL API RISK:
REQUIRED FIXES:
```
