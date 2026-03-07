package hu.puzzleir.valuta.entity;

/**
 * Dolgozói bérfizetés módja.
 * 
 * Az Employee modulhoz — NE keverjük a tranzakciós PaymentMethod-dal (CASH/CARD)!
 */
public enum EmployeePaymentMethod {
    /** Banki átutalás */
    B("Banki átutalás"),
    /** Készpénz */
    K("Készpénz");

    private final String displayName;

    EmployeePaymentMethod(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
