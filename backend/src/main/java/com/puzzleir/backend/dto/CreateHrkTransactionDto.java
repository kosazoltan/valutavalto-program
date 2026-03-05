package com.puzzleir.backend.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateHrkTransactionDto {

    @NotBlank(message = "Valutanem megadása kötelező")
    private String currencyCode;

    @NotNull(message = "Összeg megadása kötelező")
    @DecimalMin(value = "0.01", message = "Összeg nem lehet nulla vagy negatív")
    private BigDecimal amount;

    @NotNull(message = "Forint összeg megadása kötelező")
    @DecimalMin(value = "0.01", message = "Forint összeg nem lehet nulla vagy negatív")
    private BigDecimal hufAmount;

    private String bankAccountNumber;
    private String note;
}
