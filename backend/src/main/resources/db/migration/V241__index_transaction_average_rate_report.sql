-- V241: Composite partial index a v2.5.66 AverageRateReportService gyors lekérdezéséhez.
--
-- Sprint A P2.5 (legacy ATLAGARF parity) — a riport GROUP BY currency_id +
-- WHERE company_id = ? AND transaction_date BETWEEN ? AND ? AND status = 'COMPLETED'.
--
-- Production volumetria: Pmt. 8-év megőrzés → potenciálisan milliós sorszám per cég.
-- Partial index csak a status='COMPLETED' tranzakciókra (sztornózottak kihagyva → ~95%
-- méretcsökkentés egy heavy-use index esetén).
--
-- Index NEM dropolja a meglévő idx_transaction_company / idx_transaction_date / idx_transaction_branch
-- indexeket — azok más query-khez kellenek.

-- Copilot P2 #703: financial_effective = TRUE is bele kell, mert a riport
-- query kizárja a parent CONVERSION sorokat (financial_effective=false). Az
-- index predicate-jébe is — V177/V180 minta a meglévő riport-indexeknél.

CREATE INDEX IF NOT EXISTS idx_tx_company_date_status_currency
    ON transaction (company_id, transaction_date, currency_id)
    WHERE status = 'COMPLETED' AND financial_effective = TRUE;

COMMENT ON INDEX idx_tx_company_date_status_currency IS
    'V241 (2026-05-19): AverageRateReportService súlyozott átlagárfolyam riport-támogatás. '
    'Partial index csak COMPLETED + financial_effective=TRUE tranzakciókra '
    '(sztornózott és parent CONVERSION kihagyva). '
    'Sprint A P2.5 legacy ATLAGARF parity.';
