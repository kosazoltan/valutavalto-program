-- PP-11 fix: audit_log_immutable trigger helyes TG_OP-alapu NEW/OLD hivatkozassal.
-- DELETE triggerben a NEW rekord nincs inicializalva (PostgreSQL PL/pgSQL specifikacio
-- szerint DELETE-nel NEW == NULL/unassigned) -- COALESCE(OLD.id, NEW.id) PL/pgSQL
-- hibat dobna "record new is not assigned yet". Fix: TG_OP === 'DELETE' ag csak OLD-ra
-- hivatkozik. Az UPDATE ag valtozatlan (COALESCE OLD/NEW mindketto elerheto).
-- A fuggveny CREATE OR REPLACE-el frissitheto a mar futtatott V234 utan is.

CREATE OR REPLACE FUNCTION audit_log_immutable() RETURNS TRIGGER AS $$
DECLARE
    v_id     TEXT;
    v_action TEXT;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_id     := COALESCE(OLD.id::TEXT, 'unknown');
        v_action := COALESCE(OLD.action, 'unknown');
    ELSE
        -- UPDATE: mind OLD mind NEW elerheto
        v_id     := COALESCE(OLD.id::TEXT, NEW.id::TEXT, 'unknown');
        v_action := COALESCE(OLD.action, NEW.action, 'unknown');
    END IF;

    RAISE EXCEPTION 'audit_log immutable: % operation not allowed (id=%, action=%)',
        TG_OP, v_id, v_action;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
