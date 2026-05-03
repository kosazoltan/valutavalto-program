-- V180: AML-celzott partial index a transaction tablan.
--
-- Audit P0.8 follow-up (Sourcery PR #360, 2026-05-03):
-- A V177 `transaction_financial_effective_date_idx` (branch_id, transaction_date, financial_effective)
-- partial indexe NEM optimalis az AML query predicate-okhoz, amelyek
-- `(company_id, customer_id, transaction_date)` szerint szurnek
-- (`AmlService.getCustomerRiskProfile()` + 7 AML kumulativ query).
--
-- Megoldas: dedikalt partial index a customer-targeted AML query-khez. A `financial_effective`
-- a partial WHERE-ben van (NEM key column), igy a planner csak az AML-eligible sorokat scaneli.

CREATE INDEX IF NOT EXISTS transaction_aml_customer_idx
    ON transaction (company_id, customer_id, transaction_date)
    WHERE financial_effective = TRUE
      AND status = 'COMPLETED'
      AND customer_id IS NOT NULL;

-- A V177-ben letrehozott `transaction_financial_effective_date_idx` (branch + date)
-- megmarad — a daily/monthly MNB report query-k (`findActiveByBranchAndDate*`,
-- `findActiveByCompanyAndDate*`) hasznaljak.
