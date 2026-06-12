-- V321 (Batch2-E adat-ag): ertektar branch-ek cim-adatainak backfillje
--
-- GYOKEROK (2026-06-12 Fabulya-teszt, atadas-atvetel bizonylat): a bizonylat
-- fejleceben az ertektar cime/telefonszama hianyzik. A TransferService.toDto
-- (formatBranchAddress) NULL-t ad, ha a branch city+address+zip_code mind
-- ures — a renderek ilyenkor szandekosan elrejtik a sort.
--
-- ADAT-TENY: a V239 a 8 ertektar cimet CSAK az uj INSERT-nel adta meg
-- (ON CONFLICT DO NOTHING); ha a branch-sor mar letezett (pl. V145 seed,
-- cim nelkul), a cim SOSEM lett backfillelve. Ez a migracio a V239-es
-- Google Sheets ertekekkel potolja a hianyzo mezoket — kizarolag ott,
-- ahol az adott mezo ures (mar kitoltott adatot nem ir felul).
--
-- Telefonszam: a repoban NINCS hiteles telefonszam-forras egyik branch-re
-- sem (egyetlen migracio sem allitott be branch.phone-t) — telefonszamot
-- NEM talalunk ki; a fejlec telefon-sora a torzsadat-karbantartasban valo
-- kitoltesig rejtve marad (szandekos null-safe render).
DO $$
DECLARE
    updated_count INT;
BEGIN
    WITH vault_data(code, address, city, zip_code) AS (VALUES
        ('BR010', 'Széchenyi u. 26.',      'Szekszárd',   '7100'),
        ('BR020', 'Tisza L. krt 57',       'Szeged',      '6722'),
        ('BR026', 'Szabadkai út 7.',       'Szeged',      '6729'),
        ('BR040', 'Deák F. tér 6.',        'Kecskemét',   '6000'),
        ('BR050', 'Péterfia u. 18.',       'Debrecen',    '4026'),
        ('BR063', 'Országzászló tér 6.',   'Nyíregyháza', '4400'),
        ('BR075', 'Andrássy út 24-28.',    'Békéscsaba',  '5600'),
        ('BR120', 'Megyeri út 76.',        'Pécs',        '7632'),
        ('BR145', 'Ady utca 12-14',        'Kaposvár',    '7400')
    )
    UPDATE branch b
       SET address  = COALESCE(NULLIF(TRIM(b.address), ''),  vd.address),
           city     = COALESCE(NULLIF(TRIM(b.city), ''),     vd.city),
           zip_code = COALESCE(NULLIF(TRIM(b.zip_code), ''), vd.zip_code),
           updated_at = NOW()
      FROM vault_data vd
     WHERE b.code = vd.code
       AND (NULLIF(TRIM(b.address), '') IS NULL
            OR NULLIF(TRIM(b.city), '') IS NULL
            OR NULLIF(TRIM(b.zip_code), '') IS NULL);
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'V321 ertektar cim-backfill: % branch-sor frissitve (0 = mindenhol volt mar cim).', updated_count;
END $$;
