-- V316: Értéktári zárás-előtti ellenőrzőlista tábla
-- FR-ZARUI-16..26 (b2-zaras-kepernyok-bizonylatok.md)
--
-- 9 kötelező/eseti tétel (item_1..item_9) + FR-ZARUI-26 ellenőrző személy adatai.
-- UNIQUE (company_id, branch_id, closing_date) — egy nap egy zárás egy pénztárnál.

CREATE TABLE vault_closing_checklist (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Multi-tenant izoláció (P0 invariáns — minden sor céghez kötött)
    company_id      UUID        NOT NULL,
    branch_id       UUID        NOT NULL
                    REFERENCES branch(id) ON DELETE RESTRICT,
    closing_date    DATE        NOT NULL,

    -- FR-ZARUI-17: "Minden pénztár készlete feltöltve (címletek, fém euró)"
    item_1          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-18: "Esetleges helyettesítéskor kollégának minden infó átadólapon átadva"
    item_2          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-19: "Grafikon kitöltve, kifüggesztve, érintetteknek továbbítva"
    item_3          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-20: "Konkurencia árfolyamainak/készleteinek figyelemmel követése;
    --               konkurencia-jelentés megírása (eseti)"
    item_4          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-21: "Próbaváltás (eseti); havi beszámoló megírása, lefűzése (eseti)"
    item_5          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-22: "Bizonylatok párosítása, lefűzése;
    --               Kkts/E-ker/jutalék beszedése-befizetése (eseti)"
    item_6          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-23: "TRB tábla kitöltése; egyedi árfolyamos tábla kitöltése+továbbítása (eseti);
    --               egyedi árfolyamok ellenőrzése+továbbítása (eseti)"
    item_7          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-24: "Nagy ügyfélkártyák begyűjtése/összesítése, továbbítása (eseti);
    --               könyvelések lenyomtatása, lefűzése, adatainak ellenőrzése (eseti)"
    item_8          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-25: "Hóvégi egyeztetés területekkel (eseti); hóvégi egyeztetés pénztárakkal;
    --               napi jelentések leszavainak elküldése SMS-ben a pénztáraknak/értéktárosoknak stb. (eseti)"
    item_9          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- FR-ZARUI-26: Zárást ellenőrző személy adatai (complete() híváskor kötelező kitöltve)
    auditor_name    VARCHAR(255),
    auditor_role    VARCHAR(100),

    -- Zárás elvégzője
    completed_by_worker_id  BIGINT,
    completed_at            TIMESTAMP,

    created_at      TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP   NOT NULL DEFAULT NOW(),

    -- Egy napra egy checklist egy pénztárnál (cégszintű izoláció)
    CONSTRAINT uq_vault_closing_checklist_day
        UNIQUE (company_id, branch_id, closing_date)
);

-- Index a lekérdezési minta szerint: branch + dátum range
CREATE INDEX idx_vault_closing_checklist_branch_date
    ON vault_closing_checklist (branch_id, closing_date DESC);
