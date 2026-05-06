-- W-S094 (Kiss Kornel) jelszava: "Teszt1234" (BCrypt $2a$10)
-- 2026-05-06: tesztelo kollegak nem tudtak belepni → jelszoreset
UPDATE worker
SET password_hash = '$2a$10$5I9DAESy4LtUU0vwUc2o6OAUi0VcLRdgy9nhNZtX0Qp3R9aV/uh3G',
    updated_at = NOW()
WHERE UPPER(code) = 'W-S094'
  AND password_hash IS NOT NULL;
