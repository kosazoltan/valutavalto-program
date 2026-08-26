package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.calculator.CalculationResultDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * CurrencyCalculatorService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class CurrencyCalculatorServiceTest {

    @InjectMocks
    private CurrencyCalculatorService service;

    @Mock
    private ExchangeRateRepository exchangeRateRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    @Mock
    private RoundingRuleService roundingRuleService;

    @Mock
    private HandlingFeeService handlingFeeService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    private Currency createCurrency(Long id, String code) {
        return Currency.builder().id(id).code(code).build();
    }

    private ExchangeRate createRate(BigDecimal buyRate, BigDecimal sellRate) {
        return ExchangeRate.builder()
                .baseBuyRate(buyRate)
                .baseSellRate(sellRate)
                .active(true)
                .build();
    }

    @Test
    @DisplayName("calculate BUY EUR → correct HUF amount")
    void testCalculate_buyEur() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            Currency eur = createCurrency(1L, "EUR");
            ExchangeRate rate = createRate(new BigDecimal("390.00"), new BigDecimal("395.00"));

            when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 1L, BRANCH_ID))
                    .thenReturn(Optional.of(rate));
            when(handlingFeeService.calculateHandlingFee(any(BigDecimal.class), any()))
                    .thenReturn(BigDecimal.ZERO);

            // BUY direction: customer sells EUR, gets HUF → buy rate
            CalculationResultDto result = service.calculate("EUR", "HUF",
                    new BigDecimal("100"), "BUY");

            assertThat(result).isNotNull();
            assertThat(result.getFromCurrency()).isEqualTo("EUR");
            assertThat(result.getToCurrency()).isEqualTo("HUF");
            assertThat(result.getFromAmount()).isEqualByComparingTo(new BigDecimal("100"));
            // 100 * 390 = 39000
            assertThat(result.getToAmount()).isEqualByComparingTo(new BigDecimal("39000"));
            assertThat(result.getDirection()).isEqualTo("BUY");
        }
    }

    @Test
    @DisplayName("calculate SELL USD → correct amount")
    void testCalculate_sellUsd() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            Currency usd = createCurrency(2L, "USD");
            ExchangeRate rate = createRate(new BigDecimal("355.00"), new BigDecimal("360.00"));

            when(currencyRepository.findByCode("USD")).thenReturn(Optional.of(usd));
            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 2L, BRANCH_ID))
                    .thenReturn(Optional.of(rate));
            when(roundingRuleService.roundAmount(eq("USD"), any(BigDecimal.class), eq("SELL")))
                    .thenAnswer(inv -> inv.getArgument(1));
            when(handlingFeeService.calculateHandlingFee(any(BigDecimal.class), any()))
                    .thenReturn(BigDecimal.ZERO);

            // SELL direction: customer buys USD with HUF → sell rate
            // HUF → USD: 36000 / 360 = 100
            CalculationResultDto result = service.calculate("HUF", "USD",
                    new BigDecimal("36000"), "SELL");

            assertThat(result).isNotNull();
            assertThat(result.getFromCurrency()).isEqualTo("HUF");
            assertThat(result.getToCurrency()).isEqualTo("USD");
            assertThat(result.getFromAmount()).isEqualByComparingTo(new BigDecimal("36000"));
            assertThat(result.getToAmount()).isEqualByComparingTo(new BigDecimal("100"));
        }
    }

    @Test
    @DisplayName("calculateReverse → correct foreign amount for HUF")
    void testCalculateReverse() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            Currency eur = createCurrency(1L, "EUR");
            ExchangeRate rate = createRate(new BigDecimal("390.00"), new BigDecimal("395.00"));

            when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 1L, BRANCH_ID))
                    .thenReturn(Optional.of(rate));
            when(roundingRuleService.roundAmount(eq("EUR"), any(BigDecimal.class), eq("SELL")))
                    .thenAnswer(inv -> inv.getArgument(1));

            // 39500 HUF / 395 sell rate = 100 EUR
            BigDecimal result = service.calculateReverse("EUR", new BigDecimal("39500"));

            assertThat(result).isNotNull();
            assertThat(result).isEqualByComparingTo(new BigDecimal("100.0000"));
        }
    }

    @Test
    @DisplayName("calculate → negative amount → ValidationException")
    void testCalculate_negativeAmount() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatThrownBy(() ->
                    service.calculate("EUR", "HUF", new BigDecimal("-100"), "BUY"))
                    .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class);
        }
    }

    @Test
    @DisplayName("calculateReverse → zero amount → ValidationException")
    void testCalculateReverse_zeroAmount() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            assertThatThrownBy(() ->
                    service.calculateReverse("EUR", BigDecimal.ZERO))
                    .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class);
        }
    }

    @Test
    @DisplayName("getExchangeMatrix → correct dimensions")
    void testGetExchangeMatrix_dimensions() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);

            Currency eur = createCurrency(1L, "EUR");
            eur.setActive(true);
            Currency usd = createCurrency(2L, "USD");
            usd.setActive(true);
            Currency huf = createCurrency(3L, "HUF");
            huf.setActive(true);

            when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc())
                    .thenReturn(List.of(eur, usd, huf));

            ExchangeRate eurRate = createRate(new BigDecimal("390.00"), new BigDecimal("395.00"));
            ExchangeRate usdRate = createRate(new BigDecimal("355.00"), new BigDecimal("360.00"));

            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 1L, BRANCH_ID))
                    .thenReturn(Optional.of(eurRate));
            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 2L, BRANCH_ID))
                    .thenReturn(Optional.of(usdRate));

            Map<String, Map<String, BigDecimal>> matrix = service.getExchangeMatrix();

            assertThat(matrix).isNotNull();
            // EUR → USD és USD → EUR (HUF kihagyva)
            assertThat(matrix).containsKey("EUR");
            assertThat(matrix).containsKey("USD");
            assertThat(matrix.get("EUR")).containsKey("USD");
            assertThat(matrix.get("USD")).containsKey("EUR");
        }
    }
}
