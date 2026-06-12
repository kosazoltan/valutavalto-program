-- V320 (Batch2-A): teljes cimlet-katalogus backfill minden aktiv branch-re,
-- minden aktivan forgalmazott valutara.
--
-- GYOKEROK (2026-06-12 Fabulya-teszt): a Cimletezes menu EUR-ra (es minden
-- nem-HUF valutara) ures tablat mutat, es az atadas-atvetel cimlet-preset is
-- ures. Ok: a denomination tablat kizarolag a V168/V169/V170 toltotte fel, es
-- azok CSAK a 14 HUF cimletet seedelik. A kodbeli FOREIGN_DENOMINATIONS
-- katalogust (EUR/USD/GBP/CHF/CZK) egyedul a BranchService.create() hivja —
-- az eles branch-ek viszont SQL seed migraciokkal (V145/V239/V250/V277)
-- jottek letre, igy rajtuk ez sosem futott le.
--
-- KATALOGUS-FORRAS (ketszeres validacio, 2026-06-12):
-- 1. Hivatalos jegybanki forrasok (ECB, Fed, BoE, SNB, RBA, BoC, BoJ, CNB,
--    NBP, BNR, NBS, BoI, NBU, TCMB, PBoC, CBBH, BoT, BCB, Banxico, RBNZ) —
--    a JELENLEG forgalomban levo bankjegy/erme cimletek.
-- 2. Legacy EXCMD program keresztvalidacio (legacy-transfer/text/VALUTA/DLL/
--    KCIMLET/MAKEDLL/Unit2.pas:111-135 dekodolt katalogus). Elteresek a
--    legacy-tol szandekosak: TRY 20000 legacy-mutermek kihagyva (a KISCIMLET
--    DLL is hard-patch-elte), RON +20 lej (2021-tol letezik), PLN +500 zloty
--    (2017-tol), UAH kisbankjegyek ermekent (2026.03.02-tol a regi kis-
--    bankjegyek nem fizetoeszkozok).
-- A Java-oldali tukor: DenominationService.FOREIGN_DENOMINATIONS (1:1 azonos
-- keszlet — az uj branch-ek inicializalasat az vezerli).
--
-- SZABALYOK:
-- - Csak AKTIV valutakra (is_active=true) — a V319 utan a RUB mar inaktiv,
--   igy kimarad (user-direktiva: RUB-ot nem forgalmazunk).
-- - Csak AKTIV branch-ekre (V168 minta).
-- - Idempotens: (branch, currency, face_value) harmasra NOT EXISTS guard.
-- - HUF is benne van: a V170 utan SQL-lel letrehozott branch-ek (V239/V250/
--   V277) HUF cimlet-sorai is potlodnak.
-- - EUA = euro erme (apro) kulon katalogus-tetel, csak COIN sorokkal.
-- - Tipus-korrekcio a mar letezo sorokon, ket ismert hibara:
--   a) a regi classifyForeignDenomination >=1 -> BANKNOTE szabalya az
--      EUR 1/2, CHF 5/2/1, CZK 50..1 ermeket bankjegynek minositette;
--   b) a V169 az 500 Ft-ot ERME-nek allitotta — ez TEVES: az MNB-nel az
--      500 Ft bankjegy (megujitott sorozat, Rakoczi), 500 Ft-os erme nem
--      letezik (a legnagyobb erme a 200 Ft). HUF 500 = BANKNOTE.
--
-- Megvalositas: egyetlen set-alapu statement, data-modifying CTE-kkel
-- (nincs temp tabla, nincs DROP/DELETE). Az UPDATE a snapshot miatt csak a
-- mar korabban letezo sorokat latja — az most beszurt sorok eleve helyes
-- tipussal keletkeznek.
DO $$
DECLARE
    v_inserted INT;
    v_type_fixed INT;
