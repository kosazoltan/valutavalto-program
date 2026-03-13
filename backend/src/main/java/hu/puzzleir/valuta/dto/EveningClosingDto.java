package hu.puzzleir.valuta.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EveningClosingDto {
    private UUID id;
    private UUID branchId;
    private LocalDate closingDate;
    private String status;
    private String packageData;
    private Integer transactionCount;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private String inventorySnapshot;
    private LocalDateTime sentAt;
    private LocalDateTime confirmedAt;
    private LocalDateTime createdAt;
}
