-- V225: Copilot P3 #580 follow-up — DISCOUNT_MAX_PCT seed
--
-- A V221 csak a 3 threshold-paramétert (SUPERVISOR/MANAGER/DIRECTOR) seedelte.
-- A DiscountApprovalService.validateApprovalLevel (Codex P2 #571 follow-up)
-- bevezetett egy 15%-os felső korlátot, de a system_parameter táblán nem volt
-- DISCOUNT_MAX_PCT sor → admin UI nem látta, nem tudta szerkeszteni (a default 15.0
-- a kódban hard-coded fallback maradt). Most már seedelve.

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES
    (gen_random_uuid(), 'DISCOUNT_MAX_PCT', '15.0', 'STRING', 'TRANSACTION',
     'Kedvezmény % felső korlát — efelett MINDEN szint elutasítja (üzleti policy max)', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;
