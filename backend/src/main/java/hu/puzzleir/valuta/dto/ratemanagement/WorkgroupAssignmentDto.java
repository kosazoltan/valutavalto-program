package hu.puzzleir.valuta.dto.ratemanagement;

import lombok.*;
import java.util.List;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkgroupAssignmentDto {
    private UUID workgroupId;
    private List<UUID> branchIds;
}
