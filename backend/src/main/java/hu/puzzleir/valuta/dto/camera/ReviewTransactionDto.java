package hu.puzzleir.valuta.dto.camera;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewTransactionDto {
    private UUID id;
    private Long transactionId;
    private String receiptNumber;
    private LocalDateTime transactionTime;
    private Integer frameOffsetSeconds;
    private String cameraId;
    private UUID recordingId;
}
