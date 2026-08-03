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

    /**
     * FK-072: 1 alatti (tört) névérték sehol nem rögzíthető — a frontend-védelem
     * (BanknoteBreakdown / isAllowedFaceValue) backend-oldali párja, direkt API-hívás
     * ellen. A korábbi 0.01-es minimum a tört címletet átengedte.
     */
    @NotNull(message = "faceValue kötelező")
    @DecimalMin(value = "1", message = "A címlet névértéke nem lehet 1-nél kisebb (tört címlet nem rögzíthető)!")
    private BigDecimal faceValue;

    @NotNull(message = "quantity kötelező")
    @Min(value = 1, message = "quantity minimum 1")
    private Integer quantity;

    @NotBlank(message = "direction kötelező")
    @Pattern(regexp = "^(IN|OUT)$", message = "direction: IN vagy OUT")
    private String direction;

    private BigDecimal totalValue;
}
