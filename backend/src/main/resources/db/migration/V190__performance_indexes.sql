-- F6 + F7 + F8 missing performance indexes (backend audit 2026-05-06)
--
-- Production scale (50k+ tx, 60+ branch, 200+ worker) hot query optimalizáció.
-- Az audit findingek konkrét file:line forrásai:
-- - F6: ReceiptSearchService.java:130-132 (LIKE %s% receipt_number search)
-- - F7: ReceiptSearchService.java:136-139 (transaction_date range query)
-- - F8: BranchService.findByCompanyIdAndIsActive*True (scattered uses)

-- F6 — pg_trgm GIN index a receipt_number LIKE '%X%' search-höz
-- A jelenlegi search full table scan lenne 100k+ tranzakcióra.
-- A pg_trgm extension GIN-jel a `LIKE '%substring%'` lekérdezést index-meg
-- használhatóvá teszi.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_tx_receipt_number_trgm
    ON transaction USING gin (lower(receipt_number) gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_tx_customer_name_trgm
    ON transaction USING gin (lower(customer_name) gin_trgm_ops);

-- F7 — composite index a (company_id, transaction_date) szűrőhöz
-- A ReceiptSearchService minden query-t company_id = ? AND transaction_date BETWEEN ?
-- mintával végez. A composite index pontosan ezt a szűrőt fedi le.
-- A V180 (transaction_aml_customer_idx) más oszlopokra szól (AML).
CREATE INDEX IF NOT EXISTS idx_tx_company_date
    ON transaction (company_id, transaction_date DESC, transaction_time DESC);

-- F8 — composite a branch leggyakoribb filter-ére (company + active + vault)
-- A BranchService.findByCompanyIdAndIsActiveTrue és findByCompanyIdAndIsVaultTrue
-- külön-külön index-merge-elne; egy covering composite hatékonyabb.
CREATE INDEX IF NOT EXISTS idx_branch_company_active_vault
    ON branch (company_id, is_active, is_vault);

-- Bonus: SupervisorPinAttempt cleanup index — a régi rekordok periodikus
-- törléséhez (lockout window 5 perc, tartós tárolás 30 nap).
--
-- KRITIKUS POSTGRES SZABÁLY: partial index WHERE predicate-ben tilos NOW(),
-- CURRENT_DATE stb. mutable függvényt használni — ezért NEM partial index,
-- hanem teljes index. A periodikus cleanup query a (attempt_at) order-en
-- futhat hatékonyan így is.
CREATE INDEX IF NOT EXISTS idx_supervisor_pin_attempt_cleanup
    ON supervisor_pin_attempt (attempt_at);

COMMENT ON INDEX idx_tx_receipt_number_trgm IS
    'V190 (2026-05-06): pg_trgm GIN index a ReceiptSearchService LIKE search-höz. '
    'F6 finding a backend audit-ból. 100k+ tx esetén kritikus.';

COMMENT ON INDEX idx_tx_company_date IS
    'V190 (2026-05-06): composite index multi-tenant cég-szűrt date range query-hez. '
    'F7 finding a backend audit-ból.';

COMMENT ON INDEX idx_branch_company_active_vault IS
    'V190 (2026-05-06): composite index a BranchService szűrt query-hez. '
    'F8 finding a backend audit-ból.';
