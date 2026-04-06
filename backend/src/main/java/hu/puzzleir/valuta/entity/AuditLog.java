package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

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
}
