-- V238: Currency audit log (Pmt./NAV 8-eves megorzes)
--
-- Kosa Zoltan user-direktiva (2026-05-19): "az adatbazisban mindig mindent
-- meg kell orizni, tehat itt az Arfolyamkeszitoben kert valuta fajta
-- modositasok, legyenek lehetsegesek, de az adatbazisbol nem torolhet
-- semmit, legfeljebb onnantol kezdve, amit kivett valutanemeket nem
-- modositja, nem boviti, de ott kell, hogy maradjanak az adatbazisban
-- 8 evig."
--
-- A currency_audit_log immutable tabla rogzit minden Currency modositast:
-- - CREATE: uj valuta hozzaadasa
-- - ACTIVATE: deaktivalt valuta visszaaktivalasa
-- - DEACTIVATE: valuta inaktivalasa (NEM DELETE)
-- - UPDATE: nev / decimal_places / display_order modositasa
--
-- A `worker_id` rgzti hogy melyik foertekitaros/ugyvezeto vegezte a muveletet
-- (Pmt./NAV-compliance: ki, mikor, mit modositott).

CREATE TABLE IF NOT EXISTS currency_audit_log (
    id              BIGSERIAL PRIMARY KEY,
    currency_id     BIGINT NOT NULL REFERENCES currency(id),
    currency_code   VARCHAR(10) NOT NULL,  -- snapshot (a Currency.code potencialisan modosulhat)
    action          VARCHAR(20) NOT NULL CHECK (action IN ('CREATE', 'ACTIVATE', 'DEACTIVATE', 'UPDATE')),
    old_value       JSONB,                  -- elozo allapot JSON-ben (NULL CREATE eseten)
    new_value       JSONB NOT NULL,         -- uj allapot JSON-ben
    worker_id       BIGINT REFERENCES worker(id),
    company_id      UUID REFERENCES company(id),
    ip_address      VARCHAR(45),            -- IPv4 vagy IPv6
    user_agent      VARCHAR(500),
    note            TEXT,                   -- opcionalis indoklas
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_currency_audit_log_currency
    ON currency_audit_log(currency_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_currency_audit_log_worker
    ON currency_audit_log(worker_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_currency_audit_log_action
    ON currency_audit_log(action, created_at DESC);

-- Immutable trigger: UPDATE/DELETE tiltott (V234 audit_log mintajara)
CREATE OR REPLACE FUNCTION currency_audit_log_immutable_guard()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'currency_audit_log: UPDATE tiltott (immutable Pmt./NAV-compliance)';
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'currency_audit_log: DELETE tiltott (8-eves megorzes Pmt. tv.)';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS currency_audit_log_immutable ON currency_audit_log;
CREATE TRIGGER currency_audit_log_immutable
    BEFORE UPDATE OR DELETE ON currency_audit_log
    FOR EACH ROW EXECUTE FUNCTION currency_audit_log_immutable_guard();

COMMENT ON TABLE currency_audit_log IS
    'V238 (2026-05-19): Currency modositasok immutable audit log. Pmt./NAV 8-eves megorzes.';
COMMENT ON COLUMN currency_audit_log.action IS
    'CREATE/ACTIVATE/DEACTIVATE/UPDATE - a Currency entity allapot-valtozasa';
COMMENT ON COLUMN currency_audit_log.old_value IS
    'JSONB: a Currency entity AZON pillanatban valo allapota MIELOTT az action lefutott (CREATE eseten NULL)';
COMMENT ON COLUMN currency_audit_log.new_value IS
    'JSONB: a Currency entity allapota MIUTAN az action lefutott';
