package hu.puzzleir.valuta.dto.cashregister;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class CashRegisterEventDto {
    private UUID id;
    private UUID branchId;
    private String eventType;
    private String receiptNumber;
    private BigDecimal amount;
    private String currencyCode;
    private BigDecimal amountHuf;
    private String taxNumber;
    private String cashRegisterId;
    private LocalDateTime eventTimestamp;
    private String rawResponse;
}
