package hu.puzzleir.valuta.dto.stamp;

import hu.puzzleir.valuta.entity.StampAssignment;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StampAssignmentDto {
    private UUID id;
    private UUID batchId;
    private String serialNumber;
    private Long transactionId;
    private LocalDateTime assignedAt;
    private String assignedBy;

    public static StampAssignmentDto from(StampAssignment assignment) {
        return StampAssignmentDto.builder()
                .id(assignment.getId())
                .batchId(assignment.getStampBatch().getId())
                .serialNumber(assignment.getSerialNumber())
                .transactionId(assignment.getTransactionId())
                .assignedAt(assignment.getAssignedAt())
                .assignedBy(assignment.getAssignedBy())
                .build();
    }
}
