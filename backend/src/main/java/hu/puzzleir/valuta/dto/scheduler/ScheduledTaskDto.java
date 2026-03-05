package hu.puzzleir.valuta.dto.scheduler;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class ScheduledTaskDto {
    private UUID id;
    private String taskName;
    private String cronExpression;
    private String taskType;
    private Boolean isActive;
    private LocalDateTime lastRunAt;
    private LocalDateTime nextRunAt;
    private String lastResult;
    private String parameters;
    private LocalDateTime createdAt;
}
