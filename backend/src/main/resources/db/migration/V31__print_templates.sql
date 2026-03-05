-- V31: Nyomtatási sablonok
-- Testreszabható nyomtatási sablonok (bizonylat, jelentés, címke, zárás)

CREATE TABLE IF NOT EXISTS print_template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    template_type VARCHAR(30) NOT NULL,
    content TEXT,
    is_default BOOLEAN NOT NULL DEFAULT false,
    company_id INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_print_template_type ON print_template(template_type);
CREATE INDEX idx_print_template_company ON print_template(company_id);
CREATE INDEX idx_print_template_default ON print_template(is_default);
