# Tamás Teszt 1/6 — Auth + Security
> Dátum: 2026-04-07 | Production: excvaluta.com

| # | Teszt | HTTP | Eredmény | Evidence |
|---|-------|------|----------|----------|
| 1 | Login MANAGER | 200 | PASS | token OK |
| 2 | Login CASHIER | 200 | PASS | token OK |
| 3 | Rossz jelszó | 401 | PASS | UNAUTHORIZED |
| 4 | Rossz companyCode | 401 | PASS | security fix OK |
| 5 | Üres body | 500 | FAIL | 500 helyett 400 kéne |
| 6 | Rates no auth | 401 | PASS | |
| 7 | Invalid Bearer | 401 | PASS | |
| 8 | License VALID | 200 | PASS | 633 nap hátra |

**Eredmény: 7 PASS / 1 FAIL**
FINDING: üres body login → 500 (kéne 400)
