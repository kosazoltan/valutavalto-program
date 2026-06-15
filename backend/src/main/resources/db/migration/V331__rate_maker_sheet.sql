-- V331: Árfolyamkészítő munkaív (rate-maker working sheet) szerver-oldali authoritatív replika.
--
-- A vékony kliens (árfolyamkészítő, főértéktáros gépén) Local-First igazságforrása a SZERKESZTÉSI
-- munkaív: a 0. ív (elszámoló A–I) + munkacsoport-overlayek + képletek. Ezt kétirányban szinkronizáljuk
-- a központi modullal. A táblában a munkaív teljes, kliens-átlátszó JSON-snapshotja él (cégenként egy
-- aktív munkaív). A nemzeti TERÍTÉS továbbra is a publish-flow-n megy (rate_template/exchange_rate);
-- ez a tábla CSAK a szerkesztési munkaív sync-replikája, nem a publikált árfolyamok tárolója.
--
-- Konfliktus: a vékony kliens az igazságforrás aktív szerkesztéskor (last-write-wins a kliens javára);
-- megnyitáskor (más gépről is) a kliens a szerver verzióját olvassa BE alapként (version-összevetés),
-- onnantól újra a kliens a forrás. A `version` minden PUT-nál nő → a kliens ebből látja a más gépről
-- történt változást.
CREATE TABLE IF NOT EXISTS rate_maker_sheet (
    id          UUID PRIMARY KEY,
    company_id  UUID        NOT NULL,
    sheet_json  JSONB       NOT NULL,
    version     BIGINT      NOT NULL DEFAULT 1,
    source      VARCHAR(32) NOT NULL DEFAULT 'rate-maker',
    device_id   VARCHAR(128),
    updated_by  BIGINT,
    updated_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- Cégenként pontosan egy aktív munkaív (multi-tenant izoláció + felső-bound).
CREATE UNIQUE INDEX IF NOT EXISTS uq_rate_maker_sheet_company ON rate_maker_sheet (company_id);
