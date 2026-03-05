package hu.puzzleir.valuta.dto.nav;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * NAV pénztárgép kommunikáció eredmény.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NavSendResult {
    private boolean success;
    private String receiptNumber;
    private String error;
}
