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
    /**
     * #868 (Codex P2): a jóváhagyási státusz Dictionary KÓDJA (PENDING/APPROVED/REJECTED) —
     * a frontend ez ellen hasonlít (NEM az approvalStatusDid UUID ellen). E mező nélkül a
     * StornoPage sosem oldotta fel a sztornó-űrlapot jóváhagyás után (UUID !== 'APPROVED').
     */
    private String approvalStatusCode;
    private String requestReason;
    private String rejectionReason;
    private String approvedByWorkerId;
    private LocalDateTime approvedAt;
    /**
     * Supervisor jóváhagyó-lista megjelenítési mezői: kérelmező neve, az eredeti
     * bizonylatszám és a kérés időpontja — ezek nélkül a jóváhagyó nem tudja
     * azonosítani, mit hagy jóvá.
     */
    private String workerName;
    private String receiptNumber;
    private LocalDateTime createdAt;
}
