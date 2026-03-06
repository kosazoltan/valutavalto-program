-- V38: LED kijelző konfiguráció
-- A fizikai LED kijelző beállításai (csatlakozás típus, megjelenített valuták stb.)

CREATE TABLE IF NOT EXISTS led_display_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    branch_id UUID NOT NULL REFERENCES branch(id),
    display_type VARCHAR(30) NOT NULL DEFAULT 'NETWORK',
    connection_string VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    refresh_interval_seconds INTEGER NOT NULL DEFAULT 60,
    displayed_currencies TEXT,
    last_updated_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_led_display_config_branch ON led_display_config(branch_id);
