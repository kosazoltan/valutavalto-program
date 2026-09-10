package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.MnbExchangeRateCacheRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-061 (A6, Defect D part 2): getRatesForDate must fill a PARTIALLY cached date.
 *
 * <p>Production shape: the cache for a date may hold only the currencies someone asked for
 * earlier (AUD,CAD,DKK,NOK,SEK,TRY) while the active currency list also contains EUR/USD/GBP.
 * On BASE 1588b5b2 a non-empty {@code findByRateDate} result short-circuited, the missing codes
 * were never fetched, and the decade report later threw "Hiányzó MNB árfolyam".</p>
 *
 * <p>Target behaviour (WU-6): completeness = the cached day holds every ACTIVE currency code.
 * Incomplete cache ⇒ one bounded SOAP attempt per date (in-process TTL attempt map, so the
 * 7-day walk-back × MNB-unquoted currencies cannot hammer MNB), the SOAP result merged OVER the
 * cached map, union returned; on fetch failure or a suppressed repeat attempt the cached partial
 * map is returned (never emptied). A complete cached date never fetches.</p>
 *
 * <p>The SOAP call is intercepted by spying the package-visible {@code fetchAndCacheRates}
 * (same test-seam convention as {@code parseSoapResponse}); the test never touches the network.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class MnbPartialCacheFkh061Test {

    private static final LocalDate DATE = LocalDate.of(2026, 9, 1);

    @Mock private MnbExchangeRateCacheRepository cacheRepository;
    @Mock private CurrencyRepository currencyRepository;

    private MnbExchangeRateService service;

    @BeforeEach
    void setUp() {
        service = spy(new MnbExchangeRateService(cacheRepository, currencyRepository));
        // Active currency list: the 6 cached codes plus the 3 the cache is missing.
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc())
            .thenReturn(List.of(
                currency("AUD"), currency("CAD"), currency("DKK"),
                currency("NOK"), currency("SEK"), currency("TRY"),
                currency("EUR"), currency("USD"), currency("GBP")));
    }

    private static Currency currency(String code) {
        return Currency.builder().code(code).name(code).active(true).build();
    }

    private static MnbExchangeRateCache cached(String code) {
        return MnbExchangeRateCache.builder()
            .currencyCode(code)
            .rateDate(DATE)
            .officialRate(new BigDecimal("100.00"))
            .unit(1)
            .build();
    }

    private static MnbExchangeRateCache fetched(String code) {
        return MnbExchangeRateCache.builder()
            .currencyCode(code)
            .rateDate(DATE)
            .officialRate(new BigDecimal("400.00"))
            .unit(1)
            .build();
    }

    private void stubPartialCache() {
        when(cacheRepository.findByRateDate(DATE)).thenReturn(List.of(
            cached("AUD"), cached("CAD"), cached("DKK"),
            cached("NOK"), cached("SEK"), cached("TRY")));
    }

    @Test
    @DisplayName("FKH-061 A6: partial cache ⇒ one SOAP attempt, union of 9 codes returned")
    void partialCacheIsCompletedWithOneFetch() throws Exception {
        stubPartialCache();
        doReturn(Map.of("EUR", fetched("EUR"), "USD", fetched("USD"), "GBP", fetched("GBP")))
            .when(service).fetchAndCacheRates(DATE);

        Map<String, MnbExchangeRateCache> result = service.getRatesForDate(DATE);

        assertThat(result)
            .containsKeys("AUD", "CAD", "DKK", "NOK", "SEK", "TRY", "EUR", "USD", "GBP");
        // Cached rows keep their cached rate; fetched rows carry the SOAP rate.
        assertThat(result.get("AUD").getOfficialRate()).isEqualByComparingTo("100.00");
        assertThat(result.get("EUR").getOfficialRate()).isEqualByComparingTo("400.00");
        verify(service, times(1)).fetchAndCacheRates(DATE);
    }

    @Test
    @DisplayName("FKH-061 A6: second call inside the TTL does not fetch again (bounded walk-back)")
    void secondCallInsideTtlDoesNotFetchAgain() throws Exception {
        stubPartialCache();
        doReturn(Map.of("EUR", fetched("EUR")))
            .when(service).fetchAndCacheRates(DATE);

        Map<String, MnbExchangeRateCache> first = service.getRatesForDate(DATE);
        Map<String, MnbExchangeRateCache> second = service.getRatesForDate(DATE);

        // Attempt map: still exactly one SOAP call for the date — the walk-back cannot
        // hammer MNB. The second call returns the cached partial map (never empty).
        verify(service, times(1)).fetchAndCacheRates(DATE);
        assertThat(first).containsKeys("AUD", "EUR");
        assertThat(second).containsKeys("AUD", "CAD", "DKK", "NOK", "SEK", "TRY");
    }

    @Test
    @DisplayName("FKH-061 A6: complete cached date never fetches")
    void completeCacheNeverFetches() throws Exception {
        when(cacheRepository.findByRateDate(DATE)).thenReturn(List.of(
            cached("AUD"), cached("CAD"), cached("DKK"), cached("NOK"),
            cached("SEK"), cached("TRY"), cached("EUR"), cached("USD"), cached("GBP")));

        Map<String, MnbExchangeRateCache> result = service.getRatesForDate(DATE);

        assertThat(result).hasSize(9);
        verify(service, never()).fetchAndCacheRates(any(LocalDate.class));
    }

    @Test
    @DisplayName("FKH-061 A6: SOAP failure on a partial date returns the cached partial map (never empty)")
    void soapFailureKeepsCachedPartialMap() throws Exception {
        stubPartialCache();
        doThrow(new RuntimeException("MNB down")).when(service).fetchAndCacheRates(DATE);

        @SuppressWarnings("unchecked")
        final Map<String, MnbExchangeRateCache>[] holder = new Map[1];
        assertThatCode(() -> holder[0] = service.getRatesForDate(DATE)).doesNotThrowAnyException();
        assertThat(holder[0]).containsKeys("AUD", "CAD", "DKK", "NOK", "SEK", "TRY");
        assertThat(holder[0]).doesNotContainKey("EUR");
    }
}
