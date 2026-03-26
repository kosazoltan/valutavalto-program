-- V123: Ensure receipt_sequence rows exist for ALL branches (V42 only seeded branches existing at that time)
-- This fixes: "Bizonylat szekvencia nem talalhato branch-hez" for branches created after V42
-- All sequence counters start at 100000 (matching entity @Builder.Default)

INSERT INTO receipt_sequence (
    branch_id,
    last_buy_receipt,
    last_sell_receipt,
    last_transfer_out_receipt,
    last_transfer_in_receipt,
    last_forint_transfer_out_receipt,
    last_forint_transfer_in_receipt,
    last_conversion_receipt
)
SELECT id, 100000, 100000, 100000, 100000, 100000, 100000, 100000
FROM branch
WHERE id NOT IN (SELECT branch_id FROM receipt_sequence);
