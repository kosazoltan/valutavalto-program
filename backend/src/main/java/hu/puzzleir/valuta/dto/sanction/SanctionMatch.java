package hu.puzzleir.valuta.dto.sanction;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Egyedi szankciós találat.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SanctionMatch {

    private UUID entryId;
    private String fullName;
    private String aliases;
    private String dateOfBirth;
    private String nationality;
    private String documentNumber;
    private String listType;
    private String listReference;

    /** EXACT, PARTIAL, ALIAS */
    private String matchType;

    /** Egyezési pontszám (0.0 - 1.0) */
    private double score;
}
