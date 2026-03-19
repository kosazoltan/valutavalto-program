package hu.puzzleir.valuta.dto.checklist;

import lombok.*;

import java.time.LocalDateTime;

/**
 * Napi checklist tétel DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyChecklistItemDto {

    private int itemNumber;
    private String itemTitle;
    private String itemDescription;
    private boolean checked;
    private LocalDateTime checkedAt;
    private Long checkedByWorkerId;
    private String notes;
}
