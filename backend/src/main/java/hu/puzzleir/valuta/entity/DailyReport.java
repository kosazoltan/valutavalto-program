package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Napi jelentés entity (irodánként).
 *
 * Legacy mapping: SZERVER — napijel.dll, zarasctrl.dll
 * Napi forgalmi adatok összesítése és beküldése a központba.
 */
@Entity
@Table(name = "daily_report", indexes = {
    @Index(name = "idx_daily_report_branch", columnList = "branch_id"),
    @Index(name = "idx_daily_report_date", columnList = "report_date")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_daily_report_branch_date",
                      columnNames = {"branch_id", "report_date"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Iroda
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Jelentés dátuma
     */
    @Column(name = "report_date", nullable = false)
    private LocalDate reportDate;

    /**
     * Beküldve (lezárva)
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean submitted = false;

    /**
     * Beküldés időpontja
     */
    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;

    /**
     * Beküldő dolgozó
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "submitted_by_id")
    private Worker submittedBy;

    /**
     * Jelentés adatai (JSON formátumú összesítés)
     */
    @Column(name = "report_data", columnDefinition = "TEXT")
    private String reportData;

    /**
     * Napi vételi forgalom (HUF)
     */
    @Column(name = "total_buy_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalBuyHuf = BigDecimal.ZERO;

    /**
     * Napi eladási forgalom (HUF)
     */
    @Column(name = "total_sell_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalSellHuf = BigDecimal.ZERO;

    /**
     * Napi kezelési díj (HUF)
     */
    @Column(name = "total_fee_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalFeeHuf = BigDecimal.ZERO;

    /**
     * Napi profit (HUF)
     */
    @Column(name = "total_profit", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalProfit = BigDecimal.ZERO;

    /**
     * Tranzakciók száma
     */
    @Column(name = "transaction_count")
    @Builder.Default
    private Integer transactionCount = 0;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
