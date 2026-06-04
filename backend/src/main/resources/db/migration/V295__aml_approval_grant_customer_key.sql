-- AML felsovezetoi jovahagyas grant — customer-kotes (Codex P1, 2026-06-04).
--
-- Elozmeny: a verify-approver eddig a kliens-oldali grantUses count-ot fogadta el (a nyugta sorszama),
-- amibol egy kompromittalt renderer 6-ot kuldhetett, majd UGYANAZT a kliens-valasztott approvalSessionId-t
-- ujrahasznalhatta FUGGETLEN tranzakcio-POST-okon -> egy supervisor-PIN akar 6 nem-osszefuggo AML-koteles
-- tranzakciot is jovahagyhatott ("Derive grant use count on the server" P1).
--
-- Megoldas: a grant SINGLE-USE (uses_remaining=1), a konkret UGYFELHEZ kotott (customer_key). A multi-line
-- nyugta EGY aggregalt backend-tranzakciokent dolgozodik fel (TransactionMultiLineService, egy AML-kapu, egy
-- consume), ezert egy nyugta egyetlen grant-felhasznalast igenyel; a kimerult grant ELUTASIT (nincs sibling-
-- ujrafelhasznalas). Egy MAS ugyfelre ujrahasznalt session is elbukik (customer_key elter) -> a "nem-osszefuggo
-- tranzakciok" amplifikacio megszunik, a count NEM a klienstol jon (server-derived single-use).
--
-- A customer_key NULL marad a regi (V294) grantoknal -> azoknal nincs customer-kotes (visszafele-kompatibilis).

-- A hossz a TransactionAmlApproval.customer_name-mel (255) egyezik, hogy egy hosszú ügyfél/cég-név se
-- bukjon el a grant-mentéskor (a consume customerName-mel egyezteti — a kettőnek konzisztensnek kell lennie).
ALTER TABLE aml_approval_grant
    ADD COLUMN IF NOT EXISTS customer_key VARCHAR(255);

-- A consume-lookup customer-szures gyorsitasa (a meglevo ix_aml_approval_grant_consume mellett).
CREATE INDEX IF NOT EXISTS ix_aml_approval_grant_session_customer
    ON aml_approval_grant (company_id, cashier_worker_id, approver_worker_id, session_id, customer_key);
