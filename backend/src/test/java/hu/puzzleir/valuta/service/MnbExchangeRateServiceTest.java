package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.repository.MnbExchangeRateCacheRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * MnbExchangeRateService UNIT tesztek — Mockito.
 *
 * Teszteli:
 * - SOAP XML válasz parsingját
 * - Cache logikát (ha van cache, ne hívjon SOAP-ot)
 * - Fallback viselkedést (ha nincs pontos nap, utolsó cache-elt adat)
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class MnbExchangeRateServiceTest {

    @InjectMocks
    private MnbExchangeRateService mnbExchangeRateService;

    @Mock
    private MnbExchangeRateCacheRepository cacheRepository;

    // ============ XML PARSING TESZTEK ============

    @Test
    @DisplayName("parseSoapResponse: helyes EUR/HUF és USD/HUF parsing tizedesvesszővel")
    void testParseSoapResponse_validXml() throws Exception {
        String soapXml = """
                <?xml version="1.0" encoding="utf-8"?>
                <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
                  <soap:Body>
                    <GetExchangeRatesResponse xmlns="http://www.mnb.hu/webservices/">
                      <GetExchangeRatesResult>
                        &lt;MNBExchangeRates&gt;
                          &lt;Day date="2026-03-10"&gt;
                            &lt;Rate unit="1" curr="EUR"&gt;395,12&lt;/Rate&gt;
                            &lt;Rate unit="1" curr="USD"&gt;370,50&lt;/Rate&gt;
                            &lt;Rate unit="1" curr="GBP"&gt;470,85&lt;/Rate&gt;
                            &lt;Rate unit="1" curr="CHF"&gt;418,30&lt;/Rate&gt;
                            &lt;Rate unit="100" curr="CZK"&gt;1572,00&lt;/Rate&gt;
                            &lt;Rate unit="100" curr="JPY"&gt;265,00&lt;/Rate&gt;
                          &lt;/Day&gt;
                        &lt;/MNBExchangeRates&gt;
                      </GetExchangeRatesResult>
                    </GetExchangeRatesResponse>
                  </soap:Body>
                </soap:Envelope>
                """;

        Map<String, MnbExchangeRateCache> result = mnbExchangeRateService.parseSoapResponse(soapXml);

        assertThat(result).hasSize(6);

        // EUR — unit=1, rate=395.12
        MnbExchangeRateCache eur = result.get("EUR");
        assertThat(eur).isNotNull();
        assertThat(eur.getCurrencyCode()).isEqualTo("EUR");
        assertThat(eur.getOfficialRate()).isEqualByComparingTo(new BigDecimal("395.12"));
        assertThat(eur.getUnit()).isEqualTo(1);
        assertThat(eur.getRateDate()).isEqualTo(LocalDate.of(2026, 3, 10));
        assertThat(eur.getRatePerUnit()).isEqualByComparingTo(new BigDecimal("395.12"));

        // USD — unit=1, rate=370.50
        MnbExchangeRateCache usd = result.get("USD");
        assertThat(usd).isNotNull();
        assertThat(usd.getOfficialRate()).isEqualByComparingTo(new BigDecimal("370.50"));

        // CZK — unit=100, rate=1572.00 → ratePerUnit=15.72
        MnbExchangeRateCache czk = result.get("CZK");
        assertThat(czk).isNotNull();
        assertThat(czk.getOfficialRate()).isEqualByComparingTo(new BigDecimal("1572.00"));
        assertThat(czk.getUnit()).isEqualTo(100);
        assertThat(czk.getRatePerUnit()).isEqualByComparingTo(new BigDecimal("15.7200"));

        // JPY — unit=100, rate=265.00 → ratePerUnit=2.65
        MnbExchangeRateCache jpy = result.get("JPY");
        assertThat(jpy).isNotNull();
        assertThat(jpy.getRatePerUnit()).isEqualByComparingTo(new BigDecimal("2.6500"));
    }

    @Test
    @DisplayName("parseSoapResponse: üres válasz kezelése")
    void testParseSoapResponse_emptyResult() throws Exception {
        String soapXml = """
                <?xml version="1.0" encoding="utf-8"?>
                <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
                  <soap:Body>
                    <GetExchangeRatesResponse xmlns="http://www.mnb.hu/webservices/">
                      <GetExchangeRatesResult></GetExchangeRatesResult>
                    </GetExchangeRatesResponse>
                  </soap:Body>
                </soap:Envelope>
                """;

        Map<String, MnbExchangeRateCache> result = mnbExchangeRateService.parseSoapResponse(soapXml);

        assertThat(result).isEmpty();
    }

    // ============ CACHE LOGIKA TESZTEK ============

    @Test
    @DisplayName("getRatesForDate: cache-ből szolgálja ki, ha van adat")
    void testGetRatesForDate_fromCache() {
        LocalDate date = LocalDate.of(2026, 3, 10);

        MnbExchangeRateCache cachedEur = MnbExchangeRateCache.builder()
                .currencyCode("EUR")
                .rateDate(date)
                .officialRate(new BigDecimal("395.12"))
                .unit(1)
                .build();

        when(cacheRepository.findByRateDate(date)).thenReturn(List.of(cachedEur));

        Map<String, MnbExchangeRateCache> result = mnbExchangeRateService.getRatesForDate(date);

        assertThat(result).hasSize(1);
        assertThat(result.get("EUR").getOfficialRate()).isEqualByComparingTo(new BigDecimal("395.12"));

        // Nem szabad SOAP-ot hívnia (cache volt)
        verify(cacheRepository, never()).save(any());
    }

    @Test
    @DisplayName("getRatesForDate: fallback a legutolsó cache-elt adatra")
    void testGetRatesForDate_fallback() {
        LocalDate date = LocalDate.of(2026, 3, 10);

        // Nincs pontos nap
        when(cacheRepository.findByRateDate(date)).thenReturn(Collections.emptyList());

        // Fallback
        MnbExchangeRateCache fallbackEur = MnbExchangeRateCache.builder()
                .currencyCode("EUR")
                .rateDate(LocalDate.of(2026, 3, 7)) // pénteki adat
                .officialRate(new BigDecimal("394.80"))
                .unit(1)
                .build();

        when(cacheRepository.findLatestRates(date)).thenReturn(List.of(fallbackEur));

        Map<String, MnbExchangeRateCache> result = mnbExchangeRateService.getRatesForDate(date);

        assertThat(result).hasSize(1);
        assertThat(result.get("EUR").getOfficialRate()).isEqualByComparingTo(new BigDecimal("394.80"));
        assertThat(result.get("EUR").getRateDate()).isEqualTo(LocalDate.of(2026, 3, 7));
    }

    // ============ SOAP REQUEST BUILDING TESZT ============

    @Test
    @DisplayName("buildGetExchangeRatesSoapRequest: helyes XML struktúra")
    void testBuildSoapRequest() {
        String xml = mnbExchangeRateService.buildGetExchangeRatesSoapRequest("2026-03-10", "2026-03-10");

        assertThat(xml).contains("soap:Envelope");
        assertThat(xml).contains("GetExchangeRates");
        assertThat(xml).contains("<web:startDate>2026-03-10</web:startDate>");
        assertThat(xml).contains("<web:endDate>2026-03-10</web:endDate>");
    }
}
