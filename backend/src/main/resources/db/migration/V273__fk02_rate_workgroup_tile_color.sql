-- V273 (FK-02): munkacsoport-csempe szín a kezelő felülethez.
--
-- Az árfolyamkészítő "Munkacsoportok kezelő felület" (FK-02) csempés nézetén minden
-- munkacsoporthoz egy választható szín rendelhető, hogy a csoportokat területenként
-- vizuálisan el lehessen különíteni. A szín egy fix paletta-kulcs (pl. 'amber', 'sky'),
-- NEM nyers hex — a frontend képezi le Tailwind-osztályra. NULL = alapértelmezett (szürke).
--
-- Idempotens: ADD COLUMN IF NOT EXISTS.

ALTER TABLE rate_workgroup ADD COLUMN IF NOT EXISTS tile_color VARCHAR(20);
