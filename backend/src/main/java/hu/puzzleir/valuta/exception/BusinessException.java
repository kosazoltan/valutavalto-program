package hu.puzzleir.valuta.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Üzleti logikai kivétel — domain-specifikus hibák kezelésére.
 * HTTP 422 Unprocessable Entity státusszal tér vissza.
 */
@Getter
public class BusinessException extends RuntimeException {

    private final String errorCode;
    private final HttpStatus httpStatus;

    public BusinessException(String message, String errorCode) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = HttpStatus.UNPROCESSABLE_ENTITY;
    }

    public BusinessException(String message, String errorCode, HttpStatus httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }

    // --- Predefined factory methods ---

    public static BusinessException insufficientStock() {
        return new BusinessException("Nincs elég készlet a művelet végrehajtásához", ErrorCodes.INSUFFICIENT_STOCK);
    }

    public static BusinessException sessionClosed() {
        return new BusinessException("A napi session már le van zárva", ErrorCodes.SESSION_CLOSED);
    }

    public static BusinessException rateExpired() {
        return new BusinessException("Az árfolyam lejárt, kérjük frissítse", ErrorCodes.RATE_EXPIRED);
    }

    public static BusinessException tradeAlreadyCompleted() {
        return new BusinessException("A tranzakció már teljesítve van", ErrorCodes.TRADE_ALREADY_COMPLETED);
    }

    public static BusinessException licenseExpired() {
        return new BusinessException("A licenc lejárt", ErrorCodes.LICENSE_EXPIRED);
    }

    public static BusinessException closingNotFinalized() {
        return new BusinessException("A zárás még nincs véglegesítve", ErrorCodes.CLOSING_NOT_FINALIZED);
    }

    /**
     * Üzleti hibakódok.
     */
    public static final class ErrorCodes {
        public static final String INSUFFICIENT_STOCK = "INSUFFICIENT_STOCK";
        public static final String SESSION_CLOSED = "SESSION_CLOSED";
        public static final String RATE_EXPIRED = "RATE_EXPIRED";
        public static final String TRADE_ALREADY_COMPLETED = "TRADE_ALREADY_COMPLETED";
        public static final String LICENSE_EXPIRED = "LICENSE_EXPIRED";
        public static final String CLOSING_NOT_FINALIZED = "CLOSING_NOT_FINALIZED";

        private ErrorCodes() {}
    }
}
