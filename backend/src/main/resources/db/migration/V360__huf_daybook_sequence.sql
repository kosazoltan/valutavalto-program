CREATE TABLE IF NOT EXISTS huf_daybook_sequence (
    company_id UUID NOT NULL,
    sequence_year INTEGER NOT NULL,
    last_value INTEGER NOT NULL,
    PRIMARY KEY (company_id, sequence_year)
);

ALTER TABLE shipment_request
    ADD COLUMN IF NOT EXISTS annual_journal_sequence INTEGER;
