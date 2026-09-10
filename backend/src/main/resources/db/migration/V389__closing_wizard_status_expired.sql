-- FKH-061 / Defect B: allow the EXPIRED wizard status.
--
-- WHY: entity WizardStatus declares five values (IN_PROGRESS, COMPLETED, FAILED, CANCELLED,
-- EXPIRED) and ClosingWizardService.autoExpireStaleWizards writes EXPIRED through
-- ClosingWizardRepository.transitionIfStale. In production a CHECK constraint named
-- closing_wizard_wizard_status_check allows only the first four values, so the scheduled
-- auto-expiry (SchedulerService, cron "0 */30 * * * *") aborted every 30 minutes with
-- "new row for relation closing_wizard violates check constraint", poisoning the scheduler
-- transaction (SQLSTATE 25P02). Consequence: zero EXPIRED rows can exist, stale IN_PROGRESS
-- wizards never expire, and the EXPIRED fallback branch in ClosingWizardService is dead code.
--
-- SCOPE: constraint definition only. No row is inserted, updated or deleted; no money data and
-- no company_id scoping is involved.
--
-- IDEMPOTENCY / DRIFT NOTE: V75__missing_secondary_tables.sql creates closing_wizard.wizard_status
-- as a plain VARCHAR(20) with NO check constraint, and no later migration adds one. The production
-- constraint is therefore schema drift introduced outside Flyway. This migration must succeed on
-- BOTH shapes: DROP ... IF EXISTS is a no-op on a freshly migrated database and removes the
-- drifted constraint in production, after which the canonical five-value constraint is added.
-- Re-running the pair is safe.

ALTER TABLE closing_wizard
    DROP CONSTRAINT IF EXISTS closing_wizard_wizard_status_check;

ALTER TABLE closing_wizard
    ADD CONSTRAINT closing_wizard_wizard_status_check
    CHECK (wizard_status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED', 'EXPIRED'));
