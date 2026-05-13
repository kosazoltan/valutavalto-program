package hu.puzzleir.valuta.entity;

/**
 * Címletezési szabály típusok — v2.0 specifikáció (07_cimletkezeles.md).
 *
 * <p>A szabály-típus határozza meg, milyen körülmények között alkalmazandó
 * az adott `DenominationRule`. Egy tranzakciónál a rendszer kiválasztja az
 * első matching szabályt prioritás szerint.</p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 1 (P1-B — Címletezési szabályok).</p>
 */
public enum DenominationRuleType {
    /** Fix címletezés: minden tranzakcióra ugyanaz. */
    FIXED("Fix"),
    /** Összeg alapú: min/max HUF tartomány alapján. */
    AMOUNT_BASED("Összeg alapú"),
    /** Ügyfél típus alapú: pl. VIP ügyfélre más címletezés. */
    CUSTOMER_TYPE("Ügyfél típus alapú"),
    /** Tranzakció típus alapú: BUY/SELL/CONVERSION különböző. */
    TRANSACTION_TYPE("Tranzakció típus alapú"),
    /** Fiók alapértelmezett: a branch-specifikus szabály. */
    BRANCH_DEFAULT("Fiók alapértelmezett"),
    /** Időszak alapú: pl. nyitáskor különböző mint záráskor. */
    TIME_BASED("Időszak alapú"),
    /** Készlet alapú: készlet-aware (ami van, azt használja). */
    AVAILABILITY("Készlet alapú"),
    /** Prioritás alapú: explicit prioritási lista a JSON-ben. */
    PRIORITY("Prioritás alapú");

    private final String displayName;

    DenominationRuleType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
