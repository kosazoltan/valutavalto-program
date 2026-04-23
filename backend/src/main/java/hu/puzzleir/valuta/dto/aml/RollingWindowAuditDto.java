package hu.puzzleir.valuta.dto.aml;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Sprint 6.2 C2 compliance audit - 8 napos gordulo limit feletti ugyfelek.
 * Pmt. (2017. LIII. tv.) szerinti hatosagi audit lista.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RollingWindowAuditDto {
    /** Ugyfel azonositoja. */
    private String customerId;

    /** Ugyfel neve (ha ismert). */
    private String customerName;

    /** 8 napos gordult osszeg (HUF). */
    private BigDecimal rollingWindowTotalHuf;

    /** Kuszob, ami feletti a figyelem (HUF). */
    private BigDecimal rollingWindowLimitHuf;

    /** Mennyivel haladja meg a kuszobot (%). */
    private BigDecimal exceedPercent;

    /** Audit generalas idopontja. */
    private LocalDateTime auditAt;

    /** 8 napos ablak kezdo datuma. */
    private LocalDate sinceDate;

    /** Ablak hossza (alapertelmezett 8 nap). */
    private int windowDays;

    /** Kiemelt kockazatu jelolesre mar megjelolt-e. */
    private boolean highRiskFlag;
}