-- V79: Legacy parity gaps — business logic closures
-- GAP 1: Daily discount limit tracking (napi kedvezmény limit pénztárosonként)
-- GAP 2: Raiffeisen max deviation system parameter
-- GAP 3: Reservation auto-expiry support (EXPIRED státusz)
-- GAP 4: Conversion linked receipt tracking (konverziós bizonylat pár)

-- ============================================================
-- GAP 1: Nincs új tábla szükséges — a meglévő transaction tábla
-- discount_percent > 0 AND worker_id + transaction_date kombóval
-- lekérdezhető. Lásd: TransactionRepository.countDailyDiscountsByWorker()
-- ============================================================

-- ============================================================
-- GAP 2: Raiffeisen max deviation system parameter
-- ============================================================
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
VALUES (
    gen_random_uuid(),
    'raiffeisen.max.deviation.percent',
    '10.0',
    'DECIMAL',
    'EXCHANGE_RATE',
    'Raiffeisen banki partnerség: maximális megengedett eltérés a középárfolyamtól (%). Minden valutára vonatkozik, felülírja az egyedi currency-szintű limitet ha ez kisebb.',
    true
) ON CONFLICT (parameter_key) DO NOTHING;

-- ============================================================
-- GAP 3: Reservation EXPIRED státusz hozzáadás
-- A reservation.status mező VARCHAR(30) CHECK nélkül — az enum
-- bővítés JPA szinten elegendő. Nincs DDL módosítás szükséges.
-- ============================================================

-- ============================================================
-- GAP 4: Konverziós bizonylat pár — linked_receipt_number mező
-- ============================================================
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS linked_receipt_number VARCHAR(20);
COMMENT ON COLUMN transaction.linked_receipt_number IS 'Konverziós bizonylat pár: a másik bizonylat száma (vétel↔eladás)';

CREATE INDEX IF NOT EXISTS idx_transaction_linked_receipt ON transaction(linked_receipt_number);
