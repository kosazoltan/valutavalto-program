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
 * Darius/Raiffeisen napi jelentés.
 *
 * Üzleti háttér:
 * A valutaváltó cégcsoport napi tranzakciós adatait a Raiffeisen Banknak
 * (Darius rendszeren keresztül) be kell küldeni. Ez törvényi/szerződéses
 * kötelezettség. A főértéktár felelős a beküldésért és jóváhagyásáért.
 *
 * Állapotgép: DRAFT → GENERATED → SUBMITTED → ACKNOWLEDGED / FAILED → RETRY
 */
@Entity
@Table(name = "darius_daily_report", indexes = {
    @Index(name = "idx_darius_report_company", columnList = "company_id"),
    @Index(name = "idx_darius_report_date", columnList = "report_date"),
    @Index(name = "idx_darius_report_status", columnList = "status")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_darius_report_company_date",
        columnNames = {"company_id", "report_date"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DariusDailyReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** A jelentés napja */
    @Column(name = "report_date", nullable = false)
    private LocalDate reportDate;

    /** Állapot: DRAFT, GENERATED, SUBMITTED, ACKNOWLEDGED, FAILED */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DariusReportStatus status;

    // === Összesített adatok ===

    /** Összes vétel HUF összeg (napi) */
    @Column(name = "total_buy_huf", precision = 18, scale = 2)
    private BigDecimal totalBuyHuf;

    /** Összes eladás HUF összeg (napi) */
    @Column(name = "total_sell_huf", precision = 18, scale = 2)
    private BigDecimal totalSellHuf;

    /** Összes tranzakció darabszám */
    @Column(name = "transaction_count")
    private Integer transactionCount;

    /** Összes kezelési díj HUF */
    @Column(name = "total_handling_fee_huf", precision = 18, scale = 2)
    private BigDecimal totalHandlingFeeHuf;

    /** Irodák száma a jelentésben */
    @Column(name = "branch_count")
    private Integer branchCount;

    // === Payload ===

    /** Generált payload (JSON/XML) — a ténylegesen beküldött adat */
    @Column(name = "payload", columnDefinition = "TEXT")
    private String payload;

    /** Payload formátum: JSON vagy XML */
    @Column(name = "payload_format", length = 10)
    private String payloadFormat;

    /** Payload SHA-256 hash (integritás) */
    @Column(name = "payload_hash", length = 64)
    private String payloadHash;

    // === Beküldés ===

    /** Beküldés időpontja */
    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;

    /** Beküldő felhasználó */
    @Column(name = "submitted_by", length = 100)
    private String submittedBy;

    /** Bank válasz / acknowledgment referencia */
    @Column(name = "ack_reference", length = 200)
    private String ackReference;

    /** Bank válasz időpontja */
    @Column(name = "ack_at")
    private LocalDateTime ackAt;

    // === Hiba ===

    /** Utolsó hiba üzenet */
    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    /** Retry számláló */
    @Column(name = "retry_count", nullable = false)
    @Builder.Default
    private Integer retryCount = 0;

    /** Maximális retry szám */
    @Column(name = "max_retries", nullable = false)
    @Builder.Default
    private Integer maxRetries = 3;

    /** Következő retry időpont */
    @Column(name = "next_retry_at")
    private LocalDateTime nextRetryAt;

    // === Jóváhagyás (4-eyes) ===

    /** Jóváhagyó felhasználó (főértéktáros) */
    @Column(name = "approved_by", length = 100)
    private String approvedBy;

    /** Jóváhagyás időpontja */
    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    // === Audit ===

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /** Megjegyzés (opcionális, pl. manuális korrekció oka) */
    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;
}
