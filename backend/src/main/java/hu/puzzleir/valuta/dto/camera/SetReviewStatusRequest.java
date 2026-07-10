package hu.puzzleir.valuta.dto.camera;

import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
public class SetReviewStatusRequest {
    private UUID branchId;
    private LocalDate reviewDate;
    private boolean reviewed;
}
