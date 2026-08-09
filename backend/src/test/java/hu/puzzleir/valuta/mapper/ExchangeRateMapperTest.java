package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.exchangerate.CurrentRateDto;
import hu.puzzleir.valuta.dto.exchangerate.ExchangeRateDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;

class ExchangeRateMapperTest {

    private final ExchangeRateMapper mapper = new ExchangeRateMapper();

    /**
     * FKH-032 FR-6: a jelzes-kuszob (stale-warning-hours) es a dobo validacio hatara
     * (max-age-hours) KULON konfig. A mapper mindig a SZIGORUBBAT alkalmazza, hogy ne
     * letezzen olyan arfolyam, amit a rendszer elutasit, de a felulet frissnek mutat.
     */
    private ExchangeRateMapper mapperWith(int staleWarningHours, int maxAgeHours) {
        ExchangeRateMapper configured = new ExchangeRateMapper();
        ReflectionTestUtils.setField(configured, "staleWarningHours", staleWarningHours);
        ReflectionTestUtils.setField(configured, "maxAgeHours", maxAgeHours);
        return configured;
    }

    private ExchangeRate rateAgedHours(long hoursOld) {
        LocalDateTime moment = LocalDateTime.now().minusHours(hoursOld);
        return ExchangeRate.builder()
                .id(1L)
                .currency(Currency.builder().id(1L).code("EUR").name("Euro").build())
                .validDate(moment.toLocalDate())
                .validTime(moment.toLocalTime())
                .baseBuyRate(new BigDecimal("390.0000"))
                .baseSellRate(new BigDecimal("395.0000"))
                .active(true)
                .build();
    }

    @Test
    @DisplayName("FKH-032 FR-6: a jelzes a szigorubb stale-warning-hours szerint sul el, nem a 720 oras validacios hatar szerint")
    void staleWarningUsesTheStricterThreshold() {
        // Eles konfiguracio: a tranzakcio-tiltas 720 ora (30 nap), a jelzes 24 ora.
        ExchangeRateMapper production = mapperWith(24, 720);

        // 30 oras arfolyam: a validacio meg atengedne, a JELZESNEK viszont mar szolnia kell.
        assertThat(production.toDto(rateAgedHours(30)).getStale())
                .as("30 oras arfolyam elavultnak jelolt a 24 oras jelzes-kuszob szerint")
                .isTrue();

        // 2 oras arfolyam: friss.
        assertThat(production.toDto(rateAgedHours(2)).getStale())
                .as("2 oras arfolyam nem elavult")
                .isFalse();
    }

    @Test
    @DisplayName("FKH-032 FR-6: a jelzes soha nem lehet megengedobb a dobo validacional")
    void staleWarningNeverLooserThanValidation() {
        // Rosszul konfiguralt kornyezet: a jelzes lazabb (48h), mint a validacio (12h).
        ExchangeRateMapper misconfigured = mapperWith(48, 12);

        assertThat(misconfigured.toDto(rateAgedHours(20)).getStale())
                .as("A 12 oras validacio mar elutasitana — a felulet nem mutathatja frissnek")
                .isTrue();
    }

    @Test
    @DisplayName("FKH-032 FR-6: 0 jelzes-kuszob eseten a validacios hatarra esik vissza")
    void staleWarningFallsBackToValidationLimit() {
        ExchangeRateMapper fallback = mapperWith(0, 24);

        assertThat(fallback.toDto(rateAgedHours(30)).getStale()).isTrue();
        assertThat(fallback.toDto(rateAgedHours(10)).getStale()).isFalse();
    }

    @Test
    @DisplayName("null entity → null DTO")
    void mapsNullEntity() {
        assertThat(mapper.toDto(null)).isNull();
    }

    @Test
    @DisplayName("Árfolyam pénzügyi mezők és limit-sávok átkerülnek a DTO-ba")
    void mapsRateFieldsAndLimits() {
        LocalDate validDate = LocalDate.of(2026, 7, 6);
        LocalTime validTime = LocalTime.of(10, 15);
        LocalDateTime createdAt = LocalDateTime.of(2026, 7, 6, 10, 0);
        ExchangeRate entity = ExchangeRate.builder()
                .id(9L)
                .currency(Currency.builder().id(1L).code("EUR").name("Euro").build())
                .validDate(validDate)
                .validTime(validTime)
                .baseBuyRate(new BigDecimal("390.1000"))
                .baseSellRate(new BigDecimal("395.2000"))
                .limit1Amount(new BigDecimal("100000"))
                .limit1BuyRate(new BigDecimal("391.1000"))
                .limit1SellRate(new BigDecimal("394.2000"))
                .limit2Amount(new BigDecimal("500000"))
                .limit2BuyRate(new BigDecimal("392.1000"))
                .limit2SellRate(new BigDecimal("393.2000"))
                .limit3Amount(new BigDecimal("1000000"))
                .limit3BuyRate(new BigDecimal("393.1000"))
                .limit3SellRate(new BigDecimal("392.2000"))
                .officialRate(new BigDecimal("392.5000"))
                .active(true)
                .createdBy("rate-admin")
                .createdAt(createdAt)
                .build();

        ExchangeRateDto dto = mapper.toDto(entity);

        assertThat(dto.getId()).isEqualTo(9L);
        assertThat(dto.getCurrencyId()).isEqualTo(1L);
        assertThat(dto.getCurrencyCode()).isEqualTo("EUR");
        assertThat(dto.getCurrencyName()).isEqualTo("Euro");
        assertThat(dto.getValidDate()).isEqualTo(validDate);
        assertThat(dto.getValidTime()).isEqualTo(validTime);
        assertThat(dto.getBaseBuyRate()).isEqualByComparingTo("390.1000");
        assertThat(dto.getBaseSellRate()).isEqualByComparingTo("395.2000");
        assertThat(dto.getLimit1Amount()).isEqualByComparingTo("100000");
        assertThat(dto.getLimit1BuyRate()).isEqualByComparingTo("391.1000");
        assertThat(dto.getLimit1SellRate()).isEqualByComparingTo("394.2000");
        assertThat(dto.getLimit2Amount()).isEqualByComparingTo("500000");
        assertThat(dto.getLimit2BuyRate()).isEqualByComparingTo("392.1000");
        assertThat(dto.getLimit2SellRate()).isEqualByComparingTo("393.2000");
        assertThat(dto.getLimit3Amount()).isEqualByComparingTo("1000000");
        assertThat(dto.getLimit3BuyRate()).isEqualByComparingTo("393.1000");
        assertThat(dto.getLimit3SellRate()).isEqualByComparingTo("392.2000");
        assertThat(dto.getOfficialRate()).isEqualByComparingTo("392.5000");
        assertThat(dto.getActive()).isTrue();
        assertThat(dto.getCreatedBy()).isEqualTo("rate-admin");
        assertThat(dto.getCreatedAt()).isEqualTo(createdAt);
    }

