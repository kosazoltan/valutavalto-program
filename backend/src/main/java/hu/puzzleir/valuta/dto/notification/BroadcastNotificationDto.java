package hu.puzzleir.valuta.dto.notification;

import lombok.*;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class BroadcastNotificationDto {
    private String title;
    private String message;
    private String type;
}
