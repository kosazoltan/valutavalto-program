package hu.puzzleir.valuta.dto.sanction;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Szankciós szűrés eredménye.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SanctionScreeningResult {

    /** Volt-e találat */
    private boolean matched;

    /** Találatok listája */
    private List<SanctionMatch> matches;

    /** Kockázati szint: CLEAR, POSSIBLE, CONFIRMED */
    private String riskLevel;
}
