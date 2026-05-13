package hu.puzzleir.valuta.entity;

/**
 * Kedvezmény (discount) ok kategorizálás — v2.0 spec 03_tranzakciok.md.
 *
 * <p>2026-05-13 v2.5.50+ Sprint 4 (P2-D — VIP discount granular).</p>
 */
public enum DiscountReason {
    /** Kiemelt ügyfél (VIP, törzsügyfél). */
    SPECIAL_CUSTOMER("Kiemelt ügyfél"),
    /** Üzleti érdek (kompetitív árazás, nagy összeg). */
    BUSINESS_NEED("Üzleti érdek"),
    /** Vezetői jóváhagyás (manuális override). */
    MANAGEMENT_APPROVAL("Vezetői jóváhagyás");

    private final String displayName;

    DiscountReason(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public static DiscountReason parseOrNull(String value) {
        if (value == null || value.trim().isEmpty()) return null;
        try {
            return DiscountReason.valueOf(value.trim().toUpperCase(java.util.Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
