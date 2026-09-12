# KAN-15 — DEPLOY.md titokmentesítése

A Neon-deploy példa **nem** tartalmaz jelszót. A `DATABASE_PASSWORD` és a
`DATABASE_HOST` a gazda `.env` / processz-környezetéből jön; hiányuknál a
példa fail-closed.

Őr: `node scripts/assert-no-plaintext-secrets.cjs` (a security pipeline
gitleaks jobja után).

A git-történet literáljai a Neon-jelszó egyeztetett cseréjéig élnek — a
HEAD tiszta.
