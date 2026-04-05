package hu.puzzleir.valuta.entity;

/**
 * AML bejelentés státusz.
 */
public enum AmlReportStatus {
    DRAFT,
    SUBMITTED,
    ACKNOWLEDGED,
    FLAGGED,
    /** 2017. LIII. tv. 33.§ — 2 munkanapon belüli bejelentési kötelezettség lejárt */
    OVERDUE
}
