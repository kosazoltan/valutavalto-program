package hu.puzzleir.valuta.entity;

/**
 * Körlevél típusok — a legacy rendszer 17+ variánsának modern megfelelői.
 *
 * Legacy: KORLEV DLL — különböző körlevél típusok a pénztárak felé.
 * A Delphi rendszerben a körlevél típusok az FZS/BT/KI/KZ/DA/SCS/DURU
 * prefixekkel voltak jelölve (FZS001.odt, BT008.odt, stb.).
 *
 * Az új rendszerben enum-ként kezeljük, és minden típushoz tartozik:
 * - Sablon (template) — ha van előre definiált formátum
 * - Célcsoport — kik kapják (összes iroda / egy iroda / vezetők)
 * - Prioritás — sürgős / normál / tájékoztató
 */
public enum CircularType {

    // === ÁLTALÁNOS (FZS prefix) ===
    /** Általános utasítás — minden irodának szól */
    GENERAL("Általános utasítás", CircularTarget.ALL_BRANCHES, CircularPriority.NORMAL),

    /** Új szabályozás — jogszabályváltozás, MNB rendelet */
    REGULATION("Új szabályozás / rendelet", CircularTarget.ALL_BRANCHES, CircularPriority.HIGH),

    /** Árfolyam-politika változás */
    RATE_POLICY("Árfolyam-politika változás", CircularTarget.ALL_BRANCHES, CircularPriority.HIGH),

    /** Biztonsági tájékoztató — hamis bankjegy, gyanús ügyfél */
    SECURITY_ALERT("Biztonsági figyelmeztetés", CircularTarget.ALL_BRANCHES, CircularPriority.URGENT),

    /** Készlet utasítás — deviza ellátás, visszaszállítás */
    INVENTORY("Készlet utasítás", CircularTarget.ALL_BRANCHES, CircularPriority.NORMAL),

    /** HR utasítás — munkarend, szabadság, bérszámfejtés */
    HR("HR utasítás", CircularTarget.ALL_BRANCHES, CircularPriority.NORMAL),

    /** Műszaki utasítás — IT, szoftver update, gép csere */
    TECHNICAL("Műszaki / IT utasítás", CircularTarget.ALL_BRANCHES, CircularPriority.NORMAL),

    // === BEST CHANGE SPECIFIKUS (BT prefix) ===
    /** Best Change specifikus utasítás */
    BEST_CHANGE("Best Change utasítás", CircularTarget.COMPANY_SPECIFIC, CircularPriority.NORMAL),

    // === ZÁLOG SPECIFIKUS ===
    /** Zálog fiók specifikus utasítás */
    ZALOG("Zálog utasítás", CircularTarget.COMPANY_SPECIFIC, CircularPriority.NORMAL),

    // === KIADÓ / KÖZPONTI (KI/KZ prefix) ===
    /** Központi utasítás — igazgatói körlevél */
    MANAGEMENT("Igazgatói / központi körlevél", CircularTarget.ALL_BRANCHES, CircularPriority.HIGH),

    /** Kinevezés / személyi utasítás */
    APPOINTMENT("Kinevezés / személyzeti", CircularTarget.ALL_BRANCHES, CircularPriority.NORMAL),

    // === IDŐSZAKOS ===
    /** Újévi köszöntő (legacy: NEWYEAR) */
    NEW_YEAR("Újévi köszöntő", CircularTarget.ALL_BRANCHES, CircularPriority.LOW),

    /** Éves zárási utasítás */
    YEAR_END("Éves zárási utasítás", CircularTarget.ALL_BRANCHES, CircularPriority.HIGH),

    /** Havi összesítő — eredmények, statisztikák */
    MONTHLY_SUMMARY("Havi összesítő", CircularTarget.MANAGERS_ONLY, CircularPriority.NORMAL),

    // === VIP / SPECIÁLIS ===
    /** VIP ügyfél értesítés — kiemelt ügyfelek kezelése */
    VIP_NOTICE("VIP ügyfél értesítés", CircularTarget.ALL_BRANCHES, CircularPriority.NORMAL),

    /** Audit / ellenőrzés értesítés */
    AUDIT_NOTICE("Audit / ellenőrzés értesítés", CircularTarget.ALL_BRANCHES, CircularPriority.URGENT),

    /** Oktatási anyag — kötelező tréning, vizsgafelkészítő */
    TRAINING("Oktatási anyag", CircularTarget.ALL_BRANCHES, CircularPriority.NORMAL);

    private final String description;
    private final CircularTarget defaultTarget;
    private final CircularPriority defaultPriority;

    CircularType(String description, CircularTarget defaultTarget, CircularPriority defaultPriority) {
        this.description = description;
        this.defaultTarget = defaultTarget;
        this.defaultPriority = defaultPriority;
    }

    public String getDescription() { return description; }
    public CircularTarget getDefaultTarget() { return defaultTarget; }
    public CircularPriority getDefaultPriority() { return defaultPriority; }

    /** Célcsoport */
    public enum CircularTarget {
        /** Minden iroda */
        ALL_BRANCHES,
        /** Csak egy adott cég irodái */
        COMPANY_SPECIFIC,
        /** Csak egy iroda */
        SINGLE_BRANCH,
        /** Csak vezetők (supervisor+) */
        MANAGERS_ONLY
    }

    /** Prioritás */
    public enum CircularPriority {
        /** Tájékoztató — nem kötelező nyugtázni */
        LOW,
        /** Normál — nyugtázás szükséges */
        NORMAL,
        /** Fontos — sürgős nyugtázás */
        HIGH,
        /** Kritikus — azonnali intézkedés + nyugtázás */
        URGENT
    }
}
