-- FK-076: denomination_allowed torzsadat-tabla + seed.
--
-- Cel: a ket, jelenleg a teljes jegybanki katalogust (V320/V328) vakon ujratermelo
-- forras (DenominationService.initializeBranchDenominations es
-- ClosingWizardService.saveDenominationBalance auto-create ag) atiranyitasa egy
-- szukitett, uzletileg engedelyezett cimlet-katalogusra.
--
-- FONTOS: a meglevo `denomination` tabla tartalmahoz ez a migracio NEM nyul
-- (sem DELETE, sem UPDATE) - kizarolag a jovobeli, uj sorok keletkezeset szabalyozza.
--
-- Uzleti szabaly (Foertektaros, 2026-08-01/08-02): tort cimlet sehol, meg EUR-nal sem;
-- nem-EUR erme (egesz erteku is) sehol. Egyetlen erme-kivetel: EUR 1 es 2.
-- A HUF szandekosan NINCS ebben a tablaban (Scope OUT) - a HUF-zaras validacioja
-- ezert explicit ki van kapcsolva (FR-3/b).
--
-- Megjegyzes: nincs FK a `denomination` tablara (szandekos, a currency_denomination_image
-- V346 precedens-mintaja szerint), es nincs branch_id - ez fiok-fuggetlen, deviza-szintu
-- uzleti katalogus.

CREATE TABLE denomination_allowed (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    currency_id BIGINT NOT NULL REFERENCES currency(id) ON DELETE RESTRICT,
    face_value DECIMAL(15,2) NOT NULL,
    denomination_type VARCHAR(20) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL,
    CONSTRAINT uq_denomination_allowed UNIQUE (company_id, currency_id, face_value),
    CONSTRAINT chk_denomination_allowed_positive CHECK (face_value > 0),
    CONSTRAINT chk_denomination_allowed_whole CHECK (face_value = TRUNC(face_value, 0)),
    CONSTRAINT chk_denomination_allowed_type CHECK (denomination_type IN ('BANKNOTE','COIN'))
);

CREATE INDEX idx_denomination_allowed_company_currency
    ON denomination_allowed(company_id, currency_id);

