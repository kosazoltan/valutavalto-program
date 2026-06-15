-- V330: FK-030 — a VAULT_COUNTERPARTY (virtualis partner) branch-ek region mezoje NULL-ra.
--
-- A V277 (FK-013) a 10 virtualis partner-branch-et (PRB, UPT, TRB, ERB, FRB, RB, JRB, MNB,
-- TH, FOP1) region='ORSZAGOS'-szal seedelte, holott a dokumentalt szandek "nem teruleti"
-- (a region_code mar most is NULL). Emiatt az Atlag arfolyam riportban (FK-027) egy nem
-- szandekos, mindig ures "ORSZAGOS" oszlop jelent meg a 8 teruleti es az osszesito oszlop koze.
--
-- Ez a migracio a region mezot NULL-ra allitja, osszhangba a region_code-dal. NEM destruktiv
-- (UPDATE, nem DELETE); a branch_type_did / is_vault / code / name valtozatlan. Az ertektari
-- atadas-atvetel menu (FK-013) a branch_type.code alapjan szur, NEM a region alapjan -> erintetlen.
-- Idempotens: csak a meg 'ORSZAGOS'-on allo sorokat erinti.
DO $$
DECLARE
    updated_count INT;
BEGIN
    UPDATE branch
       SET region = NULL
     WHERE branch_type_did = (
            SELECT id FROM dictionary
             WHERE category = 'BRANCH_TYPE' AND code = 'VAULT_COUNTERPARTY'
         )
       AND region = 'ORSZAGOS';
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'V330: % VAULT_COUNTERPARTY branch region NULL-ra allitva (ures ORSZAGOS oszlop megszuntetese)', updated_count;
END $$;
