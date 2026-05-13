package hu.puzzleir.valuta.entity;

/**
 * Devizastátusz — egy tranzakció ügyfelének állampolgársági/devizahatósági besorolása.
 *
 * <p>A bizonylatra nyomtatott mező. V210 migráció óta tárolva a `transaction.foreign_status`
 * oszlopban. V214 migráció óta DB-szintű CHECK constraint védi ('DOMESTIC' VAGY 'FOREIGN' VAGY NULL).</p>
 *
 * <ul>
 *   <li>{@link #DOMESTIC} — belföldi (magyar állampolgárságú) ügyfél</li>
 *   <li>{@link #FOREIGN} — külföldi (nem magyar állampolgárságú) ügyfél</li>
 * </ul>
 *
 * <p>Default megjelenítés: ha a tranzakció `foreign_status` mezője NULL, a UI/bizonylat
 * "—" jelet ír (NEM automatikusan DOMESTIC, ahogy a Copilot review PR #562 megjegyzése
 * jelezte régebbi adatoknál).</p>
 *
 * @since v2.5.50 (2026-05-13)
 */
public enum ForeignStatus {
    DOMESTIC("Belföldi"),
    FOREIGN("Külföldi");

    private final String displayName;

    ForeignStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    /**
     * Biztonságos parsolás String-ből. Trim + uppercase + enum match.
     * Ha nem felismerhető, null-t ad vissza (NEM dob exception-t — a service
     * eldöntheti hogy validál vagy elfogad).
     *
     * @param value beérkező érték (lehet null, üres, kis/nagybetűs)
     * @return ForeignStatus enum vagy null ha nem értelmezhető
     */
    public static ForeignStatus parseOrNull(String value) {
        if (value == null) {
            return null;
        }
        String normalized = value.trim().toUpperCase();
        if (normalized.isEmpty()) {
            return null;
        }
        try {
            return ForeignStatus.valueOf(normalized);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
