package hu.puzzleir.valuta.dto.authorization;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AuthorizationDto {
    private UUID id;
    private UUID representativeId;
    private String operationDid;
    private String authorizationTypeDid;
    private String statusDid;
    private LocalDate startDate;
    private LocalDate expiryDate;
    private BigDecimal singleTransactionLimit;
    private BigDecimal maxAmount;
    private Integer maxTransactionCount;
    private Integer usedTransactionCount;
    private BigDecimal usedAmount;
    private String notes;
    private String statusReason;
    private LocalDateTime verifiedAt;
    private LocalDateTime createdAt;
}
