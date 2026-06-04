-- AML felsovezetoi jovahagyas grant — customer-kotes (Codex P1, 2026-06-04).
--
-- Elozmeny: a verify-approver eddig a kliens-oldali grantUses count-ot fogadta el (a nyugta sorszama),
-- amibol egy kompromittalt renderer 6-ot kuldhetett, majd UGYANAZT a kliens-valasztott approvalSessionId-t
-- ujrahasznalhatta FUGGETLEN tranzakcio-POST-okon -> egy supervisor-PIN akar 6 nem-osszefuggo AML-koteles
-- tranzakciot is jovahagyhatott ("Derive grant use count on the server" P1).
--
-- Megoldas: a grant SINGLE-USE (uses_remaining=1), de a konkret UGYFELHEZ kotott (customer_key). Egy
-- multi-line nyugta minden sora UGYANAZT az ugyfelet viszi: az ELSO sor elhasznalja az egyetlen grantot es
-- rogziti a jovahagyast, a tobbi sor (ugyanaz a session ES ugyanaz a customer_key) jovahagyas-fedettkent
-- atmegy ujabb grant nelkul. Egy MAS ugyfelre ujrahasznalt session viszont elbukik (customer_key eltér) ->
-- a "nem-osszefuggo tranzakciok" amplifikacio megszunik, a count NEM a klienstol jon.
--
-- A customer_key NULL marad a regi (V294) grantoknal -> azoknal nincs customer-kotes (visszafele-kompatibilis).

-- A hossz a TransactionAmlApproval.customer_name-mel (255) egyezik, hogy egy hosszú ügyfél/cég-név se
-- bukjon el a grant-mentéskor (a consume customerName-mel egyezteti — a kettőnek konzisztensnek kell lennie).
ALTER TABLE aml_approval_grant
    ADD COLUMN IF NOT EXISTS customer_key VARCHAR(255);

-- A consume-lookup customer-szures gyorsitasa (a meglevo ix_aml_approval_grant_consume mellett).
CREATE INDEX IF NOT EXISTS ix_aml_approval_grant_session_customer
    ON aml_approval_grant (company_id, cashier_worker_id, approver_worker_id, session_id, customer_key);
