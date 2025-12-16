package hu.puzzleir.valuta.entity;

/**
 * Tranzakció típusok.
 *
 * Legacy mapping:
 * - V = Vétel (VASARLAS) - ügyfél valutát ad, forintot kap
 * - E = Eladás (ELADAS) - ügyfél forintot ad, valutát kap
 * - S = Sztornó (STORNO) - korábbi tranzakció érvénytelenítése
 * - F = Fronton - közvetlen valuta-valuta csere
 * - K = Konverzió - vételből eladásba átváltás
 * - W = Western Union
 * - G = Gongytáska - pénztárak közötti transzfer
 * - T = Telefon töltés
 * - A = Autópálya matrica
 */
public enum TransactionType {
    BUY("Vétel", "V"),           // Ügyfél valutát ad, HUF-ot kap
    SELL("Eladás", "E"),         // Ügyfél HUF-ot ad, valutát kap
    REVERSAL("Sztornó", "S"),    // Korábbi tranzakció sztornózása
    CONVERSION("Konverzió", "K"), // Valuta-valuta csere
    TRANSFER_OUT("Átutalás", "GO"), // Pénztárból ki
    TRANSFER_IN("Átvétel", "GI"),   // Pénztárba be
    WESTERN_UNION_SEND("WU küldés", "WS"),
    WESTERN_UNION_RECEIVE("WU fogadás", "WR"),
    MONEYGRAM_SEND("MG küldés", "MS"),
    MONEYGRAM_RECEIVE("MG fogadás", "MR"),
    VIGNETTE("Autópálya matrica", "A"),
    PHONE_TOPUP("Telefon feltöltés", "T"),
    OTHER("Egyéb", "X");

    private final String displayName;
    private final String legacyCode;

    TransactionType(String displayName, String legacyCode) {
        this.displayName = displayName;
        this.legacyCode = legacyCode;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getLegacyCode() {
        return legacyCode;
    }

    /**
     * Legacy kódból TransactionType
     */
    public static TransactionType fromLegacyCode(String code) {
        for (TransactionType type : values()) {
            if (type.legacyCode.equals(code)) {
                return type;
            }
        }
        return OTHER;
    }

    /**
     * Ez vétel típusú tranzakció?
     */
    public boolean isBuyType() {
        return this == BUY || this == WESTERN_UNION_RECEIVE || this == MONEYGRAM_RECEIVE;
    }

    /**
     * Ez eladás típusú tranzakció?
     */
    public boolean isSellType() {
        return this == SELL || this == WESTERN_UNION_SEND || this == MONEYGRAM_SEND;
    }

    /**
     * Pénzmozgással jár?
     */
    public boolean affectsCashRegister() {
        return this != VIGNETTE && this != PHONE_TOPUP;
    }
}
