package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.BranchHandlingFeeConfig;
import hu.puzzleir.valuta.entity.FeeConfigStatus;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchHandlingFeeConfigRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.HandlingFeeTransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * HandlingFeeService UNIT tesztek — FK-096 WU-4: iroda-tudatos, fail-closed feloldás.
 *
 * <p>A korábbi cégszintű (system_parameter-alapú) tesztek MECHANIKUS szignatúra-migrációja:
 * a calculateHandlingFee(hufAmount, branchId) kétargumentumú lett, a mockok a
 * system_paraméterről az iroda-szintű BranchHandlingFeeConfig LIVE sorra költöztek.
 * Az assertált díjértékek változatlanok.</p>
 *
 * Teszteli:
 * - Sávos díjszámítás (BRACKET) — közös LIVE sávok (FR-6)
 * - Ezrelékes díjszámítás (PER_MILLE) — az iroda SAJÁT mértékével/sapkájával (FR-4)
 * - NONE mód (nincs díj, D4)
 * - NULL/negatív összeg kezelés (változatlan viselkedés)
 * - Fail-closed: nincs LIVE sor → ValidationException, SOHA nem néma 0 Ft (FR-5)
 * - DRAFT sor sosem használódik (FR-8 paritás a feloldásban)
 * - DiscountThreshold automatikus alkalmazás (változatlan)
 */
@ExtendWith(MockitoExtension.class)
class HandlingFeeServiceTest {

    @Mock private SystemParameterService systemParameterService;
    @Mock private BranchHandlingFeeConfigRepository branchConfigRepository;
    @Mock private HandlingFeeBracketRepository bracketRepository;
    @Mock private HandlingFeeTransactionRepository feeTransactionRepository;
    @Mock private DiscountThresholdService discountThresholdService;

    @InjectMocks
    private HandlingFeeService handlingFeeService;

    private UUID companyId;
    private UUID branchId;

    @BeforeEach
    void setupSecurity() {
        companyId = UUID.randomUUID();
        branchId = UUID.randomUUID();
        setupSecurityContext(companyId, branchId);
    }

    @Nested
    @DisplayName("calculateHandlingFee — BRACKET mód")
    class BracketTests {

