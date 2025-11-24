-- =============================================================================
-- Migration: 001_initial_schema.sql
-- Description: Valutaváltó rendszer teljes adatbázis schema
-- Author: Copilot + Kósa Zoltán
-- Date: 2025-11-24
-- =============================================================================

-- PostgreSQL Extensions
-- CREATE EXTENSION IF NOT EXISTS pg_uuidv7;  -- Nem elérhető Render-ben
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- AES-256 titkosításhoz

-- =============================================================================
-- PROHIBITED LISTS (AML/Terror ellenőrzés - MNB által kiadott listák)
-- =============================================================================

-- Tiltott személyek lista (MNB compliance)
DROP TABLE IF EXISTS "prohibited_person" CASCADE;
CREATE TABLE "prohibited_person" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "full_name" VARCHAR(255) NOT NULL,
    "birth_date" DATE,
    "nationality" VARCHAR(100),
    "passport_number" VARCHAR(50),
    "identity_number" VARCHAR(50),
    "address" TEXT,
    "list_type" VARCHAR(50) NOT NULL,  -- 'AML', 'TERROR', 'SANCTION'
    "list_source" VARCHAR(100) NOT NULL,  -- 'MNB', 'EU', 'UN', 'OFAC'
    "added_date" timestamp DEFAULT NOW() NOT NULL,
    "updated_date" timestamp,
    "notes" TEXT,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp DEFAULT NOW() NOT NULL,
    "updated_at" timestamp DEFAULT NOW()
);

CREATE INDEX idx_prohibited_person_name ON "prohibited_person" (full_name);
CREATE INDEX idx_prohibited_person_passport ON "prohibited_person" (passport_number);
CREATE INDEX idx_prohibited_person_identity ON "prohibited_person" (identity_number);
CREATE INDEX idx_prohibited_person_active ON "prohibited_person" (is_active);

COMMENT ON TABLE "prohibited_person" IS 'MNB által kiadott tiltott személyek listája (AML/terror screening)';
COMMENT ON COLUMN "prohibited_person"."list_type" IS 'Lista típusa: AML (pénzmosás), TERROR (terrorizmus), SANCTION (szankció)';

-- Tiltott cégek lista (MNB compliance)
DROP TABLE IF EXISTS "prohibited_company" CASCADE;
CREATE TABLE "prohibited_company" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "company_name" VARCHAR(255) NOT NULL,
    "registration_number" VARCHAR(50),
    "tax_number" VARCHAR(50),
    "country" VARCHAR(100),
    "address" TEXT,
    "list_type" VARCHAR(50) NOT NULL,  -- 'AML', 'TERROR', 'SANCTION'
    "list_source" VARCHAR(100) NOT NULL,  -- 'MNB', 'EU', 'UN', 'OFAC'
    "added_date" timestamp DEFAULT NOW() NOT NULL,
    "updated_date" timestamp,
    "notes" TEXT,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp DEFAULT NOW() NOT NULL,
    "updated_at" timestamp DEFAULT NOW()
);

CREATE INDEX idx_prohibited_company_name ON "prohibited_company" (company_name);
CREATE INDEX idx_prohibited_company_reg ON "prohibited_company" (registration_number);
CREATE INDEX idx_prohibited_company_tax ON "prohibited_company" (tax_number);
CREATE INDEX idx_prohibited_company_active ON "prohibited_company" (is_active);

COMMENT ON TABLE "prohibited_company" IS 'MNB által kiadott tiltott cégek listája (AML/terror screening)';

-- =============================================================================
-- KÖVETKEZŐ LÉPÉS: valuta_data.sql teljes tartalmának importálása
-- =============================================================================
-- FONTOS: Ez a fájl csak a hiányzó prohibited táblákat tartalmazza.
-- A teljes schema (customer, aml_check, stb.) a valuta_data.sql-ben van!
-- 
-- Használat:
-- 1. Először futtasd ezt a fájlt (prohibited táblák)
-- 2. Utána futtasd a valuta_data.sql-t (teljes schema)
-- 
-- psql $env:RENDER_DB_URL_EXTERNAL -f database\migrations\001_initial_schema.sql
-- =============================================================================
