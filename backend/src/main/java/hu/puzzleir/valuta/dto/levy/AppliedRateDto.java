package hu.puzzleir.valuta.dto.levy;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/** FK-099 — a riport által ténylegesen felhasznált ráta-sor (FR-8 küszöb-badge). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppliedRateDto {

    private LocalDate effectiveFrom;
    private BigDecimal baseRatePercent;
    private BigDecimal baseRateCapHuf;
    private BigDecimal supplementRatePercent;
    private BigDecimal supplementRateCapHuf;
    private boolean conversionSingleSideFlag;

    /** Számított küszöb (D4); null, ha a cap elérhetetlen (0 ráta). */
    private BigDecimal thresholdHuf;
}
