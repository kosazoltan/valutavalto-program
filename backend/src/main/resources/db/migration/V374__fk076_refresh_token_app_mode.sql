-- FK-076 (B1 + appMode-szures): a refresh token megjegyzi a kibocsato kliens appMode-jat.
--
-- Indok: a JWT `grantedRoles` claim appMode-ra SZURT canonical szerepkor-listat hordoz, hogy a
-- penztargepen kapott token ne kaphasson ertektar/vezetoi ROLE_* authority-t. A silent refresh
-- (/auth/refresh-cookie) viszont nem lat appMode-ot a keresben, ezert a rotacio a szures nelkul
-- ujra kiadna a teljes listat -- ami pontosan az izolaciot lyukasztana ki, amit vedeni akarunk.
--
-- A kibocsataskor ismert appMode-ot ezert perzisztaljuk, es a rotacio ebbol szur ujra.
-- NULL = ismeretlen/legacy appMode (pl. sync-engine bootstrap-login, regi sorok): ilyenkor a
-- grantedRolesForAppMode nem szur, ami megegyezik a login-agi viselkedessel ugyanezen bemenetre.

ALTER TABLE refresh_token
    ADD COLUMN IF NOT EXISTS app_mode VARCHAR(32);

COMMENT ON COLUMN refresh_token.app_mode IS
    'FK-076: a tokent kibocsato kliens appMode-ja (penztar/ertektar/full/kamera/rate-maker). '
    'A silent refresh ebbol szuri ujra a JWT grantedRoles claim-et. NULL = legacy/ismeretlen.';
