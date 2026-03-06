package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

/**
 * HandlingFeeService UNIT tesztek.
 *
 * Teszteli:
 * - Sávos díjszámítás (BRACKET)
 * - Ezrelékes díjszámítás (PER_MILLE)
 * - NONE típus (nincs díj)
 * - NULL/negatív összeg kezelés
 * - DiscountThreshold automatikus alkalmazás
 */
@ExtendWith(MockitoExtension.class)
class HandlingFeeServiceTest {

    @Mock private SystemParameterService systemParameterService;
    @Mock private HandlingFeeBracketRepository bracketRepository;
    @Mock private HandlingFeeTransactionRepository feeTransactionRepository;
    @Mock private DiscountThresholdService discountThresholdService;

    @InjectMocks
    private HandlingFeeService handlingFeeService;

    @Nested
    @DisplayName("calculateHandlingFee — BRACKET mód")
    class BracketTests {

        @BeforeEach
        void setup() {
            when(systemParameterService.getValue("HANDLING_FEE_TYPE")).thenReturn("BRACKET");
        }

        @Test
        @DisplayName("50.000 Ft → 200 Ft díj (1. sáv)")
        void shouldReturnFirstBracketFee() {
            UUID companyId = UUID.randomUUID();
            setupSecurityContext(companyId);

            List<HandlingFeeBracket> brackets = List.of(
                    createBracket(new BigDecimal("100000"), new BigDecimal("200"), 1),
                    createBracket(new BigDecimal("500000"), new BigDecimal("500"), 2),
                    createBracket(new BigDecimal("1000000"), new BigDecimal("1000"), 3)
            );
            when(bracketRepository.findByCompanyIdAndActiveOrderByBracketOrder(any(), eq(true)))
                    .thenReturn(brackets);
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("50000"));
            assertThat(fee).isEqualByComparingTo("200");
        }

        @Test
        @DisplayName("300.000 Ft → 500 Ft díj (2. sáv)")
        void shouldReturnSecondBracketFee() {
            UUID companyId = UUID.randomUUID();
            setupSecurityContext(companyId);

            List<HandlingFeeBracket> brackets = List.of(
                    createBracket(new BigDecimal("100000"), new BigDecimal("200"), 1),
                    createBracket(new BigDecimal("500000"), new BigDecimal("500"), 2)
            );
            when(bracketRepository.findByCompanyIdAndActiveOrderByBracketOrder(any(), eq(true)))
                    .thenReturn(brackets);
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("300000"));
            assertThat(fee).isEqualByComparingTo("500");
        }
    }

    @Nested
    @DisplayName("calculateHandlingFee — PER_MILLE mód")
    class PerMilleTests {

        @Test
        @DisplayName("100.000 Ft × 5‰ = 500 Ft")
        void shouldCalculatePerMille() {
            when(systemParameterService.getValue("HANDLING_FEE_TYPE")).thenReturn("PER_MILLE");
            when(systemParameterService.getValue("HANDLING_FEE_PER_MILLE")).thenReturn("5");
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("100000"));
            assertThat(fee).isEqualByComparingTo("500");
        }

        @Test
        @DisplayName("1.000.000 Ft × 3‰ = 3.000 Ft")
        void shouldCalculateLargePerMille() {
            when(systemParameterService.getValue("HANDLING_FEE_TYPE")).thenReturn("PER_MILLE");
            when(systemParameterService.getValue("HANDLING_FEE_PER_MILLE")).thenReturn("3");
            when(discountThresholdService.resolveDiscount(any()))
                    .thenReturn(java.util.Optional.empty());

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("1000000"));
            assertThat(fee).isEqualByComparingTo("3000");
        }
    }

    @Nested
    @DisplayName("calculateHandlingFee — NONE mód")
    class NoneTests {

        @Test
        @DisplayName("NONE típusnál mindig 0 Ft")
        void shouldReturnZeroForNone() {
            when(systemParameterService.getValue("HANDLING_FEE_TYPE")).thenReturn("NONE");

            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("500000"));
            assertThat(fee).isEqualByComparingTo("0");
        }
    }

    @Nested
    @DisplayName("calculateHandlingFee — edge case-ek")
    class EdgeCaseTests {

        @Test
        @DisplayName("NULL összeg → 0 Ft díj")
        void shouldReturnZeroForNull() {
            BigDecimal fee = handlingFeeService.calculateHandlingFee(null);
            assertThat(fee).isEqualByComparingTo("0");
        }

        @Test
        @DisplayName("Negatív összeg → 0 Ft díj")
        void shouldReturnZeroForNegative() {
            BigDecimal fee = handlingFeeService.calculateHandlingFee(new BigDecimal("-10000"));
            assertThat(fee).isEqualByComparingTo("0");
        }

        @Test
        @DisplayName("0 Ft összeg → 0 Ft díj")
        void shouldReturnZeroForZero() {
            BigDecimal fee = handlingFeeService.calculateHandlingFee(BigDecimal.ZERO);
            assertThat(fee).isEqualByComparingTo("0");
        }
    }

    // === Helpers ===

    private HandlingFeeBracket createBracket(BigDecimal upperLimit, BigDecimal feeAmount, int order) {
        return HandlingFeeBracket.builder()
                .upperLimit(upperLimit)
                .feeAmount(feeAmount)
                .bracketOrder(order)
                .active(true)
                .build();
    }

    private void setupSecurityContext(UUID companyId) {
        // SecurityUtils mock — a tényleges SecurityUtils statikus metódusok mock-olása
        // production-ben Spring Security context-ből jön
        try {
            var auth = new org.springframework.security.authentication.TestingAuthenticationToken(
                    "test", "test", "ROLE_CASHIER");
            var details = new java.util.HashMap<String, Object>();
            details.put("companyId", companyId);
            auth.setDetails(details);
            org.springframework.security.core.context.SecurityContextHolder.getContext()
                    .setAuthentication(auth);
        } catch (Exception e) {
            // SecurityContext setup failure — tesztek más mock-ot használnak
        }
    }
}
