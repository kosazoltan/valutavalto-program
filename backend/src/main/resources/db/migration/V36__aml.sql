-- V36: AML (Pénzmosás elleni) modul
-- 2017. évi LIII. tv. szerinti kötelezettségek

-- AML bejelentés tábla
CREATE TABLE IF NOT EXISTS aml_report (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id),
    customer_id VARCHAR(50),
    transaction_id BIGINT REFERENCES transaction(id),
    report_type VARCHAR(30) NOT NULL,
    risk_level VARCHAR(20) NOT NULL DEFAULT 'LOW',
    amount_huf NUMERIC(18, 2) NOT NULL DEFAULT 0,
    currency_code VARCHAR(3),
    original_amount NUMERIC(18, 2),
    customer_name VARCHAR(200),
    document_type VARCHAR(30),
    document_number VARCHAR(50),
    worker_notes TEXT,
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    submitted_at TIMESTAMP,
    acknowledged_at TIMESTAMP,
    external_reference VARCHAR(100),
    created_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX idx_aml_report_company ON aml_report(company_id);
CREATE INDEX idx_aml_report_status ON aml_report(status);
CREATE INDEX idx_aml_report_customer ON aml_report(customer_id);
CREATE INDEX idx_aml_report_type ON aml_report(report_type);
CREATE INDEX idx_aml_report_created ON aml_report(created_at);

-- AML küszöbértékek tábla
CREATE TABLE IF NOT EXISTS aml_threshold (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    threshold_type VARCHAR(30) NOT NULL UNIQUE,
    amount_huf NUMERIC(18, 2) NOT NULL,
    description VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Seed küszöbértékek (magyar jogszabály)
INSERT INTO aml_threshold (threshold_type, amount_huf, description, is_active)
VALUES
    ('IDENTIFICATION', 300000, 'Ügyfél-azonosítási kötelezettség határa (2017. évi LIII. tv.)', TRUE),
    ('ENHANCED', 4500000, 'Fokozott átvilágítási kötelezettség határa', TRUE),
    ('REPORTING', 2000000, 'Bejelentési kötelezettség határa (MNB felé)', TRUE),
    ('SUSPICIOUS', 0, 'Gyanús tranzakció — összeghatártól független, mintázat alapú', TRUE)
ON CONFLICT (threshold_type) DO NOTHING;
