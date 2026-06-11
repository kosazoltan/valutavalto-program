-- V309: Megerősített eljárás (EDD) 1 éves követési ablak az ügyfélen (EBC szabályzat V.2.7)
--
-- Szabály (Pmt. + EBC ZRT pénzmosási szabályzat V.2.7): megerősített eljárás alá kerül
-- 1 évre az ügyfél, ha a) >=50M Ft egyedi tranzakció; b) >=100M Ft havi készpénzforgalom;
-- c) Pmt. 30.§ (1) bejelentett. Az ügylet-elemzés 30 munkanapon belül írásban, megőrzés 8 év.
--
-- Implementáció: AmlEddService (napi ütemezett scan, AmlEddScheduler) jelöli az ügyfelet;
-- az AmlService.checkAllThresholds az aktív ablakot fokozott átvilágításként érvényesíti.
-- A 2026-06-03-as AML-go-live-terv 4) pontja ([M]).

-- 1) EDD-ablak mezők a customer táblán (additív, zero-downtime)
ALTER TABLE customer ADD COLUMN IF NOT EXISTS edd_until DATE;
ALTER TABLE customer ADD COLUMN IF NOT EXISTS edd_reason VARCHAR(500);
ALTER TABLE customer ADD COLUMN IF NOT EXISTS edd_set_at TIMESTAMP;

COMMENT ON COLUMN customer.edd_until IS
    'Megerősített eljárás (V.2.7) 1 éves ablakának vége — amíg >= mai nap, fokozott átvilágítás kötelező';
COMMENT ON COLUMN customer.edd_reason IS
    'Az EDD-ablak indoka (pl. >=50M egyedi tranzakció / >=100M havi készpénzforgalom)';
COMMENT ON COLUMN customer.edd_set_at IS
    'Az EDD-ablak (utolsó) beállításának időpontja';

-- 2) Detektálási flag (idempotens seed, default KIKAPCSOLVA — élesítés üzleti döntés,
--    a V.2.7 b) havi kumulált detektálás bekapcsolása a compliance-vezető jóváhagyásával)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_EDD_TRACKING_ENFORCEMENT', 'false', 'BOOLEAN', 'AML',
       'V.2.7: megerősített eljárás (EDD) automatikus követése — napi scan jelöli az ügyfélen '
       || 'az 1 éves ablakot (>=50M egyedi / >=100M havi készpénzforgalom). false = scan kikapcsolva.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_EDD_TRACKING_ENFORCEMENT'
);
