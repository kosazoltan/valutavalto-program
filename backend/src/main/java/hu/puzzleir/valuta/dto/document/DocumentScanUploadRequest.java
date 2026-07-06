package hu.puzzleir.valuta.dto.document;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentScanUploadRequest {

    private Long customerId;
    private Long transactionId;

    @Pattern(regexp = "ID_CARD|PASSPORT|DRIVERS_LICENSE|COMPANY_REGISTRY|OTHER", message = "Érvénytelen dokumentum típus")
    @Builder.Default
    private String documentType = "OTHER";

    @Size(max = 500, message = "Megjegyzés túl hosszú")
    private String notes;
}
