-- V315: Gépenként tárolt konfigurációs tábla (EXCMD b6-beallitasok FR-14).
-- Az egyes pénztárállomások helyi beállításait (FR-02..FR-13 értékek) JSONB-ben
-- tárolja, company_id + workstation_code szerint izolálva (multi-tenant).
-- A napi-jelentés jelszava BCrypt-hash-elve tárolódik a config mezőn KÍVÜL (külön
-- oszlop), hogy a GET endpoint soha ne adja vissza a hash-t (csak a "van-e beállítva"
-- jelzőt). A config JSONB szándékosan séma-szabad, hogy a kliensoldali settings-modell
-- verziósítás nélkül bővíthető legyen.

CREATE TABLE IF NOT EXISTS machine_config
(
    id                       UUID         NOT NULL DEFAULT gen_random_uuid(),
    company_id               UUID         NOT NULL,
    workstation_code         VARCHAR(100) NOT NULL,
    config                   JSONB        NOT NULL DEFAULT '{}',
    -- Jelszó hash külön oszlopban, hogy GET-ben ne szivárogjék ki.
    -- Null = nincs beállítva.
    daily_report_password_hash VARCHAR(255),
    updated_at               TIMESTAMP,
    updated_by               VARCHAR(100),

    CONSTRAINT pk_machine_config PRIMARY KEY (id),
    CONSTRAINT uq_machine_config_tenant UNIQUE (company_id, workstation_code)
);

COMMENT ON TABLE machine_config IS 'Gépenként izolált konfigurációs rekordok (EXCMD b6-beallitasok FR-14). company_id + workstation_code egyedi pár per cég per gép.';
COMMENT ON COLUMN machine_config.company_id IS 'Multi-tenant izoláció: SOHA ne kérd le company_id szűrés nélkül.';
COMMENT ON COLUMN machine_config.workstation_code IS 'A gép azonosítója (branch_code = VITE_BRANCH_CODE az Electron env-ből, pl. BR039). Nem UUID.';
COMMENT ON COLUMN machine_config.config IS 'Szabad JSONB settings payload (FR-02..FR-13 értékek: machineRole, displayColor, serverIp, stb.). Bővíthető sémaváltás nélkül.';
COMMENT ON COLUMN machine_config.daily_report_password_hash IS 'BCrypt hash a napi-jelentés jelszaváról (FR-06). NULL = nincs beállítva. GET-ben SOHA nem adható vissza.';
COMMENT ON COLUMN machine_config.updated_at IS 'Az utolsó módosítás időpontja (UTC).';
COMMENT ON COLUMN machine_config.updated_by IS 'Az utolsó módosítást végző worker kódja (audit trail).';

CREATE INDEX IF NOT EXISTS ix_machine_config_company ON machine_config (company_id);
