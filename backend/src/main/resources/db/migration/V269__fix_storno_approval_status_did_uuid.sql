-- V269: storno_approval.approval_status_did oszlop típus-javítás BIGINT -> UUID + status dictionary seed
--
-- HIBA #8 (2026-05-27, élő-API kereszt­metszet-teszt): a POST /api/v1/stornos/request-approval
-- HTTP 500-zal halt el:
--   ERROR: column "approval_status_did" is of type bigint but expression is of type uuid
--
-- Root cause: a V3_5 / V74 migráció a storno_approval.approval_status_did oszlopot BIGINT-ként
-- hozta létre, DE a StornoApproval entity a mezőt @ManyToOne Dictionary asszociációként mappeli
-- (Dictionary.id @GeneratedValue(strategy=UUID) → UUID PK). Az INSERT így UUID-típusú értéket
-- (NULL-t is) küld a BIGINT oszlopba → típus-ütközés → a sztornó-jóváhagyási folyamat ELSŐ
-- lépése (request-approval) TELJESEN működésképtelen — productionon is.
--
-- A tábla minden környezetben ÜRES (a hibás INSERT sosem futott le sikeresen), ezért a
-- típus-váltás adatvesztés nélkül biztonságos; a USING NULL::uuid bármilyen maradék (értelmetlen)
-- BIGINT értéket NULL-ra állít (a sztornó-jóváhagyás státusz Dictionary-FK, BIGINT nem értelmezhető).
--
-- A másik két BIGINT *_did oszlop (branch_group.group_type_did, organization.organization_type_did)
-- NEM érintett: azokat az entity plain Long mezőként mappeli (konzisztens), NEM Dictionary FK-ként.

ALTER TABLE storno_approval
    ALTER COLUMN approval_status_did TYPE uuid USING NULL::uuid;

-- Integritás: a státusz a dictionary táblára mutat (a Dictionary entity-vel összhangban).
-- IF NOT EXISTS-szerű védelem PL/pgSQL-lel (idempotens — ha valamiért már létezik, nem hibázik).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_storno_approval_status'
          AND table_name = 'storno_approval'
    ) THEN
        ALTER TABLE storno_approval
            ADD CONSTRAINT fk_storno_approval_status
            FOREIGN KEY (approval_status_did) REFERENCES dictionary(id);
    END IF;
END $$;

COMMENT ON COLUMN storno_approval.approval_status_did IS
    'V269 (2026-05-27): BIGINT -> UUID — Dictionary FK (StornoApproval.approvalStatus @ManyToOne). HIBA #8 fix (élő-API teszt: request-approval 500).';

-- HIBA #9 (2026-05-27, élő-API teszt): a STORNO_APPROVAL_STATUS dictionary kategóriát SOHA
-- egyetlen migráció sem seedelte → a StornoService.approve() a
-- dictionaryRepository.findByCategoryAndCode("STORNO_APPROVAL_STATUS", "APPROVED"/"REJECTED")
-- orElseThrow-jánál IllegalStateException-t dob ("Hiányzó dictionary bejegyzés") → a
-- sztornó-jóváhagyás MÁSODIK lépése (approve) is működésképtelen, productionon is.
-- Seed: PENDING / APPROVED / REJECTED (idempotens — NOT EXISTS guarddal).
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at, updated_at)
SELECT gen_random_uuid(), 'STORNO_APPROVAL_STATUS', v.code, v.name, v.name_hu, v.sort_order, TRUE, NOW(), NOW()
FROM (VALUES
    ('PENDING',  'Pending',  'Függőben',   1),
    ('APPROVED', 'Approved', 'Jóváhagyva', 2),
    ('REJECTED', 'Rejected', 'Elutasítva', 3)
) AS v(code, name, name_hu, sort_order)
WHERE NOT EXISTS (
    SELECT 1 FROM dictionary d
    WHERE d.category = 'STORNO_APPROVAL_STATUS' AND d.code = v.code
);
