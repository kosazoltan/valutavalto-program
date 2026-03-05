package hu.puzzleir.valuta.dto.rateapproval;

import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateApprovalDto {
    private String id;
    private String branchId;
    private String branchName;
    private String currencyCode;
    private BigDecimal oldBuyRate;
    private BigDecimal oldSellRate;
    private BigDecimal newBuyRate;
    private BigDecimal newSellRate;
    private String status;
    private Long requestedById;
    private String requestedByName;
    private Long approvedById;
    private String approvedByName;
    private String requestedAt;
    private String approvedAt;
    private String reason;
}
