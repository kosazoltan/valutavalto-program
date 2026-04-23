-- V159: vault_territory HUF CurrencyStock init a baseCapital alapjan
--
-- v2.2.2 hotfix: a V156-V158 csak a vault_territory recordot hozza letre,
-- de NEM inicializal HUF keszletet. A VaultBankTransactionService.createBankTransaction
-- ezert 500-at dob (IllegalStateException: "Nincs elegendo keszlet: 0 < X HUF").
--
-- Ez a migration minden aktiv vault_territory-nek letrehozza a kezdeti
-- HUF CurrencyStock rekordot a base_capital osszeggel. WAC = 1.0 (HUF mindig 1:1).
-- Idempotens: ON CONFLICT nincs szukseg, a WHERE NOT EXISTS elintezi.

INSERT INTO currency_stock (
    company_id,
    entity_type,
    entity_id,
    currency_code,
    quantity,
    weighted_avg_cost,
    last_updated
)
SELECT
    vt.company_id,
    'VAULT',
    vt.id::TEXT,
    'HUF',
    COALESCE(vt.base_capital, 0),
    1.0,
    NOW()
FROM vault_territory vt
WHERE vt.is_active = true
  AND NOT EXISTS (
      SELECT 1 FROM currency_stock cs
      WHERE cs.company_id = vt.company_id
        AND cs.entity_type = 'VAULT'
        AND cs.entity_id = vt.id::TEXT
        AND cs.currency_code = 'HUF'
  );

-- Log
DO $$
DECLARE
    init_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO init_count
    FROM currency_stock
    WHERE entity_type = 'VAULT'
      AND currency_code = 'HUF'
      AND last_updated >= NOW() - INTERVAL '1 minute';
    RAISE NOTICE 'V159 vault HUF stock init: % uj rekord', init_count;
END $$;