package hu.puzzleir.valuta.dto.notification;

import lombok.*;

import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SendNotificationDto {
    private Long workerId;
    private UUID branchId;
    private String title;
    private String message;
    private String type;
}
