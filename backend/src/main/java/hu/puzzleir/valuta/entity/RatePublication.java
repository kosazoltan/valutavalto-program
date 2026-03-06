package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "rate_publication", indexes = {
    @Index(name = "idx_rate_publication_wg", columnList = "workgroup_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RatePublication {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "template_id")
    private UUID templateId;

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

    @Column(columnDefinition = "TEXT")
    private String notes;
}
