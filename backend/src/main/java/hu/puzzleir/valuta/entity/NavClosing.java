package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * NAV zárás entity — adóhatósági kötelezettség.
 *
 * Legacy: NAVZARO.DLL — napi/havi zárás a NAV felé.
 * Összegyűjti a napi bevételt, kiadást, kezelési díjat és ÁFA-t.
 */
@Entity
@Table(name = "nav_closing", indexes = {
    @Index(name = "idx_nav_closing_branch_date", columnList = "branch_id, closing_date"),
    @Index(name = "idx_nav_closing_status", columnList = "status"),
    @Index(name = "idx_nav_closing_type_date", columnList = "closing_type, closing_date")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NavClosing {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Zárás dátuma
     */
    @Column(name = "closing_date", nullable = false)
    private LocalDate closingDate;

    /**
     * Iroda
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Zárás típusa
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "closing_type", nullable = false, length = 20)
    private NavClosingType closingType;

    /**
     * Összbevétel (eladás HUF)
     */
    @Column(name = "total_revenue", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalRevenue = BigDecimal.ZERO;

    /**
     * Összkiadás (vásárlás HUF)
     */
    @Column(name = "total_expense", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalExpense = BigDecimal.ZERO;

    /**
     * Kezelési díj összeg
     */
    @Column(name = "handling_fee_total", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal handlingFeeTotal = BigDecimal.ZERO;

    /**
     * ÁFA összeg
     */
    @Column(name = "vat_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal vatAmount = BigDecimal.ZERO;

    /**
     * Státusz
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private NavClosingStatus status = NavClosingStatus.OPEN;

    /**
     * NAV válasz hivatkozási szám
     */
    @Column(name = "nav_reference_number", length = 100)
    private String navReferenceNumber;

    /**
     * Zárást végző pénztáros
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "closed_by")
    private Worker closedBy;

    /**
     * Zárás időpontja
     */
    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    /**
     * Valutánkénti bontás sorok
     */
    @OneToMany(mappedBy = "navClosing", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("currencyCode ASC")
    @Builder.Default
    private List<NavClosingLine> lines = new ArrayList<>();

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ============ HELPER METHODS ============

    public void addLine(NavClosingLine line) {
        lines.add(line);
        line.setNavClosing(this);
    }
}
