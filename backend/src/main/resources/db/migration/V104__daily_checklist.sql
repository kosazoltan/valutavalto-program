-- V104: Napi nyitási checklist (legacy: CHECKLST.DLL)
-- 19 tételes ellenőrzőlista amit a pénztáros minden nap kitölt nyitáskor.

CREATE TABLE daily_checklist (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL REFERENCES company(id),
    branch_id       UUID NOT NULL REFERENCES branch(id),
    checklist_date  DATE NOT NULL,
    worker_id       BIGINT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    completed_at    TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT uq_daily_checklist_branch_date
        UNIQUE (branch_id, checklist_date, company_id)
);

CREATE TABLE daily_checklist_item (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checklist_id            UUID NOT NULL REFERENCES daily_checklist(id) ON DELETE CASCADE,
    item_number             INT NOT NULL,
    item_title              VARCHAR(200) NOT NULL,
    item_description        VARCHAR(500),
    checked                 BOOLEAN NOT NULL DEFAULT FALSE,
    checked_at              TIMESTAMP,
    checked_by_worker_id    BIGINT,
    notes                   VARCHAR(500),

    CONSTRAINT uq_checklist_item_number
        UNIQUE (checklist_id, item_number)
);

-- Indexek a gyakori lekérdezésekhez
CREATE INDEX idx_daily_checklist_branch_date ON daily_checklist(branch_id, checklist_date);
CREATE INDEX idx_daily_checklist_company ON daily_checklist(company_id);
CREATE INDEX idx_daily_checklist_item_checklist ON daily_checklist_item(checklist_id);
