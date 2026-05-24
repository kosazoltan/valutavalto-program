package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Archiválási feladat entity.
 */
@Entity
@Table(name = "archive_task")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ArchiveTask {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "task_type", nullable = false, length = 100)
    private String taskType;

    @Column(name = "entity_type", nullable = false, length = 100)
    private String entityType;

    @Column(columnDefinition = "TEXT")
    private String criteria;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private ArchiveTaskStatus status = ArchiveTaskStatus.PENDING;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "archive_location", length = 500)
    private String archiveLocation;
}
