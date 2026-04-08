package hu.puzzleir.valuta.dto.storno;

import lombok.*;
import java.math.BigDecimal;

/**
 * Sztornó ellenőrzés eredménye.
 * Tartalmazza az árfolyam-eltérés információt is (Felmérés: sztorno.docx).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StornoCheckResultDto {

    private Boolean requiresApproval;
    private Integer dailyStornoCount;
    private String transactionId;
    private String transactionNumber;
    private String message;

    /** Eredeti tranzakció árfolyama */
    private BigDecimal originalRate;
    /** Aktuális árfolyam (ha elérhető) */
    private BigDecimal currentRate;
    /** Árfolyam eltérés (currentRate - originalRate) */
    private BigDecimal rateDifference;
    /** Van-e árfolyam eltérés */
    private Boolean rateChanged;
}
