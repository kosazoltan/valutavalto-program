-- Worker Google OAuth email beállítás
-- A worker táblában lévő felhasználóhoz email cím hozzáadása a Google bejelentkezéshez.
-- Legacy adatbázisoknál a tábla/oszlopnevek eltérhetnek, ezért a frissítés csak akkor fusson,
-- ha a várt sémaelemek ténylegesen léteznek.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'worker'
    )
    AND EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'worker'
          AND column_name = 'code'
    )
    AND EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'worker'
          AND column_name = 'email'
    ) THEN
        UPDATE worker
        SET email = 'kos.zoltan.ebc@gmail.com'
        WHERE code = 'KOSA'
          AND email IS NULL;
    END IF;
END $$;
