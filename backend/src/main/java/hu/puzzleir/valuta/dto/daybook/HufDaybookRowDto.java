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
    private String timestamp;
    private BigDecimal atadasHuf;
    private BigDecimal atvetelHuf;
    private boolean storno;
}
