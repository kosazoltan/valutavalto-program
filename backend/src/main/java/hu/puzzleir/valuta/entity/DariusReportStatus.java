package hu.puzzleir.valuta.entity;

/**
 * Darius napi jelentés állapotgép.
 *
 * Életciklus:
 * DRAFT → GENERATED → SUBMITTED → ACKNOWLEDGED
 *                  ↘ FAILED → (retry) → SUBMITTED
 *
 * DRAFT:        Üres jelentés létrehozva, adat nincs generálva.
 * GENERATED:    Tranzakciós adatok összesítve, payload elkészült.
 * SUBMITTED:    Beküldve a banknak (Darius rendszer felé).
 * ACKNOWLEDGED: Bank visszaigazolta a fogadást.
 * FAILED:       Beküldés sikertelen (hálózat, formátum, bank oldali hiba).
 */
public enum DariusReportStatus {
    DRAFT,
    GENERATED,
    SUBMITTED,
    ACKNOWLEDGED,
    FAILED
}
