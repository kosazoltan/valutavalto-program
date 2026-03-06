package hu.puzzleir.valuta.dto.pos;

/**
 * POS terminál tranzakció eredmény.
 *
 * Legacy: OTP terminál DLL visszatérési értékek modernizálva.
 */
public record PosTransactionResult(
    boolean approved,
    String authorizationCode,
    String referenceNumber,
    String errorMessage,
    PosResultStatus status
) {

    /**
     * Sikeres (APPROVED) eredmény factory.
     */
    public static PosTransactionResult approved(String authorizationCode, String referenceNumber) {
        return new PosTransactionResult(true, authorizationCode, referenceNumber, null, PosResultStatus.APPROVED);
    }

    /**
     * Elutasított (DECLINED) eredmény factory.
     */
    public static PosTransactionResult declined(String errorMessage) {
        return new PosTransactionResult(false, null, null, errorMessage, PosResultStatus.DECLINED);
    }

    /**
     * Hiba (ERROR) eredmény factory.
     */
    public static PosTransactionResult error(String errorMessage) {
        return new PosTransactionResult(false, null, null, errorMessage, PosResultStatus.ERROR);
    }

    /**
     * Timeout eredmény factory.
     */
    public static PosTransactionResult timeout() {
        return new PosTransactionResult(false, null, null, "POS terminál nem válaszolt időben", PosResultStatus.TIMEOUT);
    }
}
