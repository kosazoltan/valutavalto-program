-- V305: AML go-live enforcement flagek élesítése (EXCMD/2026-06-03_AML-go-live-terv.md)
--
-- Tényalap (döntési lánc):
--  * User-direktíva a go-live tervben: „élesítsd teljesen" — a terv szerint minden flag a
--    bekötés + UI + teszt UTÁN seed-elhető true-ra, a V291 (AML_SOURCE_OF_FUNDS_50M) mintájára.
--  * EXCMD/_ai-protokoll/2026-06-04-excmd-teljes-audit-statusz-es-javitas.md (kód-elleni
--    reverifikáció): A1 FATF tier-bekötés KÉSZ (AmlService.checkTransaction nationality-vel,
--    minden hívó átadja); A7 vezetői jóváhagyás flow KÉSZ (AmlApprovalController +
--    AmlApproverModal + tranzakciós bekötés + local-first sync); A4 körlevél-blokkolás KÉSZ.
--  * STORNO_APPROVAL_FOUR_EYES_ENFORCEMENT és PMT_STRICT_ENFORCEMENT NEM része ennek a
--    migrációnak: a PMT_STRICT kód-defaultja már "true"; a storno four-eyes UI-készenlétére
--    nincs dokumentált evidence → DEFER (külön döntés).
--
-- Idempotens: a V291 mintát követi (insert-if-missing + update-if-different).

-- 1) FATF magas-kockázatú harmadik ország tier-akciók (Pmt./MNB 14/2025 V.2.6-2.7)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_FATF_TIER_ENFORCEMENT', 'true', 'BOOLEAN', 'AML',
       'Pmt./MNB 14/2025 V.2.6-2.7: FATF tier-akciók kényszerítése (TIER_1A vezetői jóváhagyás, '
       || 'TIER_1B EDD+SOF, >=5M Ft magas-kockázatú ország megerősített eljárás). true = blokkol/kényszerít.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_FATF_TIER_ENFORCEMENT'
);

UPDATE system_parameter
   SET parameter_value = 'true', is_active = true, updated_at = now(),
       updated_by = 'V305_migration'
 WHERE parameter_key = 'AML_FATF_TIER_ENFORCEMENT'
   AND parameter_value <> 'true';

-- 2) 10M+ / fokozott tranzakció kötelező vezetői jóváhagyása (Pmt. 14/A. § (4), szabályzat V.2.6)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_HIGH_VALUE_APPROVAL_ENFORCEMENT', 'true', 'BOOLEAN', 'AML',
       'Pmt. 14/A. § (4): 10M+ / fokozott tranzakcióhoz kötelező írásos felsővezetői jóváhagyás '
       || '(supervisor-jóváhagyó flow, jóváhagyó neve a tranzakción). true = jóváhagyás nélkül blokkol.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_HIGH_VALUE_APPROVAL_ENFORCEMENT'
);

UPDATE system_parameter
   SET parameter_value = 'true', is_active = true, updated_at = now(),
       updated_by = 'V305_migration'
 WHERE parameter_key = 'AML_HIGH_VALUE_APPROVAL_ENFORCEMENT'
   AND parameter_value <> 'true';

-- 3) Kötelező körlevél-nyugtázás tranzakció-blokkolása (b9-korlevelek FR-02)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'CIRCULAR_ACK_BLOCKING_ENFORCEMENT', 'true', 'BOOLEAN', 'AML',
       'b9-korlevelek FR-02: nyugtázatlan kötelező körlevél esetén a tranzakció-indítás blokkolása. '
       || 'true = blokkol nyugtázásig.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'CIRCULAR_ACK_BLOCKING_ENFORCEMENT'
);

UPDATE system_parameter
   SET parameter_value = 'true', is_active = true, updated_at = now(),
       updated_by = 'V305_migration'
 WHERE parameter_key = 'CIRCULAR_ACK_BLOCKING_ENFORCEMENT'
   AND parameter_value <> 'true';
