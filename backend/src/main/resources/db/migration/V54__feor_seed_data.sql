-- ============================================================================
-- V54: FEOR referencia adatok — 19 munkakör kód
-- ============================================================================

INSERT INTO feor_code (code, title) VALUES
    ('2144', 'Alkalmazásprogramozó'),
    ('4211', 'Banki pénztáros'),
    ('4122', 'Bérelszámoló'),
    ('4129', 'Egyéb számviteli foglalkozású'),
    ('4229', 'Egyéb ügyfélkapcsolati foglalkozású'),
    ('3910', 'Egyéb ügyintéző'),
    ('2910', 'Egyéb, magasan képzett ügyintéző'),
    ('4190', 'Egyéb, máshova nem sorolható irodai, ügyviteli foglalkozású'),
    ('1210', 'Gazdasági, költségvetési szervezet vezetője (igazgató, elnök, ügyvezető igazgató)'),
    ('9233', 'Hivatalsegéd, kézbesítő'),
    ('4134', 'Humánpolitikai adminisztrátor'),
    ('2514', 'Kontroller'),
    ('4121', 'Könyvelő (analitikus)'),
    ('3716', 'Lakberendező, dekoratőr'),
    ('3632', 'Marketing- és PR-ügyintéző'),
    ('1323', 'Pénzintézeti tevékenységet folytató egység vezetője'),
    ('3612', 'Pénzintézeti ügyintéző'),
    ('1411', 'Számviteli és pénzügyi tevékenységet folytató egység vezetője'),
    ('5254', 'Vagyonőr, testőr')
ON CONFLICT (code) DO NOTHING;
