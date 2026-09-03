package hu.puzzleir.valuta.dto.levy;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * FK-099 — tranzakciós illeték riport válasz.
 *
 * <p>Sorok pénztár+nap bontásban, három oszlopcsoport (Vétel / Eladás /
 * Konverzió) × 5 alkomponens + soronkénti Nagy-alap és Tranz.díj; backend-számolt
 * ÖSSZESEN sor (FR-11: a totals-ban date/branch-mezők null-ok); havi cég-panel.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionLevyReportDto {

    private LocalDate from;
    private LocalDate to;

    /** A riportban ténylegesen felhasznált ráta-sorok, effectiveFrom ASC. */
    private List<AppliedRateDto> appliedRates;

    /** Pénztár-nap sorok, branchCode ASC, date ASC rendezésben. */
    private List<Row> rows;

    /** FR-11: backend-számolt ÖSSZESEN sor (date/branchId/branchCode/branchName = null). */
    private Row totals;

    /** FR-12/13/14: havi cég-szintű panel (konverzió nélkül). */
    private MonthlySummaryDto monthlySummary;

    /** Egy pénztár-nap sora. */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Row {
        private LocalDate date;
        private UUID branchId;
        private String branchCode;
        private String branchName;
        private TypeGroupDto buy;
        private TypeGroupDto sell;
        private TypeGroupDto conversion;

        /** FR-9: a küszöb feletti tételek HUF-alapjának összege a sorban. */
        private BigDecimal largeBaseHuf;

        /**
         * FR-10 / FR-8 (FK-100): a sor illeték-összege — a 3 típus-csoport
         * (Vétel / Eladás / Konverzió) × 4 pénz-mező (normalBaseLevy,
         * normalSupplementLevy, aboveThresholdBaseLevy,
         * aboveThresholdSupplementLevy) = 12 pénz-komponens összege.
         * A darabszám (aboveThresholdCount) és a largeBaseHuf NEM illeték.
         */
        private BigDecimal levyTotal;
    }
}
