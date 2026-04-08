# Tamás Teszt 4/6 — Idempotency + SELL + Performance
> Dátum: 2026-04-07 | Production: excvaluta.com

| # | Teszt | HTTP | Eredmény | Evidence |
|---|-------|------|----------|----------|
| 1 | Idempotency same key | 201/201 | PASS | same receipt V125100036 |
| 2 | No Idempotency-Key | 400 | PASS | enforced |
| 3 | SELL USD 10 | 201 | PASS | E125100022 |
| 4 | SELL no auth | 401 | PASS | |
| 5 | Login perf | 200 | PASS | 164ms |
| 6 | Rates perf | 200 | PASS | 82ms |
| 7 | Health 5x avg | 200 | PASS | avg 225ms |

**Eredmény: 7/7 PASS**
