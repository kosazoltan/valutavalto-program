package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.BankApiAuthType;
import hu.puzzleir.valuta.entity.BankApiConfig;
import hu.puzzleir.valuta.entity.BankApiMode;
import hu.puzzleir.valuta.entity.BankApiRunStatus;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.repository.MnbExchangeRateCacheRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RaiffeisenRateServiceConfigTest {

    @Mock
    private MnbExchangeRateCacheRepository cacheRepository;

    @Mock
    private BankApiConfigService bankApiConfigService;

    @Test
    @DisplayName("Disabled bank_api_config eseten scraping nelkul SKIPPED status keletkezik")
    void fetchAndCacheRates_skipsWhenDisabled() throws Exception {
        RaiffeisenRateService service = spy(new RaiffeisenRateService(cacheRepository, bankApiConfigService));
        when(bankApiConfigService.getOrCreate("RAIFFEISEN")).thenReturn(config(BankApiMode.DISABLED, false));

        int saved = service.fetchAndCacheRates();

        assertThat(saved).isZero();
        verify(service, never()).scrapeRates(any());
        verify(bankApiConfigService).recordRun(eq("RAIFFEISEN"), eq(BankApiRunStatus.SKIPPED), any());
    }

    @Test
    @DisplayName("Scraping exception FAILED status, cache erintetlen")
    void fetchAndCacheRates_recordsFailureWhenScrapeThrows() throws Exception {
        RaiffeisenRateService service = spy(new RaiffeisenRateService(cacheRepository, bankApiConfigService));
        when(bankApiConfigService.getOrCreate("RAIFFEISEN"))
                .thenReturn(config(BankApiMode.HTML_SCRAPING_FALLBACK, true));
        doThrow(new IllegalStateException("html layout changed"))
                .when(service).scrapeRates("https://bank.example/rates");

        int saved = service.fetchAndCacheRates();

        assertThat(saved).isZero();
        verify(cacheRepository, never()).save(any());
        verify(bankApiConfigService).recordRun(eq("RAIFFEISEN"), eq(BankApiRunStatus.FAILED), any());
    }

    @Test
    @DisplayName("Sikeres konfiguralt endpoint scraping SUCCESS statust ir")
    void fetchAndCacheRates_recordsSuccess() throws Exception {
        RaiffeisenRateService service = spy(new RaiffeisenRateService(cacheRepository, bankApiConfigService));
        when(bankApiConfigService.getOrCreate("RAIFFEISEN"))
                .thenReturn(config(BankApiMode.REST_PRIMARY_WITH_HTML_FALLBACK, true));
        doReturn(scrapedRates()).when(service).scrapeRates("https://bank.example/rates");
        when(cacheRepository.findByCurrencyCodeAndRateDateAndSource(eq("EUR"), any(), eq("RAIFFEISEN")))
                .thenReturn(Optional.empty());
        when(cacheRepository.save(any(MnbExchangeRateCache.class))).thenAnswer(invocation -> invocation.getArgument(0));

        int saved = service.fetchAndCacheRates();

        assertThat(saved).isEqualTo(1);
        verify(cacheRepository).save(any(MnbExchangeRateCache.class));
        verify(bankApiConfigService).recordRun(eq("RAIFFEISEN"), eq(BankApiRunStatus.SUCCESS), any());
    }

    private BankApiConfig config(BankApiMode mode, boolean enabled) {
        return BankApiConfig.builder()
                .providerName("RAIFFEISEN")
                .mode(mode)
                .endpointUrl("https://bank.example/rates")
                .authType(BankApiAuthType.NONE)
                .updateFrequency("0 0 8 * * MON-FRI")
                .enabled(enabled)
                .lastRunStatus(BankApiRunStatus.NEVER_RUN)
                .build();
    }

    private Map<String, RaiffeisenRateService.RaiffeisenRate> scrapedRates() {
        Map<String, RaiffeisenRateService.RaiffeisenRate> rates = new LinkedHashMap<>();
        rates.put("EUR", new RaiffeisenRateService.RaiffeisenRate(
                "EUR",
                1,
                new BigDecimal("390.0000"),
                new BigDecimal("400.0000"),
                new BigDecimal("410.0000"),
                new BigDecimal("400.0000")));
        return rates;
    }
}
