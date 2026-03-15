package hu.puzzleir.valuta.dto.ertektar;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class CollectionRequestDto {
    @NotBlank
    private String sourceBranchCode;
    @NotBlank
    private String currencyCode;
    @NotNull @Positive
    private BigDecimal amount;
    private String note;
}
