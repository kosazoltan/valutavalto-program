-- V143: NAV áfa-kulcsok feloldása hardcode-ból SystemParameter-be (CB-016)
--
-- Háttér:
--   A NavClosingService korábban fixen beégetve használt 0.27-et
--   a kezelési díj ÁFA-jára. Jogszabályváltozás esetén ez redeploy-t
--   igényelt. Mostantól a service a `nav.vat-rate.<TAX_CODE>` kulcs
--   alatti paramétert olvassa, és ha nincs / hibás, fallback-el
--   a hardcoded alapértékre (log.warn mellett).
--
-- Érintett service: hu.puzzleir.valuta.service.NavClosingService
-- Enum:             NavClosingService.NavTaxCode { STANDARD, REDUCED_18, REDUCED_5, ZERO }

INSERT INTO system_parameter (parameter_key, parameter_value, parameter_type, category, description, is_active)
VALUES
    ('nav.vat-rate.STANDARD',   '0.27', 'DECIMAL', 'NAV',
     'Általános ÁFA kulcs NAV záráshoz (kezelési díj). Magyar szabályozás szerint 27%.',
     TRUE),
    ('nav.vat-rate.REDUCED_18', '0.18', 'DECIMAL', 'NAV',
     'Kedvezményes 18%-os ÁFA kulcs (pl. tej, tojás, liszt).',
     TRUE),
    ('nav.vat-rate.REDUCED_5',  '0.05', 'DECIMAL', 'NAV',
     'Kedvezményes 5%-os ÁFA kulcs (pl. gyógyszer, könyv, friss hús).',
     TRUE),
    ('nav.vat-rate.ZERO',       '0.00', 'DECIMAL', 'NAV',
     'Adómentes kategória (export, nemzetközi személyszállítás stb.).',
     TRUE)
ON CONFLICT (parameter_key) DO NOTHING;
