package hu.puzzleir.valuta.dto.daybook;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HufDaybookRowDto {
    private Integer annualSequence;
    private String receiptNumber;

    /**
     * FKH-022 FR-K3: a partner (forrás/cél pénztár) azonosítója. Fizikai pénztárnál a
     * Branch.code numerikus része 3 jegyű, 0-paddelt formában (BR076 → "076");
     * VAULT_COUNTERPARTY partnernél a betűkód változatlanul (PRB, ERB, ...).
     */
    private String partnerCode;

    private String timestamp;
    private BigDecimal atadasHuf;
    private BigDecimal atvetelHuf;
    private boolean storno;
}
