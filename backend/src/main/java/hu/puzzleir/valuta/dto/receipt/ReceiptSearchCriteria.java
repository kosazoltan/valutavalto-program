package hu.puzzleir.valuta.dto.receipt;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReceiptSearchCriteria {
    private String number;
    private LocalDate dateFrom;
    private LocalDate dateTo;
    private String type;
    private BigDecimal minAmount;
    private BigDecimal maxAmount;
    private String customer;
}
