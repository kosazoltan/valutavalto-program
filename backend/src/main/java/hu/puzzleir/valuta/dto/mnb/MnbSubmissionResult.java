package hu.puzzleir.valuta.dto.mnb;

import lombok.*;

/**
 * MNB beküldés eredmény.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MnbSubmissionResult {

    private boolean success;
    private String referenceNumber;
    private String errorMessage;
}
