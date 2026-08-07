package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Dictionary;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-030 FR-8: a Pénzforgalom riport Bank/Terület/Pénztár partner-kategorizálása.
 *
 * <p>Docker/Testcontainers NÉLKÜL fut — a kategorizálás tiszta függvény, a besorolási
 * szabály pedig üzleti döntés (TBD-2), ezért önálló, gyors tesztet érdemel.</p>
 */
class CashFlowReportPartnerCategoryFr8Test {

    @Test
    @DisplayName("FR-8: a Bank-körbe sorolt betűkódok mindegyike 'Bank' kategóriát kap")
    void bankPartnerCodesAreCategorizedAsBank() {
        for (String code : new String[]{"PRB", "ERB", "FRB", "RB", "JRB", "MNB", "UPT", "TH", "FOP1"}) {
            assertThat(CashFlowReportService.partnerCategory(counterparty(code), code))
                    .as("A(z) %s betűkód a megrendelői döntés szerint Bank", code)
                    .isEqualTo(CashFlowReportService.CATEGORY_BANK);
        }
    }

    @Test
    @DisplayName("FR-8: a TRB betűkód 'Terület' kategóriát kap")
    void trbIsCategorizedAsTerritory() {
        assertThat(CashFlowReportService.partnerCategory(counterparty("TRB"), "TRB"))
                .isEqualTo(CashFlowReportService.CATEGORY_TERRITORY);
    }

    @Test
    @DisplayName("FR-8: numerikus kódú (nem VAULT_COUNTERPARTY) fiók 'Pénztár' kategóriát kap")
    void numericBranchIsCategorizedAsCashier() {
        Branch penztar = Branch.builder()
                .code("BR076")
                .branchType(dictionary("PENZTAR"))
                .build();

        assertThat(CashFlowReportService.partnerCategory(penztar, "076"))
                .isEqualTo(CashFlowReportService.CATEGORY_CASHIER);
    }

    @Test
    @DisplayName("FR-8: branchType nélküli fiók is 'Pénztár' — a besorolás a típusból indul, nem a kódból")
    void branchWithoutTypeIsCashier() {
        Branch noType = Branch.builder().code("BR012").build();

        assertThat(CashFlowReportService.partnerCategory(noType, "012"))
                .isEqualTo(CashFlowReportService.CATEGORY_CASHIER);
    }

    /**
     * Fail-closed kontroll: ISMERETLEN betűkódú counterparty NEM eshet bele a Bank-összesenbe.
     * Inkább látszódjon "Egyéb"-ként, mint hogy egy új partner némán a Bank sorba olvadjon.
     */
    @Test
    @DisplayName("FR-8: ismeretlen counterparty-betűkód 'Egyéb' kategóriát kap (fail-closed)")
    void unknownCounterpartyCodeIsOther() {
        assertThat(CashFlowReportService.partnerCategory(counterparty("XYZ"), "XYZ"))
                .isEqualTo(CashFlowReportService.CATEGORY_OTHER);
    }

    @Test
    @DisplayName("FR-8: hiányzó partner vagy kód esetén 'Egyéb' (nem dob kivételt)")
    void nullPartnerOrCodeIsOther() {
        assertThat(CashFlowReportService.partnerCategory(null, "PRB"))
                .isEqualTo(CashFlowReportService.CATEGORY_OTHER);
        assertThat(CashFlowReportService.partnerCategory(counterparty("PRB"), null))
                .isEqualTo(CashFlowReportService.CATEGORY_OTHER);
    }

    @Test
    @DisplayName("FR-8: a betűkód-egyezés kis/nagybetű- és whitespace-tűrő")
    void codeMatchingIsNormalized() {
        assertThat(CashFlowReportService.partnerCategory(counterparty(" prb "), " prb "))
                .isEqualTo(CashFlowReportService.CATEGORY_BANK);
    }

    // ============================ FIXTURE ============================

    private static Branch counterparty(String code) {
        return Branch.builder()
                .code(code)
                .branchType(dictionary("VAULT_COUNTERPARTY"))
                .build();
    }

    private static Dictionary dictionary(String code) {
        Dictionary d = new Dictionary();
        d.setCategory("BRANCH_TYPE");
        d.setCode(code);
        return d;
    }
}
