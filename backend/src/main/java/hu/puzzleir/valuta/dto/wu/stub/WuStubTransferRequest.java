package hu.puzzleir.valuta.dto.wu.stub;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuStubTransferRequest {

    @NotNull
    private UUID branchId;

    private UUID wuCustomerId;

    @NotBlank
    @Pattern(regexp = "\\d{10}", message = "Az MTCN pontosan 10 számjegy lehet")
    private String mtcn;

    @NotNull
    @DecimalMin(value = "0.01", message = "amountUsd minimum 0.01")
    private BigDecimal amountUsd;

    @NotNull
    @DecimalMin(value = "0.00", message = "amountHuf nem lehet negatív")
    private BigDecimal amountHuf;

    @DecimalMin(value = "0.00", message = "feeAmount nem lehet negatív")
    private BigDecimal feeAmount;

    @DecimalMin(value = "0.0001", message = "exchangeRate minimum 0.0001")
    private BigDecimal exchangeRate;

    private String senderName;
    private String receiverName;
    private String destinationCountry;
    private String receiptNumber;
    private LocalDateTime transactionDate;
}
