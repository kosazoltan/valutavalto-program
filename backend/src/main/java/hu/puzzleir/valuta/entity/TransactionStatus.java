package hu.puzzleir.valuta.entity;

import java.util.EnumSet;
import java.util.Set;

/**
 * Tranzakció státusz + megengedett állapotátmenetek (state machine, VV-ELVI v2 5.1).
 *
 * <p>Megengedett átmenetek:
 * <ul>
 *   <li>PENDING → COMPLETED | FAILED | CANCELLED</li>
 *   <li>COMPLETED → REVERSED | ARCHIVED</li>
 *   <li>REVERSED → ARCHIVED</li>
 *   <li>FAILED / CANCELLED / ARCHIVED → (terminális, nincs továbblépés)</li>
 * </ul>
 */
public enum TransactionStatus {
    PENDING("Folyamatban"),
    COMPLETED("Befejezett"),
    REVERSED("Sztornózott"),
    FAILED("Sikertelen"),
    CANCELLED("Megszakított"),
    ARCHIVED("Archivált");

    private final String displayName;

    TransactionStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    /** Az adott állapotból megengedett cél-állapotok (state machine). */
    public Set<TransactionStatus> allowedTransitions() {
        return switch (this) {
            case PENDING -> EnumSet.of(COMPLETED, FAILED, CANCELLED);
            case COMPLETED -> EnumSet.of(REVERSED, ARCHIVED);
            case REVERSED -> EnumSet.of(ARCHIVED);
            case FAILED, CANCELLED, ARCHIVED -> EnumSet.noneOf(TransactionStatus.class);
        };
    }

    /** Megengedett-e az átmenet a megadott cél-állapotba (önmagába = no-op, nem engedett). */
    public boolean canTransitionTo(TransactionStatus target) {
        return target != null && allowedTransitions().contains(target);
    }

    /** Terminális állapot-e (nincs további megengedett átmenet). */
    public boolean isTerminal() {
        return allowedTransitions().isEmpty();
    }
}
