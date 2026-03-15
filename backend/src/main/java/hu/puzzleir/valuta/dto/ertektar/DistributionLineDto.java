package hu.puzzleir.valuta.dto.ertektar;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class DistributionLineDto {
    private String targetBranchCode;
    private String targetBranchName;
    private String currencyCode;
    private BigDecimal amount;
}
