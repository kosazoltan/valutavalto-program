package hu.puzzleir.valuta.entity;

import java.util.Collections;
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

    /** Előre kiszámolt, módosíthatatlan átmenethalmazok (allokáció-mentes, immutable). */
    private static final Set<TransactionStatus> PENDING_TARGETS =
            Collections.unmodifiableSet(EnumSet.of(COMPLETED, FAILED, CANCELLED));
    private static final Set<TransactionStatus> COMPLETED_TARGETS =
            Collections.unmodifiableSet(EnumSet.of(REVERSED, ARCHIVED));
    private static final Set<TransactionStatus> REVERSED_TARGETS =
            Collections.unmodifiableSet(EnumSet.of(ARCHIVED));
    private static final Set<TransactionStatus> NO_TARGETS =
            Collections.unmodifiableSet(EnumSet.noneOf(TransactionStatus.class));

    /** Az adott állapotból megengedett cél-állapotok (state machine). */
    public Set<TransactionStatus> allowedTransitions() {
        return switch (this) {
            case PENDING -> PENDING_TARGETS;
            case COMPLETED -> COMPLETED_TARGETS;
            case REVERSED -> REVERSED_TARGETS;
            case FAILED, CANCELLED, ARCHIVED -> NO_TARGETS;
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
