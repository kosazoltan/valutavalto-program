package hu.puzzleir.valuta.dto.report;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * G9: Pillanatnyi pénztárállás kimutatás (Delphi: PenztarAllas — egy-képernyős kasszanézet).
 *
 * <p>Valutánként: NYITÓ / BEVÉTEL / KIADÁS / ZÁRÓ, plusz a napi kezelési-díj egyenleg (HUF).
 * A napi mozgásokból (DailyBalance) számolt aktuális pénztárállás.</p>
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LiveCashPositionDto {

    private String branchId;
    private LocalDate date;

    @Builder.Default
    private List<CurrencyLineDto> lines = new ArrayList<>();

    /** Kezelési díj (KEZ-I DÍJ) napi egyenleg HUF-ban (HANDLING_FEE subledger). */
    @Builder.Default
    private BigDecimal handlingFeeHuf = BigDecimal.ZERO;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class CurrencyLineDto {
        private String currencyCode;     // VNEM
        private String currencyName;     // VALUTA NEVE
        @Builder.Default private BigDecimal opening = BigDecimal.ZERO; // NYITÓ
        @Builder.Default private BigDecimal income = BigDecimal.ZERO;  // BEVÉTEL (vétel + bejövő átadás)
        @Builder.Default private BigDecimal expense = BigDecimal.ZERO; // KIADÁS (eladás + kimenő átadás)
        @Builder.Default private BigDecimal closing = BigDecimal.ZERO; // ZÁRÓ
    }
}
