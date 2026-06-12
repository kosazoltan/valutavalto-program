-- V325 (Batch3-C): JOGI SZEMELY ugyfel + TENYLEGES TULAJDONOSOK adatmodell —
-- a Batch2-D-ben dokumentalt defer feloldasa (user-keres, 2026-06-12).
--
-- LEGACY FORRAS (legacy-transfer/text/VALUTA/DLL/BLOKNYOM/MAKEDLL/Unit2.pas):
-- - JogiAdatokBeolvasasa (558-640): JOGISZEMELY tabla (JOGISZEMELYNEV,
--   TELEPHELYCIM, OKIRATSZAM, ADOSZAM, MEGBIZOTTSZAMA) + UJTULAJOK tabla
--   (TULAJNEV, LAKCIM, SZULHELY+SZULIDO, ALLAMPOLGAR, TARTHELY, ERDJELLEG,
--   ERDMERTEK, TULKOZSZEREP), MAX 4 tulajdonos (array[1..4]).
-- - Ugyfelnyomtatas (1331-1433): a 300k+ bizonylat jogi-szemely blokkja.
--
-- LEKEPEZES AZ UJ RENDSZERBEN: a pultnal allo szemely (megbizott/kepviselo)
-- adatait a MEGLEVO customer_* mezok hordozzak (nev, cim, PEP-statusz) — uj
-- "kepviselo" mezok NEM kellenek. Uj mezok: a jogi szemely torzsadatai a
-- transaction-on + a tenyleges tulajdonosok kulon altablaban (Pmt. 9.§,
-- 8 eves megorzes, lekerdezhetoseg).

-- 1) Jogi szemely mezok a transaction tablan
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS is_legal_entity_customer BOOLEAN;
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS legal_entity_name VARCHAR(255);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS legal_entity_seat VARCHAR(500);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS legal_entity_tax_number VARCHAR(50);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS legal_deed_number VARCHAR(100);

COMMENT ON COLUMN transaction.is_legal_entity_customer IS
    'V325: az ugyfel jogi szemely neveben jar el (legacy _ugyfeltipus=J). NULL = regi tranzakcio / termeszetes szemely.';
COMMENT ON COLUMN transaction.legal_entity_name IS 'V325: jogi szemely neve (legacy JOGISZEMELYNEV).';
COMMENT ON COLUMN transaction.legal_entity_seat IS 'V325: jogi szemely szekhelye (legacy TELEPHELYCIM).';
COMMENT ON COLUMN transaction.legal_entity_tax_number IS 'V325: jogi szemely adoszama (legacy ADOSZAM).';
COMMENT ON COLUMN transaction.legal_deed_number IS 'V325: okiratszam / cegjegyzekszam (legacy OKIRATSZAM).';

-- 2) Tenyleges tulajdonosok altabla (legacy UJTULAJOK, max 4 — a korlatot a
--    service ervenyesiti; company_id kotelezo a multi-tenant izolaciohoz §1)
CREATE TABLE IF NOT EXISTS transaction_beneficial_owner (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    transaction_id BIGINT NOT NULL REFERENCES transaction(id) ON DELETE CASCADE,
    owner_no INT NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    owner_address VARCHAR(500),
    owner_birth_place VARCHAR(255),
    owner_birth_date VARCHAR(20),
    owner_nationality VARCHAR(100),
    -- legacy TARTHELY: kulfoldi tartozkodasi hely (csak ha van)
    owner_residence_abroad VARCHAR(255),
    -- legacy ERDJELLEG: az erdekeltseg/tulajdonosi jogviszony jellege
    owner_interest_nature VARCHAR(255),
    -- legacy ERDMERTEK: a reszesedes merteke (szovegesen, pl. "50%")
    owner_interest_extent VARCHAR(100),
    owner_is_pep BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tbo_tx_owner_no UNIQUE (transaction_id, owner_no)
);

-- Megj.: kulon index nem szukseges — a uq_tbo_tx_owner_no UNIQUE constraint
-- (transaction_id, owner_no) indexe a transaction_id szerinti lookupot fedi
-- (leftmost prefix); a tabla tranzakcionkent max 4 sort tartalmaz.

COMMENT ON TABLE transaction_beneficial_owner IS
    'V325: tenyleges tulajdonosok (Pmt. 9.§) jogi szemely ugyfelnel — legacy UJTULAJOK tukre, max 4/tranzakcio (service-szinten ervenyesitve).';
