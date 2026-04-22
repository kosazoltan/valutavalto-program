package hu.puzzleir.valuta.exception;

import java.math.BigDecimal;

/**
 * Nincs elegendő kassza egyenleg (üzleti validáció, HTTP 400 Bad Request).
 *
 * A CashBalance.subtractBalance() dobja, amikor a current_balance < requested amount.
 * A ValidationException leszármazottja → GlobalExceptionHandler automatikusan 400-ra mapeli.
 *
 * Előzőleg IllegalStateException-t dobtunk, ami HTTP 500-ra mapelődött (rossz) —
 * most explicit business validation exception (HTTP 400, helyes).
 */
public class InsufficientBalanceException extends ValidationException {

    public InsufficientBalanceException(String message) {
        super(message);
    }

    public InsufficientBalanceException(String currencyCode, BigDecimal available, BigDecimal requested) {
        super(String.format(
                "Nincs elegendő %s egyenleg: jelenlegi %s, kért %s",
                currencyCode, available.toPlainString(), requested.toPlainString()));
    }
}
