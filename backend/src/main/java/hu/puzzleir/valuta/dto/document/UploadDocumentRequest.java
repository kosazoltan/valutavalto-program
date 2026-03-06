package hu.puzzleir.valuta.dto.document;

import lombok.*;

import java.util.UUID;

/**
 * Dokumentum feltöltés metaadat (multipart form-data kiegészítés).
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class UploadDocumentRequest {
    private UUID customerId;
    private UUID transactionId;
    private String documentType;
    private String notes;
}
