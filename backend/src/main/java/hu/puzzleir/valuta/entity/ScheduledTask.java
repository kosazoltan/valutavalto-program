package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * ScheduledTask entity — időzített feladatok nyilvántartása.
 */
@Entity
@Table(name = "scheduled_task")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ScheduledTask {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "task_name", nullable = false, length = 100)
    private String taskName;

    @Column(name = "cron_expression", nullable = false, length = 50)
    private String cronExpression;

    @Enumerated(EnumType.STRING)
    @Column(name = "task_type", nullable = false, length = 30)
    private TaskType taskType;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "last_run_at")
    private LocalDateTime lastRunAt;

    @Column(name = "next_run_at")
    private LocalDateTime nextRunAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "last_result", length = 20)
    private TaskResult lastResult;

    @Column(columnDefinition = "JSONB")
    private String parameters;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    public enum TaskType {
        RATE_SYNC, BACKUP, REPORT, CLOSING_REMINDER, HEALTH_CHECK
    }

    public enum TaskResult {
        SUCCESS, FAILURE, SKIPPED
    }
}
