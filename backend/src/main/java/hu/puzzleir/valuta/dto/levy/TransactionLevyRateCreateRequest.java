package hu.puzzleir.valuta.dto.levy;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * FK-099 FR-1 — új append-only ráta-sor rögzítése.
 *
 * <p>D17: a {@code conversionSingleSideFlag} itt {@code @NotNull Boolean} (NEM
 * primitív): hiányzó JSON-mező esetén 400-at ad, nem csendben {@code false}-t.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionLevyRateCreateRequest {

    @NotNull
    @Future
    private LocalDate effectiveFrom;

    @NotNull
    @DecimalMin("0.000")
    @Digits(integer = 3, fraction = 3)
    private BigDecimal baseRatePercent;

    @NotNull
    @DecimalMin("0.00")
    @Digits(integer = 13, fraction = 2)
    private BigDecimal baseRateCapHuf;

    @NotNull
    @DecimalMin("0.000")
    @Digits(integer = 3, fraction = 3)
    private BigDecimal supplementRatePercent;

    @NotNull
    @DecimalMin("0.00")
    @Digits(integer = 13, fraction = 2)
    private BigDecimal supplementRateCapHuf;

    @NotNull
    private Boolean conversionSingleSideFlag;
}
