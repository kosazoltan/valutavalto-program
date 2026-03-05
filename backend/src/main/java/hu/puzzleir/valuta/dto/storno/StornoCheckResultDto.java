package hu.puzzleir.valuta.dto.storno;

import lombok.*;

/**
 * Sztornó ellenőrzés eredménye.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StornoCheckResultDto {

    private Boolean requiresApproval;
    private Integer dailyStornoCount;
    private String transactionId;
    private String transactionNumber;
    private String message;
}
