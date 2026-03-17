package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Munkacsoport részletes DTO — a branch hozzárendelésekkel együtt.
 * Az árfolyam-készítő csoportnézetéhez.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkgroupDetailDTO {

    private UUID id;
    private String code;
    private String name;
    private Integer legacyGroupNumber;
    private boolean active;

    /** Munkacsoporthoz tartozó irodák */
    private List<BranchInfo> branches;

    /** Kedvezmény határok (limit összeghatárok) */
    private BigDecimal limit1Boundary;  // Alsó határ (pl. 50,000)
    private BigDecimal limit2Boundary;  // Középső határ (pl. 300,000)
    private BigDecimal limit3Boundary;  // Felső határ (pl. 1,000,000)

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BranchInfo {
        private UUID id;
        private String code;
        private String name;
    }
}
