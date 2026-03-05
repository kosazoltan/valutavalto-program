package hu.puzzleir.valuta.dto.handlingfee;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @NoArgsConstructor @AllArgsConstructor
public class ApplyDiscountDto {

    @NotNull
    @Min(0)
    @Max(100)
    private Integer discountPercent;

    private String reason;
}
