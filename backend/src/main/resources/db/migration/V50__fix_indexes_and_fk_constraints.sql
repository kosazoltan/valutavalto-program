-- V50: Hianyzo osszetett indexek es FK constraintek javitasa
-- Code review: round 2-5 eredmenye alapjan

-- =============================================
-- 1. OSSZETETT INDEXEK — gyakori lekerdezesekhez
-- =============================================

-- Napi tranzakciok lekerdezese branch + datum alapjan
CREATE INDEX IF NOT EXISTS idx_transaction_branch_date
    ON transaction(branch_id, transaction_date);

-- Aktualis arfolyam keresese currency + datum alapjan
CREATE INDEX IF NOT EXISTS idx_exchange_rate_currency_date
    ON exchange_rate(currency_id, valid_date);

-- Kassza esemenyek idoszakos lekerdezese
CREATE INDEX IF NOT EXISTS idx_cash_register_event_branch_ts
    ON cash_register_event(branch_id, event_timestamp);

-- Worker aktiv szures (gyakran hasznalt filter)
CREATE INDEX IF NOT EXISTS idx_worker_active
    ON worker(active);

-- =============================================
-- 2. HIANYZO FK CONSTRAINTEK
-- =============================================

-- V15: worker_attendance.branch_id -> branch(id)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_worker_attendance_branch' AND table_name = 'worker_attendance') THEN
        ALTER TABLE worker_attendance
            ADD CONSTRAINT fk_worker_attendance_branch
            FOREIGN KEY (branch_id) REFERENCES branch(id);
    END IF;
END $$;

-- V15: worker_break.branch_id -> branch(id)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_worker_break_branch' AND table_name = 'worker_break') THEN
        ALTER TABLE worker_break
            ADD CONSTRAINT fk_worker_break_branch
            FOREIGN KEY (branch_id) REFERENCES branch(id);
    END IF;
END $$;

-- V16: stamp_batch.company_id -> company(id)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_stamp_batch_company' AND table_name = 'stamp_batch') THEN
        ALTER TABLE stamp_batch
            ADD CONSTRAINT fk_stamp_batch_company
            FOREIGN KEY (company_id) REFERENCES company(id);
    END IF;
END $$;

-- V16: stamp_batch.branch_id -> branch(id)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_stamp_batch_branch' AND table_name = 'stamp_batch') THEN
        ALTER TABLE stamp_batch
            ADD CONSTRAINT fk_stamp_batch_branch
            FOREIGN KEY (branch_id) REFERENCES branch(id);
    END IF;
END $$;

-- V22: worker_competition_entry.worker_id -> worker(id)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_comp_entry_worker' AND table_name = 'worker_competition_entry') THEN
        ALTER TABLE worker_competition_entry
            ADD CONSTRAINT fk_comp_entry_worker
            FOREIGN KEY (worker_id) REFERENCES worker(id);
    END IF;
END $$;

-- V45: daily_balance.branch_id -> branch(id)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_daily_balance_branch' AND table_name = 'daily_balance') THEN
        ALTER TABLE daily_balance
            ADD CONSTRAINT fk_daily_balance_branch
            FOREIGN KEY (branch_id) REFERENCES branch(id);
    END IF;
END $$;
