package hu.puzzleir.valuta.entity;

/**
 * Fizetési mód.
 *
 * Legacy: a Delphi rendszerben nincs explicit PaymentMethod — kártyás fizetés külön DLL-en keresztül ment (OTP terminál).
 * Modern: explicit enum a tranzakción.
 */
public enum PaymentMethod {
    CASH("Készpénz"),
    CARD("Bankkártya");

    private final String displayName;

    PaymentMethod(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
