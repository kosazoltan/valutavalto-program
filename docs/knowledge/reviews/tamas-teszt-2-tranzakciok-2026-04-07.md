# Tamás Teszt 2/6 — Tranzakciók
> Dátum: 2026-04-07 | Production: excvaluta.com

| # | Teszt | HTTP | Eredmény | Evidence |
|---|-------|------|----------|----------|
| 1 | BUY EUR 10 | 201 | PASS | V125100034 |
| 2 | SELL EUR 5 | 201 | PASS | E125100021 |
| 3 | BUY USD 20 | 201 | PASS | V125100035 |
| 4 | BUY amount=0 | 400 | PASS | elutasítva |
| 5 | BUY amount=-1 | 400 | PASS | elutasítva |
| 6 | BUY invalid currency | 404 | PASS | elutasítva |
| 7 | BUY no auth | 401 | PASS | |
| 8 | Daily turnover | 200 | PASS | 23270 buy + 4140 sell |
| 9 | Turnover date=04-06 | 200 | PASS | tegnapi adat OK |
| 10 | Invalid date | 400 | PASS | fix verifikálva |

**Eredmény: 10/10 PASS**
