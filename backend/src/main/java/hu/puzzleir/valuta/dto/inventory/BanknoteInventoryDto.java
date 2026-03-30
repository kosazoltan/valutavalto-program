package hu.puzzleir.valuta.dto.inventory;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BanknoteInventoryDto {
    private Long id;
    private UUID branchId;
    private Long currencyId;
    private String currencyCode;
    private BigDecimal faceValue;
    private Integer quantity;
    private BigDecimal totalValue;
    private Integer minQuantity;
    private Integer maxQuantity;
    private String availabilityDid;
    private boolean lowStock;
    private boolean overStock;
    private LocalDateTime lastCountedAt;
    private String lastCountedBy;
}
