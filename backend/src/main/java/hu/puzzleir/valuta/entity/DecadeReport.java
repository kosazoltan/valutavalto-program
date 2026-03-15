package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Dekádjelentés (10 napos összesítő).
 * Minden hónap 3 dekádra oszlik: 1-10, 11-20, 21-hó vége.
 * Évenként max 36 dekád (12 hónap × 3).
 */
@Entity
@Table(name = "decade_report", indexes = {
    @Index(name = "idx_decade_report_branch", columnList = "branch_id"),
    @Index(name = "idx_decade_report_year", columnList = "year")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_decade_report_branch_year_decade",
                      columnNames = {"branch_id", "year", "decade"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DecadeReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Column(nullable = false)
    private Integer year;

    /** Dekád sorszám: 1-36 (hónap * 3 - 2, hónap * 3 - 1, hónap * 3) */
    @Column(nullable = false)
    private Integer decade;

    @Column(name = "total_buy_huf", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalBuyHuf = BigDecimal.ZERO;

    @Column(name = "total_sell_huf", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalSellHuf = BigDecimal.ZERO;

    @Column(name = "total_handling_fee", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalHandlingFee = BigDecimal.ZERO;

    @Column(name = "transaction_count", nullable = false)
    @Builder.Default
    private Integer transactionCount = 0;

    // --- MNB árfolyamos készletfelértékelés (dekád haszon) ---
    @Column(name = "opening_inventory_value_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal openingInventoryValueHuf = BigDecimal.ZERO;

    @Column(name = "closing_inventory_value_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal closingInventoryValueHuf = BigDecimal.ZERO;

    @Column(name = "decade_profit_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal decadeProfitHuf = BigDecimal.ZERO;

    @OneToMany(mappedBy = "decadeReport", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<DecadeReportLine> lines = new ArrayList<>();

    // --- Forint kontroll (Legacy: DEKRUTIN.DLL) ---
    /** Forint nyitó egyenleg */
    @Column(name = "forint_opening", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal forintOpening = BigDecimal.ZERO;

    /** Összbevétel (HUF beáramlás: eladásból kapott + átvétel) */
    @Column(name = "forint_total_income", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal forintTotalIncome = BigDecimal.ZERO;

    /** Összkiadás (HUF kiáramlás: vételre kiadott + átadás) */
    @Column(name = "forint_total_expense", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal forintTotalExpense = BigDecimal.ZERO;

    /** Forint záró egyenleg */
    @Column(name = "forint_closing", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal forintClosing = BigDecimal.ZERO;

    /** Forint kontroll egyezik? (nyitó + bevétel - kiadás = záró) */
    @Column(name = "forint_control_valid")
    @Builder.Default
    private Boolean forintControlValid = false;

    /** Forint kontroll eltérés (ha nem egyezik) */
    @Column(name = "forint_control_diff", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal forintControlDiff = BigDecimal.ZERO;

    /** Első bizonylat szám a dekádban */
    @Column(name = "first_receipt_number", length = 20)
    private String firstReceiptNumber;

    /** Utolsó bizonylat szám a dekádban */
    @Column(name = "last_receipt_number", length = 20)
    private String lastReceiptNumber;

    /** Bankkártyás fizetések összege a dekádban */
    @Column(name = "card_payment_total", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal cardPaymentTotal = BigDecimal.ZERO;

    /** Nyomtatás kontroll flag (Legacy: PRINTCONTROL.DEKADPRINT) */
    @Column(name = "print_control_flag")
    @Builder.Default
    private Boolean printControlFlag = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private DecadeReportStatus status = DecadeReportStatus.DRAFT;

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

    public enum DecadeReportStatus {
        DRAFT, CLOSED
    }
}
