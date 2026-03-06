package hu.puzzleir.valuta.dto.document;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class ScannedDocumentDto {
    private UUID id;
    private UUID customerId;
    private UUID transactionId;
    private String documentType;
    private String fileName;
    private String mimeType;
    private Long fileSizeBytes;
    private String storagePath;
    private Long scannedBy;
    private LocalDateTime scannedAt;
    private String notes;
}
