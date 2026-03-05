package hu.puzzleir.valuta.dto.datacollection;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Adatgyűjtés válasz DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DataCollectionDto {

    private UUID id;
    private UUID branchId;
    private LocalDate collectionDate;
    private String status;
    private String collectionType;
    private Integer transactionCount;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private String errorMessage;
    private LocalDateTime createdAt;
}
