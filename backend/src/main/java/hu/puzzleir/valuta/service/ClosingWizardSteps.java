package hu.puzzleir.valuta.service;

import java.util.List;

/**
 * A legacy 16 lépéses zárási varázsló lépés-definíciói.
 *
 * Legacy: NAPZAR.DLL + CHECKLST.DLL + CIMLCTRL.DLL + CIMLMENU.DLL + DEKAD.DLL
 *
 * A legacy rendszerben a teljes zárási folyamat 16 lépésből állt.
 * Nem minden lépés szükséges minden zárástípusnál — a lépések a zárás típusától
 * (napi/dekád/havi/POS) függően aktívak vagy kihagyhatók.
 *
 * Lépések:
 *  1. Zárás típus kiválasztása (DAILY / DECADE / MONTHLY / POS)
 *  2. Napi tranzakció összesítés valutánként
 *  3. Pénztár nyitó/záró egyenleg ellenőrzés valutánként
 *  4. Kezelési díj összesítés
 *  5. Irodák közti mozgások ellenőrzése
 *  6. Napi árfolyam ellenőrzés (24h TTL)
 *  7. (Dekád) Dekádos tranzakció összesítés
 *  8. (Dekád) Eltéréskezelés
 *  9. (Dekád) Korrekciós bizonylatok
 * 10. POS kártyás tranzakció összesítés
 * 11. POS sztornók / visszatérítések
 * 12. POS kezelési díjak
 * 13. Zárási bizonylatok nyomtatása (napi/dekád/havi/POS)
 * 14. HUF átutalási bizonylatok nyomtatása
 * 15. Napi jelentések küldése a központba
 * 16. Dekád/havi jelentések küldése + véglegesítés
 */
public final class ClosingWizardSteps {

    private ClosingWizardSteps() {
        // Utility class
    }

    /** Teljes lépésszám a legacy rendszerben */
    public static final int LEGACY_TOTAL_STEPS = 16;

    // ============ LÉPÉS KONSTANSOK ============

    public static final int STEP_CLOSING_TYPE_SELECTION = 1;
    public static final int STEP_DAILY_TRANSACTION_SUMMARY = 2;
    public static final int STEP_CASH_BALANCE_CHECK = 3;
    public static final int STEP_HANDLING_FEES_SUMMARY = 4;
    public static final int STEP_INTER_BRANCH_MOVEMENTS = 5;
    public static final int STEP_DAILY_EXCHANGE_RATE_CHECK = 6;
    public static final int STEP_DECADE_TRANSACTION_SUMMARY = 7;
    public static final int STEP_DECADE_DISCREPANCY_HANDLING = 8;
    public static final int STEP_DECADE_CORRECTION_RECEIPTS = 9;
    public static final int STEP_POS_CARD_TRANSACTION_SUMMARY = 10;
    public static final int STEP_POS_REFUNDS_STORNOS = 11;
    public static final int STEP_POS_HANDLING_FEES = 12;
    public static final int STEP_PRINT_CLOSING_RECEIPTS = 13;
    public static final int STEP_PRINT_HUF_TRANSFER_RECEIPTS = 14;
    public static final int STEP_SEND_DAILY_REPORTS = 15;
    public static final int STEP_SEND_PERIOD_REPORTS_FINALIZE = 16;

    /**
     * Lépés definíció: {lépés szám, név, leírás, napi?, dekád?, havi?, POS?}
     */
    public record StepDefinition(
        int stepNumber,
        String stepName,
        String description,
        boolean applicableDaily,
        boolean applicableDecade,
        boolean applicableMonthly,
        boolean applicablePos
    ) {
        public boolean isApplicable(String closingType) {
            return switch (closingType) {
                case "DAILY" -> applicableDaily;
                case "DECADE" -> applicableDecade;
                case "MONTHLY" -> applicableMonthly;
                case "POS" -> applicablePos;
                default -> false;
            };
        }
    }

