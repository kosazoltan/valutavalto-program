package hu.puzzleir.valuta.exception;

/**
 * Közös magyar validációs hibaszöveg-magok (Sourcery-javaslat, PR #1547).
 *
 * FK-072: a tört (1 alatti) címlet-névérték elutasításának szövege több rétegben
 * (bean-validation, service-guard, exception-handler) és a frontendben
 * ({@code denominationRules.ts}) is megjelenik — a mag itt él egy helyen, hogy a
 * felületek ne csússzanak szét. A VV-VALID kódszám-hozzárendelés SZÁNDÉKOSAN a
 * hívó helyeken marad; a VV-VALID-005 (negatív darabszám) üzenete pedig
 * szándékosan KÜLÖN szöveg, nem ide tartozik.
 */
public final class ValidationMessages {

    /** FK-072 (FR-3/4/6): a tört-címlet elutasítás közös szöveg-magja. */
    public static final String FRACTIONAL_FACE_VALUE_CORE =
            "nem lehet 1-nél kisebb (tört címlet nem rögzíthető)";

    /**
     * FK-072 (FR-6 backend): a TransactionBanknoteDto bean-validation üzenete —
     * konstans-kifejezés, hogy annotation-értékként használható legyen.
     */
    public static final String BANKNOTE_FACE_VALUE_MIN_MESSAGE =
            "A címlet névértéke " + FRACTIONAL_FACE_VALUE_CORE + "!";

    /**
     * FKH-028 (V370): a duplikátum-korrekcióval rendezett bizonylatok notes-markere.
     * A V370 migráció írja a transfer/transaction notes-ba; a sztornó-útvonalak
     * (TransferService.storno, TransactionReversalService.executeReversal) guardja erre
     * ismer rá és 409-cel utasítja el a sztornó-kísérletet — a korrekció + app-sztornó
     * együtt DUPLA jóváírás lenne. A literálnak byte-ra egyeznie kell a V370 SQL-lel.
     */
    public static final String FKH028_V370_CORRECTION_MARKER = "[FKH-028 V370]";

    private ValidationMessages() {
    }
}
