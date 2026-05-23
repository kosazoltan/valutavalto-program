package hu.puzzleir.valuta.dto.central;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * FK-003: egy egyeztetési sor a pénztárak/értéktárak közötti pénzmozgás táblázatban.
 * Egy átadólap több sort is adhat (több-valutás {@code TransferLine}-onként egyet).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransferReconciliationRowDto {
    private Long transferId;
    private String transferNumber;
    private LocalDate date;
    private String fromBranchCode;
    private String fromBranchName;
    private String toBranchCode;
    private String toBranchName;
    private String currencyCode;
    private BigDecimal sentAmount;
    private BigDecimal receivedAmount;
    /** EGYEZIK vagy ELTERES. */
    private String status;
    /** Eltérés esetén emberi olvasású magyarázat (pl. hiányzó fogadó oldal). */
    private String discrepancyNote;
}
