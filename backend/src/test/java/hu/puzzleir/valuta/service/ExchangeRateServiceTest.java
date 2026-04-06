package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ExchangeRateServiceTest {

    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyRepository currencyRepository;
    @InjectMocks private ExchangeRateService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Test
    @DisplayName("getCurrentRate — friss arfolyam")
    void testGetCurrentRate_fresh() {
        ReflectionTestUtils.setField(service, "maxAgeHours", 24);

        Currency eur = Currency.builder().id(4L).code("EUR").build();
        ExchangeRate rate = ExchangeRate.builder()
                .id(1L)
                .currency(eur)
                .baseBuyRate(new BigDecimal("395.50"))
                .baseSellRate(new BigDecimal("405.50"))
                .validDate(LocalDate.now())
                .validTime(LocalTime.now().minusHours(1))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 4L, BRANCH_ID))
                    .thenReturn(Optional.of(rate));

            ExchangeRate result = service.getCurrentRate(4L);
            assertThat(result.getBaseBuyRate()).isEqualByComparingTo("395.50");
        }
    }

    @Test
    @DisplayName("getCurrentRate — lejart arfolyam elutasitva")
    void testGetCurrentRate_expired() {
        ReflectionTestUtils.setField(service, "maxAgeHours", 24);

        Currency eur = Currency.builder().id(4L).code("EUR").build();
        ExchangeRate rate = ExchangeRate.builder()
                .id(1L)
                .currency(eur)
                .baseBuyRate(new BigDecimal("395.50"))
                .validDate(LocalDate.now().minusDays(3))
                .validTime(LocalTime.NOON)
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 4L, BRANCH_ID))
                    .thenReturn(Optional.of(rate));

            assertThatThrownBy(() -> service.getCurrentRate(4L))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("lejárt");
        }
    }

    @Test
    @DisplayName("getCurrentRate — nem letezo valuta")
    void testGetCurrentRate_notFound() {
        ReflectionTestUtils.setField(service, "maxAgeHours", 24);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 999L, BRANCH_ID))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.getCurrentRate(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("getCurrentRateByCode — valuta kod alapjan")
    void testGetCurrentRateByCode() {
        ReflectionTestUtils.setField(service, "maxAgeHours", 0); // no expiry check

        Currency usd = Currency.builder().id(5L).code("USD").build();
        ExchangeRate rate = ExchangeRate.builder()
                .id(2L)
                .currency(usd)
                .baseBuyRate(new BigDecimal("360.00"))
                .baseSellRate(new BigDecimal("370.00"))
                .validDate(LocalDate.now())
                .validTime(LocalTime.now())
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(currencyRepository.findByCode("USD")).thenReturn(Optional.of(usd));
            when(exchangeRateRepository.findLatestRate(COMPANY_ID, 5L, BRANCH_ID))
                    .thenReturn(Optional.of(rate));

            ExchangeRate result = service.getCurrentRateByCode("USD");
            assertThat(result.getBaseSellRate()).isEqualByComparingTo("370.00");
        }
    }

    @Test
    @DisplayName("getAllCurrentRates — osszes valuta arfolyam")
    void testGetAllCurrentRates() {
        Currency eur = Currency.builder().id(4L).code("EUR").build();
        Currency usd = Currency.builder().id(5L).code("USD").build();
        ExchangeRate r1 = ExchangeRate.builder().id(1L).currency(eur).build();
        ExchangeRate r2 = ExchangeRate.builder().id(2L).currency(usd).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            when(exchangeRateRepository.findAllActiveRates(COMPANY_ID, BRANCH_ID))
                    .thenReturn(List.of(r1, r2));

            List<ExchangeRate> result = service.getAllCurrentRates();
            assertThat(result).hasSize(2);
        }
    }
}
