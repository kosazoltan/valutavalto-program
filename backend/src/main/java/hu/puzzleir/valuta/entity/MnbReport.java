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
 * MNB adatszolgáltatási riport entity.
 *
 * Legacy: MNB gyűjtő DLL — kötelező napi/heti/havi adatszolgáltatás
 * a Magyar Nemzeti Bank felé a pénzváltó forgalomról.
 */
@Entity
@Table(name = "mnb_report", indexes = {
    @Index(name = "idx_mnb_report_type_date", columnList = "report_type, report_date"),
    @Index(name = "idx_mnb_report_branch_date", columnList = "branch_id, report_date"),
    @Index(name = "idx_mnb_report_status", columnList = "status")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MnbReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Riport típusa (napi/heti/havi/negyedéves/éves)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "report_type", nullable = false, length = 20)
    private MnbReportType reportType;

    /**
     * Riport dátuma (napi: az adott nap, havi: hónap utolsó napja, stb.)
     */
    @Column(name = "report_date", nullable = false)
    private LocalDate reportDate;

    /**
     * Riport státusza
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private MnbReportStatus status = MnbReportStatus.DRAFT;

    /**
     * Iroda (branch)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Összes vétel HUF-ban
     */
    @Column(name = "total_buy_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalBuyHuf = BigDecimal.ZERO;

    /**
     * Összes eladás HUF-ban
     */
    @Column(name = "total_sell_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalSellHuf = BigDecimal.ZERO;

    /**
     * Összes tranzakció szám
     */
    @Column(name = "total_transactions")
    @Builder.Default
    private Integer totalTransactions = 0;

    /**
     * Beküldés időpontja
     */
    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;

    /**
     * Elfogadás időpontja
     */
    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    /**
     * Elutasítás indoka
     */
    @Column(name = "rejection_reason", length = 1000)
    private String rejectionReason;

    /**
     * Generált XML tartalom
     */
    @Column(name = "xml_content", columnDefinition = "TEXT")
    private String xmlContent;

    /**
     * Riport sorok (valutánkénti bontás)
     */
    @OneToMany(mappedBy = "mnbReport", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("currencyCode ASC")
    @Builder.Default
    private List<MnbReportLine> lines = new ArrayList<>();

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ============ HELPER METHODS ============

    /**
     * Sor hozzáadása a riporthoz
     */
    public void addLine(MnbReportLine line) {
        lines.add(line);
        line.setMnbReport(this);
    }
}
