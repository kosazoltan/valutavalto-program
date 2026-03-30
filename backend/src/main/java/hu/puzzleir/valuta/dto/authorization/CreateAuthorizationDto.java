package hu.puzzleir.valuta.dto.authorization;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateAuthorizationDto {

    @NotBlank
    private String operationDid;

    private String authorizationTypeDid;

    @NotNull
    private LocalDate startDate;

    private LocalDate expiryDate;

    private BigDecimal singleTransactionLimit;
    private BigDecimal maxAmount;
    private Integer maxTransactionCount;
    private String notes;
}
