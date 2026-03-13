-- V0.1: Base foundation tables (needed by V1_1+ migrations)
-- Creates company, branch, dictionary before incremental migrations run.
-- These tables use UUID primary keys as per Java entities.
-- Idempotent: all statements use IF NOT EXISTS.

-- Enable UUID extension (usually already enabled on Render Postgres)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Dictionary table (lookup values, no FK dependencies)
CREATE TABLE IF NOT EXISTS dictionary (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category    VARCHAR(100) NOT NULL,
    code        VARCHAR(50)  NOT NULL,
    name        VARCHAR(255) NOT NULL,
    name_hu     VARCHAR(255),
    description TEXT,
    sort_order  INTEGER DEFAULT 0,
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP,
    CONSTRAINT uk_dictionary_category_code UNIQUE (category, code)
);

-- Company table (top-level tenant)
CREATE TABLE IF NOT EXISTS company (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                 VARCHAR(255) NOT NULL,
    tax_number           VARCHAR(20),
    registration_number  VARCHAR(50),
    address              TEXT,
    phone                VARCHAR(50),
    email                VARCHAR(255),
    is_active            BOOLEAN DEFAULT TRUE,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP
);

-- Branch table (depends on company and dictionary)
CREATE TABLE IF NOT EXISTS branch (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code               VARCHAR(20)  NOT NULL,
    company_id         UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    bank_code          VARCHAR(20)  NOT NULL DEFAULT '',
    branch_type_did    UUID REFERENCES dictionary(id),
    parent_branch_id   UUID REFERENCES branch(id),
    name               VARCHAR(255) NOT NULL,
    address            TEXT NOT NULL DEFAULT '',
    city               VARCHAR(100) NOT NULL DEFAULT '',
    zip_code           VARCHAR(10)  NOT NULL DEFAULT '',
    country_did        UUID REFERENCES dictionary(id),
    phone              VARCHAR(50),
    email              VARCHAR(255),
    branch_status_did  UUID REFERENCES dictionary(id),
    opening_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    is_active          BOOLEAN DEFAULT TRUE,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP,
    CONSTRAINT uk_branch_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS idx_branch_company ON branch(company_id);
CREATE INDEX IF NOT EXISTS idx_branch_active   ON branch(is_active);
