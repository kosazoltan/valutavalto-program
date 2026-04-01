-- V132: ÁFA visszatérítés tranzakció tábla (Metro/ÁFA modul)
-- Legacy: WAFATABLAK (Delphi 7 Firebird)

CREATE TABLE vat_refund_transaction (
    id              BIGSERIAL PRIMARY KEY,
    company_id      UUID NOT NULL,
    branch_id       UUID NOT NULL REFERENCES branch(id),
    voucher_type    VARCHAR(2) NOT NULL CHECK (voucher_type IN ('AK', 'AB', 'AV')),
    serial_number   VARCHAR(30) NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_time TIME,
    main_unit       INTEGER,
    supply_amount   NUMERIC(18,2),
    gross_amount    NUMERIC(18,2) NOT NULL,
    vat_amount      NUMERIC(18,2) NOT NULL,
    vat_percentage  NUMERIC(5,2),
    customer_name   VARCHAR(200),
    customer_address VARCHAR(500),
    customer_identifier VARCHAR(50),
    bank_account_number VARCHAR(50),
    company_name    VARCHAR(200),
    site_address    VARCHAR(500),
    deed_number     VARCHAR(50),
    is_reversed     BOOLEAN NOT NULL DEFAULT FALSE,
    original_transaction_id BIGINT REFERENCES vat_refund_transaction(id),
    created_by_worker VARCHAR(50),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vat_refund_branch ON vat_refund_transaction(branch_id);
CREATE INDEX idx_vat_refund_date ON vat_refund_transaction(transaction_date);
CREATE INDEX idx_vat_refund_type ON vat_refund_transaction(voucher_type);
CREATE INDEX idx_vat_refund_company ON vat_refund_transaction(company_id);

COMMENT ON TABLE vat_refund_transaction IS 'ÁFA visszatérítés tranzakciók (Metro/Tesco külföldi ügyfél, céges, Innova Invest)';
COMMENT ON COLUMN vat_refund_transaction.voucher_type IS 'AK=külföldi ügyfél, AB=céges, AV=Innova Invest';
COMMENT ON COLUMN vat_refund_transaction.main_unit IS 'Fő egység: 3=Innova, 4=pénztár, 6=ügyfél';
