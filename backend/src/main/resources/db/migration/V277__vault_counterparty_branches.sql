-- V277 (Bali Henriett FK-013 / Kasza Helga 2026-05-28): egységes értéktári átadás-átvétel
-- menü támogatása. A 10 fix banki és speciális partner (PRB/UPT/TRB/ERB/FRB/RB/JRB/MNB/TH/FOP1)
-- speciális Branch entry-ként kerül a branch táblába, hogy a meglévő shipment_request flow
-- változás nélkül kezelje őket (from_branch_id / to_branch_id UUID FK-val).
--
-- Modellezés:
--   1. Új BRANCH_TYPE/VAULT_COUNTERPARTY dictionary entry — különbözteti meg a partnereket
--      a sima pénztár (PENZTAR) és értéktár (ERTEKTAR) branch-ektől.
--   2. 10 partner seed cégenként (EBC), region_code=NULL (nem területi — minden értéktár
--      közösen használja), is_vault=false (nem értéktár), is_active=true.
--   3. Idempotens: ON CONFLICT (code) DO NOTHING — a `branch.code` GLOBÁLISAN UNIQUE
--      (uk_branch_code constraint, V0_1__base_tables.sql). Ha valamely partner-kód már
--      foglalt egy másik (kis valószínűségű) cégben, az EBC seed silently skip — a DO $$
--      block RAISE WARNING-ot ad az audit-trail-ben, hogy észleljük.
--
-- A frontend a /api/v1/branches/vault-counterparties endpoint-ot hívja, ami 3 csoportot ad:
--   - territorialCashiers (saját régió pénztárai)
--   - peerVaults (másik 7 értéktár)
--   - fixedCounterparties (ez a 10 partner)
--
-- Acceptance: Bali Henriett (értéktáros, Szeged) felveheti pl. a PRB-t a Cél iroda mezőbe,
-- és a shipment_request.to_branch_id = az új PRB-branch UUID-je lesz.

-- ===========================================================================
-- 1. Új BRANCH_TYPE dictionary entry: VAULT_COUNTERPARTY
-- ===========================================================================
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_TYPE', 'VAULT_COUNTERPARTY',
        'Vault counterparty (bank / special partner)',
        'Banki és speciális partner (értéktári átadás-átvétel)',
        100, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- ===========================================================================
-- 2. 10 fix partner Branch entry seed-elése EBC cégbe
-- ===========================================================================
DO $$
DECLARE
    ebc_company_id   UUID;
    vault_cp_type_id UUID;
    country_hu_id    UUID;
    branch_status_id UUID;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V277: EBC cég nem található — seed kihagyva';
        RETURN;
    END IF;

    SELECT id INTO vault_cp_type_id
    FROM dictionary WHERE category = 'BRANCH_TYPE' AND code = 'VAULT_COUNTERPARTY' LIMIT 1;
    SELECT id INTO country_hu_id
    FROM dictionary WHERE category = 'COUNTRY' AND code = 'HU' LIMIT 1;
    SELECT id INTO branch_status_id
    FROM dictionary WHERE category = 'BRANCH_STATUS' AND code = 'ACTIVE' LIMIT 1;

    IF vault_cp_type_id IS NULL OR country_hu_id IS NULL OR branch_status_id IS NULL THEN
        RAISE NOTICE 'V277: hiányzó dictionary master-data — seed kihagyva';
        RETURN;
    END IF;

    -- Egy beemelt anonim helper a 10 partner insert-jéhez. Idempotens.
    INSERT INTO branch (
        id, company_id, code, bank_code, branch_type_did, name, address, city, zip_code,
        country_did, branch_status_did, opening_date, is_active, is_vault,
        region, region_code, created_at
    ) VALUES
        (gen_random_uuid(), ebc_company_id, 'PRB',  'PRB',  vault_cp_type_id,
         'POS Raiffeisen Bank',              'POS (bankkártyás) pénzek átvétele',          'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'UPT',  'UPT',  vault_cp_type_id,
         'Úton lévő pénztár',                 'Más értéktárnak küldött szállítás alatti valuta', 'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'TRB',  'TRB',  vault_cp_type_id,
         'Területek közötti Raiffeisen Bank', 'Területek közti forint mozgás bankon keresztül', 'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'ERB',  'ERB',  vault_cp_type_id,
         'Egyedi Raiffeisen Bank',            'Egyedi banki valuta/forint ki/be',          'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'FRB',  'FRB',  vault_cp_type_id,
         'Fixing Raiffeisen Bank',            'Fixingen kihozott/beszállított valuta',     'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'RB',   'RB',   vault_cp_type_id,
         'Raiffeisen Bank',                   'Fixingen kihozott valuta forint ellenértéke', 'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'JRB',  'JRB',  vault_cp_type_id,
         'Jutalék Raiffeisen Bank',           'Előző havi területi haszon befizetése',     'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'MNB',  'MNB',  vault_cp_type_id,
         'Magyar Nemzeti Bank',               'Hamisgyanús valuta/forint',                 'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'TH',   'TH',   vault_cp_type_id,
         'Többlet/Hiány pénztár',             'Területen keletkezett többlet/hiány kezelése', 'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW()),
        (gen_random_uuid(), ebc_company_id, 'FOP1', 'FOP1', vault_cp_type_id,
         '1-es főpénztár',                    'Visszapótlás, hó végi többlet/hiány rendezése', 'BUDAPEST', '',
         country_hu_id, branch_status_id, CURRENT_DATE, true, false, 'ORSZAGOS', NULL, NOW())
    ON CONFLICT (code) DO NOTHING;

    -- Self-review P0-1 / P2-8: ellenőrzés — ha kevesebb mint 10 VAULT_COUNTERPARTY branch
    -- létezik az EBC cégben a seed után, valószínűleg ON CONFLICT silently skip-pelt valamit.
    DECLARE
        actual_count INT;
    BEGIN
        SELECT COUNT(*) INTO actual_count
        FROM branch b
        JOIN dictionary d ON b.branch_type_did = d.id
        WHERE b.company_id = ebc_company_id
          AND d.category = 'BRANCH_TYPE' AND d.code = 'VAULT_COUNTERPARTY';
        IF actual_count < 10 THEN
            RAISE WARNING 'V277: EBC-ben csak %/10 vault-counterparty branch van — egyik vagy '
                          'több partner-kód foglalt lehet más cégben (uk_branch_code GLOBAL UNIQUE). '
                          'Audit szükséges.', actual_count;
        ELSE
            RAISE NOTICE 'V277: % vault counterparty branch elérhető az EBC cégben', actual_count;
        END IF;
    END;
END $$;

COMMENT ON COLUMN branch.branch_type_did IS
    'BRANCH_TYPE dictionary FK: PENZTAR=lakossági pénztár, ERTEKTAR=értéktár, '
    'VAULT_COUNTERPARTY=banki/speciális partner (FK-013, Bali Henriett 2026-05-28).';
