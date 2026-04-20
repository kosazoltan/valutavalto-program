package hu.puzzleir.valuta.dto.transit;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Uton levo (transit) csomag: penztar <-> ertektar kezbol-kezbe atadas-atvetel tracking.
 *
 * Tipus:
 *   - DISTRIBUTION: ertektar -> penztar (VaultDistribution line)
 *   - COLLECTION:   penztar -> ertektar (VaultCollection)
 *
 * A fogado branch az ack-ot kattintassal validalja, ezzel a status IN_PROGRESS -> COMPLETED.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransitItemDto {
    /** DISTRIBUTION vagy COLLECTION */
    private String type;

    /** Forras entity id - DISTRIBUTION eseten VaultDistributionLine.id, COLLECTION eseten VaultCollection.id */
    private Long id;

    /** Parent distribution id (csak DISTRIBUTION eseten - a VaultDistribution.id) */
    private Long distributionId;

    /** Bizonylat jelolo - pl. "DIST-2026-042" vagy "COLL-2026-015" */
    private String documentNumber;

    /** Feladoi branch (DISTRIBUTION: az ertektar munkatarsa, COLLECTION: a penztar branch-kod) */
    private String fromBranchCode;
    private String fromBranchName;

    /** Cel branch (DISTRIBUTION: line.targetBranchCode, COLLECTION: kozponti ertektar - null mezo esetben) */
    private String toBranchCode;
    private String toBranchName;

    private String currencyCode;
    private BigDecimal amount;

    /** REQUESTED, IN_PROGRESS, COMPLETED, REJECTED */
    private String status;

    private LocalDateTime createdAt;
    private LocalDateTime completedAt;
    private String note;
}
