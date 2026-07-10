package hu.puzzleir.valuta.dto.camera;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewOverviewRowDto {
    private UUID branchId;
    private String branchCode;
    private String branchName;
    private LocalDate date;
    private int recordingCount;
    private int markCount;
    private boolean reviewed;
    private boolean problematic;
}
