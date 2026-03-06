-- V47: Kis ügyfél típus + kedvezmény threshold paraméterek
-- Legacy: KISUGYFEL + BIGARFVALT/KISARFVALT

-- Ügyfél típus mező (FULL / SIMPLIFIED)
ALTER TABLE customer ADD COLUMN IF NOT EXISTS customer_type VARCHAR(20) NOT NULL DEFAULT 'FULL';

-- Kedvezmény threshold system paraméterek
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
VALUES
    (gen_random_uuid(), 'BIG_DISCOUNT_THRESHOLD_HUF', '500000', 'INTEGER', 'DISCOUNT',
     'Nagy összegű kedvezmény küszöb (Ft) — felette automatikus kedvezmény', true),
    (gen_random_uuid(), 'SMALL_SURCHARGE_THRESHOLD_HUF', '10000', 'INTEGER', 'DISCOUNT',
     'Kis összegű felár küszöb (Ft) — alatta automatikus felár', true),
    (gen_random_uuid(), 'BIG_DISCOUNT_CODE', 'NAGY_OSSZEG', 'STRING', 'DISCOUNT',
     'Nagy összegű kedvezmény kódja (fee_discount tábla)', true),
    (gen_random_uuid(), 'SMALL_SURCHARGE_CODE', 'KIS_OSSZEG', 'STRING', 'DISCOUNT',
     'Kis összegű felár kódja (fee_discount tábla)', true),
    (gen_random_uuid(), 'SIMPLIFIED_CUSTOMER_THRESHOLD_HUF', '300000', 'INTEGER', 'CUSTOMER',
     'Egyszerűsített ügyfél küszöb — alatta nem kell teljes KYC', true)
ON CONFLICT DO NOTHING;

-- Alapértelmezett kedvezmény/felár rekordok
INSERT INTO fee_discount (id, code, name, discount_type, discount_value, is_active, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'NAGY_OSSZEG', 'Nagy összegű kedvezmény (500.000 Ft+)', 'PERCENT', 50.0, true, now(), now()),
    (gen_random_uuid(), 'KIS_OSSZEG', 'Kis összegű felár (10.000 Ft-)', 'SURCHARGE_FIXED', 200.0, true, now(), now())
ON CONFLICT (code) DO NOTHING;
