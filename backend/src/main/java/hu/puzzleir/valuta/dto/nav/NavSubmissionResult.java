package hu.puzzleir.valuta.dto.nav;

import lombok.*;

/**
 * NAV beküldés eredmény.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NavSubmissionResult {

    private boolean success;
    private String referenceNumber;
    private String errorMessage;
}