        @BeforeEach
        void setup() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.BRACKET, null, null)));
        }

        @Test
        @DisplayName("50.000 Ft → 200 Ft díj (1. sáv)")
        void shouldReturnFirstBracketFee() {
            List<HandlingFeeBracket> brackets = List.of(
                    createBracket(new BigDecimal("100000"), new BigDecimal("200"), 1),
                    createBracket(new BigDecimal("500000"), new BigDecimal("500"), 2),
                    createBracket(new BigDecimal("1000000"), new BigDecimal("1000"), 3)
            );
            when(bracketRepository.findByCompanyIdAndStatusAndActiveOrderByBracketOrder(
                    companyId, FeeConfigStatus.LIVE, true))
                    .thenReturn(brackets);
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("50000"), branchId);
            assertThat(fee).isEqualByComparingTo("200");
        }

        @Test
        @DisplayName("300.000 Ft → 500 Ft díj (2. sáv)")
        void shouldReturnSecondBracketFee() {
            List<HandlingFeeBracket> brackets = List.of(
                    createBracket(new BigDecimal("100000"), new BigDecimal("200"), 1),
                    createBracket(new BigDecimal("500000"), new BigDecimal("500"), 2)
            );
            when(bracketRepository.findByCompanyIdAndStatusAndActiveOrderByBracketOrder(
                    companyId, FeeConfigStatus.LIVE, true))
                    .thenReturn(brackets);
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("300000"), branchId);
            assertThat(fee).isEqualByComparingTo("500");
        }
    }

    @Nested
    @DisplayName("calculateHandlingFee — PER_MILLE mód")
    class PerMilleTests {

        @Test
        @DisplayName("100.000 Ft × 5‰ = 500 Ft")
        void shouldCalculatePerMille() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.PER_MILLE,
                            new BigDecimal("5"), null)));
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("100000"), branchId);
            assertThat(fee).isEqualByComparingTo("500");
        }

        @Test
        @DisplayName("1.000.000 Ft × 3‰ = 3.000 Ft")
        void shouldCalculateLargePerMille() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.PER_MILLE,
                            new BigDecimal("3"), null)));
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("1000000"), branchId);
            assertThat(fee).isEqualByComparingTo("3000");
        }

        @Test
        @DisplayName("PER_MILLE_MAX cap: 1.000.000 Ft × 5‰ = 5.000 → cap 2.000 Ft")
        void shouldCapPerMilleAtMax() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.PER_MILLE,
                            new BigDecimal("5"), new BigDecimal("2000"))));
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("1000000"), branchId);
            assertThat(fee).isEqualByComparingTo("2000");
        }
    }

    @Nested
    @DisplayName("calculateHandlingFee — NONE mód")
    class NoneTests {

        @Test
        @DisplayName("NONE típusnál mindig 0 Ft")
        void shouldReturnZeroForNone() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.NONE, null, null)));

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("500000"), branchId);
            assertThat(fee).isEqualByComparingTo("0");
        }
    }

    @Nested
    @DisplayName("calculateHandlingFee — edge case-ek")
    class EdgeCaseTests {

        @Test
        @DisplayName("NULL összeg → 0 Ft díj")
        void shouldReturnZeroForNull() {
            BigDecimal fee = handlingFeeService.calculateHandlingFee(null, branchId);
            assertThat(fee).isEqualByComparingTo("0");
        }

        @Test
        @DisplayName("Negatív összeg → 0 Ft díj")
        void shouldReturnZeroForNegative() {
            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("-10000"), branchId);
            assertThat(fee).isEqualByComparingTo("0");
        }

        @Test
        @DisplayName("0 Ft összeg → 0 Ft díj")
        void shouldReturnZeroForZero() {
            BigDecimal fee = handlingFeeService.calculateHandlingFee(BigDecimal.ZERO, branchId);
            assertThat(fee).isEqualByComparingTo("0");
        }
    }

    @Nested
    @DisplayName("calculateHandlingFee — iroda-tudatos fail-closed feloldás (FK-096)")
    class BranchAwareTests {

        @Test
        @DisplayName("FR-4: PER_MILLE — az iroda SAJÁT mértékével számol, system_parameter ÉRINTETLEN")
        void perMilleAzIrodaSajatMertekevelSzamol() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.PER_MILLE,
                            new BigDecimal("3"), null)));
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("100000"), branchId);

            assertThat(fee).isEqualByComparingTo("300");
            verifyNoInteractions(systemParameterService);
        }

        @Test
        @DisplayName("PER_MILLE sapka az iroda SAJÁT maximumával")
        void perMilleSapkaAzIrodaSajatMaximumaval() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.PER_MILLE,
                            new BigDecimal("10"), new BigDecimal("500"))));
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("1000000"), branchId);
            assertThat(fee).isEqualByComparingTo("500");
        }

        @Test
        @DisplayName("FR-6: BRACKET mód a közös LIVE sávokat használja (status-szűrt finder)")
        void bracketModAKozosLiveSavokatHasznalja() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.BRACKET, null, null)));
            when(bracketRepository.findByCompanyIdAndStatusAndActiveOrderByBracketOrder(
                    companyId, FeeConfigStatus.LIVE, true))
                    .thenReturn(List.of(createBracket(new BigDecimal("100000"), new BigDecimal("200"), 1)));
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            handlingFeeService.calculateHandlingFee(new BigDecimal("50000"), branchId);

            verify(bracketRepository).findByCompanyIdAndStatusAndActiveOrderByBracketOrder(
                    companyId, FeeConfigStatus.LIVE, true);
        }

        @Test
        @DisplayName("FR-5: nincs LIVE sor → ValidationException (a branch id-val), SOHA nem néma 0 Ft")
        void nincsLiveSorEsetenValidationException() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() ->
                    handlingFeeService.calculateHandlingFee(new BigDecimal("100000"), branchId))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining(branchId.toString())
                    .hasMessageContaining("Nincs élő kezelési díj konfiguráció");
        }

        @Test
        @DisplayName("D4: NONE mód → 0 Ft")
        void noneModNullaFt() {
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(liveConfig(HandlingFeeType.NONE, null, null)));

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("100000"), branchId);
            assertThat(fee).isEqualByComparingTo("0");
        }

        @Test
        @DisplayName("DRAFT sor sosem használódik: csak DRAFT van → ValidationException")
        void draftSortSosemHasznal() {
            // A feloldás kizárólag LIVE statusra kérdez; DRAFT jelenléte nem számít.
            when(branchConfigRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    companyId, branchId, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() ->
                    handlingFeeService.calculateHandlingFee(new BigDecimal("100000"), branchId))
                    .as("Csak DRAFT konfiguráció mellett a díjfeloldás fail-closed")
                    .isInstanceOf(ValidationException.class);
        }
    }

    // === Helpers ===

    private static BranchHandlingFeeConfig liveConfig(HandlingFeeType mode,
                                                      BigDecimal perMilleRate,
                                                      BigDecimal perMilleCap) {
        return BranchHandlingFeeConfig.builder()
                .id(UUID.randomUUID())
                .companyId(UUID.randomUUID())
                .branchId(UUID.randomUUID())
                .feeMode(mode)
                .perMilleRate(perMilleRate)
                .perMilleCap(perMilleCap)
                .status(FeeConfigStatus.LIVE)
                .active(true)
                .version(0L)
                .build();
    }

    private HandlingFeeBracket createBracket(BigDecimal upperLimit, BigDecimal feeAmount, int order) {
        return HandlingFeeBracket.builder()
                .upperLimit(upperLimit)
                .feeAmount(feeAmount)
                .bracketOrder(order)
                .active(true)
                .build();
    }

    private void setupSecurityContext(UUID companyId, UUID branchId) {
        var details = new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, companyId, branchId, "CASHIER");
        var auth = new org.springframework.security.authentication.TestingAuthenticationToken(
                "test", "test", "ROLE_CASHIER");
        auth.setDetails(details);
        org.springframework.security.core.context.SecurityContextHolder.getContext()
                .setAuthentication(auth);
    }
}
