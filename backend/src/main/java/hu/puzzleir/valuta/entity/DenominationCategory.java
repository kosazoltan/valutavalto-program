package hu.puzzleir.valuta.entity;

/**
 * Címletezési kategória — a napi zárás során különböző kasszatípusok
 * külön-külön címletezése szükséges.
 *
 * Legacy: CIMLET.CIMLETSORSZAM mező (1..9)
 *
 * A DailyClosingService 9 belső ellenőrzési lépése ezeket a kategóriákat
 * használja az esti zárás validálásához.
 */
public enum DenominationCategory {

    EVENING("Esti pénztárállomány", 1),
    HANDLING_FEE("Kezelési díj", 2),
    WESTERN_UNION("Western Union", 3),
    VAT("ÁFA", 4),
    DEPOSIT("Foglaló", 5),
    ECOMMERCE("E-kereskedelem", 6),
    AXA("AXA", 7),
    MONEYGRAM("MoneyGram", 8),
    OTHER("Egyéb", 9);

    private final String displayName;
    private final int legacyCimletSorszam;

    DenominationCategory(String displayName, int legacyCimletSorszam) {
        this.displayName = displayName;
        this.legacyCimletSorszam = legacyCimletSorszam;
    }

    public String getDisplayName() {
        return displayName;
    }

    public int getLegacyCimletSorszam() {
        return legacyCimletSorszam;
    }

    /**
     * Legacy sorszám alapján keresés.
     */
    public static DenominationCategory fromLegacySorszam(int sorszam) {
        for (DenominationCategory cat : values()) {
            if (cat.legacyCimletSorszam == sorszam) {
                return cat;
            }
        }
        throw new IllegalArgumentException("Ismeretlen legacy címlet sorszám: " + sorszam);
    }

    /**
     * Név alapján keresés (case-insensitive, backwards compatible).
     * A DailyClosingService String alapú hívásait támogatja.
     */
    public static DenominationCategory fromString(String value) {
        if (value == null || value.isBlank()) {
            return EVENING;
        }
        try {
            return valueOf(value.toUpperCase().trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Ismeretlen címletezési kategória: " + value);
        }
    }
}
