package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Import felíró entity — fióki adatimport nyilvántartás.
 *
 * Legacy: Import felíró DLL — fiókok adatainak (tranzakciók, készletek, zárások)
 * importálása a központi rendszerbe.
 */
@Entity
@Table(name = "data_import_jobs", indexes = {
    @Index(name = "idx_data_import_jobs_branch", columnList = "branch_id"),
    @Index(name = "idx_data_import_jobs_status", columnList = "status"),
    @Index(name = "idx_data_import_jobs_type", columnList = "import_type")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DataImportJob {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Enumerated(EnumType.STRING)
    @Column(name = "import_type", nullable = false, length = 30)
    private DataImportType importType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private DataImportStatus status = DataImportStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false, length = 10)
    @Builder.Default
    private DataImportSourceType sourceType = DataImportSourceType.API;

    @Column(name = "source_file", length = 500)
    private String sourceFile;

    @Column(name = "total_records")
    @Builder.Default
    private Integer totalRecords = 0;

    @Column(name = "imported_records")
    @Builder.Default
    private Integer importedRecords = 0;

    @Column(name = "failed_records")
    @Builder.Default
    private Integer failedRecords = 0;

    @Column(name = "error_log", columnDefinition = "TEXT")
    private String errorLog;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
