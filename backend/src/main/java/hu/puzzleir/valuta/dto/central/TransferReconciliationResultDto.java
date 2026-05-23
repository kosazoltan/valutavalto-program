package hu.puzzleir.valuta.dto.central;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * FK-003: az egyeztetési lekérdezés eredménye egy intervallumra.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransferReconciliationResultDto {
    private LocalDate startDate;
    private LocalDate endDate;
    private int totalRows;
    private int matchedRows;
    private int discrepancyRows;
    /** Hány érintett értéktár kapott eltérés-értesítést ebben a futásban. */
    private int notifiedBranches;
    private LocalDateTime generatedAt;
    private List<TransferReconciliationRowDto> rows;
}
