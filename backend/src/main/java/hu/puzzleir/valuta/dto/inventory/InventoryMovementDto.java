package hu.puzzleir.valuta.dto.inventory;

import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InventoryMovementDto {
    private Long id;
    private String fromBranchId;
    private String fromBranchName;
    private String toBranchId;
    private String toBranchName;
    private Long currencyId;
    private String currencyCode;
    private String currencyName;
    private BigDecimal amount;
    private BigDecimal hufValue;
    // V280 / audit-finding 2026-05-31 (P1): a ténylegesen fogadott összeg + az eltérés (received-amount).
    // Eddig perzisztált + auditált volt, de a read-DTO-ból hiányzott → a kliens nem látta a fogadáskori
    // hiányt. NULL, amíg nincs fogadva; difference 0, ha pontos.
    private BigDecimal receivedAmount;
    private BigDecimal difference;
    private String movementType;
    private String movementTypeDisplay;
    private String status;
    private String statusDisplay;
    private Long initiatedById;
    private String initiatedByName;
    private Long approvedById;
    private String approvedByName;
    private Long receivedById;
    private String receivedByName;
    private String referenceNumber;
    private String notes;
    private String movementDate;
    private String movementTime;
    private String approvedAt;
    private String receivedAt;
    private String createdAt;
}
