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
    CANCELLED,
    // F3 (2026-06-01): az ELUTASÍTÁS (reject) külön állapot a VISSZAVONÁStól (cancel) —
    // auditálási és üzleti szempontból elkülönített folyamat (rejectionReason + rejectedByWorkerId).
    REJECTED
}