    @Test
    @DisplayName("CurrentRate: JPY unit=100 és createdAt az updatedAt forrása")
    void mapsCurrentRateWithJpyUnitAndCreatedAt() {
        ExchangeRate entity = baseRate("JPY")
                .currency(Currency.builder().id(2L).code("JPY").name("Yen").build())
                .createdAt(LocalDateTime.of(2026, 7, 6, 10, 0))
                .build();

        CurrentRateDto dto = mapper.toCurrentRateDto(entity);

        assertThat(dto.getCurrencyCode()).isEqualTo("JPY");
        assertThat(dto.getUnit()).isEqualTo(100);
        assertThat(dto.getBuyRate()).isEqualByComparingTo("0.0250");
        assertThat(dto.getSellRate()).isEqualByComparingTo("0.0270");
        assertThat(dto.getUpdatedAt()).isEqualTo("2026-07-06T10:00");
        assertThat(dto.getOfficialRate()).isEqualByComparingTo("0.0260");
    }

    @Test
    @DisplayName("CurrentRate: nem-JPY vagy null currency unit=1, createdAt hiányában validDate fallback")
    void mapsCurrentRateUnitOneAndValidDateFallback() {
        ExchangeRate eurRate = baseRate("EUR")
                .currency(Currency.builder().id(1L).code("EUR").name("Euro").build())
                .createdAt(null)
                .validDate(LocalDate.of(2026, 7, 7))
                .build();
        ExchangeRate noCurrencyRate = baseRate(null)
                .currency(null)
                .createdAt(null)
                .validDate(LocalDate.of(2026, 7, 8))
                .build();

        CurrentRateDto eurDto = mapper.toCurrentRateDto(eurRate);
        CurrentRateDto noCurrencyDto = mapper.toCurrentRateDto(noCurrencyRate);

        assertThat(eurDto.getCurrencyCode()).isEqualTo("EUR");
        assertThat(eurDto.getUnit()).isEqualTo(1);
        assertThat(eurDto.getUpdatedAt()).isEqualTo("2026-07-07");
        assertThat(noCurrencyDto.getCurrencyCode()).isNull();
        assertThat(noCurrencyDto.getUnit()).isEqualTo(1);
        assertThat(noCurrencyDto.getUpdatedAt()).isEqualTo("2026-07-08");
    }

    @Test
    @DisplayName("Hiányzó currency → ExchangeRate DTO currency mezők null")
    void mapsNullCurrencySafely() {
        ExchangeRate entity = baseRate(null).currency(null).build();

        ExchangeRateDto dto = mapper.toDto(entity);

        assertThat(dto.getCurrencyId()).isNull();
        assertThat(dto.getCurrencyCode()).isNull();
        assertThat(dto.getCurrencyName()).isNull();
    }

    private ExchangeRate.ExchangeRateBuilder baseRate(String currencyCode) {
        Currency currency = currencyCode == null ? null : Currency.builder().id(1L).code(currencyCode).name(currencyCode).build();
        return ExchangeRate.builder()
                .currency(currency)
                .validDate(LocalDate.of(2026, 7, 6))
                .baseBuyRate(new BigDecimal("0.0250"))
                .baseSellRate(new BigDecimal("0.0270"))
                .limit1Amount(new BigDecimal("100000"))
                .limit1BuyRate(new BigDecimal("0.0255"))
                .limit1SellRate(new BigDecimal("0.0265"))
                .limit2Amount(new BigDecimal("500000"))
                .limit2BuyRate(new BigDecimal("0.0258"))
                .limit2SellRate(new BigDecimal("0.0262"))
                .limit3Amount(new BigDecimal("1000000"))
                .limit3BuyRate(new BigDecimal("0.0260"))
                .limit3SellRate(new BigDecimal("0.0260"))
                .officialRate(new BigDecimal("0.0260"));
    }
}
