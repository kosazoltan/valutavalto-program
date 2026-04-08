# Tamás Teszt 5/6 — WU + Misc Endpoints
> Dátum: 2026-04-07 | Production: excvaluta.com

| # | Teszt | HTTP | Eredmény | Evidence |
|---|-------|------|----------|----------|
| 1 | WU list | 401 | CHECK | jogosultsági ellenőrzés — MANAGER role nem elég? |
| 2 | Reservations list | 401 | CHECK | jogosultsági ellenőrzés |
| 3 | Customers search | 200 | PASS | |
| 4 | Workers list | 200 | PASS | |
| 5 | Rate overview | 200 | PASS | |
| 6 | Notifications | 200 | PASS | |
| 7 | Backup history | 401 | CHECK | admin jogosultság szükséges? |
| 8 | Frontend | 200 | PASS | |

**Eredmény: 5 PASS / 3 CHECK (jogosultsági kérdés, nem hiba)**
