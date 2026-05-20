package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "rate_publication", indexes = {
    @Index(name = "idx_rate_publication_wg", columnList = "workgroup_id"),
    @Index(name = "idx_rate_publication_company", columnList = "company_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RatePublication {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "template_id")
    private UUID templateId;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "workgroup_id", nullable = false)
    private UUID workgroupId;

    @Column(name = "published_by", nullable = false)
    private Long publishedBy;

    @Column(name = "published_at")
    @Builder.Default
    private LocalDateTime publishedAt = LocalDateTime.now();

    @Column(name = "affected_branches")
    @Builder.Default
    private Integer affectedBranches = 0;

    @Column(name = "source", length = 32)
    @Builder.Default
    private String source = "SERVER_UI";

    @Column(name = "client_package_id", length = 80)
    private String clientPackageId;

    @Column(name = "client_package_hash", length = 128)
    private String clientPackageHash;

    @Column(name = "client_version", length = 40)
    private String clientVersion;

    @Column(name = "client_device_id", length = 80)
    private String clientDeviceId;

    @Column(columnDefinition = "TEXT")
    private String notes;

    /** Optimista zárolás (RFM concurrent szerkesztés-védelem, VV-ELVI 7.3). */
    @Version
    private Long version;
}
