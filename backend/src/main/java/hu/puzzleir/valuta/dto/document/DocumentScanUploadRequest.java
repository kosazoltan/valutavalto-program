package hu.puzzleir.valuta.dto.document;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentScanUploadRequest {

    private UUID customerId;
    private UUID transactionId;

    @Pattern(regexp = "ID_CARD|PASSPORT|DRIVERS_LICENSE|OTHER", message = "Érvénytelen dokumentum típus")
    @Builder.Default
    private String documentType = "OTHER";

    @Size(max = 500, message = "Megjegyzés túl hosszú")
    private String notes;
}
