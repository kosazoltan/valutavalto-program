package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FTP szinkronizáció napló entity.
 * Legacy FTP kompatibilitás: a régi rendszer FTP-vel kommunikált a központi szerverrel (port 21100).
 */
@Entity
@Table(name = "ftp_sync_log", indexes = {
    @Index(name = "idx_ftp_sync_log_branch", columnList = "branch_id"),
    @Index(name = "idx_ftp_sync_log_status", columnList = "status"),
    @Index(name = "idx_ftp_sync_log_started", columnList = "started_at")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class FtpSyncLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private FtpSyncDirection direction;

    @Column(name = "file_name", length = 255)
    private String fileName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private FtpSyncStatus status = FtpSyncStatus.SUCCESS;

    @Column(name = "file_size_bytes")
    private Long fileSizeBytes;

    @Column(name = "started_at", nullable = false)
    @Builder.Default
    private LocalDateTime startedAt = LocalDateTime.now();

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    public enum FtpSyncDirection {
        UPLOAD, DOWNLOAD
    }

    public enum FtpSyncStatus {
        SUCCESS, FAILED
    }
}
