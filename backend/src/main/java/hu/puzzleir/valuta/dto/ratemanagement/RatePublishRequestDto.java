package hu.puzzleir.valuta.dto.ratemanagement;

import lombok.*;
import java.util.List;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RatePublishRequestDto {
    private UUID workgroupId;
    private List<UUID> templateIds;
    private String notes;
}
