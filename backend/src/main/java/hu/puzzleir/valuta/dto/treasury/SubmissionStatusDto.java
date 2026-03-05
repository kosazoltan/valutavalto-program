package hu.puzzleir.valuta.dto.treasury;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SubmissionStatusDto {
    private String branchId;
    private String branchCode;
    private String branchName;
    private Boolean submitted;
    private String submittedAt;
}
