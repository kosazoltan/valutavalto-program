package hu.puzzleir.valuta.entity;

import lombok.Getter;

/**
 * Árfolyam típusok a legacy GETARF modul szerint.
 *
 * A régi Delphi rendszer 9 különböző árfolyam típust tartott nyilván valutánként.
 */
@Getter
public enum RateType {

    BUY("Vételi", 1),
    SELL("Eladási", 2),
    MNB_MID("MNB közép", 3),
    DISCOUNT_BUY("Kedvezményes vételi", 4),
    DISCOUNT_SELL("Kedvezményes eladási", 5),
    F1_BUY("F1 vételi", 6),
    F1_SELL("F1 eladási", 7),
    CHIEF_TREASURER_BUY("Főértéktáros vételi", 8),
    CHIEF_TREASURER_SELL("Főértéktáros eladási", 9);

    private final String displayName;
    private final int legacyIndex;

    RateType(String displayName, int legacyIndex) {
        this.displayName = displayName;
        this.legacyIndex = legacyIndex;
    }

    /**
     * Legacy index alapján RateType keresés (1-9)
     */
    public static RateType fromLegacyIndex(int index) {
        for (RateType type : values()) {
            if (type.legacyIndex == index) {
                return type;
            }
        }
        throw new IllegalArgumentException("Ismeretlen legacy árfolyam index: " + index);
    }
}
