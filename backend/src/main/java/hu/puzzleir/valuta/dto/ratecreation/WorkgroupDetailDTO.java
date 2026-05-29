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

    /**
     * FK-02: csempeszín-palettakulcs (pl. 'amber'); null = alapértelmezett.
     * A rate-maker csempés kezelő nézet ebből színezi a csempét — e nélkül a
     * /rate-creation/workgroups bootstrap nem adná vissza a beállított színt.
     */
    private String tileColor;

    /**
     * FK-04/E: árfolyamvédelem flag. A rate-maker csempén lévő interaktív checkbox
     * ezt jeleníti meg; e nélkül a toggle után a reload mindig true-ra esne vissza.
     */
    private Boolean protectionEnabled;

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
