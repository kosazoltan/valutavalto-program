-- V184: BORSI dolgozó jelszó reset '1234'-re
-- Tesztelő (Tomi) 2026-05-06: 401 "Hibás pénztáros kód vagy jelszó" BORSI/1234
-- BCrypt $2a$10$ hash, Spring BCrypt kompatibilis
UPDATE worker
SET password_hash = '$2a$10$aSYw7zBrwroHxFBJP63V9eQrj3qLv0UdvO1oD6KTDtjfEsvInhabm',
    updated_at = NOW()
WHERE UPPER(code) = 'BORSI'
  AND password_hash IS NOT NULL;
