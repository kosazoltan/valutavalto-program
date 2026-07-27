-- V362: FK-065 — beragadt zárási varázsló auto-lejárat küszöb-paramétere
--
-- Tényalap:
--  * A ClosingWizardService.autoExpireStaleWizards() a CLOSING_WIZARD_AUTO_EXPIRE_MINUTES
--    SystemParameter-ből olvassa a lejárati küszöböt (perc), kód-oldali default: 120.
--  * A paraméter seedelése nélkül a feature működik (default), de az érték nem látható /
--    nem állítható az admin felületen — a V307 (CLOSING_DISCREPANCY_EXPLANATION_REQUIRED)
--    go-live mintáját követve seedeljük.
--
-- Idempotens: insert-if-missing (V307 minta). SZÁNDÉKOSAN nincs update-if-different ág:
-- egy üzemeltető által átállított küszöböt újra-deploykor nem írunk felül.

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'CLOSING_WIZARD_AUTO_EXPIRE_MINUTES', '120', 'INTEGER', 'CLOSING',
       'FK-065: beragadt (IN_PROGRESS) zárási varázsló automatikus lejáratási küszöbe '
       || 'percben, az indítástól (started_at) számítva. A scheduler a küszöbnél régebben '
       || 'indított varázslókat EXPIRED státuszra állítja.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'CLOSING_WIZARD_AUTO_EXPIRE_MINUTES'
);
