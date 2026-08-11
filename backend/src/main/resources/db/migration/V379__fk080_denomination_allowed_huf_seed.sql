-- FK-080 (FR-1): a HUF felvetele a denomination_allowed torzsadatba.
--
-- Cel: a denomination_allowed EGYETLEN igazsagforrassa valjon. A V376 a HUF-ot
-- szandekosan kihagyta (Scope OUT), ezert a zaras-varazslo HUF-ra ki volt kapcsolva
-- (ClosingWizardService HUF-kivetel), a DenominationService pedig egy 14 elemu
-- hardkodolt HUF tombbol dolgozott — igy minden uj fiok HUF 1 es 2 forintos ERME
-- sorokat is kapott. A FK-080 mindket agat a katalogusra vezeti at.
--
-- UZLETI SZABALY (Foertektaros, 2026-08-01/08-02 + FK-080):
--   erme KIZAROLAG HUF 200/100/50/20/10/5 es EUR 2/1;
--   minden mas deviza minden nevertekben BANKNOTE.
-- A HUF 1 es 2 forint SZANDEKOSAN NINCS ebben a seedben: az MNB 2008. marcius 1-jen
-- bevonta oket, nem torvenyes fizetoeszkozok. Ezert company-nkent pontosan 12 HUF sor
-- keletkezik (6 COIN + 6 BANKNOTE), NEM 14.
--
-- FONTOS: ez a migracio a `denomination` tablahoz NEM nyul (sem INSERT, sem UPDATE,
-- sem DELETE) — kizarolag a `denomination_allowed` katalogusba ir. A meglevo, mar
-- letrejott tiltott erme-sorok inaktivalasa a V380 dolga (FR-6).
--
-- MIERT NEM A V376-OT MODOSITJUK (ticket C1): a V376 eles kornyezetben MAR ALKALMAZOTT
-- migracio. A tartalma barmilyen modositasa megvaltoztatja a Flyway checksumot, es a
-- `validate-on-migrate=true` + `repair-on-migrate=false` beallitas mellett ez a kovetkezo
-- deploy-t megbuktatna (production outage). Ezert a V376 fajl ERINTETLEN marad, a
-- tabla-kommentjet pedig ez a migracio irja felul a COMMENT ON TABLE utasitassal.
--
-- NFR-1 (idempotencia): a WHERE NOT EXISTS gat miatt az INSERT ismetelt futtatasa
-- 0 sort illeszt be; a COMMENT ON TABLE ismetelheto.
-- NFR-3: egyetlen tranzakcio (Flyway default), cegenkent 12 sor — futasideje
-- ezredmasodperc nagysagrendu, karbantartasi ablak nem szukseges.

INSERT INTO denomination_allowed (company_id, currency_id, face_value, denomination_type, created_at, updated_at)
SELECT c.id, cur.id, v.face_value, v.denomination_type, now(), now()
FROM company c
CROSS JOIN (VALUES
    -- HUF bankjegy: 500 - 20 000 Ft (MNB: az 500 Ft BANKJEGY, 500 Ft-os erme nem letezik)
    ('HUF', 20000, 'BANKNOTE'), ('HUF', 10000, 'BANKNOTE'), ('HUF', 5000, 'BANKNOTE'),
    ('HUF', 2000, 'BANKNOTE'),  ('HUF', 1000, 'BANKNOTE'),  ('HUF', 500, 'BANKNOTE'),
    -- HUF erme: 5 - 200 Ft (az 1 es 2 forintot 2008-ban bevontak — SZANDEKOSAN kimarad)
    ('HUF', 200, 'COIN'), ('HUF', 100, 'COIN'), ('HUF', 50, 'COIN'),
    ('HUF', 20, 'COIN'),  ('HUF', 10, 'COIN'),  ('HUF', 5, 'COIN')
) AS v(currency_code, face_value, denomination_type)
JOIN currency cur ON cur.code = v.currency_code
WHERE NOT EXISTS (
    SELECT 1 FROM denomination_allowed da
    WHERE da.company_id = c.id AND da.currency_id = cur.id AND da.face_value = v.face_value
);

COMMENT ON TABLE denomination_allowed IS
    'FK-076/FK-080: uzletileg engedelyezett cimlet-katalogus (deviza-szintu, fiok-fuggetlen). '
    'EGYETLEN igazsagforras, a HUF-ot IS tartalmazza (FK-080 V379): erme kizarolag '
    'HUF 200/100/50/20/10/5 es EUR 2/1; minden mas deviza minden nevertekben BANKNOTE. '
    'HUF 1 es 2 forint szandekosan NINCS benne (2008-ban bevontak).';
