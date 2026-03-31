package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TransactionCalculationServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private TransactionCalculationService calculationService;

    private ExchangeRate mockRate;

    @BeforeEach
    void setUp() {
        mockRate = mock(ExchangeRate.class);
        lenient().when(mockRate.getBaseBuyRate()).thenReturn(new BigDecimal("390.50"));
        lenient().when(mockRate.getBaseSellRate()).thenReturn(new BigDecimal("395.80"));
        lenient().when(mockRate.getBuyRateForAmount(any())).thenReturn(new BigDecimal("390.50"));
        lenient().when(mockRate.getSellRateForAmount(any())).thenReturn(new BigDecimal("395.80"));
    }

    // --- calculateBuyHufAmount ---

    @Test
    @DisplayName("calculateBuyHufAmount - no discount")
    void calculateBuyHufAmount_noDiscount() {
        BigDecimal result = calculationService.calculateBuyHufAmount(
                new BigDecimal("100"), mockRate, null);
        // 100 * 390.50 = 39050
        assertThat(result).isEqualByComparingTo("39050");
    }

    @Test
    @DisplayName("calculateBuyHufAmount - with discount adds to buy amount")
    void calculateBuyHufAmount_withDiscount() {
        BigDecimal result = calculationService.calculateBuyHufAmount(
                new BigDecimal("100"), mockRate, new BigDecimal("2"));
        // base = 39050, discount = 39050 * 2/100 = 781 -> 39050 + 781 = 39831
        assertThat(result).isEqualByComparingTo("39831");
    }

    @Test
    @DisplayName("calculateBuyHufAmount - zero discount same as no discount")
    void calculateBuyHufAmount_zeroDiscount() {
        BigDecimal result = calculationService.calculateBuyHufAmount(
                new BigDecimal("100"), mockRate, BigDecimal.ZERO);
        assertThat(result).isEqualByComparingTo("39050");
    }

    // --- calculateSellHufAmount ---

    @Test
    @DisplayName("calculateSellHufAmount - no discount")
    void calculateSellHufAmount_noDiscount() {
        BigDecimal result = calculationService.calculateSellHufAmount(
                new BigDecimal("100"), mockRate, null);
        // 100 * 395.80 = 39580
        assertThat(result).isEqualByComparingTo("39580");
    }

    @Test
    @DisplayName("calculateSellHufAmount - with discount subtracts from sell amount")
    void calculateSellHufAmount_withDiscount() {
        BigDecimal result = calculationService.calculateSellHufAmount(
                new BigDecimal("100"), mockRate, new BigDecimal("2"));
        // base = 39580, discount = 39580 * 2/100 = 792 -> 39580 - 792 = 38788
        assertThat(result).isEqualByComparingTo("38788");
    }

    // --- resolveBuyRate ---

    @Test
    @DisplayName("resolveBuyRate - null custom rate uses tier-based rate")
    void resolveBuyRate_noCustomRate() {
        BigDecimal result = calculationService.resolveBuyRate(
                mockRate, new BigDecimal("100"), null);
        assertThat(result).isEqualByComparingTo("390.50");
    }

    @Test
    @DisplayName("resolveBuyRate - valid custom rate accepted")
    void resolveBuyRate_validCustomRate() {
        when(mockRate.getOfficialRate()).thenReturn(new BigDecimal("395.00"));
        BigDecimal result = calculationService.resolveBuyRate(
                mockRate, new BigDecimal("100"), new BigDecimal("392.00"));
        assertThat(result).isEqualByComparingTo("392.00");
    }

    @Test
    @DisplayName("resolveBuyRate - custom rate below base throws")
    void resolveBuyRate_belowBase_throws() {
        assertThatThrownBy(() ->
                calculationService.resolveBuyRate(mockRate, new BigDecimal("100"), new BigDecimal("380.00")))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("resolveBuyRate - zero custom rate throws")
    void resolveBuyRate_zero_throws() {
        assertThatThrownBy(() ->
                calculationService.resolveBuyRate(mockRate, new BigDecimal("100"), BigDecimal.ZERO))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("resolveBuyRate - custom rate above official throws")
    void resolveBuyRate_aboveOfficial_throws() {
        when(mockRate.getOfficialRate()).thenReturn(new BigDecimal("393.00"));
        assertThatThrownBy(() ->
                calculationService.resolveBuyRate(mockRate, new BigDecimal("100"), new BigDecimal("394.00")))
                .isInstanceOf(ValidationException.class);
    }

    // --- resolveSellRate ---

    @Test
    @DisplayName("resolveSellRate - null custom rate uses tier-based rate")
    void resolveSellRate_noCustomRate() {
        BigDecimal result = calculationService.resolveSellRate(
                mockRate, new BigDecimal("100"), null);
        assertThat(result).isEqualByComparingTo("395.80");
    }

    @Test
    @DisplayName("resolveSellRate - custom rate above base throws")
    void resolveSellRate_aboveBase_throws() {
        assertThatThrownBy(() ->
                calculationService.resolveSellRate(mockRate, new BigDecimal("100"), new BigDecimal("400.00")))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("resolveSellRate - custom rate below official throws")
    void resolveSellRate_belowOfficial_throws() {
        when(mockRate.getOfficialRate()).thenReturn(new BigDecimal("393.00"));
        assertThatThrownBy(() ->
                calculationService.resolveSellRate(mockRate, new BigDecimal("100"), new BigDecimal("392.00")))
                .isInstanceOf(ValidationException.class);
    }

    // --- applyBuyDiscount ---

    @Test
    @DisplayName("applyBuyDiscount - null discount returns original")
    void applyBuyDiscount_null() {
        BigDecimal result = calculationService.applyBuyDiscount(new BigDecimal("39050"), null);
        assertThat(result).isEqualByComparingTo("39050");
    }

    @Test
    @DisplayName("applyBuyDiscount - 2% adds to amount")
    void applyBuyDiscount_2pct() {
        BigDecimal result = calculationService.applyBuyDiscount(new BigDecimal("39050"), new BigDecimal("2"));
        assertThat(result).isEqualByComparingTo("39831");
    }

    // --- applySellDiscount ---

    @Test
    @DisplayName("applySellDiscount - 2% subtracts from amount")
    void applySellDiscount_2pct() {
        BigDecimal result = calculationService.applySellDiscount(new BigDecimal("39580"), new BigDecimal("2"));
        assertThat(result).isEqualByComparingTo("38788");
    }

    // --- calculateDiscountAmount ---

    @Test
    @DisplayName("calculateDiscountAmount - zero percent returns ZERO")
    void calculateDiscountAmount_zero() {
        BigDecimal result = calculationService.calculateDiscountAmount(new BigDecimal("50000"), BigDecimal.ZERO);
        assertThat(result).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("calculateDiscountAmount - 5% of 50000 = 2500")
    void calculateDiscountAmount_5pct() {
        BigDecimal result = calculationService.calculateDiscountAmount(new BigDecimal("50000"), new BigDecimal("5"));
        assertThat(result).isEqualByComparingTo("2500");
    }

    // --- validateDiscount ---

    @Test
    @DisplayName("validateDiscount - negative throws")
    void validateDiscount_negative_throws() {
        assertThatThrownBy(() -> calculationService.validateDiscount(new BigDecimal("-1")))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("validateDiscount - above 15% throws")
    void validateDiscount_above15_throws() {
        assertThatThrownBy(() -> calculationService.validateDiscount(new BigDecimal("16")))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("validateDiscount - above 2% non-supervisor throws")
    void validateDiscount_above2_nonSupervisor_throws() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

            assertThatThrownBy(() -> calculationService.validateDiscount(new BigDecimal("3")))
                    .isInstanceOf(ValidationException.class);
        }
    }

    @Test
    @DisplayName("validateDiscount - above 2% supervisor passes")
    void validateDiscount_above2_supervisor_passes() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            lenient().when(transactionRepository.countDailyDiscountsByWorker(eq(1L), any())).thenReturn(0L);

            assertThatCode(() -> calculationService.validateDiscount(new BigDecimal("3")))
                    .doesNotThrowAnyException();
        }
    }

    @Test
    @DisplayName("validateDiscount - daily limit exceeded throws")
    void validateDiscount_dailyLimit_throws() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            lenient().when(transactionRepository.countDailyDiscountsByWorker(eq(1L), any())).thenReturn(5L);

            // 1% is within 2% limit, so it passes supervisor check but hits daily limit
            assertThatThrownBy(() -> calculationService.validateDiscount(new BigDecimal("1")))
                    .isInstanceOf(ValidationException.class);
        }
    }
}
