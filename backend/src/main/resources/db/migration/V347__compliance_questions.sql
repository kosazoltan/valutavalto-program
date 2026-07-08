-- FS-10 S1: compliance-kérdések (center definíció → pénztár sync → válasz vissza), cégenként.
-- Új táblák (nincs ALTER → PROD-502 tanulság). FK szándékosan NINCS
-- (V39/V77 típus-drift tanulság; V346 precedens): UNIQUE + index véd.
CREATE TABLE IF NOT EXISTS compliance_question (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_worker_code VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_cq_company_active
    ON compliance_question (company_id, is_active);

CREATE TABLE IF NOT EXISTS customer_question_answer (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    question_id UUID NOT NULL,
    customer_id BIGINT NOT NULL,
    transaction_id BIGINT,
    answer_text TEXT NOT NULL,
    answered_by_worker_code VARCHAR(50),
    answered_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- transaction_id NULLABLE → sima UNIQUE nem véd NULL-nál (Postgres: NULL ≠ NULL),
-- ezért KÉT parciális unique index:
CREATE UNIQUE INDEX IF NOT EXISTS ux_cqa_company_question_customer_tx
    ON customer_question_answer (company_id, question_id, customer_id, transaction_id)
    WHERE transaction_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_cqa_company_question_customer_notx
    ON customer_question_answer (company_id, question_id, customer_id)
    WHERE transaction_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_cqa_company_customer
    ON customer_question_answer (company_id, customer_id);
CREATE INDEX IF NOT EXISTS idx_cqa_company_question
    ON customer_question_answer (company_id, question_id);
