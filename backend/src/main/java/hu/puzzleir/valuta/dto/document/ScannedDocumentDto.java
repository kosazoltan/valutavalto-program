package hu.puzzleir.valuta.dto.document;

import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class ScannedDocumentDto {
    private UUID id;
    private Long customerId;
    private Long transactionId;
    private String documentType;
    private String fileName;
    private String mimeType;
    private Long fileSizeBytes;
    private String storagePath;
    private Long scannedBy;
    private LocalDateTime scannedAt;
    private String notes;
    private LocalDate validUntil;

    /** FS-5: van-e előlap-kép (side=FRONT) a dokumentumhoz. */
    private Boolean hasFrontImage;
    /** FS-5: van-e hátlap-kép (side=BACK) a dokumentumhoz. */
    private Boolean hasBackImage;
}
