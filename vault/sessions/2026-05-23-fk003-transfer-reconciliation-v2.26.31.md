# Session: FK-003 + V4.0 audit — v2.26.31 (2026-05-23)

## Összefoglaló

Két PR mergelt ma ebben a sessionben:

### PR #813 — V4.0 audit backend biztonsági javítások
- **PP-01 (IDOR AmlService):** `findByIdAndCompanyId` + company-scoped lookup, ValidationException (nem 404 side-channel)
- **PP-02–PP-07, PP-10:** CORS, rate-limit, race-condition, jogosultság — lásd commit `e8c9c57d3`
- **Teszt:** `testSubmitReport_crossTenantOrMissingTransactionBlocked` — cross-tenant elutasítás

### PR #814 — FK-003 pénztárak közötti pénzmozgás egyeztetés (v2.26.31)

Kasza Helga (főértéktár) kérésére: a "Beérkezett adatok" menüpont (legacy branch-lista) teljes
felváltása pénztárak/értéktárak közötti Transfer-egyeztetési modullal.

**Backend:**
- `TransferReconciliationService` (214 sor) — company-scoped, JPQL JOIN FETCH lines, EGYEZIK/ELTÉRÉS logika, eltérés-értesítés multi-tenant safe (csak saját cég értesíthető)
- `TransferReconciliationController` — POST `/api/v1/central/transfer-reconciliation/run`, `@PreAuthorize("hasAnyRole('FOERTEKTAR', 'ADMIN')")`
- `TransferRepository.findForReconciliation` — DISTINCT + JOIN FETCH fromBranch/toBranch/currency/lines/line.currency, CANCELLED/REJECTED kizárva
- `NotificationService.notifyBranchOnce` — idempotens (existsByEntityTypeAndEntityIdAndNotificationType), fan-out per-worker
- 6 unit teszt: match, amountMismatch, missingReceiver, multiCurrencyLines, crossCompanyNotification, validation

**Frontend:**
- `ReceivedDataOverviewPage.tsx` — manuális "Ellenőrzés" gomb (nincs autorun), intervallum/keresés/szűrő, EGYEZIK/ELTÉRÉS badge, CSV export
- `transfer-reconciliation.ts` API wrapper
- `CentralWorkstationPage.tsx` — roles: `['foertektar']` (csak főértéktár látja)
- 3 UI teszt: nincs autorun, futtatás megjelenítés, eltérés filter

**Copilot review fixek (2 alkalmazva commit `ff009a332`-ben, 1 elfogadott):**
1. `previousDayIso()` → `localIsoDate()` (UTC off-by-one éjfél körül CET/CEST időzónában)
2. `SELECT DISTINCT + LEFT JOIN FETCH t.lines l + LEFT JOIN FETCH l.currency` (N+1 kiküszöbölve)
3. check-then-act idempotencia: elfogadott design tradeoff — UNIQUE constraint nem alkalmazható (fan-out per-worker több sort hoz létre ugyanazon kulcsra); manuális, single-user művelet

**Self-review subagent finding (alkalmazva):**
- `resolveAffectedVault` cross-tenant notification leak → `belongsToCompany()` guard hozzáadva + unit teszt

## Tanulságok

- DISTINCT + JOIN FETCH egyszerre egyetlen kollekcióra (lines) biztonságos Hibernate-ben (nincs MultipleBagFetchException ha csak 1 bag)
- Multi-tenant notification: nem a Transfer.toBranch, hanem a SAJÁT cég irodája kapja az értesítést — külön `belongsToCompany()` guard szükséges
- `localIsoDate()` util mindig helyi dátumot ad — kötelező UTC-érzékeny kontextusban (dátum picker default értékek)

## CI/Deploy állapot

- GitHub CI: minden check pass (Backend Build + Test, frontend Lint + TypeCheck, Playwright, CodeQL stb.)
- Sourcery: weekly rate limit (zaj)
- Codex: usage limit (zaj)  
- Copilot: 3 finding — mind kezelve
- Hetzner deploy: SUCCESS, bootstrap 200, 73 iroda OK
- Main HEAD: `89aaf5617`

## Verzió

v2.26.31 — server-served (frontend-react + backend), NEM kell installer-build (csak PR #813 + #814 server-réteg).
