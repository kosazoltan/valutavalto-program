-- V307: Zárás eltérés-magyarázat gate élesítése (G3 / FR-13)
--
-- Tényalap:
--  * A G3 enforcement-lánc KÉSZ: ClosingWizardService.finalizeWizard — tolerancián túli
--    pénzügyi eltérésnél magyarázat-kötelezettség (closingDiscrepancyBlockReason), a
--    magyarázat perzisztált (closing_wizard.discrepancy_explanation, V257).
--  * A frontend explain-and-retry flow KÉSZ: ClosingWizardPage.handleFinalize — az
--    eltérés-hibaüzenetre magyarázatot kér és újraküld.
--  * A flaget azonban EGYETLEN migráció sem seedelte — a gate e nélkül sosem tudott
--    élesedni (a 2026-06-10-i flag-audit találata). A V305/V306 go-live mintát követjük.
--
-- Hatás: bekapcsolva a napzárás-véglegesítés tolerancián túli pénzügyi eltérésnél
-- (címletezett − várt készlet) magyarázat nélkül blokkol; magyarázattal átenged és auditál.
--
-- Idempotens: insert-if-missing + update-if-different (V291/V305/V306 minta).

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'CLOSING_DISCREPANCY_EXPLANATION_REQUIRED', 'true', 'BOOLEAN', 'CLOSING',
       'G3 (FR-13): napzárás-véglegesítésnél a tolerancián túli pénzügyi eltéréshez '
       || 'kötelező eltérés-magyarázat. true = magyarázat nélkül blokkol.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'CLOSING_DISCREPANCY_EXPLANATION_REQUIRED'
);

UPDATE system_parameter
   SET parameter_value = 'true', is_active = true, updated_at = now(),
       updated_by = 'V307_migration'
 WHERE parameter_key = 'CLOSING_DISCREPANCY_EXPLANATION_REQUIRED'
   AND parameter_value <> 'true';
