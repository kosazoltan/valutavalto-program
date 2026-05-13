-- V221: Kedvezmény jóváhagyási küszöbök (Sprint 4 P2-D)
-- v2.0 spec 03_tranzakciok.md alapján — 4 jóváhagyási szint

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES
    (gen_random_uuid(), 'DISCOUNT_SUPERVISOR_THRESHOLD_PCT', '2.0', 'STRING', 'TRANSACTION',
     'Kedvezmény % küszöb — efelett supervisor jóváhagyás kell', true, now(), 'SYSTEM'),
    (gen_random_uuid(), 'DISCOUNT_MANAGER_THRESHOLD_PCT', '5.0', 'STRING', 'TRANSACTION',
     'Kedvezmény % küszöb — efelett manager jóváhagyás kell', true, now(), 'SYSTEM'),
    (gen_random_uuid(), 'DISCOUNT_DIRECTOR_THRESHOLD_PCT', '10.0', 'STRING', 'TRANSACTION',
     'Kedvezmény % küszöb — efelett director jóváhagyás kell', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;
