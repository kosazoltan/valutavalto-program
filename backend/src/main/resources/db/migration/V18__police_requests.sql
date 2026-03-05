-- V18: Rendőrségi adatkérés (Police Request)
-- Hatósági megkeresések nyilvántartása és feldolgozása

CREATE TABLE police_request (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_number  VARCHAR(100) NOT NULL,
    request_date    DATE NOT NULL,
    requested_by    VARCHAR(200) NOT NULL,
    customer_name   VARCHAR(200),
    document_number VARCHAR(100),
    date_range_from DATE,
    date_range_to   DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'RECEIVED',
    response_data   TEXT,
    completed_at    TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP,
    created_by      BIGINT REFERENCES worker(id)
);

CREATE INDEX idx_police_request_status ON police_request(status);
CREATE INDEX idx_police_request_date ON police_request(request_date);
CREATE INDEX idx_police_request_number ON police_request(request_number);
