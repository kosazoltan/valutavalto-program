package hu.puzzleir.valuta.dto.cashregister;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Bizonylat nyomtatás kérés a pénztárgépre.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class CashRegisterReceiptRequest {

    @NotNull
    private UUID branchId;

    @NotBlank
    private String receiptNumber;

    @NotNull
    private BigDecimal amount;

    @NotBlank
    private String currencyCode;

    @NotNull
    private BigDecimal amountHuf;
}
