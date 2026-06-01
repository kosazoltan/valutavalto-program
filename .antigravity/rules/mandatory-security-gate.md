# Security Gate Rule

Antigravity agents follow `AGENTS.md`.

- Run the security gate for deploy, release, dependency/security/auth/CI changes,
  or explicit security audit requests.
- Do not run the full security gate for every ordinary coding task.
- `FAILED` or `BLOCKED` gate status blocks deploy-ready claims.