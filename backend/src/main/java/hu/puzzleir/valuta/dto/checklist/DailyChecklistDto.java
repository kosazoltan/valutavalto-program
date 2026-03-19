package hu.puzzleir.valuta.dto.checklist;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Napi checklist DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyChecklistDto {

    private UUID id;
    private UUID branchId;
    private LocalDate checklistDate;
    private Long workerId;
    private String status;
    private LocalDateTime completedAt;
    private LocalDateTime createdAt;
    private List<DailyChecklistItemDto> items;
}
