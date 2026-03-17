-- Worker Google OAuth email beállítás
-- A workers táblában lévő felhasználókhoz email cím hozzáadása a Google bejelentkezéshez

UPDATE workers
SET email = 'kos.zoltan.ebc@gmail.com'
WHERE worker_code = 'KOSA'
  AND email IS NULL;
