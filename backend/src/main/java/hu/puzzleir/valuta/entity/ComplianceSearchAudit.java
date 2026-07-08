package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-11 S2b: compliance keresés-audit bejegyzés — a keresés pillanatának jogi snapshotja.
 * IMMUTABLE (invariáns: mentés után nem változhat, sztornó/módosítás után sem).
 */
@Entity
@Immutable
@Table(name = "compliance_search_audit",
        indexes = @Index(name = "ix_csa_company_created", columnList = "company_id, created_at"))
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ComplianceSearchAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** MULTI-TENANT: cég-azonosító — MINDEN query erre szűr. */
    @Column(name = "company_id", nullable = false, updatable = false)
    private UUID companyId;

    @Column(name = "title", nullable = false, length = 200, updatable = false)
    private String title;

    @Column(name = "description", length = 2000, updatable = false)
    private String description;

    /** JSONB — a TELJES criteria (startDate/endDate MEGTARTVA: a keresés pillanata). */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "criteria_json", nullable = false, columnDefinition = "jsonb", updatable = false)
    private String criteriaJson;

    /** JSONB — List<ComplianceTransactionRowDto> a mentés pillanatában. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "result_snapshot_json", nullable = false, columnDefinition = "jsonb", updatable = false)
    private String resultSnapshotJson;

    @Column(name = "result_count", nullable = false, updatable = false)
    private Integer resultCount;

    @Column(name = "created_by_worker_code", length = 50, updatable = false)
    private String createdByWorkerCode;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
