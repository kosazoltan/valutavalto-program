package hu.puzzleir.valuta.dto.ertektar;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultTransferResponseDto {
    private Long id;
    private String transferNumber;
    private Integer sourceVaultId;
    private String sourceVaultName;
    private Integer targetVaultId;
    private String targetVaultName;
    private String sourceBranchCode;
    private String targetBranchCode;
    private String currencyCode;
    private BigDecimal amount;
    private BigDecimal wacAtTransfer;
    private String status;
    private Boolean requiresSupervisor;
    private String note;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;
    private LocalDateTime receivedAt;
}
