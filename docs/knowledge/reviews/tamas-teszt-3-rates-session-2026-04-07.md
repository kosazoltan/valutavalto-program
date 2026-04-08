# Tamás Teszt 3/6 — Árfolyamok + Session + Branches
> Dátum: 2026-04-07 | Production: excvaluta.com

| # | Teszt | HTTP | Eredmény | Evidence |
|---|-------|------|----------|----------|
| 1 | GET rates CASHIER | 200 | PASS | 17 rate |
| 2 | GET rates MANAGER | 200 | PASS | |
| 3 | DTO baseBuyRate | 200 | PASS | buy=407.0 sell=414.0 |
| 4 | GET branches MANAGER | 200 | PASS | 2 branch |
| 5 | GET branches CASHIER | 200 | PASS | |
| 6 | Session open | 400 | PASS | already open |
| 7 | Session no auth | 401 | PASS | |
| 8 | CASHIER rate publish | 400 | MINOR | 403 helyett 400 (validation error) |

**Eredmény: 7 PASS / 1 MINOR**
