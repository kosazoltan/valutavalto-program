package hu.puzzleir.valuta.dto.stamp;

import hu.puzzleir.valuta.entity.StampBatch;
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
public class StampBatchDto {
    private UUID id;
    private UUID branchId;
    private String serialPrefix;
    private Integer serialStart;
    private Integer serialEnd;
    private Integer totalCount;
    private Long usedCount;
    private LocalDateTime receivedAt;
    private String receivedBy;
    private String note;

    public static StampBatchDto from(StampBatch batch, long usedCount) {
        return StampBatchDto.builder()
                .id(batch.getId())
                .branchId(batch.getBranchId())
                .serialPrefix(batch.getSerialPrefix())
                .serialStart(batch.getSerialStart())
                .serialEnd(batch.getSerialEnd())
                .totalCount(batch.getSerialEnd() - batch.getSerialStart() + 1)
                .usedCount(usedCount)
                .receivedAt(batch.getReceivedAt())
                .receivedBy(batch.getReceivedBy())
                .note(batch.getNote())
                .build();
    }
}
