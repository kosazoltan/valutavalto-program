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

import static org.assertj.core.api.Assertions.*;

/**
 * N3 (legacy ELADAS/VASARLAS) — HUF/inaktív-valuta "nem választható" guard tesztjei.
 */
@ExtendWith(MockitoExtension.class)
class TransactionValidationServiceTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private SystemParameterService systemParameterService;
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
}
