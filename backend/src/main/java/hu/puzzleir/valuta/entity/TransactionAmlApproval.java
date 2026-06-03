package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * AML felsővezetői jóváhagyás audit-rekord (Pmt. 14/A. § (4), 14/2025. (VI. 16.) MNB rendelet,
 * EBC pénzmosási szabályzat V.2.6).
 *
 * <p>A magas kockázatú esetekben (FATF 1/a ellenintézkedés, magas-kockázatú harmadik ország ≥5M Ft,
 * PEP, éves göngyölési limit stb.) a tranzakció kizárólag a kijelölt felelős vezető írásos
 * jóváhagyásával teljesíthető. A szabályzat V.2.6 4. lépése szerint <b>az engedélyező nevét a
 * rendszerben rögzíteni kell</b>, és a dokumentációt 8 évig megőrizni. Ez a rekord INSERT-ONLY
 * (módosítás/törlés nincs → immutable audit), és az engedélyező NEVÉT pillanatképként tárolja.</p>
 */
@Entity
@Table(name = "transaction_aml_approval", indexes = {
        @Index(name = "idx_aml_approval_company", columnList = "company_id"),
        @Index(name = "idx_aml_approval_branch", columnList = "branch_id"),
        @Index(name = "idx_aml_approval_approved_at", columnList = "approved_at")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransactionAmlApproval {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "branch_id")
    private UUID branchId;

    /** A jóváhagyott tranzakció bizonylatszáma (ha a jóváhagyáskor már ismert). */
    @Column(name = "receipt_number", length = 50)
    private String receiptNumber;

    /** A tranzakció HUF végösszege (a jóváhagyás kontextusához). */
    @Column(name = "huf_amount", precision = 18, scale = 2)
    private BigDecimal hufAmount;

    /** Az ügyfél neve (a jóváhagyás kontextusához). */
    @Column(name = "customer_name", length = 255)
    private String customerName;

    /** A jóváhagyást kiváltó AML-indok (FATF 1/a, magas-kockázatú ország ≥5M, PEP, éves limit stb.). */
    @Column(name = "approval_reason", nullable = false, length = 500)
    private String approvalReason;

    /** Az engedélyező felsővezető workerId-ja. */
    @Column(name = "approved_by_worker_id", nullable = false)
    private Long approvedByWorkerId;

    /** Az engedélyező NEVE — pillanatkép (V.2.6: "az engedélyező nevét rögzíti"; immutable). */
    @Column(name = "approved_by_name", nullable = false, length = 255)
    private String approvedByName;

    @Column(name = "approved_at", nullable = false)
    private LocalDateTime approvedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
