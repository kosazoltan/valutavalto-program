package hu.puzzleir.valuta.dto.vaultchecklist;

import lombok.*;

/**
 * PUT kérés — a 9 checklist-tétel frissítése.
 *
 * <p>FR-ZARUI-17..25</p>
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateChecklistItemsRequest {
    private boolean item1;
    private boolean item2;
    private boolean item3;
    private boolean item4;
    private boolean item5;
    private boolean item6;
    private boolean item7;
    private boolean item8;
    private boolean item9;
}
