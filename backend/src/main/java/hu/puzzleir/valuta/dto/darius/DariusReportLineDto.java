package hu.puzzleir.valuta.dto.darius;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DariusReportLineDto {
    private UUID id;
    private UUID branchId;
    private String branchCode;
    private String currencyCode;

    private Integer buyCount;
    private BigDecimal buyCurrencyAmount;
    private BigDecimal buyHufAmount;

    private Integer sellCount;
    private BigDecimal sellCurrencyAmount;
    private BigDecimal sellHufAmount;

    private BigDecimal avgBuyRate;
    private BigDecimal avgSellRate;
    private BigDecimal handlingFeeHuf;
}
