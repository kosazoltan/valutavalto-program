package hu.puzzleir.valuta.entity;

/**
 * Nyomtatási sablon típusa.
 */
public enum PrintTemplateType {
    /** Bizonylat — tranzakciós bizonylat */
    RECEIPT,
    /** Jelentés — napi/havi riport */
    REPORT,
    /** Címke — értéktári címke */
    LABEL,
    /** Záróbizonylat — napi zárás */
    CLOSING
}
