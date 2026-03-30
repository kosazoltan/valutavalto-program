package hu.puzzleir.valuta.dto.transaction;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransactionBanknoteDto {
    private Long id;
    private Long transactionId;
    private Long transactionLineId;

    @NotBlank(message = "currencyCode kötelező")
    @Size(min = 3, max = 3, message = "currencyCode 3 karakter kell legyen")
    private String currencyCode;

    @NotNull(message = "faceValue kötelező")
    @DecimalMin(value = "0.01", message = "faceValue pozitív kell legyen")
    private BigDecimal faceValue;

    @NotNull(message = "quantity kötelező")
    @Min(value = 1, message = "quantity minimum 1")
    private Integer quantity;

    @NotBlank(message = "direction kötelező")
    @Pattern(regexp = "^(IN|OUT)$", message = "direction: IN vagy OUT")
    private String direction;

    private BigDecimal totalValue;
}
