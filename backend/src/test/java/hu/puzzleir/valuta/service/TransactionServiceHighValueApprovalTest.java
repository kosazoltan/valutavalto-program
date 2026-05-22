package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.aml.AmlCheckResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * G11 (EXCMD b5-kezeles FR-KC-11) — 10M+ / fokozott tranzakció vezetői jóváhagyás
 * enforcement döntésének unit tesztje.
 *
 * <p>A {@link TransactionService#highValueApprovalBlockReason} statikus, függőség-mentes
 * segédmetódus: a feature-flag (AML_HIGH_VALUE_APPROVAL_ENFORCEMENT) értékét a hívó adja át.</p>
 */
class TransactionServiceHighValueApprovalTest {

    private AmlCheckResult result(boolean requiresApproval, String reason) {
        return AmlCheckResult.builder()
                .requiresManagerApproval(requiresApproval)
                .managerApprovalReason(reason)
                .build();
    }

    @Test
    @DisplayName("enforce=true + jóváhagyás-köteles → a megadott indokkal blokkol")
    void enforceOn_requiresApproval_blocksWithReason() {
        String reason = TransactionService.highValueApprovalBlockReason(
                result(true, "TranzTipus 5 — SUPERVISOR vagy MANAGER jóváhagyás szükséges"), true);
        assertThat(reason).isEqualTo("TranzTipus 5 — SUPERVISOR vagy MANAGER jóváhagyás szükséges");
    }

    @Test
    @DisplayName("enforce=true + jóváhagyás-köteles + null indok → default indokkal blokkol")
    void enforceOn_nullReason_usesDefault() {
        String reason = TransactionService.highValueApprovalBlockReason(result(true, null), true);
        assertThat(reason).isNotNull().contains("vezetői");
    }

    @Test
    @DisplayName("enforce=true + üres/blank indok → default indok (nem üres üzenet)")
    void enforceOn_blankReason_usesDefault() {
        String reason = TransactionService.highValueApprovalBlockReason(result(true, "   "), true);
        assertThat(reason).isNotBlank().contains("vezetői");
    }

    @Test
    @DisplayName("enforce=false (default) + jóváhagyás-köteles → NEM blokkol (WARN-only)")
    void enforceOff_requiresApproval_noBlock() {
        String reason = TransactionService.highValueApprovalBlockReason(
                result(true, "TranzTipus 5"), false);
        assertThat(reason).isNull();
    }

    @Test
    @DisplayName("nem jóváhagyás-köteles → NEM blokkol akkor sem, ha enforce=true")
    void notRequiresApproval_noBlock() {
        String reason = TransactionService.highValueApprovalBlockReason(result(false, null), true);
        assertThat(reason).isNull();
    }

    @Test
    @DisplayName("null eredmény → NEM blokkol")
    void nullResult_noBlock() {
        assertThat(TransactionService.highValueApprovalBlockReason(null, true)).isNull();
    }
}
