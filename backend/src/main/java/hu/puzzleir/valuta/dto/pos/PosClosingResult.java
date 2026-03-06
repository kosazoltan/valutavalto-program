package hu.puzzleir.valuta.dto.pos;

import java.math.BigDecimal;

/**
 * POS terminál napi zárás eredménye.
 *
 * Legacy: otpterminal DLL — napi záráskor összesítés.
 */
public record PosClosingResult(
    boolean success,
    int transactionCount,
    BigDecimal totalAmount,
    String errorMessage
) {

    /**
     * Sikeres napi zárás factory.
     */
    public static PosClosingResult success(int transactionCount, BigDecimal totalAmount) {
        return new PosClosingResult(true, transactionCount, totalAmount, null);
    }

    /**
     * Sikertelen napi zárás factory.
     */
    public static PosClosingResult failure(String errorMessage) {
        return new PosClosingResult(false, 0, BigDecimal.ZERO, errorMessage);
    }
}
