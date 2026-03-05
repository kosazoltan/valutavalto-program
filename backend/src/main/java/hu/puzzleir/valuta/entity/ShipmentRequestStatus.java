package hu.puzzleir.valuta.entity;

/**
 * Szállítmánykérés státusz.
 */
public enum ShipmentRequestStatus {
    DRAFT,
    SUBMITTED,
    APPROVED,
    IN_TRANSIT,
    DELIVERED,
    CANCELLED
}