BEGIN
    WITH catalog(code, face_value, denom_type) AS (VALUES
        -- HUF (V168 keszlet; 500 Ft = BANKNOTE — MNB-teny)
        ('HUF',20000::numeric,'BANKNOTE'),('HUF',10000,'BANKNOTE'),('HUF',5000,'BANKNOTE'),
        ('HUF',2000,'BANKNOTE'),('HUF',1000,'BANKNOTE'),('HUF',500,'BANKNOTE'),
        ('HUF',200,'COIN'),('HUF',100,'COIN'),('HUF',50,'COIN'),('HUF',20,'COIN'),
        ('HUF',10,'COIN'),('HUF',5,'COIN'),('HUF',2,'COIN'),('HUF',1,'COIN'),
        -- EUR (ECB; az 500-as mar nem nyomtatott, de torvenyes fizetoeszkoz)
        ('EUR',500,'BANKNOTE'),('EUR',200,'BANKNOTE'),('EUR',100,'BANKNOTE'),
        ('EUR',50,'BANKNOTE'),('EUR',20,'BANKNOTE'),('EUR',10,'BANKNOTE'),('EUR',5,'BANKNOTE'),
        ('EUR',2,'COIN'),('EUR',1,'COIN'),('EUR',0.50,'COIN'),('EUR',0.20,'COIN'),
        ('EUR',0.10,'COIN'),('EUR',0.05,'COIN'),('EUR',0.02,'COIN'),('EUR',0.01,'COIN'),
        -- EUA = euro erme (apro) — kulon valutakod, csak ermek
        ('EUA',2,'COIN'),('EUA',1,'COIN'),('EUA',0.50,'COIN'),('EUA',0.20,'COIN'),
        ('EUA',0.10,'COIN'),('EUA',0.05,'COIN'),('EUA',0.02,'COIN'),('EUA',0.01,'COIN'),
        -- USD (Fed/uscurrency.gov; az 1 dollar bankjegykent dominans)
        ('USD',100,'BANKNOTE'),('USD',50,'BANKNOTE'),('USD',20,'BANKNOTE'),
        ('USD',10,'BANKNOTE'),('USD',5,'BANKNOTE'),('USD',2,'BANKNOTE'),('USD',1,'BANKNOTE'),
        ('USD',0.50,'COIN'),('USD',0.25,'COIN'),('USD',0.10,'COIN'),('USD',0.05,'COIN'),('USD',0.01,'COIN'),
        -- GBP (BoE polimer sorozat)
        ('GBP',50,'BANKNOTE'),('GBP',20,'BANKNOTE'),('GBP',10,'BANKNOTE'),('GBP',5,'BANKNOTE'),
        ('GBP',2,'COIN'),('GBP',1,'COIN'),('GBP',0.50,'COIN'),('GBP',0.20,'COIN'),
        ('GBP',0.10,'COIN'),('GBP',0.05,'COIN'),('GBP',0.02,'COIN'),('GBP',0.01,'COIN'),
        -- CHF (SNB 9. sorozat)
        ('CHF',1000,'BANKNOTE'),('CHF',200,'BANKNOTE'),('CHF',100,'BANKNOTE'),
        ('CHF',50,'BANKNOTE'),('CHF',20,'BANKNOTE'),('CHF',10,'BANKNOTE'),
        ('CHF',5,'COIN'),('CHF',2,'COIN'),('CHF',1,'COIN'),('CHF',0.50,'COIN'),
        ('CHF',0.20,'COIN'),('CHF',0.10,'COIN'),('CHF',0.05,'COIN'),
        -- AUD (RBA)
        ('AUD',100,'BANKNOTE'),('AUD',50,'BANKNOTE'),('AUD',20,'BANKNOTE'),
        ('AUD',10,'BANKNOTE'),('AUD',5,'BANKNOTE'),
        ('AUD',2,'COIN'),('AUD',1,'COIN'),('AUD',0.50,'COIN'),('AUD',0.20,'COIN'),
        ('AUD',0.10,'COIN'),('AUD',0.05,'COIN'),
        -- CAD (BoC; a penny 2013 ota kivont)
        ('CAD',100,'BANKNOTE'),('CAD',50,'BANKNOTE'),('CAD',20,'BANKNOTE'),
        ('CAD',10,'BANKNOTE'),('CAD',5,'BANKNOTE'),
        ('CAD',2,'COIN'),('CAD',1,'COIN'),('CAD',0.25,'COIN'),('CAD',0.10,'COIN'),('CAD',0.05,'COIN'),
        -- JPY (BoJ; 2024-es uj sorozat + 2004-es egyutt forog)
        ('JPY',10000,'BANKNOTE'),('JPY',5000,'BANKNOTE'),('JPY',2000,'BANKNOTE'),('JPY',1000,'BANKNOTE'),
        ('JPY',500,'COIN'),('JPY',100,'COIN'),('JPY',50,'COIN'),('JPY',10,'COIN'),
        ('JPY',5,'COIN'),('JPY',1,'COIN'),
        -- CZK (CNB)
        ('CZK',5000,'BANKNOTE'),('CZK',2000,'BANKNOTE'),('CZK',1000,'BANKNOTE'),
        ('CZK',500,'BANKNOTE'),('CZK',200,'BANKNOTE'),('CZK',100,'BANKNOTE'),
        ('CZK',50,'COIN'),('CZK',20,'COIN'),('CZK',10,'COIN'),('CZK',5,'COIN'),
        ('CZK',2,'COIN'),('CZK',1,'COIN'),
        -- PLN (NBP; az 500 zloty 2017 ota forog)
        ('PLN',500,'BANKNOTE'),('PLN',200,'BANKNOTE'),('PLN',100,'BANKNOTE'),
        ('PLN',50,'BANKNOTE'),('PLN',20,'BANKNOTE'),('PLN',10,'BANKNOTE'),
        ('PLN',5,'COIN'),('PLN',2,'COIN'),('PLN',1,'COIN'),('PLN',0.50,'COIN'),
        ('PLN',0.20,'COIN'),('PLN',0.10,'COIN'),('PLN',0.05,'COIN'),('PLN',0.02,'COIN'),('PLN',0.01,'COIN'),
        -- RON (BNR; polimer, a 20 lej 2021-tol)
        ('RON',500,'BANKNOTE'),('RON',200,'BANKNOTE'),('RON',100,'BANKNOTE'),
        ('RON',50,'BANKNOTE'),('RON',20,'BANKNOTE'),('RON',10,'BANKNOTE'),
        ('RON',5,'BANKNOTE'),('RON',1,'BANKNOTE'),
        ('RON',0.50,'COIN'),('RON',0.10,'COIN'),('RON',0.05,'COIN'),('RON',0.01,'COIN'),
        -- RSD (NBS; a 10/20 dinar bankjegykent ES ermekent is forog -> BANKNOTE)
        ('RSD',5000,'BANKNOTE'),('RSD',2000,'BANKNOTE'),('RSD',1000,'BANKNOTE'),
        ('RSD',500,'BANKNOTE'),('RSD',200,'BANKNOTE'),('RSD',100,'BANKNOTE'),
        ('RSD',50,'BANKNOTE'),('RSD',20,'BANKNOTE'),('RSD',10,'BANKNOTE'),
        ('RSD',5,'COIN'),('RSD',2,'COIN'),('RSD',1,'COIN'),
        -- ILS (BoI; kerekites 10 agorotra)
        ('ILS',200,'BANKNOTE'),('ILS',100,'BANKNOTE'),('ILS',50,'BANKNOTE'),('ILS',20,'BANKNOTE'),
        ('ILS',10,'COIN'),('ILS',5,'COIN'),('ILS',2,'COIN'),('ILS',1,'COIN'),
        ('ILS',0.50,'COIN'),('ILS',0.10,'COIN'),
        -- UAH (NBU; az 1-10 hrivnya mar erme, a regi kisbankjegyek 2026.03.02-tol bevontak)
        ('UAH',1000,'BANKNOTE'),('UAH',500,'BANKNOTE'),('UAH',200,'BANKNOTE'),
        ('UAH',100,'BANKNOTE'),('UAH',50,'BANKNOTE'),('UAH',20,'BANKNOTE'),
        ('UAH',10,'COIN'),('UAH',5,'COIN'),('UAH',2,'COIN'),('UAH',1,'COIN'),
        ('UAH',0.50,'COIN'),('UAH',0.10,'COIN'),
        -- TRY (TCMB E9; a legacy 20000-es mutermek NINCS benne)
        ('TRY',200,'BANKNOTE'),('TRY',100,'BANKNOTE'),('TRY',50,'BANKNOTE'),
        ('TRY',20,'BANKNOTE'),('TRY',10,'BANKNOTE'),('TRY',5,'BANKNOTE'),
        ('TRY',1,'COIN'),('TRY',0.50,'COIN'),('TRY',0.25,'COIN'),('TRY',0.10,'COIN'),
        ('TRY',0.05,'COIN'),('TRY',0.01,'COIN'),
        -- CNY (PBoC 5. sorozat; az 1 juan bankjegykent dominans)
        ('CNY',100,'BANKNOTE'),('CNY',50,'BANKNOTE'),('CNY',20,'BANKNOTE'),
        ('CNY',10,'BANKNOTE'),('CNY',5,'BANKNOTE'),('CNY',1,'BANKNOTE'),
        ('CNY',0.50,'COIN'),('CNY',0.10,'COIN'),
        -- BAM (CBBH; latin+cirill valtozatok egyenertekuek)
        ('BAM',200,'BANKNOTE'),('BAM',100,'BANKNOTE'),('BAM',50,'BANKNOTE'),
        ('BAM',20,'BANKNOTE'),('BAM',10,'BANKNOTE'),
        ('BAM',5,'COIN'),('BAM',2,'COIN'),('BAM',1,'COIN'),('BAM',0.50,'COIN'),
        ('BAM',0.20,'COIN'),('BAM',0.10,'COIN'),('BAM',0.05,'COIN'),
        -- THB (BoT 17. sorozat)
        ('THB',1000,'BANKNOTE'),('THB',500,'BANKNOTE'),('THB',100,'BANKNOTE'),
        ('THB',50,'BANKNOTE'),('THB',20,'BANKNOTE'),
        ('THB',10,'COIN'),('THB',5,'COIN'),('THB',2,'COIN'),('THB',1,'COIN'),
        ('THB',0.50,'COIN'),('THB',0.25,'COIN'),
        -- BRL (BCB; a 200 real 2020 ota forog)
        ('BRL',200,'BANKNOTE'),('BRL',100,'BANKNOTE'),('BRL',50,'BANKNOTE'),
        ('BRL',20,'BANKNOTE'),('BRL',10,'BANKNOTE'),('BRL',5,'BANKNOTE'),('BRL',2,'BANKNOTE'),
        ('BRL',1,'COIN'),('BRL',0.50,'COIN'),('BRL',0.25,'COIN'),('BRL',0.10,'COIN'),('BRL',0.05,'COIN'),
        -- MXN (Banxico G-sorozat; a 20 peso bankjegykent ES ermekent -> BANKNOTE)
        ('MXN',1000,'BANKNOTE'),('MXN',500,'BANKNOTE'),('MXN',200,'BANKNOTE'),
        ('MXN',100,'BANKNOTE'),('MXN',50,'BANKNOTE'),('MXN',20,'BANKNOTE'),
        ('MXN',10,'COIN'),('MXN',5,'COIN'),('MXN',2,'COIN'),('MXN',1,'COIN'),('MXN',0.50,'COIN'),
        -- NZD (RBNZ Series 7; az 5 cent 2006-ban bevont)
        ('NZD',100,'BANKNOTE'),('NZD',50,'BANKNOTE'),('NZD',20,'BANKNOTE'),
        ('NZD',10,'BANKNOTE'),('NZD',5,'BANKNOTE'),
        ('NZD',2,'COIN'),('NZD',1,'COIN'),('NZD',0.50,'COIN'),('NZD',0.20,'COIN'),('NZD',0.10,'COIN')
    ),
    ins AS (
        INSERT INTO denomination (
            company_id, branch_id, currency_id, face_value,
            denomination_type, quantity, min_quantity, is_active,
            created_at, updated_at
        )
        SELECT
            b.company_id, b.id, c.id, cat.face_value,
            cat.denom_type, 0, 0, true,
            NOW(), NOW()
        FROM branch b
        CROSS JOIN catalog cat
        -- Codex P2 #1108: az EUA-t a V298 SZANDEKOSAN is_active=false-szal seedeli
        -- (minimal blast-radius) — a cimlet-sorait megis letrehozzuk (FK04 "aktiv
        -- UNION EUA" minta), hogy az EUA aktivalasakor a cimletezes azonnal mukodjon.
        JOIN currency c ON c.code = cat.code AND (c.is_active = true OR c.code = 'EUA')
        WHERE b.is_active = true
          AND NOT EXISTS (
              SELECT 1 FROM denomination d
              WHERE d.branch_id = b.id
                AND d.currency_id = c.id
                AND d.face_value = cat.face_value
          )
        RETURNING 1
    ),
    upd AS (
        UPDATE denomination d
           SET denomination_type = cat.denom_type,
               updated_at = NOW()
          FROM currency c
          JOIN catalog cat ON cat.code = c.code
         WHERE d.currency_id = c.id
           AND d.face_value = cat.face_value
           AND d.denomination_type IS DISTINCT FROM cat.denom_type
        RETURNING 1
    )
    SELECT (SELECT COUNT(*) FROM ins), (SELECT COUNT(*) FROM upd)
      INTO v_inserted, v_type_fixed;

    RAISE NOTICE 'V320 cimlet-katalogus backfill: % uj denomination sor, % tipus-korrekcio.',
                 v_inserted, v_type_fixed;
END $$;
