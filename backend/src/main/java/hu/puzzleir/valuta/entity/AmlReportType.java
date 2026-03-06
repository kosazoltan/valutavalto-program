package hu.puzzleir.valuta.entity;

/**
 * AML bejelentés típusa.
 */
public enum AmlReportType {
    /** Normál azonosítás (300K+ Ft) */
    STANDARD,
    /** Fokozott átvilágítás (4.5M+ Ft) */
    ENHANCED,
    /** Gyanús tranzakció (mintázat alapú) */
    SUSPICIOUS,
    /** Küszöbérték alapú bejelentés (2M+ Ft) */
    THRESHOLD
}
