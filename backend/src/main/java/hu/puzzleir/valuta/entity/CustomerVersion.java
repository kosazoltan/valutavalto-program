package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FS-3 (D1): ügyfél-törzsadat történeti snapshot. IMMUTABILIS — nincs update
 * útvonal. Snapshot: a CustomerDto teljes JSON-ja (terv T1).
 */
@Entity
@Table(name = "customer_version",
       uniqueConstraints = @UniqueConstraint(name = "uq_customer_version_no",
               columnNames = {"customer_id", "version_no"}),
       indexes = @Index(name = "idx_customer_version_company",
               columnList = "company_id, customer_id"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerVersion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    /** MULTI-TENANT: denormalizált tenant-kulcs a szűrt lekérdezésekhez. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "version_no", nullable = false)
    private Long versionNo;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "snapshot", nullable = false, columnDefinition = "jsonb")
    private String snapshot;

    @Enumerated(EnumType.STRING)
    @Column(name = "change_source", nullable = false, length = 20)
    private DataChangeSource changeSource;

    @Column(name = "changed_by", length = 80)
    private String changedBy;

    @Column(name = "changed_at", nullable = false)
    @Builder.Default
    private LocalDateTime changedAt = LocalDateTime.now();
}
