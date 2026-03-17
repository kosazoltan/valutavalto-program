package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Branch lista DTO az árfolyam-készítő munkacsoport kezelőhöz.
 * Jelzi, hogy az adott iroda hozzá van-e rendelve a kiválasztott munkacsoporthoz.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchListDTO {
    private UUID id;
    private String code;
    private String name;
    private String city;
    private boolean assignedToCurrentWorkgroup;
}
