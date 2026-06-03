-- V291: az 50M Ft feletti pénzeszköz-forrás igazolás ENFORCEMENT élesítése (Pmt. / 14/2025. MNB rendelet)
--
-- Háttér: a V290 + #1005 bevezette a strukturált forrás-dokumentum (source_of_funds_doc_type/date)
-- szerver-oldali validációját (TransactionService.sourceOfFundsBlockReason), az
-- AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT feature-flag mögött (alapérték "false" = NEM blokkol).
-- A pénztáros felület (CustomerPanel) MOST MÁR gyűjti az 50M feletti ügyletnél a forrás-dokumentum
-- típusát (közjegyző/ügyvéd magánokirat vagy max. 3 éves banki szlip; két tanú TILOS) és dátumát,
-- ezért az enforcement élesítése biztonságos: a >=50M Ft ügylet csak érvényes forrás-igazolással
-- teljesíthető (a szabályzat V.2.5/V.2.8 pontja szerint).
--
-- Idempotens: csak akkor szúr be, ha a kulcs még nincs a táblában.

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT', 'true', 'BOOLEAN', 'AML',
       'Pmt./MNB 14/2025: 50M Ft feletti ügyletnél kötelező strukturált forrás-igazolás (közjegyző/ügyvéd '
       || 'magánokirat VAGY max. 3 éves banki szlip; két tanú TILOS). true = blokkol érvényes igazolás nélkül.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT'
);

-- Ha a kulcs már létezik (korábbi kézi beállítás), élesítsük "true"-ra.
UPDATE system_parameter
   SET parameter_value = 'true', is_active = true, updated_at = now(),
       updated_by = 'V291_migration'
 WHERE parameter_key = 'AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT'
   AND parameter_value <> 'true';
