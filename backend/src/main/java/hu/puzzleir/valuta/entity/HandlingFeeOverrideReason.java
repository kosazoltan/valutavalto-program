package hu.puzzleir.valuta.entity;

/**
 * FK-KEZDÍJ (2026-06-02): a kezelési díj módosításának jogcíme (ki/mi alapján).
 *
 * <ul>
 *   <li>DIRECTOR_APPROVAL — ügyvezetői/főértéktárosi jóváhagyás (felezés/elengedés/speciális).</li>
 *   <li>CUSTOMER_CARD     — ügyfélkártyás kedvezmény (felezés/elengedés) — kártyaszám KÖTELEZŐ.</li>
 *   <li>PROMOTION         — akció keretében adott kedvezmény (felezés/elengedés) — nincs kártyaszám.</li>
 * </ul>
 */
public enum HandlingFeeOverrideReason {
    DIRECTOR_APPROVAL,
    CUSTOMER_CARD,
    PROMOTION
}
