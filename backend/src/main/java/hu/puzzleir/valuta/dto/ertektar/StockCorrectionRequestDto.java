package hu.puzzleir.valuta.dto.ertektar;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockCorrectionRequestDto {

    @NotBlank(message = "Entitás típus kötelező (VAULT/CASHIER)")
    private String entityType;

    @NotBlank(message = "Entitás azonosító kötelező")
    private String entityId;

    @NotBlank(message = "Valutakód kötelező")
    private String currencyCode;

    @NotNull(message = "Új mennyiség kötelező")
    @DecimalMin(value = "0", message = "A mennyiség nem lehet negatív")
    private BigDecimal newQuantity;

    @NotBlank(message = "Indoklás kötelező")
    private String reason;
}
