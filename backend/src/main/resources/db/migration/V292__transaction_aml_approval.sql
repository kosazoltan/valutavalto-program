-- V292: AML felsővezetői jóváhagyás audit-tábla (Pmt. 14/A. § (4), 14/2025. MNB rendelet V.2.6).
--
-- A magas kockázatú esetekben (FATF 1/a, magas-kockázatú harmadik ország ≥5M Ft, PEP, éves limit)
-- a tranzakció kizárólag a kijelölt felelős vezető írásos jóváhagyásával teljesíthető. A szabályzat
-- szerint az engedélyező NEVÉT rögzíteni kell, és a dokumentációt 8 évig megőrizni. A rekord
-- insert-only (immutable audit) — nincs UPDATE/DELETE útvonal a kódban.
--
-- Idempotens: CREATE TABLE IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS transaction_aml_approval (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id             UUID NOT NULL,
    branch_id              UUID,
    receipt_number         VARCHAR(50),
    huf_amount             NUMERIC(18, 2),
    customer_name          VARCHAR(255),
    approval_reason        VARCHAR(500) NOT NULL,
    approved_by_worker_id  BIGINT NOT NULL,
    approved_by_name       VARCHAR(255) NOT NULL,
    approved_at            TIMESTAMP NOT NULL,
    created_at             TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_aml_approval_company   ON transaction_aml_approval (company_id);
CREATE INDEX IF NOT EXISTS idx_aml_approval_branch    ON transaction_aml_approval (branch_id);
CREATE INDEX IF NOT EXISTS idx_aml_approval_approved_at ON transaction_aml_approval (approved_at);

COMMENT ON TABLE transaction_aml_approval IS
  'Pmt. 14/A. § (4) / MNB 14/2025 V.2.6: AML felsővezetői jóváhagyás immutable audit-rekord — az '
  'engedélyező nevével (pillanatkép), 8 éves megőrzés. Insert-only.';
