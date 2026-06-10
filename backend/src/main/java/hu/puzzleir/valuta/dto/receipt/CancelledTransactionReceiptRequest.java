package hu.puzzleir.valuta.dto.receipt;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CancelledTransactionReceiptRequest {

    @NotBlank
    @Pattern(regexp = "BUY|SELL", message = "A megszakitott tranzakcio modja csak BUY vagy SELL lehet.")
    private String mode;

    @Size(max = 500)
    private String reason;

    @Size(max = 100)
    private String customerName;

    @Size(max = 100)
    private String customerDocumentNumber;

    @Size(max = 6)
    @Valid
    private List<Line> lines;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Line {
        @Size(max = 3)
        private String currencyCode;

        @DecimalMin(value = "0.0", inclusive = false)
        @Digits(integer = 18, fraction = 6)
        private BigDecimal foreignAmount;

        @DecimalMin(value = "0.0", inclusive = false)
        @Digits(integer = 18, fraction = 8)
        private BigDecimal rate;

        @DecimalMin(value = "0.0", inclusive = false)
        @Digits(integer = 18, fraction = 2)
        private BigDecimal hufAmount;
    }
}
