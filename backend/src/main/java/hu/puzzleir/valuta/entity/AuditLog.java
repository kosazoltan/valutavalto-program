package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Table(name = "audit_log", indexes = {
    @Index(name = "idx_audit_log_company_id", columnList = "company_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(nullable = false, length = 50)
    private String action;

    @Column(name = "entity_type", nullable = false, length = 50)
    private String entityType;

    @Column(name = "entity_id", length = 50)
    private String entityId;

    @Column(name = "user_id", length = 50)
    private String userId;

    @Column(name = "user_name", length = 100)
    private String userName;

    @Column(name = "branch_id", length = 50)
    private String branchId;

    @Column(name = "branch_name", length = 100)
    private String branchName;

    @Column(columnDefinition = "TEXT")
    private String changes;

    @Column(name = "ip_address", length = 50)
    private String ipAddress;

    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @Column(name = "old_value", columnDefinition = "TEXT")
    private String oldValue;

    @Column(name = "new_value", columnDefinition = "TEXT")
    private String newValue;

    @Column(name = "reason", length = 1000)
    private String reason;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * SHA-256 hash az aktualis bejegyzes tartalmabol.
     * H11 gap fix: tamper-evidence hash-lanc penzugyi audit logokhoz.
     */
    @Column(name = "entry_hash", length = 64)
    private String entryHash;

    /**
     * Az elozo bejegyzes hash-e — lancolashoz.
     * Ha null, ez az elso bejegyzes a lancban.
     */
    @Column(name = "previous_hash", length = 64)
    private String previousHash;

    // =========================================================================
    // V234 (2026-05-18) - belso log+audit modul - AI-olvashato mezok
    // =========================================================================

    /**
     * Globalisan egyedi UUID, kliens-szinten generalt (idempotency).
     *
     * <p>Copilot PR #681 P2: a UNIQUE constraint a Flyway V234-ben
     * `audit_log_event_id_unique` neven mar letre van hozva. NEM duplazzuk
     * @Column unique=true-val (Hibernate auto-gen nev kollizio ddl-auto=validate-nel).
     */
    @Column(name = "event_id")
    private UUID eventId;

    /** Idozona-tudatos timestamp (UTC). A regi `created_at` LocalDateTime backward-compat marad. */
    @Column(name = "ts")
    private Instant ts;

    /** Esemeny tipusa kanonikus formaban (pl. "transaction.committed", "rate.published"). */
    @Column(name = "event_type", length = 80)
    private String eventType;

    /** JSONB - elozo allapot UPDATE-nel. */
    @Column(name = "before_state", columnDefinition = "jsonb")
    private String beforeState;

    /** JSONB - uj allapot CREATE/UPDATE-nel. */
    @Column(name = "after_state", columnDefinition = "jsonb")
    private String afterState;

    /** Penzugyi-szintu osszeg (sztorno/tranzakcio audit). */
    @Column(name = "amount", precision = 18, scale = 2)
    private BigDecimal amount;

    @Column(name = "currency", length = 3)
    private String currency;

    @Column(name = "receipt_number", length = 20)
    private String receiptNumber;

    /** W3C TraceContext 32-hex - kliens-backend korrelacio. */
    @Column(name = "trace_id", length = 32)
    private String traceId;

    /** Kliens kontextus: CASHIER | TREASURY_HQ | RFM | ADMIN. */
    @Column(name = "client_context", length = 20)
    private String clientContext;

    /** Manager-approval audit (ha valaki jovahagyta a sztornot/etc). */
    @Column(name = "signed_by", length = 80)
    private String signedBy;

    @Column(name = "worker_role", length = 40)
    private String workerRole;
}
