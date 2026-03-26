-- V122: Ensure receipt_sequence rows exist for ALL branches (V42 only seeded branches existing at that time)
-- This fixes: "Bizonylat szekvencia nem találhatob branch-hez" for branches created after V42
-- NOTE: receipt_sequence has no UNIQUE constraint on branch_id (only a btree index),
--       so we use NOT IN subquery instead of ON CONFLICT

INSERT INTO receipt_sequence (branch_id)
SELECT id FROM branch
WHERE id NOT IN (SELECT branch_id FROM receipt_sequence);
