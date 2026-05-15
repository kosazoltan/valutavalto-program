-- V229: Transaction customer snapshot fields (Pmt. azonosítási adatok)
--
-- HIBA #5 + #7 + #8 (2026-05-15 user-jelentés): A 100-300k és 300k+ tranzakciók
-- bizonylatán hiányzott a Pmt. törvény szerinti azonosítási adatok:
-- - 100-300k SIMPLIFIED: nev + szuletes hely + szuletes ido + allampolgarsag
-- - 300k+ FULL: + okmány típus + anyja neve + lakcím + PEP + saját nevében jár-e
--
-- A jelenlegi Transaction entity TARTALMAZ: customerName, customerAddress,
-- customerDocumentNumber, customerNationality, sourceOfFunds, customerIsPep.
-- HIANYZIK: customerBirthPlace, customerBirthDate, customerMotherName,
-- customerDocumentType, customerOnOwnBehalf, customerActorName.
--
-- A snapshot azert tortenik tranzakcio-szinten (NEM a customer entitybol JOIN-nal),
-- mert az ugyfel mestere kesobb modosulhat (pl. cimkartya csere), es a regi
-- bizonylaton meg kell maradni az AKKORI allapotnak (NAV audit, Pmt. compliance).

ALTER TABLE transaction
    ADD COLUMN IF NOT EXISTS customer_birth_place      VARCHAR(255),
    ADD COLUMN IF NOT EXISTS customer_birth_date       DATE,
    ADD COLUMN IF NOT EXISTS customer_mother_name      VARCHAR(255),
    ADD COLUMN IF NOT EXISTS customer_document_type    VARCHAR(50),
    -- 300k+ Pmt. JOGCIM nyilatkozat: sajat-nevben vagy mas nevben?
    -- NULL = nem keruelt megkerdezesre (regebbi tranzakciok, vagy <300k)
    -- TRUE  = sajat nevben jar el
    -- FALSE = mas nevben jar el (akkor customer_actor_name-ben a kepviselt fel neve)
    ADD COLUMN IF NOT EXISTS customer_on_own_behalf    BOOLEAN,
    ADD COLUMN IF NOT EXISTS customer_actor_name       VARCHAR(255);

COMMENT ON COLUMN transaction.customer_birth_place IS
    'V229: Snapshot a Pmt. azonositashoz - 100k+ tranzakcional kotelezo';
COMMENT ON COLUMN transaction.customer_birth_date IS
    'V229: Snapshot a Pmt. azonositashoz - 100k+ tranzakcional kotelezo';
COMMENT ON COLUMN transaction.customer_mother_name IS
    'V229: Snapshot a Pmt. azonositashoz - 300k+ tranzakcional kotelezo';
COMMENT ON COLUMN transaction.customer_document_type IS
    'V229: ID_CARD/PASSPORT/etc snapshot a bizonylathoz';
COMMENT ON COLUMN transaction.customer_on_own_behalf IS
    'V229: 300k+ JOGCIM nyilatkozat - TRUE=sajat, FALSE=mas nevben (akkor actor_name)';
COMMENT ON COLUMN transaction.customer_actor_name IS
    'V229: Ha customer_on_own_behalf=FALSE, itt a kepviselt fel neve';
