package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionLine;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.*;

/**
 * N3 (legacy ELADAS/VASARLAS) — HUF/inaktív-valuta "nem választható" guard tesztjei.
 */
@ExtendWith(MockitoExtension.class)
class TransactionValidationServiceTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private SystemParameterService systemParameterService;
    @Mock private ValueBandService valueBandService;
    @InjectMocks private TransactionValidationService service;

    private static TransactionLine line(String code, boolean active) {
        return TransactionLine.builder()
                .currency(Currency.builder().code(code).active(active).build())
                .build();
    }

    @Test
    @DisplayName("validateCurrencyExchangeable — HUF kereskedett valuta tiltott (legacy: A FORINT NEM VÁLASZTHATÓ VALUTA)")
    void testHufNotSelectable() {
        Transaction tx = Transaction.builder().lines(List.of(line("HUF", true))).build();

        assertThatThrownBy(() -> service.validateCurrencyExchangeable(tx))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("FORINT");
    }

    @Test
    @DisplayName("validateCurrencyExchangeable — HUF kisbetűs is tiltott (case-insensitive)")
    void testHufLowercaseNotSelectable() {
        Transaction tx = Transaction.builder().lines(List.of(line("huf", true))).build();

        assertThatThrownBy(() -> service.validateCurrencyExchangeable(tx))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("validateCurrencyExchangeable — inaktív valuta (pl. HRK) tiltott")
    void testInactiveCurrencyNotSelectable() {
        Transaction tx = Transaction.builder().lines(List.of(line("HRK", false))).build();

        assertThatThrownBy(() -> service.validateCurrencyExchangeable(tx))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("HRK");
    }

    @Test
    @DisplayName("validateCurrencyExchangeable — aktív deviza (EUR) engedélyezett")
    void testActiveForeignCurrencyAllowed() {
        Transaction tx = Transaction.builder().lines(List.of(line("EUR", true))).build();

        assertThatCode(() -> service.validateCurrencyExchangeable(tx))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("validateCurrencyExchangeable — null lines / null currency nem dob (defenzív)")
    void testNullSafe() {
        Transaction txNullLines = Transaction.builder().build();
        Transaction txNullCurrency = Transaction.builder()
                .lines(List.of(TransactionLine.builder().currency(null).build()))
                .build();

        assertThatCode(() -> service.validateCurrencyExchangeable(txNullLines)).doesNotThrowAnyException();
        assertThatCode(() -> service.validateCurrencyExchangeable(txNullCurrency)).doesNotThrowAnyException();
    }

    // === Egy-valutás overload (buy/sell egysoros + multi-line per-sor flow) ===

    @Test
    @DisplayName("validateCurrencyExchangeable(Currency) — HUF tiltott")
    void testSingleCurrencyHufRejected() {
        assertThatThrownBy(() -> service.validateCurrencyExchangeable(
                Currency.builder().code("HUF").active(true).build()))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("FORINT");
    }

    @Test
    @DisplayName("validateCurrencyExchangeable(Currency) — inaktív tiltott, aktív deviza OK, null OK")
    void testSingleCurrencyActiveAndNull() {
        assertThatThrownBy(() -> service.validateCurrencyExchangeable(
                Currency.builder().code("HRK").active(false).build()))
                .isInstanceOf(ValidationException.class);
        assertThatCode(() -> service.validateCurrencyExchangeable(
                Currency.builder().code("EUR").active(true).build())).doesNotThrowAnyException();
        assertThatCode(() -> service.validateCurrencyExchangeable((Currency) null)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("validateIdentificationRequired — konfigurált 200000 Ft küszöb felett azonosítást kér")
    void validateIdentificationRequired_usesConfiguredLimit() {
        org.mockito.Mockito.when(valueBandService.getEffectiveBands()).thenReturn(new ValueBandService.ValueBands(
                new BigDecimal("100000"), new BigDecimal("200000"), new BigDecimal("10000000"), 8));
        Transaction tx = Transaction.builder()
                .hufAmount(new BigDecimal("200001"))
                .build();

        assertThatThrownBy(() -> service.validateIdentificationRequired(tx))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("200000")
                .hasMessageContaining("200001");
    }

    @Test
    @DisplayName("validateIdentificationRequired — null ValueBands esetén default 300000 Ft paritás marad")
    void validateIdentificationRequired_nullBands_defaultsApply() {
        org.mockito.Mockito.when(valueBandService.getEffectiveBands()).thenReturn(null);
        Transaction belowDefault = Transaction.builder()
                .hufAmount(new BigDecimal("200001"))
                .build();
        Transaction aboveDefault = Transaction.builder()
                .hufAmount(new BigDecimal("300001"))
                .build();

        assertThatCode(() -> service.validateIdentificationRequired(belowDefault)).doesNotThrowAnyException();
        assertThatThrownBy(() -> service.validateIdentificationRequired(aboveDefault))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("300000");
    }
}
