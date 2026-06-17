---
name: ci-cd-gate
description: CI/CD validation and workflow safety for GitHub Actions, GitLab CI, Docker, and deployment pipelines.
---

# CI/CD Gate Skill

## Goal

Keep automation safe and reproducible.

## Inspect

- `.github/workflows/**`
- `.gitlab-ci.yml`
- Dockerfile
- docker-compose files
- deploy scripts
- package scripts
- test scripts
- env examples

## Rules

- Do not weaken CI to make builds pass.
- Do not remove failing jobs without approval.
- Do not hide test failures.
- Do not print secrets.
- Do not run production deploy on pull_request unless intended.
- Pin risky action versions when possible.
- Separate build, test, deploy stages.

## Output

```text
CI/CD RESULT:
WORKFLOWS TOUCHED:
JOBS CHANGED:
VALIDATION:
SECRET RISK:
DEPLOYMENT RISK:
RECOMMENDATION:
```
