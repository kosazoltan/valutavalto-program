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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-11 S2a: mentett compliance szűrő-sablon (cégszinten közös, D2 döntés).
 * A criteria dátum NÉLKÜL tárolt (P136): startDate/endDate a mentés előtt nullázva.
 */
@Entity
@Table(name = "compliance_search_template",
        indexes = @Index(name = "ux_cst_company_name", columnList = "company_id, name", unique = true))
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ComplianceSearchTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** MULTI-TENANT: cég-azonosító — MINDEN query erre szűr. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    /** JSONB — ComplianceTransactionSearchCriteria JSON-ként, startDate/endDate nélkül. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "criteria_json", nullable = false, columnDefinition = "jsonb")
    private String criteriaJson;

    @Column(name = "created_by_worker_code", length = 50)
    private String createdByWorkerCode;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
