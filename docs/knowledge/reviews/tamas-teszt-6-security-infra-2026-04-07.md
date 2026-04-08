# Tamás Teszt 6/6 — Security + Infra
> Dátum: 2026-04-07 | Production: excvaluta.com

| # | Teszt | HTTP | Eredmény | Evidence |
|---|-------|------|----------|----------|
| 1 | Actuator blocked | 403 | PASS | |
| 2 | Cloudflare proxy | 200 | PASS | cf-ray aktív |
| 3 | Swagger disabled | 401 | PASS | |
| 4 | HTTPS redirect | 301 | PASS | |
| 5 | SQL injection | 403 | PASS | |

**Eredmény: 5/5 PASS**