    /**
     * A teljes 16 lépés definíciója.
     * Az "applicable" flag-ek jelzik, melyik zárástípusnál aktív az adott lépés.
     */
    public static final List<StepDefinition> ALL_STEPS = List.of(
        //                                                            DAILY  DECADE MONTHLY POS
        new StepDefinition(STEP_CLOSING_TYPE_SELECTION,
            "Zárás típus kiválasztása",
            "Napi / dekád / havi / POS zárás típusának kiválasztása",
            true,  true,  true,  true),

        new StepDefinition(STEP_DAILY_TRANSACTION_SUMMARY,
            "Napi tranzakció összesítés",
            "Napi tranzakciók összesítése valutánként (vétel, eladás, konverzió)",
            true,  true,  true,  false),

        new StepDefinition(STEP_CASH_BALANCE_CHECK,
            "Pénztár nyitó/záró egyenleg",
            "Készpénz nyitó- és záró egyenleg ellenőrzése valutánként, címletezéssel",
            true,  true,  true,  false),

        new StepDefinition(STEP_HANDLING_FEES_SUMMARY,
            "Kezelési díj összesítés",
            "Kezelési díjak összesítése és címletezése",
            true,  true,  true,  false),

        new StepDefinition(STEP_INTER_BRANCH_MOVEMENTS,
            "Irodák közti mozgások",
            "Pénztárak közötti valuta- és forintmozgások ellenőrzése (göngyöleg/transzfer)",
            true,  true,  true,  false),

        new StepDefinition(STEP_DAILY_EXCHANGE_RATE_CHECK,
            "Napi árfolyam ellenőrzés",
            "Ellenőrzi hogy a napi árfolyamok érvényesek-e (24h TTL) és egyeznek a használtakkal",
            true,  false, false, false),

        new StepDefinition(STEP_DECADE_TRANSACTION_SUMMARY,
            "Dekádos tranzakció összesítés",
            "10 napos időszak tranzakcióinak összesítése valutánként",
            false, true,  true,  false),

        new StepDefinition(STEP_DECADE_DISCREPANCY_HANDLING,
            "Eltéréskezelés",
            "Nyilvántartás és fizikai készlet közti eltérések kezelése, indoklása",
            false, true,  true,  false),

        new StepDefinition(STEP_DECADE_CORRECTION_RECEIPTS,
            "Korrekciós bizonylatok",
            "Eltérésekhez tartozó korrekciós bizonylatok kiállítása",
            false, true,  true,  false),

        new StepDefinition(STEP_POS_CARD_TRANSACTION_SUMMARY,
            "POS kártyás tranzakciók",
            "POS terminál kártyás tranzakcióinak összesítése",
            false, false, false, true),

        new StepDefinition(STEP_POS_REFUNDS_STORNOS,
            "POS sztornók / visszatérítések",
            "POS terminál sztornó és visszatérítési tranzakcióinak összesítése",
            false, false, false, true),

        new StepDefinition(STEP_POS_HANDLING_FEES,
            "POS kezelési díjak",
            "POS terminál kezelési díjainak összesítése",
            false, false, false, true),

        new StepDefinition(STEP_PRINT_CLOSING_RECEIPTS,
            "Zárási bizonylatok nyomtatása",
            "Napi/dekád/havi/POS zárási bizonylatok nyomtatása",
            true,  true,  true,  true),

        new StepDefinition(STEP_PRINT_HUF_TRANSFER_RECEIPTS,
            "HUF átutalási bizonylatok",
            "Forint átutalási bizonylatok nyomtatása (FF/UF)",
            true,  true,  true,  false),

        new StepDefinition(STEP_SEND_DAILY_REPORTS,
            "Napi jelentések küldése",
            "Napi jelentések küldése a központba (legacy: FTP, modern: REST API)",
            true,  true,  true,  false),

        new StepDefinition(STEP_SEND_PERIOD_REPORTS_FINALIZE,
            "Időszaki jelentések + véglegesítés",
            "Dekád/havi jelentések küldése a központba és a zárás véglegesítése",
            // FK-068: napi zárásnál nem aktív — a DailyClosingService 9 lépéses
            // ellenőrzés-lánca csak az 1-9 pozíciókat ismeri, a 10. perzisztált
            // lépés a felületről soha nem volt teljesíthető.
            false, true,  true,  true)
    );

    /**
     * Visszaadja az adott zárástípusra vonatkozó aktív lépéseket.
     */
    public static List<StepDefinition> getStepsForType(String closingType) {
        return ALL_STEPS.stream()
            .filter(s -> s.isApplicable(closingType))
            .toList();
    }

    /**
     * Visszaadja az adott zárástípusra vonatkozó lépések számát.
     */
    public static int getStepCountForType(String closingType) {
        return (int) ALL_STEPS.stream()
            .filter(s -> s.isApplicable(closingType))
            .count();
    }
}
