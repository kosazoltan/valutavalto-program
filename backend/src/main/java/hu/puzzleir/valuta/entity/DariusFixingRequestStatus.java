package hu.puzzleir.valuta.entity;

/**
 * A Darius fixing-igény állapota.
 *
 * <p>Állapotgép: DRAFT → APPROVED → INCLUDED; DRAFT vagy APPROVED → CANCELLED.
 * Az INCLUDED terminális állapot.</p>
 */
public enum DariusFixingRequestStatus {
    DRAFT,
    APPROVED,
    INCLUDED,
    CANCELLED
}
