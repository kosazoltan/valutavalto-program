-- V42: Bizonylat szekvencia tábla (UTOLSOBLOKKOK) + kerekítési összeg mező
-- Legacy: Delphi UTOLSOBLOKKOK tábla — globálisan persist-ált bizonylat sorszámok

-- ============================================================
-- 1. RECEIPT_SEQUENCE tábla (UTOLSOBLOKKOK)
-- ============================================================
CREATE TABLE IF NOT EXISTS receipt_sequence (
    id              BIGSERIAL PRIMARY KEY,
    branch_id       UUID NOT NULL,
    last_sell_receipt               BIGINT NOT NULL DEFAULT 100000,
    last_buy_receipt                BIGINT NOT NULL DEFAULT 100000,
    last_transfer_out_receipt       BIGINT NOT NULL DEFAULT 100000,
    last_transfer_in_receipt        BIGINT NOT NULL DEFAULT 100000,
    last_forint_transfer_out_receipt BIGINT NOT NULL DEFAULT 100000,
    last_forint_transfer_in_receipt  BIGINT NOT NULL DEFAULT 100000,
    last_conversion_receipt          BIGINT NOT NULL DEFAULT 100000,

    CONSTRAINT fk_receipt_seq_branch FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT uq_receipt_seq_branch UNIQUE (branch_id)
);

CREATE INDEX IF NOT EXISTS idx_receipt_seq_branch ON receipt_sequence(branch_id);

-- Init: minden meglévő branch-hez létrehozunk egy szekvencia sort
INSERT INTO receipt_sequence (branch_id)
SELECT id FROM branch
WHERE id NOT IN (SELECT branch_id FROM receipt_sequence)
ON CONFLICT (branch_id) DO NOTHING;

-- ============================================================
-- 2. ROUNDING_AMOUNT mező a transaction táblán
-- ============================================================
-- A kerekítési különbözet tárolása (payableAmount - bruttó)
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS rounding_amount NUMERIC(15,2) DEFAULT 0;

COMMENT ON COLUMN transaction.rounding_amount IS 'Magyar 5 Ft-os kerekítési különbözet (payableAmount - bruttó). Pozitív = felkerekítés, negatív = lekerekítés.';
COMMENT ON TABLE receipt_sequence IS 'Bizonylat sorszám szekvencia (legacy: UTOLSOBLOKKOK). Típusonként tárolja az utolsó kiadott sorszámot.';
