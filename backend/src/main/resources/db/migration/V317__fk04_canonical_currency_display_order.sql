-- V317 (FK04 / FR-5, NFR-4): kanonikus currency display_order + duplikáció-felszámolás.
--
-- Háttér: a V271 ABC-sorrendet állított be (HUF=0, AUD=1 … RUB=17 … USD=21), a V298 pedig
-- az EUA-t display_order=17-tel seedelte → EUA = RUB = 17 duplikáció. Továbbá a V3-as
-- inaktív maradványok (BGN=12, DKK=17, HRK=18) is ütköznek a V271-es értékekkel
-- (MXN=12, RUB=17, THB=18) — a V318-as UNIQUE constraint e nélkül a takarítás nélkül
-- nem vehető fel.
--
-- Kanonikus sorrend (FK04 kontextus-dokumentum §8 = MainRateSheetPage.DEFAULT_CURRENCIES):
--   HUF=0 (bázis), EUR=1, USD=2, GBP=3, CHF=4, AUD=5, CAD=6, JPY=7, CZK=8, PLN=9, RON=10,
--   RSD=11, ILS=12, UAH=13, RUB=14, EUA=15, TRY=16, CNY=17, BAM=18, THB=19, BRL=20,
--   MXN=21, NZD=22
--
-- Idempotens: ismételt futtatáskor ugyanazt a végállapotot eredményezi (a nem-kanonikus
-- sorok determinisztikusan, id-sorrendben kapnak 100 feletti értéket).

-- 1) A kanonikus halmazon KÍVÜLI valuták (inaktív maradványok: BGN, DKK, HRK, NOK, SEK,
--    illetve bármely környezet-specifikusan felvett egyéb kód) kiparkolása a 100+ tartományba,
--    hogy ne ütközzenek sem egymással, sem a kanonikus 0–22 értékekkel.
UPDATE currency AS c
   SET display_order = 100 + sub.seq,
       updated_at = NOW()
  FROM (
       SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS seq
         FROM currency
        WHERE code NOT IN ('HUF','EUR','USD','GBP','CHF','AUD','CAD','JPY','CZK','PLN','RON',
                           'RSD','ILS','UAH','RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD')
       ) AS sub
 WHERE c.id = sub.id;

-- 2) Kanonikus sorrend beállítása (EUA a RUB=14 és TRY=16 közé: display_order=15 — FR-5).
UPDATE currency AS c
   SET display_order = v.ord,
       updated_at = NOW()
  FROM (VALUES
        ('HUF', 0),
        ('EUR', 1),  ('USD', 2),  ('GBP', 3),  ('CHF', 4),  ('AUD', 5),
        ('CAD', 6),  ('JPY', 7),  ('CZK', 8),  ('PLN', 9),  ('RON', 10),
        ('RSD', 11), ('ILS', 12), ('UAH', 13), ('RUB', 14), ('EUA', 15),
        ('TRY', 16), ('CNY', 17), ('BAM', 18), ('THB', 19), ('BRL', 20),
        ('MXN', 21), ('NZD', 22)
       ) AS v(code, ord)
 WHERE c.code = v.code;
