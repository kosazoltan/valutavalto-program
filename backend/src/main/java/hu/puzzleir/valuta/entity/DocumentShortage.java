package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Okmányhiány-regiszter (legacy: OKMANYHIANY tábla / OKMCTRL.dll).
 *
 * <p>Hiányos/hiányzó okmánnyal rögzített tranzakciók követő-listája: a központ ezeket
 * utólag bekéri/pótoltatja. Manuális/API-vezérelt regiszter (mint a legacy INSERT INTO
 * OKMANYHIANY) — rögzítés + lezárás. Multi-tenant.</p>
 */
@Entity
@Table(name = "document_shortage", indexes = {
        @Index(name = "idx_doc_shortage_company", columnList = "company_id"),
        @Index(name = "idx_doc_shortage_branch", columnList = "company_id,branch_code")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DocumentShortage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "branch_code", length = 20)
    private String branchCode;

    @Column(name = "customer_id", length = 50)
    private String customerId;

    @Column(name = "customer_name", length = 200)
    private String customerName;

    /** Kapcsolódó tranzakció bizonylatszáma (opcionális). */
    @Column(name = "receipt_number", length = 50)
    private String receiptNumber;

    /** A hiányzó okmány megnevezése (pl. "Lakcímkártya", "Adószám-igazolás"). */
    @Column(name = "missing_document", nullable = false, length = 200)
    private String missingDocument;

    @Column(name = "note", columnDefinition = "TEXT")
    private String note;

    @Column(name = "recorded_by", length = 100)
    private String recordedBy;

    @CreatedDate
    @Column(name = "recorded_at", updatable = false)
    private LocalDateTime recordedAt;

    /** Lezárás (pótolva) időpontja — null = nyitott. */
    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;
}
