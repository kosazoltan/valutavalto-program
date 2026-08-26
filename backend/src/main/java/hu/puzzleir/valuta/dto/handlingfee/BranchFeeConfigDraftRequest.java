package hu.puzzleir.valuta.dto.handlingfee;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * FK-096: DRAFT mentés kérése — CSAK BRACKET/PER_MILLE mód (D4: a NONE örökölt
 * érték, az editor nem kínálja; a NONE-módú LIVE sor mellett a modal módot választat).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BranchFeeConfigDraftRequest {

    @NotNull
    @Pattern(regexp = "^(BRACKET|PER_MILLE)$")
    private String feeMode;

    @DecimalMin("0")
    @Digits(integer = 3, fraction = 3)
    private BigDecimal perMilleRate;

    @DecimalMin("0")
    @Digits(integer = 13, fraction = 2)
    private BigDecimal perMilleCap;
}