-- Seed: 126 kombinacio (124 banknote 21 kulfoldi devizara + EUR 1/2 erme) x aktiv company-k
INSERT INTO denomination_allowed (company_id, currency_id, face_value, denomination_type, created_at, updated_at)
SELECT c.id, cur.id, v.face_value, v.denomination_type, now(), now()
FROM company c
CROSS JOIN (VALUES
    -- EUR: 7 banknote + 2 erme-kivetel
    ('EUR', 500, 'BANKNOTE'), ('EUR', 200, 'BANKNOTE'), ('EUR', 100, 'BANKNOTE'), ('EUR', 50, 'BANKNOTE'),
    ('EUR', 20, 'BANKNOTE'), ('EUR', 10, 'BANKNOTE'), ('EUR', 5, 'BANKNOTE'),
    ('EUR', 2, 'COIN'), ('EUR', 1, 'COIN'),
    -- USD: 7 banknote
    ('USD', 100, 'BANKNOTE'), ('USD', 50, 'BANKNOTE'), ('USD', 20, 'BANKNOTE'), ('USD', 10, 'BANKNOTE'),
    ('USD', 5, 'BANKNOTE'), ('USD', 2, 'BANKNOTE'), ('USD', 1, 'BANKNOTE'),
    -- GBP: 4 banknote
    ('GBP', 50, 'BANKNOTE'), ('GBP', 20, 'BANKNOTE'), ('GBP', 10, 'BANKNOTE'), ('GBP', 5, 'BANKNOTE'),
    -- CHF: 6 banknote
    ('CHF', 1000, 'BANKNOTE'), ('CHF', 200, 'BANKNOTE'), ('CHF', 100, 'BANKNOTE'), ('CHF', 50, 'BANKNOTE'),
    ('CHF', 20, 'BANKNOTE'), ('CHF', 10, 'BANKNOTE'),
    -- AUD: 5 banknote
    ('AUD', 100, 'BANKNOTE'), ('AUD', 50, 'BANKNOTE'), ('AUD', 20, 'BANKNOTE'), ('AUD', 10, 'BANKNOTE'), ('AUD', 5, 'BANKNOTE'),
    -- CAD: 5 banknote
    ('CAD', 100, 'BANKNOTE'), ('CAD', 50, 'BANKNOTE'), ('CAD', 20, 'BANKNOTE'), ('CAD', 10, 'BANKNOTE'), ('CAD', 5, 'BANKNOTE'),
    -- JPY: 4 banknote
    ('JPY', 10000, 'BANKNOTE'), ('JPY', 5000, 'BANKNOTE'), ('JPY', 2000, 'BANKNOTE'), ('JPY', 1000, 'BANKNOTE'),
    -- CZK: 6 banknote
    ('CZK', 5000, 'BANKNOTE'), ('CZK', 2000, 'BANKNOTE'), ('CZK', 1000, 'BANKNOTE'), ('CZK', 500, 'BANKNOTE'),
    ('CZK', 200, 'BANKNOTE'), ('CZK', 100, 'BANKNOTE'),
    -- PLN: 6 banknote
    ('PLN', 500, 'BANKNOTE'), ('PLN', 200, 'BANKNOTE'), ('PLN', 100, 'BANKNOTE'), ('PLN', 50, 'BANKNOTE'),
    ('PLN', 20, 'BANKNOTE'), ('PLN', 10, 'BANKNOTE'),
    -- RON: 8 banknote
    ('RON', 500, 'BANKNOTE'), ('RON', 200, 'BANKNOTE'), ('RON', 100, 'BANKNOTE'), ('RON', 50, 'BANKNOTE'),
    ('RON', 20, 'BANKNOTE'), ('RON', 10, 'BANKNOTE'), ('RON', 5, 'BANKNOTE'), ('RON', 1, 'BANKNOTE'),
    -- RSD: 9 banknote
    ('RSD', 5000, 'BANKNOTE'), ('RSD', 2000, 'BANKNOTE'), ('RSD', 1000, 'BANKNOTE'), ('RSD', 500, 'BANKNOTE'),
    ('RSD', 200, 'BANKNOTE'), ('RSD', 100, 'BANKNOTE'), ('RSD', 50, 'BANKNOTE'), ('RSD', 20, 'BANKNOTE'), ('RSD', 10, 'BANKNOTE'),
    -- ILS: 4 banknote
    ('ILS', 200, 'BANKNOTE'), ('ILS', 100, 'BANKNOTE'), ('ILS', 50, 'BANKNOTE'), ('ILS', 20, 'BANKNOTE'),
    -- UAH: 6 banknote
    ('UAH', 1000, 'BANKNOTE'), ('UAH', 500, 'BANKNOTE'), ('UAH', 200, 'BANKNOTE'), ('UAH', 100, 'BANKNOTE'),
    ('UAH', 50, 'BANKNOTE'), ('UAH', 20, 'BANKNOTE'),
    -- RUB: 7 banknote
    ('RUB', 5000, 'BANKNOTE'), ('RUB', 2000, 'BANKNOTE'), ('RUB', 1000, 'BANKNOTE'), ('RUB', 500, 'BANKNOTE'),
    ('RUB', 200, 'BANKNOTE'), ('RUB', 100, 'BANKNOTE'), ('RUB', 50, 'BANKNOTE'),
    -- TRY: 6 banknote
    ('TRY', 200, 'BANKNOTE'), ('TRY', 100, 'BANKNOTE'), ('TRY', 50, 'BANKNOTE'), ('TRY', 20, 'BANKNOTE'),
    ('TRY', 10, 'BANKNOTE'), ('TRY', 5, 'BANKNOTE'),
    -- CNY: 6 banknote
    ('CNY', 100, 'BANKNOTE'), ('CNY', 50, 'BANKNOTE'), ('CNY', 20, 'BANKNOTE'), ('CNY', 10, 'BANKNOTE'),
    ('CNY', 5, 'BANKNOTE'), ('CNY', 1, 'BANKNOTE'),
    -- BAM: 5 banknote
    ('BAM', 200, 'BANKNOTE'), ('BAM', 100, 'BANKNOTE'), ('BAM', 50, 'BANKNOTE'), ('BAM', 20, 'BANKNOTE'), ('BAM', 10, 'BANKNOTE'),
    -- THB: 5 banknote
    ('THB', 1000, 'BANKNOTE'), ('THB', 500, 'BANKNOTE'), ('THB', 100, 'BANKNOTE'), ('THB', 50, 'BANKNOTE'), ('THB', 20, 'BANKNOTE'),
    -- BRL: 7 banknote
    ('BRL', 200, 'BANKNOTE'), ('BRL', 100, 'BANKNOTE'), ('BRL', 50, 'BANKNOTE'), ('BRL', 20, 'BANKNOTE'),
    ('BRL', 10, 'BANKNOTE'), ('BRL', 5, 'BANKNOTE'), ('BRL', 2, 'BANKNOTE'),
    -- MXN: 6 banknote
    ('MXN', 1000, 'BANKNOTE'), ('MXN', 500, 'BANKNOTE'), ('MXN', 200, 'BANKNOTE'), ('MXN', 100, 'BANKNOTE'),
    ('MXN', 50, 'BANKNOTE'), ('MXN', 20, 'BANKNOTE'),
    -- NZD: 5 banknote
    ('NZD', 100, 'BANKNOTE'), ('NZD', 50, 'BANKNOTE'), ('NZD', 20, 'BANKNOTE'), ('NZD', 10, 'BANKNOTE'), ('NZD', 5, 'BANKNOTE')
) AS v(currency_code, face_value, denomination_type)
JOIN currency cur ON cur.code = v.currency_code
WHERE NOT EXISTS (
    SELECT 1 FROM denomination_allowed da
    WHERE da.company_id = c.id AND da.currency_id = cur.id AND da.face_value = v.face_value
);

COMMENT ON TABLE denomination_allowed IS
    'FK-076: uzletileg engedelyezett cimlet-katalogus (deviza-szintu, fiok-fuggetlen). '
    'HUF szandekosan nincs benne - a zaras-validacio HUF-ra ki van kapcsolva.';
