# Handoff — FKH-070 HANDLING_FEE Expected source (2026-09-13)

Status: **MERGED** as PR #1756 → main `10a8122f` (2026-09-13). Pipeline PASS from HEAD `6756fe69` on `pipeline/20260913-fkh070-handling-fee-expected`, base `0df543d7` / v2.28.113.

## What landed

HANDLING_FEE self-check Expected = live `SUM(Transaction.handlingFee)` for company+branch+date, COMPLETED + financialEffective + buy∪sell, then `HungarianRounding.roundToFive`. KK `ShipmentHandlingFee` no longer feeds this arm. No Flyway, no frontend, no installer.

Call path: `GET .../self-check?category=HANDLING_FEE` → `DenominationBalanceController:125-135` → `DenominationBalanceService:385-394` → `TransactionRepository.sumHandlingFeeForBranchAndDate:307-319`.

## Evidence

- Smoke: 89 tests, 0 fail (session).
- Post-ruling RETEST: 7 pinning tests, 0 fail, BUILD SUCCESS.
- Judge: `.hermes/pipeline/20260913-fkh070-handling-fee-expected/round-1/40-ruling.md` PASS.
- ACCEPTED-RISKS: vacuous shipment mock verify; Postgres hardcoded type list.

## Next

Merged. Backend-only → no installer needed for this change.
