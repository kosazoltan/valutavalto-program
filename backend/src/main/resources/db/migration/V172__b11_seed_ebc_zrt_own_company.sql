-- V172 (Audit B11 fix): EBC Zrt. seed insert into own_company
-- Cel: a Beallitasok > Cegadatok tab a hardkodolt "Penzvalto Kft." placeholder
-- helyett az aktiv OwnCompany rekordot toltse be.
--
-- Forras: D:\valutavalto-vault\references\company-data-ebc-zrt.md
-- Hivatalos nev: EXCLUSIVE BEST Change Zrt.
-- Szekhely: 7621 Pecs, Citrom utca 2-6. foldszint 26. ajto.
-- Adoszam: 32313332-2-02
-- Cegjegyzekszam: 02 10 060505
--
-- Idempotens: csak akkor szur be, ha NEM letezik aktiv rekord ugyanazon company-hoz.

DO $$
DECLARE
    v_company RECORD;
    v_inserted INT := 0;
BEGIN
    -- Iterate ALL companies (multi-tenant): minden ceg sajat OwnCompany rekorddal
    FOR v_company IN
        SELECT id, name FROM company
    LOOP
        -- Idempotens: csak akkor INSERT, ha NEM letezik aktiv rekord
        INSERT INTO own_company (
            id, company_id, name, tax_number, registration_number,
            address, phone, email, license_number,
            is_active, created_at, updated_at
        )
        SELECT
            gen_random_uuid(),
            v_company.id,
            'EXCLUSIVE BEST Change Zrt.',
            '32313332-2-02',
            '02 10 060505',
            '7621 Pecs, Citrom utca 2-6. foldszint 26. ajto.',
            '',
            'kosa.zoltan.ebc@gmail.com',
            '',
            true,
            NOW(),
            NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM own_company o
            WHERE o.company_id = v_company.id
              AND o.is_active = true
        );
        IF FOUND THEN
            v_inserted := v_inserted + 1;
        END IF;
    END LOOP;

    RAISE NOTICE 'V172 B11 seed: % uj OwnCompany rekord beillesztve (EBC Zrt.)', v_inserted;
END $$;
