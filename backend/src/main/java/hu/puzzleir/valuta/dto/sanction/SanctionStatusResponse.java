package hu.puzzleir.valuta.dto.sanction;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Szankciós lista státusz — utolsó frissítés, aktív bejegyzések száma.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SanctionStatusResponse {

    private LocalDate lastUpdateDate;
    private long activeEntryCount;
}
