#!/bin/bash
# pgAudit extension telepitese a Docker PostgreSQL kontenerben
# Ez a script automatikusan lefut az elso indulaskor (docker-entrypoint-initdb.d)
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pgaudit;
    -- Audit log: minden DDL + ROLE + WRITE muvelet logolva lesz
    -- Lasd: postgresql-custom.conf a reszletes beallitasokhoz
EOSQL

echo "pgAudit extension sikeresen telepitve."
