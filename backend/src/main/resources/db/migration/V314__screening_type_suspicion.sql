-- V314: customer_screening_log.screening_type CHECK bővítése a SUSPICION típussal
--
-- A b9-korlevelek FR-03 gyanú-bejelentés (SAR) SUSPICION típusú screening-log
-- rekordot ír; a V12 eredeti CHECK-je (SANCTION/AML/ANNUAL_CHECK) ezt futásidőben
-- elutasítaná (Codex P1 finding a #1086 review-ban). A constraint nevét a Postgres
-- auto-generálta (tábla_oszlop_check) — idempotensen cseréljük.

ALTER TABLE customer_screening_log
    DROP CONSTRAINT IF EXISTS customer_screening_log_screening_type_check;

ALTER TABLE customer_screening_log
    ADD CONSTRAINT customer_screening_log_screening_type_check
    CHECK (screening_type IN ('SANCTION', 'AML', 'ANNUAL_CHECK', 'SUSPICION'));
