-- v2.5.0 B6 sprint: Branch.is_vault flag
-- Cél: a SetupWizard branch-választása CSAK az értéktári fiókokra szűkítse a listát.
-- A törzsadatban explicit jelölés kell, mely fiók ÉRTÉKTÁR (nem pénztár).
--
-- Domain háttér:
--  - Egy cégnek van több fiókja (branch).
--  - Némelyik fiók PÉNZTÁR (cashier_only) — csak váltja a pénzt, nem tárol nagy készletet.
--  - Némelyik fiók ÉRTÉKTÁR — territoriális központ, ahol a készlet nagy részét tartják,
--    és ahonnan a területéhez tartozó pénztárak töltődnek (Distribution / Collection).
--  - A vault_territory táblán keresztül a branches már tudja, hogy melyik
--    területhez tartozik (vault_territory_id), de NEM jelölte, hogy maga a branch
--    értéktári funkciót lát-e el.
--
-- Új mező: is_vault BOOLEAN NOT NULL DEFAULT FALSE
--  - TRUE = a fiók maga ÉRTÉKTÁR (lokál vagy központi)
--  - FALSE = pénztár (default, biztonságos)
--
-- Backfill: nem teszünk auto-jelölést. Az admin/foertektar a Beállítások > Pénztárak
-- (admin UI) oldalon megjelölheti a fiókokat utólag.

ALTER TABLE branches
    ADD COLUMN is_vault BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_branches_is_vault ON branches (is_vault) WHERE is_vault = TRUE;

COMMENT ON COLUMN branches.is_vault IS
    'v2.5.0: TRUE=ÉRTÉKTÁR fiók (lokál vagy központi), FALSE=PÉNZTÁR (default). '
    'A SetupWizard csak is_vault=TRUE fiókokat enged kiválasztani értéktár módú telepítésnél.';
