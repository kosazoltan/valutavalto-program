-- ============================================
-- V34: Scheduler — Időzített feladatok
-- ============================================

CREATE TABLE scheduled_task (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_name VARCHAR(100) NOT NULL,
    cron_expression VARCHAR(50) NOT NULL,
    task_type VARCHAR(30) NOT NULL CHECK (task_type IN ('RATE_SYNC', 'BACKUP', 'REPORT', 'CLOSING_REMINDER', 'HEALTH_CHECK')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_run_at TIMESTAMP,
    next_run_at TIMESTAMP,
    last_result VARCHAR(20) CHECK (last_result IN ('SUCCESS', 'FAILURE', 'SKIPPED')),
    parameters JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scheduled_task_type ON scheduled_task(task_type);
CREATE INDEX idx_scheduled_task_active ON scheduled_task(is_active);
CREATE INDEX idx_scheduled_task_next_run ON scheduled_task(next_run_at);

COMMENT ON TABLE scheduled_task IS 'Időzített feladatok — cron alapú rendszer automatizáció';
