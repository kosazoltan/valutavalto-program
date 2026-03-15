package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Kezelési díj dekád összesítő.
 * Legacy: KEZDEKAD.DLL — NAPIKEZELESIDIJ + KEZD* havi táblák összesítése.
 *
 * Minden dekád (10 napos időszak) kezelési díj forgalmát rögzíti:
 * - Nyitó egyenleg (előző dekád záró)
 * - Vételi/eladási díjak
 * - Bankkártyás/készpénzes szétválasztás
 * - Sorszámozás (KEZDIJSORSZAM)
 */
@Entity
@Table(name = "handling_fee_decade_report", uniqueConstraints = {
    @UniqueConstraint(name = "uk_hf_decade_branch_year_decade",
                      columnNames = {"branch_id", "year", "decade"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HandlingFeeDecadeReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Column(nullable = false)
    private Integer year;

    @Column(nullable = false)
    private Integer decade;

    @Column(name = "period_start", nullable = false)
    private LocalDate periodStart;

    @Column(name = "period_end", nullable = false)
    private LocalDate periodEnd;

    /** Nyitó egyenleg — előző dekád záró */
    @Column(name = "opening_balance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal openingBalance = BigDecimal.ZERO;

    /** Vételi kezelési díj összeg */
    @Column(name = "total_buy_fee", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalBuyFee = BigDecimal.ZERO;

    /** Eladási kezelési díj összeg */
    @Column(name = "total_sell_fee", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalSellFee = BigDecimal.ZERO;

    /** Bankkártyás díj (elkülönítve — FIZETOESZKOZ=2) */
    @Column(name = "total_card_fee", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalCardFee = BigDecimal.ZERO;

    /** Készpénzes díj */
    @Column(name = "total_cash_fee", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalCashFee = BigDecimal.ZERO;

    /** Záró egyenleg */
    @Column(name = "closing_balance", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal closingBalance = BigDecimal.ZERO;

    /** Első sorszám a dekádban (KEZDIJSORSZAM) */
    @Column(name = "first_sequence_number")
    private Integer firstSequenceNumber;

    /** Utolsó sorszám a dekádban */
    @Column(name = "last_sequence_number")
    private Integer lastSequenceNumber;

    @Column(name = "buy_count", nullable = false)
    @Builder.Default
    private Integer buyCount = 0;

    @Column(name = "sell_count", nullable = false)
    @Builder.Default
    private Integer sellCount = 0;

    @Column(name = "total_count", nullable = false)
    @Builder.Default
    private Integer totalCount = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private DecadeReport.DecadeReportStatus status = DecadeReport.DecadeReportStatus.DRAFT;

    @Column(nullable = false)
    @Builder.Default
    private Boolean printed = false;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    @Column(name = "closed_by")
    private Long closedBy;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
