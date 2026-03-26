-- V122: Ensure receipt_sequence rows exist for ALL branches (V42 only seeded branches existing at that time)
-- This fixes: "Bizonylat szekvencia nem található branch-hez" for branches created after V42

INSERT INTO receipt_sequence (branch_id)
SELECT id FROM branch
WHERE id NOT IN (SELECT branch_id FROM receipt_sequence)
ON CONFLICT (branch_id) DO NOTHING;
