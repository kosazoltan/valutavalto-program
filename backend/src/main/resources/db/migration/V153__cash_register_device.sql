-- V100: Penztar-eszkoz (cash register device) nyilvantartas
-- A penztar-client Electron app telepitesenel a SetupWizard online-regisztral
-- egy rekordot, hogy a szerver minden fizikai penztart nyilvantartson.

CREATE TABLE cash_register_device (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
  branch_id       UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
  code            VARCHAR(40) NOT NULL,
  name            VARCHAR(200),
  app_mode        VARCHAR(30) NOT NULL DEFAULT 'penztar',
  app_version     VARCHAR(30),
  device_fingerprint VARCHAR(255),
  os_info         VARCHAR(255),
  registered_by_worker_id BIGINT REFERENCES worker(id) ON DELETE SET NULL,
  installed_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at    TIMESTAMP,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP,
  CONSTRAINT uk_cash_register_device_company_code UNIQUE (company_id, code)
);

CREATE INDEX idx_cash_register_device_branch ON cash_register_device(branch_id);
CREATE INDEX idx_cash_register_device_company ON cash_register_device(company_id);
CREATE INDEX idx_cash_register_device_fingerprint ON cash_register_device(device_fingerprint);

COMMENT ON TABLE cash_register_device IS 'Penztar-client Electron telepitesek nyilvantartasa - SetupWizard online-registracio utan letrehozva.';
COMMENT ON COLUMN cash_register_device.app_mode IS 'penztar | ertektar | ertekszallito | full';
COMMENT ON COLUMN cash_register_device.device_fingerprint IS 'Stabil gep-azonosito (MAC hash, install UUID, stb).';
COMMENT ON COLUMN cash_register_device.last_seen_at IS 'Utolso heartbeat a SyncEngine-bol.';