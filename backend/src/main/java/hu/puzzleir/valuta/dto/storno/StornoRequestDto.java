package hu.puzzleir.valuta.dto.storno;

import lombok.*;

import java.math.BigDecimal;

/**
 * Sztornó végrehajtási kérés DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StornoRequestDto {

    private String transactionId;
    private String reason;
    private String approvalId;
    private BigDecimal customExchangeRate;
    private String paymentMethodDid;
    /** Ha true, az aktuális árfolyammal sztornózunk (eltérő árfolyam kezelés — Felmérés: sztorno.docx) */
    private Boolean useCurrentRate;
}
