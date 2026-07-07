package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.UUID;

/** FS-3 (D1): tenant-cég törzsadat történeti snapshot. */
@Entity
@Table(name = "company_version",
        uniqueConstraints = @UniqueConstraint(name = "uq_company_version_no",
                columnNames = {"company_id", "version_no"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompanyVersion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

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
