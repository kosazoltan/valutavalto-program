package hu.puzzleir.valuta.dto.checklist;

import lombok.*;

/**
 * Checklist tétel kipipálás/visszavonás request.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CheckItemRequest {

    private boolean checked;
    private String notes;
}
