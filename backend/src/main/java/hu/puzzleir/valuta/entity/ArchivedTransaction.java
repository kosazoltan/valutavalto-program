package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Archivált tranzakció entity.
 * 
 * A Delphi rendszer havonta archiválta a tranzakciókat (BLOKKFEJ → BFéévhh táblák).
 * Modern verzió: központi tábla időbélyeggel.
 * 
 * Legacy: CopyTables BLOKKFEJ→BFéévhh, BLOKKTETEL→BTéévhh
 */
@Entity
@Table(name = "archived_transactions", indexes = {
    @Index(name = "idx_archived_month", columnList = "archive_month"),
    @Index(name = "idx_archived_branch", columnList = "branch_id,archive_month"),
    @Index(name = "idx_archived_original", columnList = "original_id"),
    @Index(name = "idx_archived_date", columnList = "original_date"),
    @Index(name = "idx_archived_company", columnList = "company_id,archive_month")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ArchivedTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Archivum hónap (YYYY-MM formátum, pl. "2026-03")
     */
    @Column(name = "archive_month", nullable = false, length = 7)
    private String archiveMonth;

    /**
     * Eredeti tranzakció ID
     */
    @Column(name = "original_id", nullable = false)
    private Long originalId;

    /**
     * Bizonylat szám
     */
    @Column(name = "receipt_number", length = 20)
    private String receiptNumber;

    /**
     * Tranzakció típusa (SELL, BUY, REVERSAL stb.)
     */
    @Column(name = "transaction_type", length = 30)
    private String transactionType;

    /**
     * Valuta kód
     */
    @Column(name = "currency_code", length = 3)
    private String currencyCode;

    /**
     * Valuta összeg
     */
    @Column(name = "amount", precision = 18, scale = 2)
    private BigDecimal amount;

    /**
     * Árfolyam
     */
    @Column(name = "exchange_rate", precision = 18, scale = 6)
    private BigDecimal exchangeRate;

    /**
     * HUF összeg
     */
    @Column(name = "huf_amount", precision = 18, scale = 2)
    private BigDecimal hufAmount;

    /**
     * Kezelési díj
     */
    @Column(name = "handling_fee", precision = 18, scale = 2)
    private BigDecimal handlingFee;

    /**
     * Kerekítés
     */
    @Column(name = "rounding_amount", precision = 18, scale = 2)
    private BigDecimal roundingAmount;

    /**
     * Eredeti tranzakció időpontja
     */
    @Column(name = "original_date")
    private LocalDateTime originalDate;

    /**
     * Iroda ID
     */
    @Column(name = "branch_id")
    private UUID branchId;

    /**
     * Munkatárs ID
     */
    @Column(name = "worker_id")
    private Long workerId;

    /**
     * Ügyfél neve
     */
    @Column(name = "customer_name", length = 200)
    private String customerName;

    /**
     * Ügyfél azonosító
     */
    @Column(name = "customer_id", length = 50)
    private String customerId;

    /**
     * Okmány száma
     */
    @Column(name = "document_number", length = 50)
    private String documentNumber;

    /**
     * Archiválás időpontja
     */
    @CreatedDate
    @Column(name = "archived_at", nullable = false, updatable = false)
    private LocalDateTime archivedAt;

    /**
     * Ki archiválta
     */
    @Column(name = "archived_by", length = 100)
    private String archivedBy;

    /**
     * MULTI-TENANT: Cég kapcsolat
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Archív státusz
     */
    @Column(name = "archive_status", length = 20)
    @Builder.Default
    private String archiveStatus = "ARCHIVED";
}
