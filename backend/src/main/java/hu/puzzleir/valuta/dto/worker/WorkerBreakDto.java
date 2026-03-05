package hu.puzzleir.valuta.dto.worker;

import hu.puzzleir.valuta.entity.WorkerBreak;
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
public class WorkerBreakDto {
    private UUID id;
    private Long workerId;
    private UUID branchId;
    private LocalDateTime breakStart;
    private LocalDateTime breakEnd;
    private String reason;
    private String approvedBy;

    public static WorkerBreakDto from(WorkerBreak wb) {
        return WorkerBreakDto.builder()
                .id(wb.getId())
                .workerId(wb.getWorker().getId())
                .branchId(wb.getBranchId())
                .breakStart(wb.getBreakStart())
                .breakEnd(wb.getBreakEnd())
                .reason(wb.getReason())
                .approvedBy(wb.getApprovedBy())
                .build();
    }
}
