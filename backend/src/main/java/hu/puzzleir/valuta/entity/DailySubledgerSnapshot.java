package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Napi al-pénztár zárás snapshot (Delphi: EdatCopy, KdatCopy, WzarCopy).
 *
 * Rögzíti az al-pénztárak (kezelési díj, e-kereskedelem, WU USD/HUF/ÁFA)
 * napi nyitó/bevétel/kiadás/záró állapotát a napi záráskor.
 *
 * Legacy táblák:
 *   EDAT{ÉÉVV} — e-kereskedelem nyitó/bevétel/kiadás/záró
 *   KDAT{ÉÉVV} — kezelési díj nyitó/bevétel/kiadás/záró
 *   WZAR{ÉÉVV} — WU (USD nyitó/bevétel/kiadás/záró + HUF + ÁFA)
 *
 * Modern: egységes tábla subledger_type-pal megkülönböztetve.
 */
@Entity
@Table(name = "daily_subledger_snapshot", indexes = {
    @Index(name = "idx_subledger_snap_branch_date", columnList = "branch_id, snapshot_date"),
    @Index(name = "idx_subledger_snap_type", columnList = "subledger_type")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uq_subledger_snap",
        columnNames = {"branch_id", "snapshot_date", "subledger_type", "currency_code"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailySubledgerSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "snapshot_date", nullable = false)
    private LocalDate snapshotDate;

    /**
     * Al-pénztár típusa:
     *   ECOMMERCE — e-kereskedelem (Delphi: EKERDATA → EDAT)
     *   HANDLING_FEE — kezelési díj (Delphi: KEZDIJDATA → KDAT)
     *   WU_USD — Western Union USD pénztár
     *   WU_HUF — Western Union HUF pénztár
     *   WU_VAT — Western Union ÁFA pénztár
     */
    @Column(name = "subledger_type", nullable = false, length = 20)
    private String subledgerType;

    @Column(name = "currency_code", nullable = false, length = 3)
    @Builder.Default
    private String currencyCode = "HUF";

    @Column(name = "opening_balance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal openingBalance = BigDecimal.ZERO;

    @Column(nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal income = BigDecimal.ZERO;

    @Column(nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal expense = BigDecimal.ZERO;

    @Column(name = "closing_balance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal closingBalance = BigDecimal.ZERO;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
