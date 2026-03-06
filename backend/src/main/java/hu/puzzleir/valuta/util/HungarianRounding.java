package hu.puzzleir.valuta.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Magyar 5 forintos kerekítés.
 *
 * Legacy: Kerekito függvény — az MNB szabályozás szerint a forint készpénzes
 * tranzakcióknál 5 Ft-ra kell kerekíteni.
 *
 * Szabály (utolsó számjegy alapján):
 *   0, 5 → marad
 *   1, 2 → lefelé 0-ra
 *   3, 4 → felfelé 5-re
 *   6, 7 → lefelé 5-re
 *   8, 9 → felfelé 10-re
 */
public final class HungarianRounding {

    private HungarianRounding() {
        // Utility class — nem példányosítható
    }

    /**
     * Long összeg kerekítése 5 Ft-ra.
     *
     * @param amount kerekítendő összeg (Ft)
     * @return 5 Ft-ra kerekített összeg
     */
    public static long roundToFive(long amount) {
        int lastDigit = (int) (Math.abs(amount) % 10);
        long base = amount - (amount >= 0 ? lastDigit : -lastDigit);
        switch (lastDigit) {
            case 0:
            case 5:
                return amount;
            case 1:
            case 2:
                return base;
            case 3:
            case 4:
                return base + (amount >= 0 ? 5 : -5);
            case 6:
            case 7:
                return base + (amount >= 0 ? 5 : -5);
            case 8:
            case 9:
                return base + (amount >= 0 ? 10 : -10);
            default:
                return amount;
        }
    }

    /**
     * BigDecimal összeg kerekítése 5 Ft-ra.
     * Először egészre kerekít (HALF_UP), majd az 5-ös szabályt alkalmazza.
     *
     * @param amount kerekítendő összeg (Ft)
     * @return 5 Ft-ra kerekített összeg
     */
    public static BigDecimal roundToFive(BigDecimal amount) {
        if (amount == null) {
            return BigDecimal.ZERO;
        }
        return BigDecimal.valueOf(roundToFive(amount.setScale(0, RoundingMode.HALF_UP).longValue()));
    }
}
