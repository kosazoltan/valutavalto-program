-- Tenant + prefix szintu, atomikusan leptetett atadas-atvetel sorszam allapot.
-- Prefixek:
--   AT = deviza atadas, AV = deviza atvetel, FF = HUF atadas, UF = HUF atvetel

CREATE TABLE IF NOT EXISTS transfer_serial_sequence (
    company_id  UUID NOT NULL,
    prefix      VARCHAR(2) NOT NULL,
    last_value  BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (company_id, prefix),
    CONSTRAINT fk_transfer_serial_sequence_company
        FOREIGN KEY (company_id) REFERENCES company(id),
    CONSTRAINT ck_transfer_serial_sequence_prefix
        CHECK (prefix IN ('AT', 'AV', 'FF', 'UF')),
    CONSTRAINT ck_transfer_serial_sequence_last_value
        CHECK (last_value >= 0)
);

COMMENT ON TABLE transfer_serial_sequence IS 'Cegszintu, prefixenkent folyamatos atadas-atvetel sorszam allapot.';
COMMENT ON COLUMN transfer_serial_sequence.prefix IS 'AT=deviza atadas, AV=deviza atvetel, FF=HUF atadas, UF=HUF atvetel.';

INSERT INTO transfer_serial_sequence (company_id, prefix, last_value)
SELECT company_id, prefix, MAX(serial_number)
FROM (
    SELECT
        COALESCE(t.company_id, fb.company_id, tb.company_id) AS company_id,
        substring(t.transfer_number FROM '^([A-Z]{2})-') AS prefix,
        CAST(substring(t.transfer_number FROM '^[A-Z]{2}-([0-9]{6,})$') AS BIGINT) AS serial_number
    FROM transfer t
    LEFT JOIN branch fb ON fb.id = t.from_branch_id
    LEFT JOIN branch tb ON tb.id = t.to_branch_id
    WHERE t.transfer_number ~ '^[A-Z]{2}-[0-9]{6,}$'
      AND t.transfer_number NOT LIKE '%-SZ'
) existing_serials
WHERE company_id IS NOT NULL
  AND prefix IN ('AT', 'AV', 'FF', 'UF')
  AND serial_number IS NOT NULL
GROUP BY company_id, prefix
ON CONFLICT (company_id, prefix)
DO UPDATE SET last_value = GREATEST(transfer_serial_sequence.last_value, EXCLUDED.last_value);
