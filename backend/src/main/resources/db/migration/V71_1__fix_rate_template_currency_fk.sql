-- V71: Fix rate_template.currency_id type and FK compatibility with currency(id BIGINT)
-- Background: V52 created currency_id as UUID FK, while runtime schema uses BIGINT currency IDs.

DO $$
DECLARE
    v_data_type text;
    v_row_count bigint;
BEGIN
    SELECT c.data_type
      INTO v_data_type
      FROM information_schema.columns c
     WHERE c.table_schema = 'public'
       AND c.table_name = 'rate_template'
       AND c.column_name = 'currency_id';

    IF v_data_type = 'uuid' THEN
        EXECUTE 'SELECT COUNT(*) FROM rate_template' INTO v_row_count;

        IF v_row_count > 0 THEN
            RAISE EXCEPTION 'Migration V71 stopped: rate_template.currency_id is UUID and table has % rows. Manual data migration is required before type change.', v_row_count;
        END IF;

        ALTER TABLE rate_template
            DROP CONSTRAINT IF EXISTS rate_template_currency_id_fkey;

        ALTER TABLE rate_template
            ALTER COLUMN currency_id DROP NOT NULL;

        ALTER TABLE rate_template
            ALTER COLUMN currency_id TYPE BIGINT USING NULL;

        ALTER TABLE rate_template
            ALTER COLUMN currency_id SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'rate_template'
           AND column_name = 'currency_id'
           AND data_type = 'bigint'
    ) THEN
        ALTER TABLE rate_template
            DROP CONSTRAINT IF EXISTS rate_template_currency_id_fkey;

        ALTER TABLE rate_template
            ADD CONSTRAINT rate_template_currency_id_fkey
            FOREIGN KEY (currency_id) REFERENCES currency(id);
    END IF;
END $$;
