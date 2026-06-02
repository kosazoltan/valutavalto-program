-- V287 — FK-KEZDÍJ (2026-06-02): a kezelési díj módosításának (override) auditálható mezői.
--
-- A pénztári tranzakciónál a kezelési díj felezhető / elengedhető / speciális összegre állítható
-- az engedély-mátrix szerint (ügyvezető/főértéktáros: felezés/elengedés/speciális; ügyfélkártya:
-- felezés/elengedés + kártyaszám; akció: felezés/elengedés). Ezek auditálandók: MILYEN típusú a
-- módosítás, MILYEN jogcímen, MENNYI volt az eredeti (számolt) díj, és — kártyás jogcímnél — a
-- kártyaszám. A jogosultság-ellenőrzést a szerver (HandlingFeeOverrideService) végzi.
--
-- Zero-downtime: mind nullable (a meglévő rekordok NULL-ok = nem volt override). Idempotens.

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS handling_fee_override_type   VARCHAR(20);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS handling_fee_override_reason VARCHAR(30);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS handling_fee_base            NUMERIC(15,2);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS customer_card_number        VARCHAR(100);
