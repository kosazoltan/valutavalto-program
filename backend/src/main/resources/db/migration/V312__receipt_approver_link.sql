-- V312: FR-BSZUR-05 ENGEDÉLYEZŐ — bizonylat <-> AML-jóváhagyás összekapcsolás
--
-- A transaction_aml_approval.receipt_number szándékosan NULL (a bizonylatszám az
-- AML-check pillanatában még nem ismert, GDPR/adatminimalizálás), így eddig NEM volt
-- kapcsolókulcs a bizonylat-böngésző "ENGEDÉLYEZŐ neve + beosztása" megjelenítéséhez
-- (EXCMD b5b FR-BSZUR-05). A kliens által generált approval_session_id már végigmegy
-- mindkét úton (AmlApprovalGrant + performAmlCheck) — mostantól PERZISZTÁLJUK:
--   transaction.approval_session_id  <->  transaction_aml_approval.approval_session_id
-- A jóváhagyó BEOSZTÁSA (szerepkör) pillanatkép-mezőt kap (a név-pillanatkép V292 mintájára) —
-- a Worker.role később változhat, az audit a jóváhagyáskori állapotot őrzi (Pmt., 8 év).

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS approval_session_id VARCHAR(64);
ALTER TABLE transaction_aml_approval ADD COLUMN IF NOT EXISTS approval_session_id VARCHAR(64);
ALTER TABLE transaction_aml_approval ADD COLUMN IF NOT EXISTS approved_by_role VARCHAR(50);

COMMENT ON COLUMN transaction.approval_session_id IS
    'AML jóváhagyás-session (kliens-generált, opaque) — a tranzakciót a transaction_aml_approval rekordhoz köti (FR-BSZUR-05)';
COMMENT ON COLUMN transaction_aml_approval.approval_session_id IS
    'AML jóváhagyás-session — a jóváhagyást a tranzakció(k)hoz köti (FR-BSZUR-05)';
COMMENT ON COLUMN transaction_aml_approval.approved_by_role IS
    'Az engedélyező BEOSZTÁSA (szerepkör) a jóváhagyás pillanatában — pillanatkép, a V292 név-snapshot mintájára';

-- A bizonylat-lista batch-lookupja: (company_id, approval_session_id) szerinti keresés
CREATE INDEX IF NOT EXISTS idx_aml_approval_company_session
    ON transaction_aml_approval (company_id, approval_session_id)
    WHERE approval_session_id IS NOT NULL;
