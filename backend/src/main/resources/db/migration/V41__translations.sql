-- V41: Többnyelvűség (i18n) tábla + magyar seed adatok
-- A rendszer alapból magyar, a bizonylatok/kijelzők angol/német nyelvre is fordíthatók.

CREATE TABLE IF NOT EXISTS translation (
    id              BIGSERIAL PRIMARY KEY,
    language_code   VARCHAR(5)   NOT NULL,
    message_key     VARCHAR(200) NOT NULL,
    message_value   TEXT         NOT NULL,
    module          VARCHAR(30)  NOT NULL DEFAULT 'UI',
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP,
    CONSTRAINT uk_translation_lang_key UNIQUE (language_code, message_key)
);

CREATE INDEX IF NOT EXISTS idx_translation_module ON translation(module);

-- ============================================================
-- Magyar (hu) alapszövegek — ~50 kulcs
-- ============================================================

-- RECEIPT modul — bizonylat szövegek
INSERT INTO translation (language_code, message_key, message_value, module) VALUES
('hu', 'receipt.title.buy', 'VÉTEL BIZONYLAT', 'RECEIPT'),
('hu', 'receipt.title.sell', 'ELADÁS BIZONYLAT', 'RECEIPT'),
('hu', 'receipt.title.storno', 'SZTORNÓ BIZONYLAT', 'RECEIPT'),
('hu', 'receipt.title.transfer', 'ÁTADÁS BIZONYLAT', 'RECEIPT'),
('hu', 'receipt.title.closing', 'ZÁRÓ BIZONYLAT', 'RECEIPT'),
('hu', 'receipt.field.receiptNumber', 'Bizonylat szám', 'RECEIPT'),
('hu', 'receipt.field.date', 'Dátum', 'RECEIPT'),
('hu', 'receipt.field.time', 'Idő', 'RECEIPT'),
('hu', 'receipt.field.currency', 'Valuta', 'RECEIPT'),
('hu', 'receipt.field.amount', 'Összeg', 'RECEIPT'),
('hu', 'receipt.field.rate', 'Árfolyam', 'RECEIPT'),
('hu', 'receipt.field.hufAmount', 'Forint összeg', 'RECEIPT'),
('hu', 'receipt.field.fee', 'Kezelési díj', 'RECEIPT'),
('hu', 'receipt.field.customer', 'Ügyfél', 'RECEIPT'),
('hu', 'receipt.field.cashier', 'Pénztáros', 'RECEIPT'),
('hu', 'receipt.field.branch', 'Fiók', 'RECEIPT'),
('hu', 'receipt.footer.signature', 'Aláírás', 'RECEIPT'),
('hu', 'receipt.footer.copy', 'Ügyfélpéldány', 'RECEIPT');

-- UI modul — felhasználói felület szövegek
INSERT INTO translation (language_code, message_key, message_value, module) VALUES
('hu', 'ui.menu.sell', 'Eladás', 'UI'),
('hu', 'ui.menu.buy', 'Vétel', 'UI'),
('hu', 'ui.menu.stock', 'Készlet', 'UI'),
('hu', 'ui.menu.denom', 'Címletek', 'UI'),
('hu', 'ui.menu.transfer', 'Átadás', 'UI'),
('hu', 'ui.menu.storno', 'Sztornó', 'UI'),
('hu', 'ui.menu.closing', 'Zárás', 'UI'),
('hu', 'ui.menu.rates', 'Árfolyamok', 'UI'),
('hu', 'ui.menu.reports', 'Listák', 'UI'),
('hu', 'ui.menu.settings', 'Beállítások', 'UI'),
('hu', 'ui.menu.customer', 'Ügyfél', 'UI'),
('hu', 'ui.menu.reservation', 'Foglalás', 'UI'),
('hu', 'ui.menu.dashboard', 'Irányítópult', 'UI'),
('hu', 'ui.button.save', 'Mentés', 'UI'),
('hu', 'ui.button.cancel', 'Mégse', 'UI'),
('hu', 'ui.button.delete', 'Törlés', 'UI'),
('hu', 'ui.button.edit', 'Szerkesztés', 'UI'),
('hu', 'ui.button.search', 'Keresés', 'UI'),
('hu', 'ui.button.print', 'Nyomtatás', 'UI'),
('hu', 'ui.button.export', 'Exportálás', 'UI'),
('hu', 'ui.button.back', 'Vissza', 'UI'),
('hu', 'ui.label.loading', 'Betöltés...', 'UI'),
('hu', 'ui.label.noData', 'Nincs adat', 'UI'),
('hu', 'ui.label.error', 'Hiba történt', 'UI');

-- REPORT modul — riport szövegek
INSERT INTO translation (language_code, message_key, message_value, module) VALUES
('hu', 'report.title.daily', 'Napi jelentés', 'REPORT'),
('hu', 'report.title.monthly', 'Havi jelentés', 'REPORT'),
('hu', 'report.title.mnb', 'MNB adatszolgáltatás', 'REPORT'),
('hu', 'report.title.nav', 'NAV adatszolgáltatás', 'REPORT'),
('hu', 'report.title.aml', 'AML ellenőrzés', 'REPORT'),
('hu', 'report.field.period', 'Időszak', 'REPORT'),
('hu', 'report.field.totalBuy', 'Összes vétel (HUF)', 'REPORT'),
('hu', 'report.field.totalSell', 'Összes eladás (HUF)', 'REPORT'),
('hu', 'report.field.txCount', 'Tranzakciók száma', 'REPORT');

-- DISPLAY modul — LED kijelző szövegek
INSERT INTO translation (language_code, message_key, message_value, module) VALUES
('hu', 'display.welcome', 'Üdvözöljük!', 'DISPLAY'),
('hu', 'display.closed', 'ZÁRVA', 'DISPLAY'),
('hu', 'display.buyRate', 'Vétel', 'DISPLAY'),
('hu', 'display.sellRate', 'Eladás', 'DISPLAY');
