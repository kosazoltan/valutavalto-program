-- V335: competitor_rates egyediseg-garancia (competitor_id, currency_id, rate_date)
--
-- FK-041/II security-audit FINDING 6 (PROBABLE/LOW): a versenytars-arfolyam upsert
-- (CompetitorRateService.submit) korabban find-or-insert mintat hasznalt UNIQUE constraint
-- nelkul. Ket parhuzamos bekuldes ugyanarra a (versenyhely, valuta, mai datum) harmasra
-- DUPLIKALT sorokat hozhatott letre: mindketto null-t olvasott a find-ben, majd ket INSERT
-- futott. A megjelenites helyes maradt (createdAt DESC dedup), de a DB-ben duplikacio
-- halmozodott. A tabla a V75-ben jott letre, az iro funkcio (PR #1217) frissen elt, igy
-- minimalis adat erintett.
--
-- A javitas ket reteg:
--   1. DB: ez a migracio dedup-ol, majd UNIQUE indexet tesz a harmasra.
--   2. App: a service atomi `INSERT ... ON CONFLICT DO UPDATE` upsert-re valt (V335-tel
--      parhuzamosan), igy parhuzamos bekuldes se hoz letre duplikatumot, es nem dob hibat.

-- ============================================================
-- 1. lepes: meglevo duplikatumok DEDUP-ja
-- (competitor_id, currency_id, rate_date)-enkent a legfrissebb created_at sort tartjuk
-- meg (tie-break: id), a tobbit toroljuk. Ez nem veszit erdemi informaciot, mert a
-- megjelenites amugy is csak a legfrissebbet (createdAt DESC) mutatja harmasonkent.
-- A DELETE WHERE-rel szuri a torlendo sorokat (nem teljes-tabla torles).
-- ============================================================
DELETE FROM competitor_rates cr
USING (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY competitor_id, currency_id, rate_date
               ORDER BY created_at DESC, id DESC
           ) AS rn
    FROM competitor_rates
) ranked
WHERE cr.id = ranked.id
  AND ranked.rn > 1;

-- ============================================================
-- 2. lepes: UNIQUE index a harmasra
-- IF NOT EXISTS -> idempotens ujrafuttatasnal (V155 mintaja). A tabla kicsi (friss adat),
-- igy a CREATE UNIQUE INDEX rovid ACCESS EXCLUSIVE lockja elhanyagolhato. Ez az index egyben
-- a service ON CONFLICT (competitor_id, currency_id, rate_date) upsert-jenek konfliktus-kulcsa.
-- ============================================================
CREATE UNIQUE INDEX IF NOT EXISTS uq_competitor_rate_comp_curr_date
    ON competitor_rates (competitor_id, currency_id, rate_date);
