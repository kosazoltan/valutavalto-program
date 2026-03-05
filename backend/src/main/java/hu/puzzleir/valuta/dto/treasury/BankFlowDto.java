package hu.puzzleir.valuta.dto.treasury;

import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BankFlowDto {
    private String currencyCode;
    private String currencyName;
    private BigDecimal totalWithdraw;
    private BigDecimal totalDeposit;
    private BigDecimal netFlow;
}
