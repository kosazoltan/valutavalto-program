package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.exception.InsufficientBalanceException;
import hu.puzzleir.valuta.exception.ValidationException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.*;

/**
 * PR #114: CashBalance.subtractBalance() nem dob IllegalStateException-t,
 * hanem InsufficientBalanceException-t (ValidationException leszármazott)
 * → HTTP 400 Bad Request a GlobalExceptionHandler-ben.
 */
class CashBalanceSubtractTest {

    private CashBalance build(BigDecimal balance, String currencyCode) {
        Currency currency = Currency.builder().id(3L).code(currencyCode).build();
        return CashBalance.builder()
                .currentBalance(balance)
                .currency(currency)
                .build();
    }

    @Test
    @DisplayName("subtractBalance: elegendő egyenleg → sikeres csökkentés")
    void subtractBalance_success() {
        CashBalance cb = build(new BigDecimal("1000"), "HUF");
        cb.subtractBalance(new BigDecimal("300"));
        assertThat(cb.getCurrentBalance()).isEqualByComparingTo("700");
        assertThat(cb.getLastTransactionAt()).isNotNull();
    }

    @Test
    @DisplayName("subtractBalance: pontosan annyi → 0-ra csökken")
    void subtractBalance_exactAmount() {
        CashBalance cb = build(new BigDecimal("100"), "EUR");
        cb.subtractBalance(new BigDecimal("100"));
        assertThat(cb.getCurrentBalance()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("subtractBalance: nincs elég → InsufficientBalanceException (business validation)")
    void subtractBalance_insufficient_throwsValidationException() {
        CashBalance cb = build(BigDecimal.ZERO, "HUF");

        assertThatThrownBy(() -> cb.subtractBalance(new BigDecimal("39300")))
                .isInstanceOf(InsufficientBalanceException.class)
                .isInstanceOf(ValidationException.class) // parent - 400 Bad Request handler matches
                .hasMessageContaining("Nincs elegendő HUF")
                .hasMessageContaining("jelenlegi 0")
                .hasMessageContaining("kért 39300");
    }

    @Test
    @DisplayName("subtractBalance: null currency → exception message '?' currency code-dal")
    void subtractBalance_nullCurrency_includesQuestionMark() {
        CashBalance cb = CashBalance.builder()
                .currentBalance(BigDecimal.ZERO)
                .build(); // NINCS currency

        assertThatThrownBy(() -> cb.subtractBalance(new BigDecimal("100")))
                .isInstanceOf(InsufficientBalanceException.class)
                .hasMessageContaining("?"); // placeholder currency code
    }
}
