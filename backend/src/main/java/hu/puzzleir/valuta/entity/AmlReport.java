package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * AML bejelentés entity.
 *
 * 2017. évi LIII. tv. — Pénzmosás és terrorizmus finanszírozása megelőzéséről.
 */
@Entity
@Table(name = "aml_report", indexes = {
    @Index(name = "idx_aml_report_company", columnList = "company_id"),
    @Index(name = "idx_aml_report_status", columnList = "status"),
    @Index(name = "idx_aml_report_customer", columnList = "customer_id"),
    @Index(name = "idx_aml_report_type", columnList = "report_type"),
    @Index(name = "idx_aml_report_created", columnList = "created_at")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AmlReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "customer_id", length = 50)
    private String customerId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id")
    private Transaction transaction;

    @Enumerated(EnumType.STRING)
    @Column(name = "report_type", nullable = false, length = 30)
    private AmlReportType reportType;

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_level", nullable = false, length = 20)
    @Builder.Default
    private AmlRiskLevel riskLevel = AmlRiskLevel.LOW;

    @Column(name = "amount_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal amountHuf = BigDecimal.ZERO;

    @Column(name = "currency_code", length = 3)
    private String currencyCode;

    @Column(name = "original_amount", precision = 18, scale = 2)
    private BigDecimal originalAmount;

    @Column(name = "customer_name", length = 200)
    private String customerName;

    @Column(name = "document_type", length = 30)
    private String documentType;

    @Column(name = "document_number", length = 50)
    private String documentNumber;

    @Column(name = "worker_notes", columnDefinition = "TEXT")
    private String workerNotes;

    @Column(name = "reviewed_by", length = 100)
    private String reviewedBy;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    @Builder.Default
    private AmlReportStatus status = AmlReportStatus.DRAFT;

    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;

    @Column(name = "acknowledged_at")
    private LocalDateTime acknowledgedAt;

    @Column(name = "external_reference", length = 100)
    private String externalReference;

    @Column(name = "created_by", length = 100)
    private String createdBy;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
