package hu.puzzleir.valuta.dto.storno;

import lombok.*;

import java.time.LocalDateTime;

/**
 * Sztornó jóváhagyás DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StornoApprovalDto {

    private String id;
    private String transactionId;
    private String workerId;
    private String branchId;
    private Integer dailyStornoCount;
    private String approvalStatusDid;
    private String requestReason;
    private String rejectionReason;
    private String approvedByWorkerId;
    private LocalDateTime approvedAt;
}
