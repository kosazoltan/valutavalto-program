-- V310: EDD-követés (V.2.7) élesítése — AML_EDD_TRACKING_ENFORCEMENT = true
--
-- A V309 a flaget default FALSE-szal seedelte (élesítés = compliance-vezetői döntés).
-- A jóváhagyás megtörtént (Kósa Zoltán ügyvezető, 2026-06-11), így a napi EDD-scan
-- (AmlEddScheduler 07:45) mostantól jelöli az 1 éves ablakokat:
--   a) >=50M Ft egyedi tranzakció; b) >=100M Ft naptári havi készpénzforgalom.
-- A V307/V308 idempotens aktiválási mintát követi.

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_EDD_TRACKING_ENFORCEMENT', 'true', 'BOOLEAN', 'AML',
       'V.2.7: megerősített eljárás (EDD) automatikus követése — napi scan jelöli az ügyfélen '
       || 'az 1 éves ablakot (>=50M egyedi / >=100M havi készpénzforgalom). true = scan aktív.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_EDD_TRACKING_ENFORCEMENT'
);

UPDATE system_parameter
   SET parameter_value = 'true', is_active = true, updated_at = now(),
       updated_by = 'V310_migration'
 WHERE parameter_key = 'AML_EDD_TRACKING_ENFORCEMENT'
   AND parameter_value <> 'true';
