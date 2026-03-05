package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Backup mentés nyilvántartás.
 * Tárolja a mentés típusát, státuszát, fájl elérési útját és méretét.
 */
@Entity
@Table(name = "backup_record")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BackupRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "backup_type", nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private BackupType backupType;

    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private BackupStatus status;

    @Column(name = "file_path", length = 500)
    private String filePath;

    @Column(name = "file_size_bytes")
    private Long fileSizeBytes;

    @Column(name = "started_at", nullable = false)
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_by", length = 100)
    private String createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (startedAt == null) startedAt = LocalDateTime.now();
        if (status == null) status = BackupStatus.RUNNING;
    }
}
