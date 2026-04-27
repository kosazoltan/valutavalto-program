-- V161: V111 seed jelszo ("1234") reset — force first-time worker setup.
--
-- Hatter:
-- A V111 Flyway migration felvitte 4 dolgozot (BORSI/BALI/KASZA/KOSA) azonos
-- alapjelszoval ("1234", BCrypt hash $2b$10$dEHXvZQsnLDxcoSw...). Ez dev-time
-- konfiguracio volt. Production-hez nem megengedheto, hogy az osszes user
-- ugyanazzal a trivialis jelszoval lepjen be.
--
-- V2.3.0 refaktor:
-- A telepito wizard mostantol a /auth/first-time-worker-setup endpoint-ot hivja
-- a kivalasztott dolgozora. A worker sajat jelszavat allitja be.
-- Ahhoz hogy minden V111 seed-dolgozo kotelezo uj jelszot kapjon, ezzel a
-- migracioval resetejuk a password_changed_at-et NULL-ra (jelzes:
-- seed-telepitett, meg nincs valodi jelszavuk).
--
-- Biztonsag:
-- A password_hash megmarad (BCrypt("1234")) egy extra ellenorzeshez: ha valaki
-- a kovetkezo telepitesben a wizard-ban megadja a "1234"-et currentPassword-kent,
-- az atmegy (normal first-time-setup).
-- De a /auth/login nem enged direkt login-t amig a password_changed_at NULL +
-- az applikacio nem az eredeti V111 seed jelszot fogadja el login-nal (v2.3.0
-- biztonsagi kovetelmeny). Ehhez meg kellene egy ellenorzes a WorkerService-ben,
-- de ezt egy kesobbi migracio kezeli.

UPDATE worker
SET password_changed_at = NULL
WHERE password_hash = '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie'
   OR (code IN ('BORSI', 'BALI', 'KASZA', 'KOSA') AND password_changed_at IS NULL);

-- Naplozaas: hany worker erintett
DO $$
DECLARE
    affected_count INT;
BEGIN
    SELECT COUNT(*) INTO affected_count
    FROM worker
    WHERE password_changed_at IS NULL
      AND code IN ('BORSI', 'BALI', 'KASZA', 'KOSA');
    RAISE NOTICE 'V161: % worker reseteve — force first-time-setup a kovetkezo login-nal', affected_count;
END
$$;