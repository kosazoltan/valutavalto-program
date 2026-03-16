-- WuCustomer deduplikáció: UNIQUE constraint a (company_id, last_name, first_name, id_number) oszlopokra
-- Csak a nem-null id_number rekordokra vonatkozik (partial unique index)
CREATE UNIQUE INDEX IF NOT EXISTS uq_wu_customer_company_name_idnum
    ON wu_customers(company_id, last_name, first_name, id_number)
    WHERE id_number IS NOT NULL AND id_number != '';
