-- V313: Szakmai bizonyítványok mezők az employee táblán
-- EXCMD b9-munkavallalo FR-03 (Becsüs / Eladói / Valutapénztárosi bizonyítvány)

ALTER TABLE employee
    ADD COLUMN IF NOT EXISTS appraiser_certificate_number VARCHAR(100),
    ADD COLUMN IF NOT EXISTS appraiser_certificate_date   DATE,
    ADD COLUMN IF NOT EXISTS seller_certificate_number    VARCHAR(100),
    ADD COLUMN IF NOT EXISTS seller_certificate_date      DATE,
    ADD COLUMN IF NOT EXISTS cashier_certificate_number   VARCHAR(100),
    ADD COLUMN IF NOT EXISTS cashier_certificate_date     DATE;

COMMENT ON COLUMN employee.appraiser_certificate_number IS 'Becsüs bizonyítvány száma (b9 FR-03)';
COMMENT ON COLUMN employee.appraiser_certificate_date   IS 'Becsüs bizonyítvány megszerzési/érvényességi dátuma (b9 FR-03)';
COMMENT ON COLUMN employee.seller_certificate_number    IS 'Eladói bizonyítvány száma (b9 FR-03)';
COMMENT ON COLUMN employee.seller_certificate_date      IS 'Eladói bizonyítvány megszerzési/érvényességi dátuma (b9 FR-03)';
COMMENT ON COLUMN employee.cashier_certificate_number   IS 'Valutapénztárosi bizonyítvány száma (b9 FR-03)';
COMMENT ON COLUMN employee.cashier_certificate_date     IS 'Valutapénztárosi bizonyítvány megszerzési/érvényességi dátuma (b9 FR-03)';
