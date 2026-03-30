package hu.puzzleir.valuta.dto.transaction;

import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransactionBanknoteDto {
    private Long id;
    private Long transactionId;
    private Long transactionLineId;
    private String currencyCode;
    private BigDecimal faceValue;
    private Integer quantity;
    private String direction;
    private BigDecimal totalValue;
}
