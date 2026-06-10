-- V306: Sztornó 4-szem-elv enforcement élesítése (#954)
--
-- Tényalap (döntési lánc):
--  * A V305 ezt a flaget DEFER-rel kihagyta: „a storno four-eyes UI-készenlétére nincs
--    dokumentált evidence → DEFER (külön döntés)."
--  * Az evidence-hiány megszűnt (EXCMD/_compare/2026-06-10-storno-four-eyes-ui-evidence.md):
--    supervisor jóváhagyó-lista (GET /stornos/approvals/pending + StornoApprovalListPage).
--  * Üzleti döntés (Kósa Zoltán, 2026-06-10): a valutaváltó irodák jellemzően
--    EGYSZEMÉLYESEK, a supervisor-jóváhagyás telefonon, PIN-kóddal történik — ez a
--    flow implementálva: POST /stornos/approve-by-pin (pénztáros-sessionből hívható,
--    4-szem KEMÉNYEN + szerepkör + cég + SupervisorPinService lockout/audit) +
--    StornoPinApprovalModal a StornoPage-en. Az egyszemélyes-iroda blokkoló ezzel
--    megszűnt, a flag élesíthető.
--
-- Hatás: bekapcsolva a sztornó-jóváhagyásnál a kérelmező NEM hagyhatja jóvá a saját
-- kérését (StornoService.approve — pozitív jóváhagyást blokkol, saját elutasítás engedett).
-- A telefonos PIN-út (approveByPin) a 4-szem-elvet flag-től függetlenül, keményen tartatja.
--
-- Idempotens: a V291/V305 mintát követi (insert-if-missing + update-if-different).

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'STORNO_APPROVAL_FOUR_EYES_ENFORCEMENT', 'true', 'BOOLEAN', 'STORNO',
       '#954 4-szem-elv: a sztornó-jóváhagyás jóváhagyója nem lehet azonos a kérelmezővel '
       || '(független jóváhagyó — helyben vagy telefonos supervisor-PIN-nel). true = blokkol.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'STORNO_APPROVAL_FOUR_EYES_ENFORCEMENT'
);

UPDATE system_parameter
   SET parameter_value = 'true', is_active = true, updated_at = now(),
       updated_by = 'V306_migration'
 WHERE parameter_key = 'STORNO_APPROVAL_FOUR_EYES_ENFORCEMENT'
   AND parameter_value <> 'true';
