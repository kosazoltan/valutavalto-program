package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * A3 (Pmt. 50M, EXCMD b4-foglalo FR-16) — 50M Ft feletti ügylet pénzeszköz-forrás igazolásának
 * enforcement döntése unit teszt.
 *
 * <p>A {@link TransactionService#sourceOfFundsBlockReason} statikus, függőség-mentes segédmetódus:
 * a feature-flag (AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT) értékét a hívó adja át. Szabály (Pmt.):
 * &ge; 50M Ft → KÖTELEZŐ közjegyző/ügyvéd ellenjegyzésű teljes bizonyító erejű magánokirat VAGY
 * max. 3 éves banki bizonylat (szlip); két tanús magánnyilatkozat TILOS.</p>
 */
class TransactionServiceSourceOfFundsTest {

    private static final BigDecimal FIFTY_M = new BigDecimal("50000000");
    private static final BigDecimal BELOW = new BigDecimal("49999999");
    private static final LocalDate TX_DATE = LocalDate.of(2026, 6, 3);

    @Test
    @DisplayName("enforce=false (default) → NEM blokkol akkor sem, ha hiányzik a forrás-dokumentum")
    void enforceOff_noBlock() {
        assertThat(TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, null, null, TX_DATE, false)).isNull();
    }

    @Test
    @DisplayName("50M alatt → NEM blokkol (külön forrás-igazolási kényszer nincs)")
    void belowThreshold_noBlock() {
        assertThat(TransactionService.sourceOfFundsBlockReason(
                BELOW, null, null, TX_DATE, true)).isNull();
    }

    @Test
    @DisplayName("null összeg → NEM blokkol")
    void nullAmount_noBlock() {
        assertThat(TransactionService.sourceOfFundsBlockReason(
                null, null, null, TX_DATE, true)).isNull();
    }

    @Test
    @DisplayName("pontosan 50M + hiányzó dokumentum → blokkol (a küszöb inkluzív)")
    void exactlyThreshold_missingDoc_blocks() {
        String reason = TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, null, null, TX_DATE, true);
        assertThat(reason).isNotNull().contains("forrását");
    }

    @Test
    @DisplayName("50M felett + üres dokumentumtípus → blokkol")
    void aboveThreshold_blankDoc_blocks() {
        String reason = TransactionService.sourceOfFundsBlockReason(
                new BigDecimal("60000000"), "   ", null, TX_DATE, true);
        assertThat(reason).isNotNull().contains("igazolni kell");
    }

    @Test
    @DisplayName("50M felett + két tanús magánnyilatkozat → TILOS, blokkol")
    void aboveThreshold_twoWitness_blocks() {
        assertThat(TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "KET_TANU", null, TX_DATE, true))
                .isNotNull().contains("két tanú");
        assertThat(TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "TWO_WITNESS", null, TX_DATE, true))
                .isNotNull().contains("két tanú");
    }

    @Test
    @DisplayName("50M felett + ismeretlen dokumentumtípus → blokkol")
    void aboveThreshold_unknownType_blocks() {
        String reason = TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "VALAMI_MAS", null, TX_DATE, true);
        assertThat(reason).isNotNull().contains("nem elfogadható");
    }

    @Test
    @DisplayName("50M felett + közjegyzői magánokirat → NEM blokkol")
    void aboveThreshold_notaryDeed_ok() {
        assertThat(TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "MAGANOKIRAT_KOZJEGYZO", null, TX_DATE, true)).isNull();
    }

    @Test
    @DisplayName("50M felett + ügyvédi magánokirat (kisbetűs, whitespace) → NEM blokkol")
    void aboveThreshold_lawyerDeed_caseInsensitive_ok() {
        assertThat(TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "  maganokirat_ugyved  ", null, TX_DATE, true)).isNull();
    }

    @Test
    @DisplayName("50M felett + banki szlip dátum nélkül → blokkol")
    void aboveThreshold_bankSlip_noDate_blocks() {
        String reason = TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "BANK_SZLIP", null, TX_DATE, true);
        assertThat(reason).isNotNull().contains("kiállítás dátuma");
    }

    @Test
    @DisplayName("50M felett + banki szlip jövőbeli dátummal → blokkol")
    void aboveThreshold_bankSlip_futureDate_blocks() {
        String reason = TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "BANK_SZLIP", TX_DATE.plusDays(1), TX_DATE, true);
        assertThat(reason).isNotNull().contains("jövőben");
    }

    @Test
    @DisplayName("50M felett + banki szlip 3 éven belül → NEM blokkol")
    void aboveThreshold_bankSlip_within3y_ok() {
        assertThat(TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "BANK_SZLIP", TX_DATE.minusDays(1095), TX_DATE, true)).isNull();
    }

    @Test
    @DisplayName("50M felett + banki szlip 3 évnél régebbi → blokkol")
    void aboveThreshold_bankSlip_olderThan3y_blocks() {
        String reason = TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "BANK_SZLIP", TX_DATE.minusDays(1096), TX_DATE, true);
        assertThat(reason).isNotNull().contains("3 évnél régebbi");
    }

    @Test
    @DisplayName("txDate null → a szlip korát a dokumentum dátumából számolja (0 nap, elfogad)")
    void aboveThreshold_bankSlip_nullTxDate_usesDocDate() {
        assertThat(TransactionService.sourceOfFundsBlockReason(
                FIFTY_M, "BANK_SZLIP", TX_DATE.minusDays(10), null, true)).isNull();
    }
}
