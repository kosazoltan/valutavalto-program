package hu.puzzleir.valuta.dto.mnb;

import lombok.*;

import java.math.BigDecimal;

/**
 * MNB riport valutánkénti sor DTO.
 *
 * Legacy: Delphi MNB gyűjtő DLL valutánkénti bontás.
 * Tartalmaz forgalmi adatokat ÉS készlet/mozgás adatokat (S1-01 bővítés).
 *
 * Készlet képlet (Delphi AdatKiertekeles):
 *   bevétel = nyitó + vétel + többlet + pénztárból + bankból + visszaPlusz
 *   kiadás  = eladás + hiány + pénztárba + bankba + visszaMinusz
 *   számítottZáró = bevétel - kiadás
 *   diff = abs(záró - számítottZáró) → 0 = OK
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MnbCurrencyLineDto {
    private String currencyCode;

    // --- Forgalmi adatok (eredeti) ---
    private BigDecimal buyAmount;
    private BigDecimal sellAmount;
    private BigDecimal buyHuf;
    private BigDecimal sellHuf;
    private BigDecimal avgBuyRate;
    private BigDecimal avgSellRate;
    private int transactionCount;

    // --- Készlet adatok (S1-01: Delphi nyitó/záró) ---

    /** Nyitó készlet (előző nap záró vagy hónap-eleji) */
    @Builder.Default
    private BigDecimal openingBalance = BigDecimal.ZERO;

    /** Záró készlet (tényleges) */
    @Builder.Default
    private BigDecimal closingBalance = BigDecimal.ZERO;

    // --- Mozgás adatok (S1-01: Delphi pénztár/bank/többlet/hiány) ---

    /** Pénztárak közötti átvétel (bejövő) — Delphi: PENZTARIATVETEL */
    @Builder.Default
    private BigDecimal transfersIn = BigDecimal.ZERO;

    /** Pénztárak közötti kiadás (kimenő) — Delphi: PENZTARIKIADAS */
    @Builder.Default
    private BigDecimal transfersOut = BigDecimal.ZERO;

    /** Banki átvétel — Delphi: BANKIATVETEL */
    @Builder.Default
    private BigDecimal bankIn = BigDecimal.ZERO;

    /** Banki átadás — Delphi: BANKIATADAS */
    @Builder.Default
    private BigDecimal bankOut = BigDecimal.ZERO;

    /** Készlettöbblet — Delphi: TOBBLET */
    @Builder.Default
    private BigDecimal surplus = BigDecimal.ZERO;

    /** Készlethiány — Delphi: HIANY */
    @Builder.Default
    private BigDecimal shortage = BigDecimal.ZERO;

    /** Visszavétel plusz (bejövő) — Delphi: VISSZAPLUSZ */
    @Builder.Default
    private BigDecimal returnsIn = BigDecimal.ZERO;

    /** Visszavétel mínusz (kimenő) — Delphi: VISSZAMINUSZ */
    @Builder.Default
    private BigDecimal returnsOut = BigDecimal.ZERO;

    /** Bankkártyás forgalom (HUF, csak HUF sornál releváns) — Delphi: BANKKARTYA */
    @Builder.Default
    private BigDecimal cardPayment = BigDecimal.ZERO;

    // --- Validáció (S1-01: Delphi AdatKiertekeles) ---

    /** Számított záró = bevétel - kiadás */
    @Builder.Default
    private BigDecimal calculatedClosing = BigDecimal.ZERO;

    /** Eltérés = abs(záró - számítottZáró) */
    @Builder.Default
    private BigDecimal balanceDiff = BigDecimal.ZERO;

    /** Validáció eredménye: "OK" vagy "?" (Delphi MEGJEGYZES) */
    private String validationStatus;
}
