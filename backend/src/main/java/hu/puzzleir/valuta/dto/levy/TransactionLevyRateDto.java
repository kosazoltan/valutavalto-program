package hu.puzzleir.valuta.dto.levy;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

/** FK-099 — egy append-only ráta-sor megjelenítése a derived küszöbbel. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionLevyRateDto {

    private UUID id;
    private LocalDate effectiveFrom;
    private BigDecimal baseRatePercent;
    private BigDecimal baseRateCapHuf;
    private BigDecimal supplementRatePercent;
    private BigDecimal supplementRateCapHuf;
    /** D17: primitív boolean. */
    private boolean conversionSingleSideFlag;
    private String createdBy;
    private OffsetDateTime createdAt;

    /** Számított küszöb (D4); null, ha a cap elérhetetlen (0 ráta). */
    private BigDecimal thresholdHuf;
}
