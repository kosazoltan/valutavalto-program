-- V308: WU SOF 10M Ft / 7 nap kumulált trigger (EBC szabályzat V.2.8 A.1)
--
-- Szabály (Pmt. + EBC ZRT pénzmosási szabályzat V.2.8 A.1): ha ugyanazon ügyfél 7 naptári
-- napon belüli összesített pénzátutalási forgalma (küldés+fogadás) >= 10.000.000 Ft, ÉS
-- legalább 2 különböző küldőtől/kedvezményezett felé történt → a pénzeszközök forrásának
-- dokumentált igazolása KÖTELEZŐ (elfogadható doc-lista: V.2.8 B.2 — jövedelemigazolás,
-- NAV-igazolás, bankszámlakivonat, adásvételi/öröklési/ajándékozási okirat, vállalkozói
-- jövedelem, nyugdíj-igazolás + az 50M-es szabály okiratai).
--
-- Implementáció: WesternUnionService.enforceWuSofCumulative (recordSend/recordReceive),
-- WuTransactionRepository.findRecentSendReceiveByCustomer(Name). A 2026-06-03-as
-- AML-go-live-terv 2) pontja ([M]). A flag-élesítés a V291/V305/V306 mintát követi —
-- a teljes lánc (gate + DTO + UI mezők) ebben a körben együtt készült el.

-- 1) SOF dokumentum-mezők a wu_transactions táblán
ALTER TABLE wu_transactions ADD COLUMN IF NOT EXISTS source_of_funds_doc_type VARCHAR(50);
ALTER TABLE wu_transactions ADD COLUMN IF NOT EXISTS source_of_funds_doc_date DATE;

COMMENT ON COLUMN wu_transactions.source_of_funds_doc_type IS
    'Pénzeszköz-forrás dokumentum típusa (V.2.8 B.2 lista) — a 10M/7nap kumulált triggernél kötelező';
COMMENT ON COLUMN wu_transactions.source_of_funds_doc_date IS
    'A forrás-dokumentum kiállítási dátuma';

-- 2) Enforcement flag (idempotens seed)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'AML_WU_SOF_CUMULATIVE_10M_ENFORCEMENT', 'true', 'BOOLEAN', 'AML',
       'V.2.8 A.1: WU kumulált trigger — 7 napon belül >=10M Ft küldés+fogadás ÉS >=2 különböző '
       || 'partner esetén kötelező a pénzeszköz-forrás dokumentált igazolása. true = blokkol.',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter WHERE parameter_key = 'AML_WU_SOF_CUMULATIVE_10M_ENFORCEMENT'
);

UPDATE system_parameter
   SET parameter_value = 'true', is_active = true, updated_at = now(),
       updated_by = 'V308_migration'
 WHERE parameter_key = 'AML_WU_SOF_CUMULATIVE_10M_ENFORCEMENT'
   AND parameter_value <> 'true';
