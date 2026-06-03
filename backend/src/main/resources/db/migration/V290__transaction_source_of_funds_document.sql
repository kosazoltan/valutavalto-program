-- V290: 50M Ft feletti pénzeszköz-forrás igazolás strukturált mezői (A3 — b4-foglalo FR-16, Pmt.)
--
-- A Pmt. szerint az 50M HUF-ot elérő/meghaladó ügyletnél a pénzeszközök forrását KIZÁRÓLAG közjegyző
-- vagy ügyvéd által ellenjegyzett "teljes bizonyító erejű magánokirattal" szabad igazolni (két tanús
-- magánnyilatkozat TILOS). Banki kifizetési bizonylat (szlip) esetén az nem lehet 3 évnél régebbi.
--
-- A meglévő szabad-szöveges `source_of_funds` mező mellé strukturált típus + dátum, hogy a szerver
-- AUTOMATIKUSAN validálhasson. A tényleges blokkolást az AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT feature-
-- flag vezérli (default false = nem blokkol — production-biztos, a G3/G11/A4 mintát követve).
--
-- Idempotens: ADD COLUMN IF NOT EXISTS.

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS source_of_funds_doc_type VARCHAR(50);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS source_of_funds_doc_date DATE;

COMMENT ON COLUMN transaction.source_of_funds_doc_type IS
  'A4/A3 Pmt. 50M: forrás-dokumentum típus — MAGANOKIRAT_KOZJEGYZO / MAGANOKIRAT_UGYVED / BANK_SZLIP (KET_TANU TILOS).';
COMMENT ON COLUMN transaction.source_of_funds_doc_date IS
  'A4/A3 Pmt. 50M: banki bizonylat (szlip) kiállítási dátuma — max. 3 év (1095 nap) lehet a tranzakcióhoz képest.';
