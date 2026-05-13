package hu.puzzleir.valuta.entity;

/**
 * Jóváhagyási szint — v2.0 spec 03_tranzakciok.md.
 *
 * <p>Egy kedvezmény vagy speciális művelet jóváhagyásához szükséges minimum szint.
 * A worker role-jából kerül levezetésre.</p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 4 (P2-D).</p>
 */
public enum ApprovalLevel {
    /** Pénztáros — kis kedvezmények (0-2%). */
    CASHIER(0),
    /** Supervisor — közepes (2-5%). */
    SUPERVISOR(1),
    /** Manager — jelentős (5-10%). */
    MANAGER(2),
    /** Director — különleges (10-15%). */
    DIRECTOR(3);

    private final int rank;

    ApprovalLevel(int rank) {
        this.rank = rank;
    }

    public int getRank() {
        return rank;
    }

    /** Ez a szint elég-e a kívánt szintre? (rank >= required). */
    public boolean satisfies(ApprovalLevel required) {
        return required == null || this.rank >= required.rank;
    }
}
