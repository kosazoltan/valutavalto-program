package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Napi címletezés snapshot (Delphi: CIMTCopy).
 *
 * A napi záráskor a DenominationBalance aktuális állapotát rögzítjük,
 * hogy a havi gyűjtőkben visszakereshető legyen az aznapi címletezés.
 *
 * Legacy: CIMT{ÉÉVV} tábla — dátum + bankjegy + valutanem + 14 címlet oszlop.
 * Modern: normalizált forma — 1 sor = 1 címlet 1 napon 1 irodán.
 */
@Entity
@Table(name = "daily_denomination_snapshot", indexes = {
    @Index(name = "idx_denom_snap_branch_date", columnList = "branch_id, snapshot_date"),
    @Index(name = "idx_denom_snap_date", columnList = "snapshot_date")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uq_denom_snap",
        columnNames = {"branch_id", "snapshot_date", "currency_code", "denomination_type", "face_value"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyDenominationSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "snapshot_date", nullable = false)
    private LocalDate snapshotDate;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /** BANKNOTE / COIN */
    @Column(name = "denomination_type", nullable = false, length = 10)
    private String denominationType;

    @Column(name = "face_value", nullable = false, precision = 18, scale = 2)
    private BigDecimal faceValue;

    @Column(nullable = false)
    @Builder.Default
    private Integer quantity = 0;

    @Column(name = "total_value", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalValue = BigDecimal.ZERO;

    /** 1=esti, 2=kezelési díj, 3=WU, 4=ÁFA, 5=e-kereskedelem (Delphi: CIMLETTYPE) */
    @Column(name = "closing_type", nullable = false)
    @Builder.Default
    private Integer closingType = 1;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
