-- V100: Fix transfer status CHECK constraint to match Java TransferStatus enum
-- Root cause: DB had DRAFT/SENT/CONFIRMED, Java enum has PENDING/COMPLETED/REJECTED
-- Merge both sets to support existing data + new code

ALTER TABLE transfer DROP CONSTRAINT IF EXISTS chk_transfer_status;
ALTER TABLE transfer ADD CONSTRAINT chk_transfer_status
  CHECK (status IN ('PENDING', 'DRAFT', 'SENT', 'IN_TRANSIT', 'RECEIVED', 'COMPLETED', 'CONFIRMED', 'REJECTED', 'CANCELLED'));
