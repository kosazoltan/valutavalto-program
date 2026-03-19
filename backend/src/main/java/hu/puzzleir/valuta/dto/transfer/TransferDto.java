package hu.puzzleir.valuta.dto.transfer;

import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransferDto {
    private Long id;
    private String transferNumber;
    private String fromBranchId;
    private String fromBranchCode;
    private String fromBranchName;
    private String toBranchId;
    private String toBranchCode;
    private String toBranchName;
    private Long fromWorkerId;
    private String fromWorkerName;
    private Long toWorkerId;
    private String toWorkerName;
    private String transferType;
    private String transferTypeDisplay;
    private String direction;
    private String directionDisplay;
    private String status;
    private String statusDisplay;
    private String transferDate;
    private String transferTime;
    private String receivedDate;
    private String receivedTime;
    private Long currencyId;
    private String currencyCode;
    private String currencyName;
    private BigDecimal amount;
    private BigDecimal hufValue;
    private BigDecimal receivedAmount;
    private BigDecimal difference;
    private String notes;
    private Boolean handoverPrinted;
    private Boolean receiptPrinted;
    private String createdAt;
    private Boolean hasDifference;
    private Boolean isCompleted;
    private Boolean isPending;
}
