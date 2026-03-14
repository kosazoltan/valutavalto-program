-- V9__rate_management_tables.sql
-- Árfolyam kezelés: sablon, munkacsoport, publikálás, versenytárs árfolyam, történet
--
-- Legacy rendszer alapján (Delphi arftmk DLL):
-- - ARFOLYAM tábla: árfolyam törzs adatbázis (vételi, eladási, elszámolási, MNB)
-- - Munkacsoport (sajcsoport): irodák csoportosítása közös árfolyamokkal
-- - Árfolyam kiküldés: főértéktáros által készített árfolyamok küldése pénztáraknak

-- Árfolyam munkacsoportok
-- Legacy: _sajcsoport (1-54) — irodák csoportosítása közös árfolyamokkal
CREATE TABLE IF NOT EXISTS rate_workgroup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    legacy_group_number INTEGER,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Munkacsoport-iroda kapcsoló tábla
CREATE TABLE IF NOT EXISTS rate_workgroup_branch (
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE CASCADE,
    PRIMARY KEY (workgroup_id, branch_id)
);

-- Árfolyam sablonok
-- Legacy: az ARFOLYAM tábla rekordjai, amiket a főértéktáros készít
CREATE TABLE IF NOT EXISTS rate_template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    currency_id BIGINT NOT NULL,
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    base_buy_rate DECIMAL(18, 6) NOT NULL,
    base_sell_rate DECIMAL(18, 6) NOT NULL,
    buy_spread DECIMAL(18, 6) DEFAULT 0,
    sell_spread DECIMAL(18, 6) DEFAULT 0,
    rounding_rule INTEGER DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_by BIGINT,
    approved_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    published_at TIMESTAMP,
    CONSTRAINT chk_rate_template_status CHECK (status IN ('DRAFT', 'APPROVED', 'PUBLISHED', 'REVOKED'))
);

CREATE INDEX IF NOT EXISTS idx_rate_template_wg_status ON rate_template(workgroup_id, status);
CREATE INDEX IF NOT EXISTS idx_rate_template_currency ON rate_template(currency_id);

-- Árfolyam publikálási napló
-- Legacy: ArfolyamBeolvasas — FTP-n kiküldött NR*.DAT fájlok nyilvántartása
CREATE TABLE IF NOT EXISTS rate_publication (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES rate_template(id),
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    published_by BIGINT NOT NULL,
    published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    affected_branches INTEGER DEFAULT 0,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_rate_publication_wg ON rate_publication(workgroup_id);

-- Árfolyam kedvezmény szintek munkacsoport szintjén
CREATE TABLE IF NOT EXISTS rate_discount (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    level INTEGER NOT NULL DEFAULT 0,
    buy_discount_percent DECIMAL(10, 4) DEFAULT 0,
    sell_discount_percent DECIMAL(10, 4) DEFAULT 0,
    description VARCHAR(200),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rate_discount_wg ON rate_discount(workgroup_id);

-- Árfolyam történet (audit trail)
-- Legacy: minden árfolyam-változást naplóz
CREATE TABLE IF NOT EXISTS rate_history (
    id BIGSERIAL PRIMARY KEY,
    currency_code VARCHAR(3) NOT NULL,
    buy_rate DECIMAL(18, 6) NOT NULL,
    sell_rate DECIMAL(18, 6) NOT NULL,
    mnb_rate DECIMAL(18, 6),
    spread DECIMAL(10, 4),
    category VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    set_by BIGINT,
    approved_by BIGINT,
    branch_id UUID,
    company_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_rate_history_currency ON rate_history(currency_code);
CREATE INDEX IF NOT EXISTS idx_rate_history_dates ON rate_history(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_rate_history_company ON rate_history(company_id);
CREATE INDEX IF NOT EXISTS idx_rate_history_branch ON rate_history(branch_id);

-- Versenytárs árfolyamok (ha még nincs)
CREATE TABLE IF NOT EXISTS competitor_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competitor_id UUID NOT NULL REFERENCES competitor(id),
    currency_id BIGINT NOT NULL,
    buy_rate DECIMAL(18, 6),
    sell_rate DECIMAL(18, 6),
    rate_date DATE NOT NULL,
    source VARCHAR(100),
    created_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_competitor_rates_date ON competitor_rates(rate_date);
CREATE INDEX IF NOT EXISTS idx_competitor_rates_comp ON competitor_rates(competitor_id);

-- Árfolyam jóváhagyás (ha még nincs)
CREATE TABLE IF NOT EXISTS rate_approval (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    currency_code VARCHAR(3) NOT NULL,
    old_buy_rate DECIMAL(18, 6),
    old_sell_rate DECIMAL(18, 6),
    new_buy_rate DECIMAL(18, 6) NOT NULL,
    new_sell_rate DECIMAL(18, 6) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    requested_by_worker_id BIGINT,
    approved_by_worker_id BIGINT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    reason TEXT,
    CONSTRAINT chk_rate_approval_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

CREATE INDEX IF NOT EXISTS idx_rate_approval_status ON rate_approval(status);
CREATE INDEX IF NOT EXISTS idx_rate_approval_branch ON rate_approval(branch_id);

-- Árfolyam kategóriák (fiók szintű)
CREATE TABLE IF NOT EXISTS rate_category (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    currency_id BIGINT NOT NULL,
    category VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    min_amount DECIMAL(18, 2),
    max_amount DECIMAL(18, 2),
    buy_rate DECIMAL(18, 6),
    sell_rate DECIMAL(18, 6),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rate_category_type CHECK (category IN ('SMALL', 'STANDARD', 'LARGE'))
);

CREATE INDEX IF NOT EXISTS idx_rate_category_branch ON rate_category(branch_id, currency_id);
