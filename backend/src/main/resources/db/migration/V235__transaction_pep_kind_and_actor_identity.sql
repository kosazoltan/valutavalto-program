-- V235: Pmt. PEP minoseg enum + actor (kepviselt fel) teljes azonositasa
--
-- HIBA #15 (2026-05-19 user-jelentes): Teljes azonositasnal ha az ugyfel
-- "kiemelt kozszereplo", a program nem ad fel valaszsi lehetoseget hogy
-- MILYEN minosegben az (csaladtag/kozeli munkatars/kormanyfo/parlamenti/
-- NAV vezeto/egyeb), es a bizonylatra azt nyomtatja, hogy "nem kiemelt
-- kozszereplo az ugyfel". A V229 csak booleant tarol, ezert most enum-mezo
-- + 7 actor azonositasi mezo jon hozza.
--
-- HIBA #17 (2026-05-19 user-jelentes): Teljes azonositas eseten ha az ugyfel
-- mas neveben vegzi a tranzakciot csak a masik ugyfel nevet keri be, kerjen
-- be arra is teljes azonositast. A V229-ben csak customer_actor_name volt,
-- most a teljes ID-set (szul.hely/ido, anyja neve, allampolg., okm.tipus,
-- okm.szam, lakcim).

ALTER TABLE transaction
    -- HIBA #15: PEP minoseg
    ADD COLUMN IF NOT EXISTS customer_pep_kind            VARCHAR(50),
    -- HIBA #17: actor (kepviselt fel) teljes azonositasa
    ADD COLUMN IF NOT EXISTS customer_actor_birth_place   VARCHAR(255),
    ADD COLUMN IF NOT EXISTS customer_actor_birth_date    DATE,
    ADD COLUMN IF NOT EXISTS customer_actor_mother_name   VARCHAR(255),
    ADD COLUMN IF NOT EXISTS customer_actor_nationality   VARCHAR(100),
    ADD COLUMN IF NOT EXISTS customer_actor_document_type VARCHAR(50),
    ADD COLUMN IF NOT EXISTS customer_actor_document_number VARCHAR(100),
    ADD COLUMN IF NOT EXISTS customer_actor_address       VARCHAR(500);

-- CHECK constraint a PEP minosegre — csak az ervenyes enum erteket fogadjuk el
-- (NULL megengedett, ha az ugyfel nem PEP vagy <300k tranzakcio)
ALTER TABLE transaction
    DROP CONSTRAINT IF EXISTS transaction_customer_pep_kind_check;
ALTER TABLE transaction
    ADD CONSTRAINT transaction_customer_pep_kind_check
    CHECK (customer_pep_kind IS NULL OR customer_pep_kind IN (
        'CSALADTAG',
        'KOZELI_MUNKATARS',
        'KORMANYFO',
        'PARLAMENTI',
        'NAV_VEZETO',
        'EGYEB'
    ));

COMMENT ON COLUMN transaction.customer_pep_kind IS
    'V235: HIBA #15 - PEP minoseg ha customer_is_pep=TRUE. NULL = nem PEP vagy <300k.';
COMMENT ON COLUMN transaction.customer_actor_birth_place IS
    'V235: HIBA #17 - actor (kepviselt fel) szul.helye, ha on_own_behalf=FALSE.';
COMMENT ON COLUMN transaction.customer_actor_birth_date IS
    'V235: HIBA #17 - actor szul.ideje, ha on_own_behalf=FALSE.';
COMMENT ON COLUMN transaction.customer_actor_mother_name IS
    'V235: HIBA #17 - actor anyja neve, ha on_own_behalf=FALSE.';
COMMENT ON COLUMN transaction.customer_actor_nationality IS
    'V235: HIBA #17 - actor allampolgarsaga, ha on_own_behalf=FALSE.';
COMMENT ON COLUMN transaction.customer_actor_document_type IS
    'V235: HIBA #17 - actor okmany tipusa, ha on_own_behalf=FALSE.';
COMMENT ON COLUMN transaction.customer_actor_document_number IS
    'V235: HIBA #17 - actor okmanyszama, ha on_own_behalf=FALSE.';
COMMENT ON COLUMN transaction.customer_actor_address IS
    'V235: HIBA #17 - actor lakcime, ha on_own_behalf=FALSE.';
