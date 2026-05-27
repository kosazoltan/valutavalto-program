-- V271 (FK-006): Valutanem törzsadat központi egységesítése.
--
-- Beküldő: Kasza Helga (Főértéktár). A currency tábla a RENDSZERSZINTŰ igazságforrás:
-- minden árfolyamhoz kapcsolódó felület ebből építkezik (is_active + display_order).
--
-- Változások:
--  - INAKTÍV (törlés helyett, jogszabályi megfelelőség): DKK, NOK, SEK
--  - AKTÍV + felvitel (ha hiányzik): BAM, BRL, ILS, MXN, NZD, THB
--  - Egységes display_order a kért sorrend szerint (HUF=0 bázis, elöl):
--    AUD,BAM,BRL,CAD,CHF,CNY,CZK,EUR,GBP,ILS,JPY,MXN,NZD,PLN,RON,RSD,RUB,THB,TRY,UAH,USD
--  - HUF aktív marad (bázisdeviza), display_order 0 → a listákban/legördülőkben elöl.
--  - Inaktív valuták (DKK/NOK/SEK + a korábban inaktivált BGN/HRK/SKK/RCH) a korábbi
--    tranzakciókban és az adatbázisban érintetlenül megmaradnak — csak a felületeken nem
--    jelennek meg (az adott felület-query is_active szűrése miatt).
--
-- Idempotens: ismételt futtatáskor is a kívánt végállapotot eredményezi.

-- 1) A felviendő 6 valuta biztosítása (upsert) — aktív + helyes törzsadat minden környezetben.
INSERT INTO currency (code, name, symbol, decimal_places, is_active, created_at) VALUES
    ('BAM', 'Bosnyák konvertibilis márka', 'KM',  2, true, NOW()),
    ('BRL', 'Brazil real',                'R$',  2, true, NOW()),
    ('ILS', 'Izraeli sékel',              '₪',   2, true, NOW()),
    ('MXN', 'Mexikói peso',               '$',   2, true, NOW()),
    ('NZD', 'Új-zélandi dollár',          'NZ$', 2, true, NOW()),
    ('THB', 'Thai baht',                  '฿',   2, true, NOW())
ON CONFLICT (code) DO UPDATE
    SET is_active = true,
        name = EXCLUDED.name,
        symbol = COALESCE(currency.symbol, EXCLUDED.symbol),
        decimal_places = EXCLUDED.decimal_places,
        updated_at = NOW();

-- 2) Inaktiválás (törlés helyett) — DKK, NOK, SEK.
UPDATE currency
   SET is_active = false, updated_at = NOW()
 WHERE code IN ('DKK', 'NOK', 'SEK')
   AND is_active = true;

-- 3) Aktív halmaz + egységes display_order beállítása a kért sorrend szerint (HUF=0 bázis).
UPDATE currency AS c
   SET is_active = true,
       display_order = v.ord,
       updated_at = NOW()
  FROM (VALUES
        ('HUF', 0),
        ('AUD', 1), ('BAM', 2), ('BRL', 3), ('CAD', 4), ('CHF', 5),
        ('CNY', 6), ('CZK', 7), ('EUR', 8), ('GBP', 9), ('ILS', 10),
        ('JPY', 11), ('MXN', 12), ('NZD', 13), ('PLN', 14), ('RON', 15),
        ('RSD', 16), ('RUB', 17), ('THB', 18), ('TRY', 19), ('UAH', 20),
        ('USD', 21)
       ) AS v(code, ord)
 WHERE c.code = v.code;
