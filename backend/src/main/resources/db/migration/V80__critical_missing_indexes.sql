-- V79: Kritikus hiányzó indexek — AML query-k, notification, tranzakció szűrések
-- Code quality audit: 2026-03-15

-- =============================================
-- 1. TRANSACTION — AML QUERY-K (customer_id szűrés)
-- =============================================

-- AML göngyölési query-k: sumCustomerAnnualTotal, sumCustomerDailyTotal,
-- sumCustomerWeeklyTotal, countCustomerQuarterlyTransactions, findCustomerDailyTransactions, stb.
-- Mind a (company_id, customer_id, transaction_date) hármason szűrnek.
CREATE INDEX IF NOT EXISTS idx_transaction_company_customer_date
    ON transaction(company_id, customer_id, transaction_date);

-- =============================================
-- 2. TRANSACTION — company + date összetett index
-- =============================================

-- findReportableTransactions, findActiveByCompanyAndDate, findActiveByCompanyAndMonth
-- Mind (company_id, transaction_date)-on szűrnek.
CREATE INDEX IF NOT EXISTS idx_transaction_company_date
    ON transaction(company_id, transaction_date);

-- =============================================
-- 3. TRANSACTION — branch + date + status összetett index
-- =============================================

-- sumDailyTurnover, findActiveByBranchAndDate, countByBranchIdAndTransactionDateAndTransactionType,
-- sumDailyHandlingFees, countUnreportedTransactions — branch + date + status szűrés
CREATE INDEX IF NOT EXISTS idx_transaction_branch_date_status
    ON transaction(branch_id, transaction_date, status);

-- =============================================
-- 4. NOTIFICATION — user_id + is_read index
-- =============================================

-- findByUserIdAndIsReadFalseOrderByCreatedAtDesc, markAllAsRead
-- Nincs egyetlen index sem a notification táblán.
CREATE INDEX IF NOT EXISTS idx_notification_user_read
    ON notification(user_id, is_read);

CREATE INDEX IF NOT EXISTS idx_notification_user_created
    ON notification(user_id, created_at DESC);
