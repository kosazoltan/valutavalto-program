-- V20: Kezelési díj tranzakciók részletes nyilvántartása
CREATE TABLE handling_fee_transaction (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id          BIGINT NOT NULL REFERENCES transaction(id),
    fee_type                VARCHAR(20) NOT NULL DEFAULT 'TIERED' CHECK (fee_type IN ('FIXED', 'PERCENT', 'TIERED')),
    amount                  NUMERIC(18,2) NOT NULL DEFAULT 0,
    discount_percent        INTEGER NOT NULL DEFAULT 0,
    discount_reason         VARCHAR(255),
    net_fee                 NUMERIC(18,2) NOT NULL DEFAULT 0,
    worker_commission_share NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at              TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_hf_transaction_tx ON handling_fee_transaction(transaction_id);
