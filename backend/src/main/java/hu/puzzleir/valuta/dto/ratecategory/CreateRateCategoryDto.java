package hu.puzzleir.valuta.dto.ratecategory;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor
public class CreateRateCategoryDto {

    @NotNull
    private UUID branchId;

    @NotBlank
    private String currencyCode;

    @NotBlank
    private String category;

    @NotNull
    private BigDecimal buyRate;

    @NotNull
    private BigDecimal sellRate;

    private BigDecimal minAmount;
    private BigDecimal maxAmount;
}
