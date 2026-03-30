-- V129: Transaction banknote (címletszintű részletezés) tábla
CREATE TABLE IF NOT EXISTS transaction_banknote (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    transaction_line_id BIGINT,
    currency_code VARCHAR(3) NOT NULL,
    face_value NUMERIC(15,2) NOT NULL,
    quantity INTEGER NOT NULL,
    direction VARCHAR(3) NOT NULL CHECK (direction IN ('IN', 'OUT')),
    total_value NUMERIC(15,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

ALTER TABLE transaction_banknote ADD CONSTRAINT fk_txbn_transaction
    FOREIGN KEY (transaction_id) REFERENCES transaction(id);

ALTER TABLE transaction_banknote ADD CONSTRAINT fk_txbn_transaction_line
    FOREIGN KEY (transaction_line_id) REFERENCES transaction_line(id);

CREATE INDEX IF NOT EXISTS idx_txbn_transaction ON transaction_banknote(transaction_id);
CREATE INDEX IF NOT EXISTS idx_txbn_currency ON transaction_banknote(currency_code);
