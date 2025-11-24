-- Fix valuta_data.sql UUID issues
-- Replace uuid_generate_v7() with gen_random_uuid()

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Minden uuid_generate_v7() hívást cseréljünk gen_random_uuid()-re
-- Ez egy egyszerű sed/PowerShell cserével megoldható

-- PowerShell command:
-- (Get-Content backend_deployment\pgsql\valuta_data.sql) -replace 'uuid_generate_v7\(\)', 'gen_random_uuid()' | Set-Content database\migrations\002_valuta_fixed.sql
